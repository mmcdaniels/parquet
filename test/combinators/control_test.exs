defmodule Combinators.Control.Test do
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
      char_is: 1
    ]

  import Combinators.Control,
    only: [
      either: 1,
      maybe: 1,
      repeat: 1,
      repeat: 2,
      repeat_until: 2,
      sequence: 1,
      surrounded: 3,
      tagged_sequence: 1
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
        assert sequence([char(), char_is(middle), char()]) |> run(input, :text) ==
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
      assert sequence([char_is(?a), char_is(?b), char_is(?z)]) |> run("abc", :text) ==
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
      assert sequence([char(), char()]) |> run("a", :text) ==
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

  describe "tagged_sequence/1" do
    property "parses tagged sequence" do
      ExUnitProperties.check all(
                               {first, middle, last} <- {chr_gen(), chr_gen(), chr_gen()},
                               remaining <- str_gen(),
                               seq = to_string([first, middle, last]),
                               input = seq <> remaining
                             ) do
        assert tagged_sequence([
                 {:char1, char()},
                 {:char2, char_is(middle)},
                 {:char3, char()}
               ])
               |> run(input, :text) ==
                 {
                   :ok,
                   %ParseResult.Ok{
                     parsed: %{
                       :char1 => first,
                       :char2 => middle,
                       :char3 => last
                     },
                     remaining: remaining,
                     cursor: calculate_text_cursor(seq)
                   }
                 }
      end
    end

    property "ignores nil tags" do
      ExUnitProperties.check all(
                               {first, middle, last} <- {chr_gen(), chr_gen(), chr_gen()},
                               remaining <- str_gen(),
                               seq = to_string([first, middle, last]),
                               input = seq <> remaining
                             ) do
        assert tagged_sequence([
                 {:char1, char()},
                 {nil, char_is(middle)},
                 {:char3, char()}
               ])
               |> run(input, :text) ==
                 {
                   :ok,
                   %ParseResult.Ok{
                     parsed: %{
                       :char1 => first,
                       :char3 => last
                     },
                     remaining: remaining,
                     cursor: calculate_text_cursor(seq)
                   }
                 }
      end
    end

    test "errors when duplicate tag is found" do
      assert tagged_sequence([{:char1, char()}, {:char1, char()}, {:char3, char()}])
             |> run("abc", :text) ==
               {
                 :error,
                 :duplicate_tag,
                 "Found duplicated tag `char1`"
               }
    end

    test "errors when tag is not an atom" do
      assert tagged_sequence([{:char1, char()}, {"char2", char()}]) |> run("ab", :text) ==
               {
                 :error,
                 :tag_not_an_atom,
                 "Tag `char2` should be an atom or nil"
               }
    end

    test "errors when not enough input" do
      assert tagged_sequence([
               {:char1, char()},
               {:char2, char()}
             ])
             |> run("a", :text) ==
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

  describe "map/2" do
    property "maps parsed input" do
      ExUnitProperties.check all(
                               {first, middle, last} <- {chr_gen(), chr_gen(), chr_gen()},
                               remaining <- str_gen(),
                               seq =
                                 to_string([first]) <> to_string([middle]) <> to_string([last]),
                               input = seq <> remaining
                             ) do
        parser = sequence([char(), char_is(middle), char()])

        assert Combinators.Control.map(parser, fn [_f, m, _l] -> m end) |> run(input, :text) ==
                 {
                   :ok,
                   %ParseResult.Ok{
                     parsed: middle,
                     remaining: remaining,
                     cursor: calculate_text_cursor(seq)
                   }
                 }
      end
    end

    property "passes through underlying parser error" do
      ExUnitProperties.check all(
                               {first, middle, last, not_middle} <-
                                 {chr_gen(), chr_gen(), chr_gen(), chr_gen()},
                               not_middle != middle,
                               remaining <- str_gen(),
                               seq =
                                 to_string([first]) <>
                                   to_string([not_middle]) <> to_string([last]),
                               input = seq <> remaining
                             ) do
        parser = sequence([char(), char_is(middle), char()])

        assert Combinators.Control.map(parser, fn [_f, m, _l] -> m end) |> run(input, :text) ==
                 {:error,
                  %ParseResult.Error{
                    code: :unexpected_char,
                    parsed: not_middle,
                    message:
                      "@(1L:2C) Expected `#{to_string([middle])}` but found `#{to_string([not_middle])}`.",
                    cursor: calculate_text_cursor(to_string([first]))
                  }}
      end
    end

    property "errors if the mapper function raises an exception" do
      ExUnitProperties.check all(
                               {first, middle, last} <- {chr_gen(), chr_gen(), chr_gen()},
                               remaining <- str_gen(),
                               seq =
                                 to_string([first]) <> to_string([middle]) <> to_string([last]),
                               input = seq <> remaining
                             ) do
        parser = sequence([char(), char_is(middle), char()])

        assert Combinators.Control.map(parser, fn [_f, _m, _l] ->
                 raise "Something bad happened here"
               end)
               |> run(input, :text) ==
                 {:error, :mapper_error, "Something bad happened here"}
      end
    end
  end

  describe "either/1" do
    property "parses from input" do
      ExUnitProperties.check all(
                               {chr, other_chr} <- {chr_gen(), chr_gen()},
                               chr != other_chr,
                               remaining <- str_gen(),
                               input = to_string([chr]) <> remaining
                             ) do
        # Shuffle the order of alternatives
        alt = Enum.shuffle([char_is(chr), char_is(other_chr)])

        assert either(alt) |> run(input, :text) ==
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

    test "errors when no parsers succeed" do
      assert either([char_is(?a), char_is(?b)]) |> run("z", :text) ==
               {
                 :error,
                 %ParseResult.Error{
                   code: :all_parsers_failed,
                   message: "All parsers failed from @(1L:1C)",
                   cursor: %ParseResult.Text.Cursor{}
                 }
               }
    end

    test "errors when not enough input" do
      assert either([char(), char()]) |> run("", :text) ==
               {
                 :error,
                 %ParseResult.Error{
                   code: :all_parsers_failed,
                   message: "All parsers failed from @(1L:1C)",
                   cursor: %ParseResult.Text.Cursor{}
                 }
               }
    end
  end

  describe "surrounded/1" do
    property "parses from input" do
      ExUnitProperties.check all(
                               {first, middle, last} <- {chr_gen(), chr_gen(), chr_gen()},
                               remaining <- str_gen(),
                               seq = to_string([first, middle, last]),
                               input = seq <> remaining
                             ) do
        assert surrounded(char(), char_is(middle), char()) |> run(input, :text) ==
                 {
                   :ok,
                   %ParseResult.Ok{
                     parsed: middle,
                     remaining: remaining,
                     cursor: calculate_text_cursor(seq)
                   }
                 }
      end
    end

    test "errors when not enough input" do
      assert surrounded(char(), char(), char()) |> run("", :text) ==
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

  describe "maybe/1" do
    property "parses from input" do
      ExUnitProperties.check all(
                               chr <- chr_gen(),
                               remaining <- str_gen(),
                               input = to_string([chr]) <> remaining
                             ) do
        assert maybe(char_is(chr)) |> run(input, :text) ==
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

    property "returns nil parsed value when parser fails" do
      ExUnitProperties.check all(
                               {chr, other_chr} <- {chr_gen(), chr_gen()},
                               chr != other_chr,
                               remaining <- str_gen(),
                               input = to_string([chr]) <> remaining
                             ) do
        assert maybe(char_is(other_chr)) |> run(input, :text) ==
                 {
                   :ok,
                   %ParseResult.Ok{
                     parsed: nil,
                     remaining: input,
                     cursor: %ParseResult.Text.Cursor{}
                   }
                 }
      end
    end

    test "errors when no more input" do
      assert maybe(char()) |> run("", :text) ==
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

  describe "repeat/1 & repeat/2" do
    property "parses repeatedly from input without bounds" do
      ExUnitProperties.check all(
                               {chr, other_chr} <- {chr_gen(), chr_gen()},
                               chr != other_chr,
                               remaining <- str_gen(),
                               n <- StreamData.positive_integer(),
                               seq = String.duplicate(to_string([chr]), n),
                               input = seq <> to_string([other_chr]) <> remaining
                             ) do
        assert repeat(char_is(chr)) |> run(input, :text) ==
                 {
                   :ok,
                   %ParseResult.Ok{
                     parsed: String.to_charlist(seq),
                     remaining: to_string([other_chr]) <> remaining,
                     cursor: calculate_text_cursor(seq)
                   }
                 }
      end
    end

    property "parses repeatedly from input with exact bounds" do
      ExUnitProperties.check all(
                               {chr, other_chr} <- {chr_gen(), chr_gen()},
                               chr != other_chr,
                               remaining <- str_gen(),
                               n <- StreamData.positive_integer(),
                               seq = String.duplicate(to_string([chr]), n),
                               {at_least, up_to} = {n, n},
                               input = seq <> to_string([other_chr]) <> remaining
                             ) do
        assert repeat(char_is(chr), {at_least, up_to}) |> run(input, :text) ==
                 {
                   :ok,
                   %ParseResult.Ok{
                     parsed: String.to_charlist(seq),
                     remaining: to_string([other_chr]) <> remaining,
                     cursor: calculate_text_cursor(seq)
                   }
                 }
      end
    end

    property "errors when lower bound is not met" do
      ExUnitProperties.check all(
                               {chr, other_chr} <- {chr_gen(), chr_gen()},
                               chr != other_chr,
                               remaining <- str_gen(),
                               n <- StreamData.positive_integer(),
                               seq = String.duplicate(to_string([chr]), n),
                               {at_least, up_to} = {n + 1, nil},
                               input = seq <> to_string([other_chr]) <> remaining
                             ) do
        assert repeat(char_is(chr), {at_least, up_to}) |> run(input, :text) ==
                 {
                   :error,
                   %ParseResult.Error{
                     code: :min_bound_not_met,
                     message: "Did not repeat at least #{at_least} times",
                     cursor: calculate_text_cursor(seq)
                   }
                 }
      end
    end

    property "parses up to upper bound, even when more repeats are possible" do
      ExUnitProperties.check all(
                               chr <- chr_gen(),
                               remaining <- str_gen(),
                               n <- StreamData.positive_integer(),
                               seq = String.duplicate(to_string([chr]), n),
                               {at_least, up_to} = {nil, n},
                               input = seq <> to_string([chr]) <> remaining
                             ) do
        assert repeat(char_is(chr), {at_least, up_to}) |> run(input, :text) ==
                 {
                   :ok,
                   %ParseResult.Ok{
                     parsed: String.to_charlist(seq),
                     remaining: to_string([chr]) <> remaining,
                     cursor: calculate_text_cursor(seq)
                   }
                 }
      end
    end

    property "returns empty list when there are 0 repeats" do
      ExUnitProperties.check all(
                               {chr, other_chr} <- {chr_gen(), chr_gen()},
                               chr != other_chr,
                               remaining <- str_gen(),
                               input = to_string([chr]) <> remaining
                             ) do
        assert repeat(char_is(other_chr)) |> run(input, :text) ==
                 {
                   :ok,
                   %ParseResult.Ok{
                     parsed: [],
                     remaining: input,
                     cursor: %ParseResult.Text.Cursor{}
                   }
                 }
      end
    end

    test "returns empty list when end of input reached" do
      assert repeat(char()) |> run("", :text) ==
               {
                 :ok,
                 %ParseResult.Ok{
                   parsed: [],
                   remaining: "",
                   cursor: %ParseResult.Text.Cursor{}
                 }
               }
    end
  end

  describe "repeat_until/2" do
    property "parses repeatedly from input until condition is met" do
      ExUnitProperties.check all(
                               {chr, other_chr} <- {chr_gen(), chr_gen()},
                               chr != other_chr,
                               remaining <- str_gen(),
                               n <- StreamData.positive_integer(),
                               seq = String.duplicate(to_string([chr]), n),
                               input = seq <> to_string([other_chr]) <> remaining
                             ) do
        assert repeat_until(char_is(chr), char_is(other_chr))
               |> run(input, :text) ==
                 {
                   :ok,
                   %ParseResult.Ok{
                     parsed: String.to_charlist(seq),
                     remaining: to_string([other_chr]) <> remaining,
                     cursor: calculate_text_cursor(seq)
                   }
                 }
      end
    end

    test "returns empty list with end of input" do
      assert repeat_until(char_is(?a), char_is(?b)) |> run("", :text) ==
               {
                 :ok,
                 %ParseResult.Ok{
                   parsed: [],
                   remaining: "",
                   cursor: %ParseResult.Text.Cursor{}
                 }
               }
    end
  end
end
