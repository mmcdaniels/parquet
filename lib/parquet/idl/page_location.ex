defmodule Parquet.Idl.PageLocation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    # i64
    field(:offset, :integer)
    # i32
    field(:compressed_page_size, :integer)
    # i64
    field(:first_row_index, :integer)
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "offset"
      2 -> "compressed_page_size"
      3 -> "first_row_index"
    end
  end

  def changeset(page_location, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    page_location
    |> cast(mapped_params, [
      :offset,
      :compressed_page_size,
      :first_row_index
    ])
    |> validate_required([
      :offset,
      :compressed_page_size,
      :first_row_index
    ])
  end
end
