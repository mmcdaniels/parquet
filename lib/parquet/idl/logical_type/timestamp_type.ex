defmodule Parquet.Idl.LogicalType.TimestampType do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:is_adjusted_to_UTC, :boolean)
    field(:unit, Parquet.Idl.LogicalType.TimeUnit)
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "is_adjusted_to_UTC"
      2 -> "unit"
    end
  end

  def changeset(timestamp_type, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    timestamp_type
    |> cast(mapped_params, [:is_adjusted_to_UTC, :unit])
    |> validate_required([:is_adjusted_to_UTC, :unit])
  end
end
