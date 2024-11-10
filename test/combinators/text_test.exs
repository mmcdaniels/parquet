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
      char_is: 1,
      char_is_not: 1,
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

  describe "char_is/1" do
    property("reads char when expected char") do
      ExUnitProperties.check all(
                               expected <- chr_gen(),
                               remaining <- str_gen(),
                               input = to_string([expected]) <> remaining
                             ) do
        assert char_is(expected) |> run(input) ==
                 {
                   :ok,
                   %ParseResult.Ok{
                     parsed: expected,
                     remaining: remaining,
                     cursor: calculate_text_cursor(to_string([expected]))
                   }
                 }
      end
    end

    property("errors when not expected char") do
      ExUnitProperties.check all(
                               expected <- chr_gen(),
                               actual <- chr_gen(),
                               expected != actual,
                               remaining <- str_gen(),
                               input = to_string([actual]) <> remaining
                             ) do
        cursor = %ParseResult.Text.Cursor{}

        assert char_is(expected) |> run(input) ==
                 {
                   :error,
                   %ParseResult.Error{
                     code: :unexpected_char,
                     message:
                       "#{cursor} Expected `#{to_string([expected])}` but found `#{to_string([actual])}`.",
                     parsed: actual,
                     cursor: cursor
                   }
                 }
      end
    end

    property "errors when no more chars" do
      ExUnitProperties.check all(chr <- chr_gen()) do
        assert char_is(chr) |> run("") ==
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

  describe "char_is_not/1" do
    property("reads char when not unexpected char") do
      ExUnitProperties.check all(
                               chr <- chr_gen(),
                               unexpected <- chr_gen(),
                               chr != unexpected,
                               remaining <- str_gen(),
                               input = to_string([chr]) <> remaining
                             ) do
        assert char_is_not(unexpected) |> run(input) ==
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

    property("errors when unexpected char") do
      ExUnitProperties.check all(
                               chr <- chr_gen(),
                               unexpected <- chr_gen(),
                               chr != unexpected,
                               remaining <- str_gen(),
                               input = to_string([unexpected]) <> remaining
                             ) do
        cursor = %ParseResult.Text.Cursor{}

        assert char_is_not(unexpected) |> run(input) ==
                 {
                   :error,
                   %ParseResult.Error{
                     code: :unexpected_char,
                     message: "#{cursor} Found `#{to_string([unexpected])}`.",
                     parsed: unexpected,
                     cursor: cursor
                   }
                 }
      end
    end

    property "errors when no more chars" do
      ExUnitProperties.check all(chr <- chr_gen()) do
        assert char_is_not(chr) |> run("") ==
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

end
