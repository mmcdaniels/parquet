defmodule Parquet.Idl.SortingColumn do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    # i32
    field(:column_idx, :integer)
    field(:descending, :boolean)
    field(:nulls_first, :boolean)
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "column_idx"
      2 -> "descending"
      3 -> "nulls_first"
    end
  end

  def changeset(sorting_column, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    sorting_column
    |> cast(mapped_params, [:column_idx, :descending, :nulls_first])
    |> validate_required([:column_idx, :descending, :nulls_first])
  end
end
