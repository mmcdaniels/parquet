defmodule Parquet.Idl.Type do
  use Ecto.Type

  @impl Ecto.Type
  def type, do: :string

  @impl Ecto.Type
  def cast(value) when is_integer(value) do
    value =
      case value do
        0 -> :BOOLEAN
        1 -> :INT32
        2 -> :INT64
        3 -> :INT96
        4 -> :FLOAT
        5 -> :DOUBLE
        6 -> :BYTE_ARRAY
        7 -> :FIXED_LEN_BYTE_ARRAY
      end

    {:ok, value}
  end

  @impl Ecto.Type
  def cast(_), do: :error

  @impl Ecto.Type
  def dump(_), do: :error

  @impl Ecto.Type
  def load(_), do: :error
end
