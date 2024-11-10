defmodule Parquet.Idl.Reader.CommentTest do
  use ExUnit.Case
  use ExUnitProperties
  import Combinators.TextTest.Helpers
  import Parquet.Idl.Reader.Test.Helpers
  import Combinators.Base
  import Parquet.Idl.Reader.Comment
  alias Combinators.Result

  describe "inline_comment/0" do
    property "reads comment" do
      ExUnitProperties.check all(
                               spaces <- spaces_gen(),
                               %{inline_comment: inline_comment, body: body} <-
                                 inline_comment_gen(),
                               remaining <- str_gen(),
                               input = "#{spaces}#{inline_comment}\n#{remaining}"
                             ) do
        assert inline_comment()
               |> run(
                 input,
                 :text
               ) ==
                 {:ok,
                  %Result.Ok{
                    parsed: body,
                    remaining: "\n#{remaining}",
                    cursor: calculate_text_cursor("#{spaces}#{inline_comment}")
                  }}
      end
    end
  end

  describe "block_comment/0" do
    property "reads comment" do
      ExUnitProperties.check all(
                               spaces <- spaces_gen(),
                               %{block_comment: block_comment, body: body} <- block_comment_gen(),
                               remaining <- str_gen(),
                               input = "#{spaces}#{block_comment}\n#{remaining}"
                             ) do
        assert block_comment()
               |> run(
                 input,
                 :text
               ) ==
                 {:ok,
                  %Result.Ok{
                    parsed: body,
                    remaining: "\n#{remaining}",
                    cursor: calculate_text_cursor("#{spaces}#{block_comment}")
                  }}
      end
    end
  end

  describe "blockish_comment/0" do
    property "reads multiple inline comments" do
      ExUnitProperties.check all(
                               spaces <- spaces_gen(),
                               %{inline_comment: inline_comment1, body: body1} <-
                                 inline_comment_gen(),
                               %{inline_comment: inline_comment2, body: body2} <-
                                 inline_comment_gen(),
                               remaining <- str_gen(),
                               input =
                                 "#{spaces}#{inline_comment1}\n#{spaces}#{inline_comment2}\n#{remaining}"
                             ) do
        assert blockish_comment()
               |> run(
                 input,
                 :text
               ) ==
                 {:ok,
                  %Result.Ok{
                    parsed: [body1, body2],
                    remaining: "\n#{remaining}",
                    cursor:
                      calculate_text_cursor(
                        "#{spaces}#{inline_comment1}\n#{spaces}#{inline_comment2}"
                      )
                  }}
      end
    end
  end

  property "reads only a single block comment" do
    ExUnitProperties.check all(
                             spaces <- spaces_gen(),
                             %{block_comment: block_comment1, body: body1} <- block_comment_gen(),
                             %{block_comment: block_comment2, body: _body2} <-
                               block_comment_gen(),
                             remaining <- str_gen(),
                             input =
                               "#{spaces}#{block_comment1}\n#{spaces}#{block_comment2}\n#{remaining}"
                           ) do
      assert blockish_comment()
             |> run(
               input,
               :text
             ) ==
               {:ok,
                %Result.Ok{
                  parsed: body1,
                  remaining: "\n#{spaces}#{block_comment2}\n#{remaining}",
                  cursor: calculate_text_cursor("#{spaces}#{block_comment1}")
                }}
    end
  end
end
