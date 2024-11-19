defmodule Parquet.Idl.PageEncodingStats do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:page_type, Parquet.Idl.PageType)
    field(:encoding, Parquet.Idl.Encoding)
    # i32
    field(:count, :integer)
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "page_type"
      2 -> "encoding"
      3 -> "count"
    end
  end

  def changeset(page_encoding_stats, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    page_encoding_stats
    |> cast(mapped_params, [:page_type, :encoding, :count])
    |> validate_required([:page_type, :encoding, :count])
  end
end
