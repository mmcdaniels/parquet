defmodule Parquet.BinaryEncodingsTest do
  use ExUnit.Case

  import Parquet.BinaryEncodings,
    only: [
      decode_ULEB128: 1,
      encode_ULEB128: 1,
      decode_zigzag: 1,
      encode_zigzag: 1
    ]

  test "encodes unsigned integer binary input to ULEB128 binary output" do
    assert encode_ULEB128(<<50399::unsigned-16>>) == <<0xDF, 0x89, 0x03>>
  end

  test "decodes ULEB128 binary input to unsigned integer binary output" do
    assert decode_ULEB128(<<0xDF, 0x89, 0x03>>) == <<50399::unsigned-16>>
  end

  test "encodes signed integer binary input to zigzag binary output" do
    assert encode_zigzag(<<-25200::signed-16>>) == <<50399::unsigned-16>>
    assert encode_zigzag(<<-3::signed-8>>) == <<5::unsigned-8>>
    assert encode_zigzag(<<-2::signed-8>>) == <<3::unsigned-8>>
    assert encode_zigzag(<<-1::signed-8>>) == <<1::unsigned-8>>
    assert encode_zigzag(<<0::signed-8>>) == <<0::unsigned-8>>
    assert encode_zigzag(<<1::signed-8>>) == <<2::unsigned-8>>
    assert encode_zigzag(<<2::signed-8>>) == <<4::unsigned-8>>
    assert encode_zigzag(<<3::signed-8>>) == <<6::unsigned-8>>
    assert encode_zigzag(<<25200::signed-16>>) == <<50400::unsigned-16>>
  end

  test "decodes zigzag binary input to signed integer binary output" do
    assert decode_zigzag(<<50399::unsigned-16>>) == <<-25200::signed-16>>
    assert decode_zigzag(<<5::unsigned-8>>) == <<-3::signed-8>>
    assert decode_zigzag(<<3::unsigned-8>>) == <<-2::signed-8>>
    assert decode_zigzag(<<1::unsigned-8>>) == <<-1::signed-8>>
    assert decode_zigzag(<<0::unsigned-8>>) == <<0::signed-8>>
    assert decode_zigzag(<<2::unsigned-8>>) == <<1::signed-8>>
    assert decode_zigzag(<<4::unsigned-8>>) == <<2::signed-8>>
    assert decode_zigzag(<<50400::unsigned-16>>) == <<25200::signed-16>>
  end
end
