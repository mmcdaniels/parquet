defmodule Parquet.BinaryEncodings do
  defp trim_leading_zeros(<<0::size(1), rest::bitstring>>) do
    trim_leading_zeros(rest)
  end

  defp trim_leading_zeros(bs) do
    bs
  end

  defp pad_leading_zeros(bs, count) when count > 0 do
    pad_v = <<0::size(count)>>
    <<pad_v::bitstring, bs::bitstring>>
  end

  defp count_bits(<<_::size(1), rest::bitstring>>) do
    1 + count_bits(rest)
  end

  defp count_bits(<<>>) do
    0
  end

  defp chunk_exact(bs, chunk_size) when chunk_size > 0 do
    chunk_exact(bs, chunk_size, [])
  end

  defp chunk_exact(<<>>, _chunk_size, lst) do
    Enum.reverse(lst)
  end

  defp chunk_exact(bs, chunk_size, lst) do
    <<chunk::size(chunk_size), rest::bitstring>> = bs

    lst = [<<chunk::size(chunk_size)>> | lst]
    chunk_exact(rest, chunk_size, lst)
  end

  defp join_chunks(chunks) do
    Enum.reduce(chunks, <<>>, fn e, acc -> <<acc::bitstring, e::bitstring>> end)
  end

  @doc """
    Converts unsigned integer input to ULEB128-encoded binary output.
  """
  def uint_to_uleb128_bin(uint) when uint >= 0 do
    uint_bin = :binary.encode_unsigned(uint)

    trimmed = trim_leading_zeros(uint_bin)
    trimmed_rem_7 = rem(count_bits(trimmed), 7)

    padded =
      if trimmed_rem_7 != 0 do
        pad_leading_zeros(trimmed, 7 - trimmed_rem_7)
      else
        trimmed
      end

    [first_chunk | remaining_chunks] = chunk_exact(padded, 7)

    marked = [
      <<0::size(1), first_chunk::bitstring>>
      | Enum.map(remaining_chunks, &<<1::size(1), &1::bitstring>>)
    ]

    marked |> Enum.reverse() |> :binary.list_to_bin()
  end

  @doc """
    Converts ULEB128-encoded binary input to unsigned integer output.
  """

  def uleb128_bin_to_uint(bin) when is_binary(bin) do
    trimmed =
      bin
      |> :binary.bin_to_list()
      |> Enum.reverse()
      |> Enum.map(fn int ->
        <<_::1, rest::bitstring>> = <<int>>
        rest
      end)
      |> join_chunks()
      |> trim_leading_zeros()

    trimmed_rem_8 = rem(count_bits(trimmed), 8)

    uint_bin =
      if trimmed_rem_8 != 0 do
        pad_leading_zeros(trimmed, 8 - trimmed_rem_8)
      else
        trimmed
      end

    :binary.decode_unsigned(uint_bin)
  end

  @doc """
    Converts signed integer input to zigzag-encoded unsigned integer output.
  """
  def int_to_zigzag_uint(int) do
    if int >= 0 do
      2 * int
    else
      2 * abs(int) - 1
    end
  end

  @doc """
    Converts zigzag-encoded unsigned integer input to signed integer output
  """
  def zigzag_uint_to_int(uint) when uint >= 0 do
    if rem(uint, 2) == 0 do
      div(uint, 2)
    else
      -div(uint + 1, 2)
    end
  end
end
