defmodule Parquet.Idl.DataPageHeaderV2 do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    # i32
    field(:num_values, :integer)
    # i32
    field(:num_nulls, :integer)
    # i32
    field(:num_rows, :integer)
    field(:encoding, Parquet.Idl.Encoding)
    # i32
    field(:definition_levels_byte_length, :integer)
    # i32
    field(:repetition_levels_byte_length, :integer)
    field(:is_compressed, :boolean, default: true)
    embeds_one(:statistics, Parquet.Idl.Statistics)
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "num_values"
      2 -> "num_nulls"
      3 -> "num_rows"
      4 -> "encoding"
      5 -> "definition_levels_byte_length"
      6 -> "repetition_levels_byte_length"
      7 -> "is_compressed"
      8 -> "statistics"
    end
  end

  def changeset(data_page_header_v2, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    data_page_header_v2
    |> cast(mapped_params, [
      :num_values,
      :num_nulls,
      :num_rows,
      :encoding,
      :definition_levels_byte_length,
      :repetition_levels_byte_length,
      :is_compressed
    ])
    |> cast_embed(:statistics,
      required: false,
      with: &Parquet.Idl.Statistics.changeset/2
    )
    |> validate_required([
      :num_values,
      :num_nulls,
      :num_rows,
      :encoding,
      :definition_levels_byte_length,
      :repetition_levels_byte_length
    ])
  end
end
