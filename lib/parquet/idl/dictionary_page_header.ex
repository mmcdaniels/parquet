defmodule Parquet.Idl.DictionaryPageHeader do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    # i32
    field(:num_values, :integer)
    field(:encoding, Parquet.Idl.Encoding)
    field(:is_sorted, :boolean)
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "num_values"
      2 -> "encoding"
      3 -> "is_sorted"
    end
  end

  def changeset(dictionary_page_header, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    dictionary_page_header
    |> cast(mapped_params, [
      :num_values,
      :encoding,
      :is_sorted
    ])
    |> validate_required([
      :num_values,
      :encoding
    ])
  end
end
