defmodule Parquet.BinaryEncodingsTest do
  use ExUnit.Case

  import Parquet.BinaryEncodings,
    only: [
      uleb128_bin_to_uint: 1,
      uint_to_uleb128_bin: 1,
      zigzag_uint_to_int: 1,
      int_to_zigzag_uint: 1,
      unpack_hybrid_bitpacked_bin_to_uints: 2
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

  test "Decodes hybrid-bitpacked data to unsigned integers" do
    # Decodes when bit width <= 8 bits
    #
    # Packed:
    # bits  : 10001000 11000110 11111010
    # labels: HIDEFABC RMNOJKLG VWXSTUPQ
    #
    # Unpacked:
    # bits  : 000 001 010 011 100 101 110 111
    # labels: ABC DEF GHI JKL MNO PQR STU VWX
    # uints : 0   1   2   3   4   5   6   7
    assert unpack_hybrid_bitpacked_bin_to_uints(<<0b10001000, 0b11000110, 0b11111010>>, 3) ==
             [0, 1, 2, 3, 4, 5, 6, 7]

    # Decodes when bit width > 8 bits
    #
    # Packed:
    # bits  : 01010011 01110000 10010111
    # labels: EFGHIJKL UVWXABCD MNOPQRST
    #
    # Unpacked:
    # bits  : 000001010011 100101110111
    # labels: ABCDEFGHIJKL MNOPQRSTUVWX
    # uints : 83           2423
    assert unpack_hybrid_bitpacked_bin_to_uints(<<0b01010011, 0b01110000, 0b10010111>>, 12) ==
             [83, 2423]

    # Fails when bit width is not a multiple of packed bit count
    assert_raise(
      RuntimeError,
      fn -> unpack_hybrid_bitpacked_bin_to_uints(<<0b10001000, 0b11000110, 0b11111010>>, 5) end
    )

    # Fails when bit width is greater than packed bit count
    assert_raise(
      RuntimeError,
      fn -> unpack_hybrid_bitpacked_bin_to_uints(<<0b10001000, 0b11000110, 0b11111010>>, 32) end
    )

    # Fails when bit width is 0
    assert_raise(
      RuntimeError,
      fn -> unpack_hybrid_bitpacked_bin_to_uints(<<0b10001000, 0b11000110, 0b11111010>>, 0) end
    )
  end
end
