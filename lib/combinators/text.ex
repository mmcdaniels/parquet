defmodule Combinators.Text do
  @moduledoc """
  Combinators that operate on text input.
  """
  import Combinators.Base

  @doc """
  Parses a character from the input.
  """
  def char do
    fn input, cursor ->
      with <<chr::utf8, remaining::binary>> <- input do
        {line, column} =
          if chr == ?\n do
            {cursor.line + 1, 1}
          else
            {cursor.line, cursor.column + 1}
          end

        cursor = %ParseResult.Text.Cursor{
          cursor
          | line: line,
            column: column
        }

        {:ok, %ParseResult.Ok{parsed: chr, remaining: remaining, cursor: cursor}}
      else
        _ ->
          message = "No more chars #{cursor}"

          {
            :error,
            %ParseResult.Error{
              code: :no_more_chars,
              message: message,
              cursor: cursor
            }
          }
      end
    end
  end

  @doc """
  Parses a character from the input if it matches `chr`.
  """
  def char_is(chr) do
    fn input, cursor ->
      with {:error, %ParseResult.Error{code: :predicate_not_satisfied, parsed: parsed}} <-
             char_is_base(chr, false).(input, cursor) do
        {
          :error,
          %ParseResult.Error{
            code: :unexpected_char,
            message:
              "#{cursor} Expected `#{to_string([chr])}` but found `#{to_string([parsed])}`.",
            parsed: parsed,
            cursor: cursor
          }
        }
      end
    end
  end

  @doc """
  Parses a character from the input if it doesn't match `chr`.
  """
  def char_is_not(chr) do
    fn input, cursor ->
      with {:error, %ParseResult.Error{code: :predicate_not_satisfied, parsed: parsed}} <-
             char_is_base(chr, true).(input, cursor) do
        {
          :error,
          %ParseResult.Error{
            code: :unexpected_char,
            message: "#{cursor} Found `#{to_string([chr])}`.",
            parsed: parsed,
            cursor: cursor
          }
        }
      end
    end
  end

  defp char_is_base(expected, invert) do
    check(char(), fn c -> c == expected end, invert: invert)
  end

end
