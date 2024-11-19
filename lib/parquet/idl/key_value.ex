defmodule Parquet.Idl.KeyValue do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:key, :string)
    field(:value, :string)
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "key"
      2 -> "value"
    end
  end

  def changeset(key_value, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    key_value
    |> cast(mapped_params, [:key, :value])
    |> validate_required([:key])
  end
end
