defmodule Parquet.Idl.EncryptionAlgorithm do
  use Ecto.Type

  @impl Ecto.Type
  def type, do: :map

  @impl Ecto.Type
  def cast(value) do
    changeset =
      case value do
        %{1 => params} ->
          %Parquet.Idl.EncryptionAlgorithm.AesGcmV1{}
          |> Parquet.Idl.EncryptionAlgorithm.AesGcmV1.changeset(params)

        %{2 => params} ->
          %Parquet.Idl.EncryptionAlgorithm.AesGcmCtrV1{}
          |> Parquet.Idl.EncryptionAlgorithm.AesGcmCtrV1.changeset(params)
      end

    value = Ecto.Changeset.apply_action!(changeset, :parse)
    {:ok, value}
  end

  @impl Ecto.Type
  def dump(_), do: :error

  @impl Ecto.Type
  def load(_), do: :error
end
