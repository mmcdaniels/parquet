defmodule Parquet.Idl.ColumnCryptoMetadata.EncryptionWithColumnKey do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:path_in_schema, {:array, :string})
    field(:key_metadata, :binary)
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "path_in_schema"
      2 -> "key_metadata"
    end
  end

  def changeset(encryption_with_column_key, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    encryption_with_column_key
    |> cast(mapped_params, [:path_in_schema, :key_metadata])
    |> validate_required([:path_in_schema])
  end
end
