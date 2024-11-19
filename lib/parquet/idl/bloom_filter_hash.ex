defmodule Parquet.Idl.BloomFilterHash do
  use Ecto.Type

  @impl Ecto.Type
  def type, do: :map

  @impl Ecto.Type
  def cast(value) do
    changeset =
      case value do
        %{1 => %{}} ->
          Ecto.Changeset.change(%Parquet.Idl.BloomFilterHash.XxHash{})
      end

    value = Ecto.Changeset.apply_action!(changeset, :parse)
    {:ok, value}
  end

  @impl Ecto.Type
  def dump(_), do: :error

  @impl Ecto.Type
  def load(_), do: :error
end
