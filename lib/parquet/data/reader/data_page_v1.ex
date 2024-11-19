defmodule Parquet.Data.Reader.DataPageV1 do
  alias Parquet.Data.Reader.Encoding
  alias Parquet.Data.Reader.Primitive

  @doc """
  Reads a v1 data page and outputs a map representing the rows in the page.
  The returned output closely mirrors the Dremel columnar representation.
  """
  def read(
        file,
        header,
        uncompressed_page_size,
        path_info,
        definition_level_to_furthest_path_index,
        max_repetition_level,
        max_definition_level
      ) do
    {:ok, page_bytes} = :file.read(file, uncompressed_page_size)

    {page_repetition_levels, page_bytes} =
      decode_level(max_repetition_level, header.repetition_level_encoding, page_bytes)

    {page_definition_levels, page_bytes} =
      decode_level(max_definition_level, header.definition_level_encoding, page_bytes)

    decode_page(
      page_bytes,
      path_info,
      definition_level_to_furthest_path_index,
      page_repetition_levels,
      page_definition_levels,
      max_repetition_level,
      max_definition_level,
      %{},
      header.num_values
    )
  end

  defp decode_level(max_level, level_encoding, page_bytes) do
    case max_level do
      0 ->
        {nil, page_bytes}

      _ ->
        <<_encoded_length::unsigned-integer-32-little, page_bytes::binary>> = page_bytes

        case level_encoding do
          :rle -> Encoding.decode_rle_hybrid(page_bytes, max_level)
          :bit_packed -> Encoding.decode_bitpacked(page_bytes, max_level)
        end
    end
  end

  defp decode_page(
         page_bytes,
         path_info,
         definition_level_to_furthest_path_index,
         page_repetition_levels,
         page_definition_levels,
         max_repetition_level,
         max_definition_level,
         decoded_rows,
         total_value_count,
         value_counter \\ 0
       ) do
    {page_repetition_level, page_repetition_levels} = Encoding.pop_value(page_repetition_levels)

    page_repetition_level =
      if is_binary(page_repetition_level),
        do: :binary.decode_unsigned(page_repetition_level),
        else: page_repetition_level

    {page_definition_level, page_definition_levels} = Encoding.pop_value(page_definition_levels)

    page_definition_level =
      if is_binary(page_definition_level),
        do: :binary.decode_unsigned(page_definition_level),
        else: page_definition_level

    if total_value_count == value_counter do
      decoded_rows
    else
      {value, page_bytes} =
        if page_definition_level == max_definition_level do
          # fully defined

          leaf_node = List.last(path_info)

          case leaf_node do
            %{type: :int32} ->
              Primitive.decode_int32(page_bytes)

            _ ->
              raise "Unsupported leaf node type."
          end
        else
          # partially defined => nil value
          {nil, page_bytes}
        end

      decoded_rows =
        if page_repetition_level == 0 do
          path_to_create =
            Enum.take(
              path_info,
              definition_level_to_furthest_path_index[page_definition_level] + 1
            )

          row = create_row(path_to_create, value)
          new_row_idx = map_size(decoded_rows)
          Map.put(decoded_rows, new_row_idx, row)
        else
          path_to_update =
            Enum.take(
              path_info,
              definition_level_to_furthest_path_index[page_definition_level] + 1
            )

          definition_level_to_furthest_path_index[page_definition_level]
          last_row_idx = map_size(decoded_rows) - 1

          row =
            update_row(path_to_update, value, page_repetition_level, decoded_rows[last_row_idx])

          Map.put(decoded_rows, last_row_idx, row)
        end

      decode_page(
        page_bytes,
        path_info,
        definition_level_to_furthest_path_index,
        page_repetition_levels,
        page_definition_levels,
        max_repetition_level,
        max_definition_level,
        decoded_rows,
        total_value_count,
        value_counter + 1
      )
    end
  end

  defp create_row(path_to_create, value) do
    case path_to_create do
      [] ->
        value

      [%{name: name, is_repeated: is_repeated} | path_to_create] ->
        if is_repeated do
          %{
            0 => %{
              name => create_row(path_to_create, value)
            }
          }
        else
          %{
            name => create_row(path_to_create, value)
          }
        end
    end
  end

  defp update_row(path_to_update, value, repetition_level_to_append, row, repetition_count \\ 0) do
    case path_to_update do
      [] ->
        value

      [%{name: name, is_repeated: is_repeated} | path_to_update] ->
        if is_repeated do
          repetition_count = repetition_count + 1

          if repetition_count == repetition_level_to_append do
            # Create a row entry at this repetition level

            new_entry_idx = map_size(row)
            Map.put(row, new_entry_idx, %{name => create_row(path_to_update, value)})
          else
            # Find the last row entry that repeated at this repetition level and recurse into it

            last_entry_idx = map_size(row) - 1

            put_in(
              row,
              [last_entry_idx, name],
              update_row(
                path_to_update,
                value,
                repetition_level_to_append,
                row[last_entry_idx][name],
                repetition_count
              )
            )
          end
        else
          Map.put(
            row,
            name,
            update_row(
              path_to_update,
              value,
              repetition_level_to_append,
              row[name],
              repetition_count
            )
          )
        end
    end
  end
end
