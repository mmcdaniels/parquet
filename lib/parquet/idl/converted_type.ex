defmodule Parquet.Idl.ConvertedType do
  use Ecto.Type

  @impl Ecto.Type
  def type, do: :string

  @impl Ecto.Type
  def cast(value) when is_integer(value) do
    value =
      case value do
        0 -> :utf8
        1 -> :map
        2 -> :map_key_value
        3 -> :list
        4 -> :enum
        5 -> :decimal
        6 -> :date
        7 -> :time_millis
        8 -> :time_micros
        9 -> :timestamp_millis
        10 -> :timestamp_micros
        11 -> :uint_8
        12 -> :uint_16
        13 -> :uint_32
        14 -> :uint_64
        15 -> :int_8
        16 -> :int_16
        17 -> :int_32
        18 -> :int_64
        19 -> :json
        20 -> :bson
        21 -> :interval
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
