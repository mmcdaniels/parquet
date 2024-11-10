defmodule Combinators.TextTest.Helpers do
  use ExUnitProperties
  alias Combinators.Result

  @doc """
  Calculates the cursor position assuming that `str` is parsed successfully.
  """
  def calculate_text_cursor(str) do
    {line, column} =
      for <<chr::utf8 <- str>>, reduce: {1, 1} do
        {l, c} ->
          if chr == ?\n do
            {l + 1, 1}
          else
            {l, c + 1}
          end
      end

    %Result.Text.Cursor{line: line, column: column}
  end

  @doc """
  Generates a UTF-8 codepoint.
  """
  def chr_gen do
    gen all(chr_lst <- StreamData.string(:utf8, length: 1)) do
      String.to_charlist(chr_lst) |> Enum.at(0)
    end
  end

  @doc """
  Generates a codepoint within the given range.
  """
  def chr_in_gen(range) do
    gen all(chr_lst <- StreamData.string(range, length: 1)) do
      String.to_charlist(chr_lst) |> Enum.at(0)
    end
  end

  @doc """
  Generates a UTF-8 string of arbitrary length.
  """
  def str_gen do
    gen all(str <- StreamData.string(:utf8)) do
      str
    end
  end

  @doc """
  Generates a UTF-8 string of the given length.
  """
  def str_len_gen(length) do
    gen all(str <- StreamData.string(:utf8, length: length)) do
      str
    end
  end

  @doc """
  Generates a string of arbitrary length using codepoints in the given range.
  """
  def str_in_gen(range) do
    gen all(str <- StreamData.string(range)) do
      str
    end
  end
end
