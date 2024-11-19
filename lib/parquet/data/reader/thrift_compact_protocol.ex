defmodule Parquet.Data.ThriftCompactProtocol do
  alias Parquet.BinaryEncodings

  # FIELD TYPES
  @field_type__boolean_true 1
  @field_type__boolean_false 2
  @field_type__i8 3
  @field_type__i16 4
  @field_type__i32 5
  @field_type__i64 6
  # @field_type__double 7
  @field_type__binary 8
  @field_type__list 9
  # @field_type__set 10
  # @field_type__map 11
  @field_type__struct 12
  # @field_type__uuid 13

  # ELEMENT TYPES
  # @element_type__bool 2
  # @element_type__i8 3
  # @element_type__i16 4
  @element_type__i32 5
  @element_type__i64 6
  # @element_type__double 7
  @element_type__binary 8
  @element_type__list 9
  # @element_type__set 10
  # @element_type__map 11
  @element_type__struct 12
  # @element_type__uuid 13

  ###############################################################

  defp read_binary(file) do
    byte_size = read_uleb128(file)
    {:ok, bin} = :file.read(file, byte_size)
    bin
  end

  ###############################################################
  defp read_int8(file) do
    {:ok, byte} = :file.read(file, 1)
    <<int8::integer-signed-8>> = byte
    int8
  end

  defp read_uleb128_zigzag(file) do
    {:ok, byte} = :file.read(file, 1)
    read_uleb128_zigzag(file, byte, byte)
  end

  defp read_uleb128_zigzag(file, <<1::1, _::7>>, acc) do
    {:ok, byte} = :file.read(file, 1)
    acc = acc <> byte
    read_uleb128_zigzag(file, byte, acc)
  end

  defp read_uleb128_zigzag(_file, <<0::1, _::7>>, acc) do
    acc
    |> BinaryEncodings.uleb128_bin_to_uint()
    |> BinaryEncodings.zigzag_uint_to_int()
  end

  defp read_uleb128(file) do
    {:ok, byte} = :file.read(file, 1)
    read_uleb128(file, byte, byte)
  end

  defp read_uleb128(file, <<1::1, _::7>>, acc) do
    {:ok, byte} = :file.read(file, 1)
    acc = acc <> byte
    read_uleb128(file, byte, acc)
  end

  defp read_uleb128(_file, <<0::1, _::7>>, acc) do
    acc
    |> BinaryEncodings.uleb128_bin_to_uint()
  end

  def read_struct(file) do
    read_struct(file, %{}, nil)
  end

  defp read_struct(file, struct, prev_field_id) do
    {:ok, tag} = :file.read(file, 1)

    case tag do
      <<0b00000000>> ->
        struct

      <<0b0000::4, _field_type_id::4>> ->
        raise "Reading long-form field is currently unsupported"

      <<field_id_delta::4, field_type_id::4>> ->
        {field_id, field_value} =
          read_field(:short, file, field_type_id, field_id_delta, prev_field_id)

        struct = Map.put(struct, field_id, field_value)
        read_struct(file, struct, field_id)
    end
  end

  defp read_field(
         :short,
         file,
         field_type_id,
         field_id_delta,
         prev_field_id
       ) do
    field_id =
      if is_nil(prev_field_id) do
        field_id_delta
      else
        prev_field_id + field_id_delta
      end

    field_value =
      case field_type_id do
        @field_type__boolean_true ->
          true

        @field_type__boolean_false ->
          false

        @field_type__i8 ->
          read_int8(file)

        @field_type__i16 ->
          read_uleb128_zigzag(file)

        @field_type__i32 ->
          read_uleb128_zigzag(file)

        @field_type__i64 ->
          read_uleb128_zigzag(file)

        @field_type__binary ->
          read_binary(file)

        @field_type__list ->
          read_list(file)

        @field_type__struct ->
          read_struct(file)

        _ ->
          raise "Unimplemented field type id = `#{field_type_id}`"
      end

    {field_id, field_value}
  end

  ###############################################################

  defp read_list(file) do
    {:ok, tag} = :file.read(file, 1)

    case tag do
      <<0b1111::4, _element_type_id::4>> ->
        raise "Reading long-form lists is currently unsupported"

      <<element_count::4, element_type_id::4>> ->
        read_list(:short, file, element_type_id, element_count)

      _ ->
        raise "Invalid List format"
    end
  end

  defp read_list(:short, file, element_type_id, element_count) do
    element_reader_fn =
      case element_type_id do
        @element_type__i32 ->
          fn _ -> read_uleb128_zigzag(file) end

        @element_type__i64 ->
          fn _ -> read_uleb128_zigzag(file) end

        @element_type__binary ->
          fn _ -> read_binary(file) end

        @element_type__list ->
          fn _ -> read_list(file) end

        @element_type__struct ->
          fn _ -> read_struct(file) end

        _ ->
          raise "Unimplemented element type id = `#{element_type_id}`"
      end

    1..element_count
    |> Enum.map(element_reader_fn)
  end
end
