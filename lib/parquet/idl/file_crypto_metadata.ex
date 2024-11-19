defmodule Parquet.Idl.FileCryptoMetadata do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:encryption_algorithm, Parquet.Idl.EncryptionAlgorithm)
    field(:key_metadata, :binary)
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "encryption_algorithm"
      2 -> "key_metadata"
    end
  end

  def changeset(file_crypto_metadata, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    file_crypto_metadata
    |> cast(mapped_params, [
      :encryption_algorithm,
      :key_metadata
    ])
    |> validate_required([
      :encryption_algorithm
    ])
  end
end
