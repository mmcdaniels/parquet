defmodule Parquet.Idl.Encoding do
  use Ecto.Type

  @impl Ecto.Type
  def type, do: :string

  @impl Ecto.Type
  def cast(value) when is_integer(value) do
    value =
      case value do
        0 -> :plain
        1 -> :group_var_int
        2 -> :plain_dictionary
        3 -> :rle
        4 -> :bit_packed
        5 -> :delta_binary_packed
        6 -> :delta_length_byte_array
        7 -> :delta_byte_array
        8 -> :rle_dictionary
        9 -> :byte_stream_split
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
