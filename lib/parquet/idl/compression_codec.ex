defmodule Parquet.Idl.CompressionCodec do
  use Ecto.Type

  @impl Ecto.Type
  def type, do: :string

  @impl Ecto.Type
  def cast(value) when is_integer(value) do
    value =
      case value do
        0 -> :UNCOMPRESSED
        1 -> :SNAPPY
        2 -> :GZIP
        3 -> :LZO
        4 -> :BROTLI
        5 -> :LZ4
        6 -> :ZSTD
        7 -> :LZ4_RAW
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
