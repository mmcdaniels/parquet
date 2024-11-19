defmodule Parquet.Idl.EncryptionAlgorithm.AesGcmV1 do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:aad_prefix, :binary)
    field(:aad_file_unique, :binary)
    field(:supply_aad_prefix, :boolean)
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "aad_prefix"
      2 -> "aad_file_unique"
      3 -> "supply_aad_prefix"
    end
  end

  def changeset(aes_gcm_v1, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    aes_gcm_v1
    |> cast(mapped_params, [
      :aad_prefix,
      :aad_file_unique,
      :supply_aad_prefix
    ])
  end
end
