defmodule Parquet.Idl.Type do
  use Ecto.Type

  @impl Ecto.Type
  def type, do: :string

  @impl Ecto.Type
  def cast(value) when is_integer(value) do
    value =
      case value do
        0 -> :boolean
        1 -> :int32
        2 -> :int64
        3 -> :int96
        4 -> :float
        5 -> :double
        6 -> :byte_array
        7 -> :fixed_len_byte_array
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
