defmodule Parquet.Idl.CompressionCodec do
  use Ecto.Type

  @impl Ecto.Type
  def type, do: :string

  @impl Ecto.Type
  def cast(value) when is_integer(value) do
    value =
      case value do
        0 -> :uncompressed
        1 -> :snappy
        2 -> :gzip
        3 -> :lzo
        4 -> :brotli
        5 -> :lz4
        6 -> :zstd
        7 -> :lz4_raw
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
