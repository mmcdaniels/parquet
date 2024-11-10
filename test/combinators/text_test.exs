defmodule Combinators.TextTest do
  use ExUnit.Case
  use ExUnitProperties
  import Combinators.TextTest.Helpers

  import Combinators.Base,
    only: [
      run: 3
    ]

  import Combinators.Text,
    only: [
      char: 0,
      char_is: 1,
      char_is_not: 1,
      char_in: 1,
      string_is: 1
    ]

  alias Combinators.Result

  describe "char/0" do
    property "reads char" do
      ExUnitProperties.check all(
                               chr <- chr_gen(),
                               remaining <- str_gen(),
                               input = to_string([chr]) <> remaining
                             ) do
        assert char() |> run(input, :text) ==
                 {
                   :ok,
                   %Result.Ok{
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
        assert char() |> run(input, :text) ==
                 {
                   :ok,
                   %Result.Ok{
                     parsed: ?\n,
                     remaining: remaining,
                     cursor: %Result.Text.Cursor{line: 2, column: 1}
                   }
                 }
      end
    end

    test "errors when no more chars" do
      assert char() |> run("", :text) ==
               {
                 :error,
                 %Result.Error{
                   code: :no_more_chars,
                   message: "No more chars @(1L:1C)",
                   cursor: %Result.Text.Cursor{}
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
        assert char_is(expected) |> run(input, :text) ==
                 {
                   :ok,
                   %Result.Ok{
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
        cursor = %Result.Text.Cursor{}

        assert char_is(expected) |> run(input, :text) ==
                 {
                   :error,
                   %Result.Error{
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
        assert char_is(chr) |> run("", :text) ==
                 {
                   :error,
                   %Result.Error{
                     code: :no_more_chars,
                     message: "No more chars @(1L:1C)",
                     cursor: %Result.Text.Cursor{}
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
        assert char_is_not(unexpected) |> run(input, :text) ==
                 {
                   :ok,
                   %Result.Ok{
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
        cursor = %Result.Text.Cursor{}

        assert char_is_not(unexpected) |> run(input, :text) ==
                 {
                   :error,
                   %Result.Error{
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
        assert char_is_not(chr) |> run("", :text) ==
                 {
                   :error,
                   %Result.Error{
                     code: :no_more_chars,
                     message: "No more chars @(1L:1C)",
                     cursor: %Result.Text.Cursor{}
                   }
                 }
      end
    end
  end

  describe "char_in/1" do
    property("reads char when in expected range") do
      ExUnitProperties.check all(
                               expected <- chr_in_gen(?a..?z),
                               remaining <- str_gen(),
                               input = to_string([expected]) <> remaining
                             ) do
        assert char_in(?a..?z) |> run(input, :text) ==
                 {
                   :ok,
                   %Result.Ok{
                     parsed: expected,
                     remaining: remaining,
                     cursor: calculate_text_cursor(to_string([expected]))
                   }
                 }
      end
    end

    property("errors when not in expected range") do
      ExUnitProperties.check all(
                               actual <- chr_in_gen(?A..?Z),
                               remaining <- str_gen(),
                               input = to_string([actual]) <> remaining
                             ) do
        cursor = %Result.Text.Cursor{}

        assert char_in(?a..?z) |> run(input, :text) ==
                 {
                   :error,
                   %Result.Error{
                     code: :unexpected_char,
                     message:
                       "#{cursor} Found `#{to_string([actual])}`, which is outside the target range.",
                     parsed: actual,
                     cursor: cursor
                   }
                 }
      end
    end

    property "errors when no more chars" do
      ExUnitProperties.check all(chr <- chr_gen()) do
        assert char_in(chr) |> run("", :text) ==
                 {
                   :error,
                   %Result.Error{
                     code: :no_more_chars,
                     message: "No more chars @(1L:1C)",
                     cursor: %Result.Text.Cursor{}
                   }
                 }
      end
    end
  end

  describe "string_is/1" do
    property("reads string when expected string") do
      ExUnitProperties.check all(
                               expected <- str_gen(),
                               remaining <- str_gen(),
                               input = expected <> remaining
                             ) do
        assert string_is(expected) |> run(input, :text) ==
                 {
                   :ok,
                   %Result.Ok{
                     parsed: expected,
                     remaining: remaining,
                     cursor: calculate_text_cursor(expected)
                   }
                 }
      end
    end

    property("errors when not expected string, early return after unexpected char") do
      ExUnitProperties.check all(
                               n <- StreamData.positive_integer(),
                               common_prefix <- str_len_gen(n),
                               expected_chr <- chr_gen(),
                               actual_chr <- chr_gen(),
                               expected_chr != actual_chr,
                               expected = common_prefix <> to_string([expected_chr]),
                               actual = common_prefix <> to_string([actual_chr]),
                               remaining <- str_gen(),
                               input = actual <> remaining
                             ) do
        cursor = calculate_text_cursor(common_prefix)

        assert string_is(expected) |> run(input, :text) ==
                 {
                   :error,
                   %Result.Error{
                     code: :unexpected_string,
                     message: "#{cursor} Expected `#{expected}` but found `#{actual}`.",
                     parsed: actual,
                     cursor: cursor
                   }
                 }
      end
    end

    property "errors when no more chars" do
      ExUnitProperties.check all(
                               str <- str_gen(),
                               str != ""
                             ) do
        assert string_is(str) |> run("", :text) ==
                 {
                   :error,
                   %Result.Error{
                     code: :no_more_chars,
                     message: "No more chars @(1L:1C)",
                     cursor: %Result.Text.Cursor{}
                   }
                 }
      end
    end
  end
end
