defmodule Combinators.Text do
  @moduledoc """
  Combinators that operate on text input.
  """
  import Combinators.Base
  alias Combinators.Result

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

        cursor = %Result.Text.Cursor{
          cursor
          | line: line,
            column: column
        }

        {:ok, %Result.Ok{parsed: chr, remaining: remaining, cursor: cursor}}
      else
        _ ->
          message = "No more chars #{cursor}"

          {
            :error,
            %Result.Error{
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
      with {:error, %Result.Error{code: :predicate_not_satisfied, parsed: parsed}} <-
             char_is_base(chr, false).(input, cursor) do
        {
          :error,
          %Result.Error{
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
      with {:error, %Result.Error{code: :predicate_not_satisfied, parsed: parsed}} <-
             char_is_base(chr, true).(input, cursor) do
        {
          :error,
          %Result.Error{
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

  @doc """
  Parses a string from the input if it matches `str`.
  """
  def string_is(str, acc \\ []) do
    fn input, cursor ->
      case str do
        "" ->
          {
            :ok,
            %Result.Ok{
              :parsed => to_string(Enum.reverse(acc)),
              :remaining => input,
              :cursor => cursor
            }
          }

        <<ch::utf8, rest::binary>> ->
          with {:ok, %Result.Ok{parsed: parsed, remaining: remaining, cursor: cursor}} <-
                 char_is(ch).(input, cursor) do
            string_is(rest, [parsed | acc]).(remaining, cursor)
          else
            {:error, %Result.Error{code: :unexpected_char, parsed: parsed_char}} ->
              parsed_string = to_string(Enum.reverse([parsed_char | acc]))
              expected_string = to_string(Enum.reverse([ch | acc]))

              {
                :error,
                %Result.Error{
                  code: :unexpected_string,
                  message:
                    "#{cursor} Expected `#{expected_string}` but found `#{parsed_string}`.",
                  parsed: parsed_string,
                  cursor: cursor
                }
              }

            {:error, err} ->
              {:error, err}
          end
      end
    end
  end
end
