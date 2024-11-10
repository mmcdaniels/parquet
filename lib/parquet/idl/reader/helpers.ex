defmodule Parquet.Idl.Reader.Helpers do
  import Combinators.Text
  import Combinators.Control

  def space, do: char_is(?\s)
  def spaces, do: repeat(space(), {1, nil})

  def newline, do: char_is(?\n)
  def newlines, do: repeat(newline(), {1, nil})

  def s_token(parser) do
    preceeded(
      repeat(space(), {1, nil}),
      parser
    )
  end

  def n_token(parser) do
    preceeded(
      repeat(newline(), {1, nil}),
      parser
    )
  end

  def sn_token(parser) do
    preceeded(
      repeat(
        either([space(), newline()]),
        {1, nil}
      ),
      parser
    )
  end

  def maybe_s_token(parser) do
    preceeded(
      repeat(space(), {0, nil}),
      parser
    )
  end

  def maybe_n_token(parser) do
    preceeded(
      repeat(newline(), {0, nil}),
      parser
    )
  end

  def maybe_sn_token(parser) do
    preceeded(
      repeat(
        either([space(), newline()]),
        {0, nil}
      ),
      parser
    )
  end

  def preceeded(pre_parser, value_parser) do
    sequence([
      pre_parser,
      value_parser
    ])
    |> map(fn [_, value] -> value end)
  end

  def zero_or_one(parser) do
    repeat(parser, {0, 1})
  end

  def zero_or_more(parser) do
    repeat(parser, {0, nil})
  end

  def one_or_more(parser) do
    repeat(parser, {1, nil})
  end

  def separated(parser, separator) do
    sequence([
      parser,
      repeat(sequence([separator, parser]) |> map(fn [_, parsed] -> parsed end))
    ])
    |> map(fn [p, ps] -> [p | ps] end)
  end

  def recursive(combinator) do
    fn input, position ->
      combinator.().(input, position)
    end
  end
end
