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
    Encodes unsigned integer binary input into ULEB128-encoded binary output.
  """
  def encode_ULEB128(bin) when is_binary(bin) do
    trimmed = trim_leading_zeros(bin)
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
  Decodes ULEB128-encoded binary input into n-bit unsigned integer binary output,
  where n is the smallest multiple of 8 that fits the output.
  """
  def decode_ULEB128(bin) when is_binary(bin) do
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

    if trimmed_rem_8 != 0 do
      pad_leading_zeros(trimmed, 8 - trimmed_rem_8)
    else
      trimmed
    end
  end

  @doc """
    Encodes signed integer binary input into zigzag-encoded binary output.
  """
  def encode_zigzag(bin) when is_binary(bin) do
    n = count_bits(bin)
    <<v::signed-size(n)>> = bin

    r =
      if v >= 0 do
        2 * v
      else
        2 * abs(v) - 1
      end

    <<r::unsigned-size(n)>>
  end

  @doc """
  Decodes zigzag-encoded binary input into signed integer binary output
  """
  def decode_zigzag(bin) when is_binary(bin) do
    n = count_bits(bin)
    <<v::size(n)>> = bin

    r =
      if rem(v, 2) == 0 do
        div(v, 2)
      else
        -div(v + 1, 2)
      end

    <<r::signed-size(n)>>
  end
end
