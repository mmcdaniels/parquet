defmodule Parquet.Data.Reader.Encoding do
  import Bitwise
  alias Parquet.BinaryEncodings

  @doc """
  Decodes Parquet's deprecated Bitpacked encoding.
  """
  def decode_bitpacked(data, bit_width) do
    if bit_width == 0 do
      {nil, data}
    else
      raise("Bitpacked decoding is currently unsupported.")
    end
  end

  @doc """
  Decodes Parquet's RLE / Bitpacked hybrid encoding.
  """
  def decode_rle_hybrid(data, bit_width) do
    {header, data} = decode_uleb128(data)
    bit_count_required_for_max_level = floor(:math.log2(bit_width)) + 1
    byte_count_required_for_max_level = ceil(bit_count_required_for_max_level / 8)

    case header &&& 0x01 do
      0 ->
        rle_run_len = header >>> 1
        <<repeated_value::binary-size(byte_count_required_for_max_level), data::binary>> = data
        {{:hybrid_rle, rle_run_len, repeated_value}, data}

      1 ->
        bit_pack_scaled_run_len = header >>> 1
        bit_packed_run_len = 8 * bit_pack_scaled_run_len
        bit_packed_values_bitsize = bit_count_required_for_max_level * bit_packed_run_len
        <<bit_packed_values::bitstring-size(bit_packed_values_bitsize), data::binary>> = data

        decoded =
          BinaryEncodings.unpack_hybrid_bitpacked_bin_to_uints(
            bit_packed_values,
            bit_count_required_for_max_level
          )

        {{:hybrid_bitpacked, decoded}, data}
    end
  end

  @doc """
  Pops a value from encoded data, returning both the value and the remaining data.
  """
  def pop_value(data) do
    case data do
      nil ->
        {0, nil}

      {:hybrid_rle, run_length, value} ->
        # TODO validate run_length is not exceeded
        {value, {:hybrid_rle, run_length - 1, value}}

      {:hybrid_bitpacked, decoded_bytes} ->
        [value | rest] = decoded_bytes
        {value, {:hybrid_bitpacked, rest}}
    end
  end

  defp decode_uleb128(bin, acc \\ <<>>) do
    <<byte::binary-1, rest::binary>> = bin
    acc = <<acc::binary, byte::binary>>

    case byte do
      <<1::1, _::7>> ->
        decode_uleb128(rest, acc)

      <<0::1, _::7>> ->
        uint = BinaryEncodings.uleb128_bin_to_uint(acc)
        {uint, rest}
    end
  end
end
