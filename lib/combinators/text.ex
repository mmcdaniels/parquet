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
end
