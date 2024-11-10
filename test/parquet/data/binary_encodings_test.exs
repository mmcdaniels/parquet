defmodule Parquet.BinaryEncodingsTest do
  use ExUnit.Case

  import Parquet.BinaryEncodings,
    only: [
      uleb128_bin_to_uint: 1,
      uint_to_uleb128_bin: 1,
      zigzag_uint_to_int: 1,
      int_to_zigzag_uint: 1
    ]

  test "converts unsigned integer to ULEB128 binary" do
    assert uint_to_uleb128_bin(50399) == <<0xDF, 0x89, 0x03>>
  end

  test "converts ULEB128 binary to unsigned integer" do
    assert uleb128_bin_to_uint(<<0xDF, 0x89, 0x03>>) == 50399
  end

  test "converts signed integer to zigzag unsigned integer" do
    assert int_to_zigzag_uint(-25200) == 50399
    assert int_to_zigzag_uint(-3) == 5
    assert int_to_zigzag_uint(-2) == 3
    assert int_to_zigzag_uint(-1) == 1
    assert int_to_zigzag_uint(0) == 0
    assert int_to_zigzag_uint(1) == 2
    assert int_to_zigzag_uint(2) == 4
    assert int_to_zigzag_uint(3) == 6
    assert int_to_zigzag_uint(25200) == 50400
  end

  test "converts zigzag unsigned integer to signed integer" do
    assert zigzag_uint_to_int(50399) == -25200
    assert zigzag_uint_to_int(5) == -3
    assert zigzag_uint_to_int(3) == -2
    assert zigzag_uint_to_int(1) == -1
    assert zigzag_uint_to_int(0) == 0
    assert zigzag_uint_to_int(2) == 1
    assert zigzag_uint_to_int(4) == 2
    assert zigzag_uint_to_int(50400) == 25200
  end
end
