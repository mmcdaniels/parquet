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

  @doc """
  Executes a list of parsers in order, optionally tagging the output of each parser.

  Accepts a list of tuples of the form {<tag>, <parser>}, where <tag> is an atom. If <tag>
  is `nil`, the output is ignored. The parsed value at the end of the sequence is a map containing
  all the tagged values.

  Failure of any individual parser triggers a failure of the sequence.
  """
  def tagged_sequence(tagged_parsers, parsed_map \\ %{}) do
    fn input, cursor ->
      case tagged_parsers do
        [] ->
          {:ok,
           %ParseResult.Ok{
             parsed: parsed_map,
             remaining: input,
             cursor: cursor
           }}

        [tagged_parser | rest_tagged_parsers] ->
          {tag, parser} = tagged_parser

          if not is_atom(tag) do
            {
              :error,
              :tag_not_an_atom,
              "Tag `#{tag}` should be an atom or nil"
            }
          else
            with {:ok,
                  %ParseResult.Ok{
                    parsed: parsed,
                    remaining: remaining,
                    cursor: position
                  }} <- parser.(input, cursor) do
              if Map.has_key?(parsed_map, tag) do
                {
                  :error,
                  :duplicate_tag,
                  "Found duplicated tag `#{tag}`"
                }
              else
                parsed_map =
                  if is_nil(tag), do: parsed_map, else: Map.put(parsed_map, tag, parsed)

                tagged_sequence(rest_tagged_parsers, parsed_map).(remaining, position)
              end
            end
          end
      end
    end
  end

  @doc """
  Applies the given function to the parsed value and returns the updated ParseResult.

  Exceptions in the mapper function are caught and returned as an error tuple.
  """
  def map(parser, mapper) do
    fn input, cursor ->
      with {:ok, %ParseResult.Ok{parsed: parsed} = ok} <- parser.(input, cursor) do
        try do
          mapped = mapper.(parsed)
          {:ok, %ParseResult.Ok{ok | parsed: mapped}}
        rescue
          # TODO provide more detail about the exception. Potentially include the stacktrace and the exception type.
          e -> {:error, :mapper_error, Exception.message(e)}
        end
      end
    end
  end
end
