defmodule Parquet.Idl.LogicalType.DecimalType do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    # i32
    field(:scale, :integer)
    # i32
    field(:precision, :integer)
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "scale"
      2 -> "precision"
    end
  end

  def changeset(decimal_type, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    decimal_type
    |> cast(mapped_params, [:scale, :precision])
    |> validate_required([:scale, :precision])
  end
end
