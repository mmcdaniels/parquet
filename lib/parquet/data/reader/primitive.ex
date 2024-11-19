defmodule Parquet.Data.Reader.Primitive do
  def decode_int32(bytes) do
    <<int32::signed-integer-32-little, bytes::binary>> = bytes
    {int32, bytes}
  end
end
