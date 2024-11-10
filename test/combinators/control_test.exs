defmodule Combinators.Control.Test do
  use ExUnit.Case
  use ExUnitProperties
  import Combinators.TextTest.Helpers

  import Combinators.Base,
    only: [
      run: 2
    ]

  import Combinators.Text,
    only: [
      char: 0,
      char_is: 1
    ]

  import Combinators.Control,
    only: [
      sequence: 1,
    ]

  describe "sequence/1" do
    property "parses sequence" do
      ExUnitProperties.check all(
                               {first, middle, last} <- {chr_gen(), chr_gen(), chr_gen()},
                               remaining <- str_gen(),
                               seq =
                                 to_string([first]) <> to_string([middle]) <> to_string([last]),
                               input = seq <> remaining
                             ) do
        assert sequence([char(), char_is(middle), char()]) |> run(input) ==
                 {
                   :ok,
                   %ParseResult.Ok{
                     parsed: [first, middle, last],
                     remaining: remaining,
                     cursor: calculate_text_cursor(seq)
                   }
                 }
      end
    end

    test "errors when a parser fails" do
      assert sequence([char_is(?a), char_is(?b), char_is(?z)]) |> run("abc") ==
               {
                 :error,
                 %ParseResult.Error{
                   code: :unexpected_char,
                   message: "@(1L:3C) Expected `z` but found `c`.",
                   parsed: ?c,
                   cursor: %ParseResult.Text.Cursor{line: 1, column: 3}
                 }
               }
    end

    test "errors when not enough input" do
      assert sequence([char(), char()]) |> run("a") ==
               {
                 :error,
                 %ParseResult.Error{
                   code: :no_more_chars,
                   message: "No more chars @(1L:2C)",
                   cursor: %ParseResult.Text.Cursor{line: 1, column: 2}
                 }
               }
    end
  end
end
