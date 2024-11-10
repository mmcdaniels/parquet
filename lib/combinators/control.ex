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

  @doc """
  Executes each parser in the given list of parsers until one succeeds.

  If no parser succeeds then returns an error.
  """
  def either(parsers) do
    fn input, cursor ->
      case parsers do
        [] ->
          message = "All parsers failed from #{cursor}"

          {
            :error,
            %ParseResult.Error{
              code: :all_parsers_failed,
              message: message,
              cursor: cursor
            }
          }

        [first | rest] ->
          case first.(input, cursor) do
            {:ok, parse_result} -> {:ok, parse_result}
            {:error, _} -> either(rest).(input, cursor)
          end
      end
    end
  end

  @doc """
  Executes the 3 given parsers(pre, value, post) and returns the output of the value parser.
  """
  def surrounded(pre_parser, value_parser, post_parser) do
    sequence([
      pre_parser,
      value_parser,
      post_parser
    ])
    |> map(fn [_, value, _] -> value end)
  end

  @doc """
  Tries to parse using the given parser.

  If the parser fails because the end of input was reached, then returns an error.
  If the parser fails for other reasons, then returns an Ok ParseResult with a nil parsed value.
  Otherwise, returns the parser output.
  """
  def maybe(parser) do
    fn input, cursor ->
      case parser.(input, cursor) do
        {:error, %ParseResult.Error{code: :no_more_chars} = err} ->
          {:error, err}

        {:error, _} ->
          {
            :ok,
            %ParseResult.Ok{
              parsed: nil,
              remaining: input,
              cursor: cursor
            }
          }

        {:ok, _} = ok ->
          ok
      end
    end
  end

  @doc """
  Repeats the given parser.

  If no bounds are given, then repeats the parser until it fails and then returns the successful repeats.
  If any of the bounds are set to nil, then those bounds are ignored.
  If the atleast bound is given, then errors if the # of repetitions is less than the bound.
  If the upto bound is given, then repeats no more than the bound.
  """
  def repeat(parser, {at_least, up_to} = bounds \\ {nil, nil}, parsed_list_rev \\ []) do
    fn input, cursor ->
      if length(parsed_list_rev) >= up_to do
        {
          :ok,
          %ParseResult.Ok{
            parsed: Enum.reverse(parsed_list_rev),
            remaining: input,
            cursor: cursor
          }
        }
      else
        case parser.(input, cursor) do
          {:ok,
           %ParseResult.Ok{
             parsed: parsed,
             remaining: remaining,
             cursor: cursor
           }} ->
            parsed_list_rev = [parsed | parsed_list_rev]
            repeat(parser, bounds, parsed_list_rev).(remaining, cursor)

          {:error, _err} ->
            if is_nil(at_least) or length(parsed_list_rev) >= at_least do
              {
                :ok,
                %ParseResult.Ok{
                  parsed: Enum.reverse(parsed_list_rev),
                  remaining: input,
                  cursor: cursor
                }
              }
            else
              {:error,
               %ParseResult.Error{
                 code: :min_bound_not_met,
                 message: "Did not repeat at least #{at_least} times",
                 cursor: cursor
               }}
            end
        end
      end
    end
  end
end
