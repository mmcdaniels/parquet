defmodule Parquet.Idl.Encoding do
  use Ecto.Type

  @impl Ecto.Type
  def type, do: :string

  @impl Ecto.Type
  def cast(value) when is_integer(value) do
    value =
      case value do
        0 -> :PLAIN
        1 -> :GROUP_VAR_INT
        2 -> :PLAIN_DICTIONARY
        3 -> :RLE
        4 -> :BIT_PACKED
        5 -> :DELTA_BINARY_PACKED
        6 -> :DELTA_LENGTH_BYTE_ARRAY
        7 -> :DELTA_BYTE_ARRAY
        8 -> :RLE_DICTIONARY
        9 -> :BYTE_STREAM_SPLIT
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
