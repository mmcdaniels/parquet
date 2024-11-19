defmodule Parquet.Idl.ColumnIndex do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:null_pages, {:array, :boolean})
    field(:min_values, {:array, :binary})
    field(:max_values, {:array, :binary})
    field(:boundary_order, Parquet.Idl.BoundaryOrder)
    # list<i64>
    field(:null_counts, {:array, :integer})
    # list<i64>
    field(:repetition_level_histograms, {:array, :integer})
    # list<i64>
    field(:definition_level_histograms, {:array, :integer})
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "null_pages"
      2 -> "min_values"
      3 -> "max_values"
      4 -> "boundary_order"
      5 -> "null_counts"
      6 -> "repetition_level_histograms"
      7 -> "definition_level_histograms"
    end
  end

  def changeset(column_index, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    column_index
    |> cast(mapped_params, [
      :null_pages,
      :min_values,
      :max_values,
      :boundary_order,
      :null_counts,
      :repetition_level_histograms,
      :definition_level_histograms
    ])
    |> validate_required([
      :null_pages,
      :min_values,
      :max_values,
      :boundary_order
    ])
  end
end
