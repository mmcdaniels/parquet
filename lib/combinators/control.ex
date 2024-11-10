defmodule Combinators.Control do
  @doc """
  Executes a list of parsers in order.

  Failure of any individual parser triggers a failure of the sequence.
  """
  def sequence(parsers, parsed_list_rev \\ []) do
    fn input, cursor ->
      case parsers do
        [] ->
          {:ok,
           %ParseResult.Ok{
             :parsed => Enum.reverse(parsed_list_rev),
             :remaining => input,
             :cursor => cursor
           }}

        [parser | rest_parsers] ->
          with {:ok, %ParseResult.Ok{parsed: parsed, remaining: remaining, cursor: cursor}} <-
                 parser.(input, cursor) do
            parsed_list_rev = [parsed | parsed_list_rev]
            sequence(rest_parsers, parsed_list_rev).(remaining, cursor)
          end
      end
    end
  end
end
