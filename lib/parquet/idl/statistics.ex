defmodule Parquet.Idl.Statistics do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:max, :binary)
    field(:min, :binary)
    # i64
    field(:null_count, :integer)
    # i64
    field(:distinct_count, :integer)
    field(:max_value, :binary)
    field(:min_value, :binary)
    field(:is_max_value_exact, :boolean)
    field(:is_min_value_exact, :boolean)
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "max"
      2 -> "min"
      3 -> "null_count"
      4 -> "distinct_count"
      5 -> "max_value"
      6 -> "min_value"
      7 -> "is_max_value_exact"
      8 -> "is_min_value_exact"
    end
  end

  def changeset(statistics, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    statistics
    |> cast(mapped_params, [
      :max,
      :min,
      :null_count,
      :distinct_count,
      :max_value,
      :min_value,
      :is_max_value_exact,
      :is_min_value_exact
    ])
  end
end
