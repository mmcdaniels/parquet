defmodule Parquet.BinaryEncodingsTest do
  use ExUnit.Case

  import Parquet.BinaryEncodings,
    only: [
      decode_ULEB128: 1,
      encode_ULEB128: 1,
    ]

  test "encodes unsigned integer binary input to ULEB128 binary output" do
    assert encode_ULEB128(<<50399::unsigned-16>>) == <<0xDF, 0x89, 0x03>>
  end

  test "decodes ULEB128 binary input to unsigned integer binary output" do
    assert decode_ULEB128(<<0xDF, 0x89, 0x03>>) == <<50399::unsigned-16>>
  end

  end
end
