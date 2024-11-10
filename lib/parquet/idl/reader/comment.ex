defmodule Parquet.Idl.Reader.Comment do
  import Combinators.Text
  import Combinators.Control
  import Parquet.Idl.Reader.Helpers

  def inline_comment do
    sequence([
      maybe_s_token(string_is("//")),
      repeat_until(char(), newline())
    ])
    |> map(fn [_, comment] -> to_string(comment) end)
  end

  def block_comment do
    sequence([
      maybe_s_token(string_is("/*")),
      zero_or_more(
        either([
          spaces(),
          newlines()
        ])
      ),
      repeat_until(char(), string_is("*/")),
      string_is("*/")
    ])
    |> map(fn [_, _, comment, _] -> to_string(comment) end)
  end

  def blockish_comment do
    either([
      block_comment(),
      one_or_more(maybe_sn_token(inline_comment()))
    ])
  end
end
