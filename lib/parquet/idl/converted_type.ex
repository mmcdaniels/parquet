defmodule Parquet.Idl.ConvertedType do
  use Ecto.Type

  @impl Ecto.Type
  def type, do: :string

  @impl Ecto.Type
  def cast(value) when is_integer(value) do
    value =
      case value do
        0 -> :UTF8
        1 -> :MAP
        2 -> :MAP_KEY_VALUE
        3 -> :LIST
        4 -> :ENUM
        5 -> :DECIMAL
        6 -> :DATE
        7 -> :TIME_MILLIS
        8 -> :TIME_MICROS
        9 -> :TIMESTAMP_MILLIS
        10 -> :TIMESTAMP_MICROS
        11 -> :UINT_8
        12 -> :UINT_16
        13 -> :UINT_32
        14 -> :UINT_64
        15 -> :INT_8
        16 -> :INT_16
        17 -> :INT_32
        18 -> :INT_64
        19 -> :JSON
        20 -> :BSON
        21 -> :INTERVAL
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
