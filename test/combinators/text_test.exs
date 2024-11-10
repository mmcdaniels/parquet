defmodule Combinators.TextTest do
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
    ]

  describe "char/0" do
    property "reads char" do
      ExUnitProperties.check all(
                               chr <- chr_gen(),
                               remaining <- str_gen(),
                               input = to_string([chr]) <> remaining
                             ) do
        assert char() |> run(input) ==
                 {
                   :ok,
                   %ParseResult.Ok{
                     parsed: chr,
                     remaining: remaining,
                     cursor: calculate_text_cursor(to_string([chr]))
                   }
                 }
      end
    end

    test "reads newline char and updates cursor correctly" do
      ExUnitProperties.check all(
                               remaining <- str_gen(),
                               input = to_string([?\n]) <> remaining
                             ) do
        assert char() |> run(input) ==
                 {
                   :ok,
                   %ParseResult.Ok{
                     parsed: ?\n,
                     remaining: remaining,
                     cursor: %ParseResult.Text.Cursor{line: 2, column: 1}
                   }
                 }
      end
    end

    test "errors when no more chars" do
      assert char() |> run("") ==
               {
                 :error,
                 %ParseResult.Error{
                   code: :no_more_chars,
                   message: "No more chars @(1L:1C)",
                   cursor: %ParseResult.Text.Cursor{}
                 }
               }
    end
  end
end
