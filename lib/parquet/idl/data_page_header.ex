defmodule Parquet.Idl.DataPageHeader do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    # i32
    field(:num_values, :integer)
    field(:encoding, Parquet.Idl.Encoding)
    field(:definition_level_encoding, Parquet.Idl.Encoding)
    field(:repetition_level_encoding, Parquet.Idl.Encoding)
    embeds_one(:statistics, Parquet.Idl.Statistics)
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "num_values"
      2 -> "encoding"
      3 -> "definition_level_encoding"
      4 -> "repetition_level_encoding"
      5 -> "statistics"
    end
  end

  def changeset(data_page_header, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    data_page_header
    |> cast(mapped_params, [
      :num_values,
      :encoding,
      :definition_level_encoding,
      :repetition_level_encoding
    ])
    |> cast_embed(:statistics,
      required: false,
      with: &Parquet.Idl.Statistics.changeset/2
    )
    |> validate_required([
      :num_values,
      :encoding,
      :definition_level_encoding,
      :repetition_level_encoding
    ])
  end
end
