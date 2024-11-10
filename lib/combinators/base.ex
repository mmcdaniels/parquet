defmodule Combinators.Base do
  @doc """
  Executes the parser on `input`.

  The initial cursor represents the starting position of the input stream. Parsers update this position
  after running and report it in the case of a parser error.
  """
  def run(parser, input, :text), do: parser.(input, %ParseResult.Text.Cursor{})
  def run(parser, input, :binary), do: parser.(input, %ParseResult.Binary.Cursor{})

  @doc """
    Takes the parsed output of `parser` and passes it to the predicate function.

    When `invert` is false, `check` succeeds if the predicate succeeds on the parsed value.
    When `invert` is true, `check` succeeds if the predicate fails on the parsed value.
  """
  def check(parser, predicate, invert: invert) do
    fn input, cursor ->
      with {
             :ok,
             %ParseResult.Ok{parsed: parsed} = ok
           } <- parser.(input, cursor) do
        predicate_check =
          if invert do
            not predicate.(parsed)
          else
            predicate.(parsed)
          end

        if predicate_check do
          {:ok, ok}
        else
          message =
            "The predicate did not succeed on the parsed value #{parsed} #{cursor}"

          {
            :error,
            %ParseResult.Error{
              code: :predicate_not_satisfied,
              message: message,
              parsed: parsed,
              cursor: cursor
            }
          }
        end
      end
    end
  end

  @doc """
  Displays the output of a parser without affecting parser chaining.

  For example: `parser_outer(debug(parser_inner))` will print `parser_inner`s output while still passing it to `parser_outer`.
  """
  def debug(parser) do
    fn input, cursor ->
      IO.inspect(parser.(input, cursor))
    end
  end
end
