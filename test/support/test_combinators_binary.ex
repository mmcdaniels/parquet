defmodule Combinators.BinaryTest.Helpers do
  use ExUnitProperties
  alias Combinators.Result

  @doc """
  Calculates the cursor position assuming that `bitstr` is parsed successfully.
  """
  def calculate_binary_cursor(bitstr) do
    position =
      for <<_::size(1) <- bitstr>>, reduce: 1 do
        c -> c + 1
      end

    %Result.Binary.Cursor{position: position}
  end

  @doc """
  Generates a bit.
  """
  def bit_gen do
    gen all(bit <- StreamData.bitstring(length: 1)) do
      bit
    end
  end

  @doc """
  Generates a bitstring.
  """
  def bitstr_gen do
    gen all(bitstr <- StreamData.bitstring()) do
      bitstr
    end
  end

  @doc """
  Generates a byte.
  """
  def byte_gen do
    gen all(byte <- StreamData.binary(length: 1)) do
      byte
    end
  end
end
