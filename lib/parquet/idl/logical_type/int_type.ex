defmodule Parquet.Idl.LogicalType.IntType do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    # i8
    field(:bit_width, :integer)
    field(:is_signed, :boolean)
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "bit_width"
      2 -> "is_signed"
    end
  end

  def changeset(int_type, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    int_type
    |> cast(mapped_params, [:bit_width, :is_signed])
    |> validate_required([:bit_width, :is_signed])
  end
end
