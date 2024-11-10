defmodule Combinators.BinaryTest do
  use ExUnit.Case
  use ExUnitProperties
  import Combinators.BinaryTest.Helpers

  import Combinators.Base,
    only: [
      run: 3
    ]

  import Combinators.Binary,
    only: [
      bit: 0,
      bit1: 0,
      bit0: 0,
      byte_is: 1,
      byte_is_not: 1
    ]

  alias Combinators.Result

  describe "bit/0" do
    property "reads bit" do
      ExUnitProperties.check all(
                               bit <- bit_gen(),
                               remaining <- bitstr_gen(),
                               input = <<bit::bitstring, remaining::bitstring>>
                             ) do
        assert bit() |> run(input, :binary) ==
                 {
                   :ok,
                   %Result.Ok{
                     parsed: bit,
                     remaining: remaining,
                     cursor: calculate_binary_cursor(bit)
                   }
                 }
      end
    end

    test "errors when no more bits" do
      assert bit() |> run(<<>>, :binary) ==
               {
                 :error,
                 %Result.Error{
                   code: :no_more_bits,
                   message: "No more bits @(1P)",
                   cursor: %Result.Binary.Cursor{}
                 }
               }
    end
  end

  describe "bit1/0" do
    test "reads bit=1" do
      assert bit1() |> run(<<0b10000000>>, :binary) ==
               {
                 :ok,
                 %Result.Ok{
                   parsed: <<1::size(1)>>,
                   remaining: <<0::size(7)>>,
                   cursor: %Result.Binary.Cursor{position: 2}
                 }
               }
    end

    test "errors when bit=0" do
      assert bit1() |> run(<<0b00000000>>, :binary) ==
               {
                 :error,
                 %Result.Error{
                   code: :unexpected_bit,
                   parsed: <<0::size(1)>>,
                   message: "@(1P) Expected `<<1::size(1)>>` but found `<<0::size(1)>>`.",
                   cursor: %Result.Binary.Cursor{}
                 }
               }
    end

    test "errors when no more bits" do
      assert bit1() |> run(<<>>, :binary) ==
               {
                 :error,
                 %Result.Error{
                   code: :no_more_bits,
                   message: "No more bits @(1P)",
                   cursor: %Result.Binary.Cursor{}
                 }
               }
    end
  end

  describe "bit0/0" do
    test "reads bit=0" do
      assert bit0() |> run(<<0b00000000>>, :binary) ==
               {
                 :ok,
                 %Result.Ok{
                   parsed: <<0::size(1)>>,
                   remaining: <<0::size(7)>>,
                   cursor: %Result.Binary.Cursor{position: 2}
                 }
               }
    end

    test "errors when bit=1" do
      assert bit0() |> run(<<0b10000000>>, :binary) ==
               {
                 :error,
                 %Result.Error{
                   code: :unexpected_bit,
                   parsed: <<1::size(1)>>,
                   message: "@(1P) Expected `<<0::size(1)>>` but found `<<1::size(1)>>`.",
                   cursor: %Result.Binary.Cursor{}
                 }
               }
    end

    test "errors when no more bits" do
      assert bit0() |> run(<<>>, :binary) ==
               {
                 :error,
                 %Result.Error{
                   code: :no_more_bits,
                   message: "No more bits @(1P)",
                   cursor: %Result.Binary.Cursor{}
                 }
               }
    end
  end

  describe "byte/0" do
    property "reads byte" do
      ExUnitProperties.check all(
                               byte <- byte_gen(),
                               remaining <- bitstr_gen(),
                               input = <<byte::binary, remaining::bitstring>>
                             ) do
        assert Combinators.Binary.byte() |> run(input, :binary) ==
                 {
                   :ok,
                   %Result.Ok{
                     parsed: byte,
                     remaining: remaining,
                     cursor: calculate_binary_cursor(byte)
                   }
                 }
      end
    end

    test "errors when no more bytes" do
      assert Combinators.Binary.byte() |> run(<<1::size(7)>>, :binary) ==
               {
                 :error,
                 %Result.Error{
                   code: :no_more_bytes,
                   message: "No more bytes @(1P)",
                   cursor: %Result.Binary.Cursor{}
                 }
               }
    end
  end

  describe "byte_is/1" do
    test "reads wanted byte" do
      ExUnitProperties.check all(
                               wanted <- byte_gen(),
                               remaining <- bitstr_gen(),
                               input = <<wanted::binary, remaining::bitstring>>
                             ) do
        assert byte_is(wanted) |> run(input, :binary) ==
                 {
                   :ok,
                   %Result.Ok{
                     parsed: wanted,
                     remaining: remaining,
                     cursor: calculate_binary_cursor(wanted)
                   }
                 }
      end
    end

    test "errors when not wanted byte" do
      ExUnitProperties.check all(
                               {wanted, other} <- {byte_gen(), byte_gen()},
                               wanted != other,
                               remaining <- bitstr_gen(),
                               input = <<other::binary, remaining::bitstring>>
                             ) do
        assert byte_is(wanted) |> run(input, :binary) ==
                 {
                   :error,
                   %Result.Error{
                     code: :unexpected_byte,
                     parsed: other,
                     message: "@(1P) Expected `#{wanted}` but found `#{other}`.",
                     cursor: %Result.Binary.Cursor{}
                   }
                 }
      end
    end

    test "errors when no more bytes" do
      assert byte_is(<<0xAB>>) |> run(<<>>, :binary) ==
               {
                 :error,
                 %Result.Error{
                   code: :no_more_bytes,
                   message: "No more bytes @(1P)",
                   cursor: %Result.Binary.Cursor{}
                 }
               }
    end
  end

  describe "byte_is_not/1" do
    test "reads when not unwanted byte" do
      ExUnitProperties.check all(
                               {unwanted, other} <- {byte_gen(), byte_gen()},
                               unwanted != other,
                               remaining <- bitstr_gen(),
                               input = <<other::binary, remaining::bitstring>>
                             ) do
        assert byte_is_not(unwanted) |> run(input, :binary) ==
                 {
                   :ok,
                   %Result.Ok{
                     parsed: other,
                     remaining: remaining,
                     cursor: calculate_binary_cursor(other)
                   }
                 }
      end
    end

    test "errors when unwanted byte" do
      ExUnitProperties.check all(
                               {unwanted, other} <- {byte_gen(), byte_gen()},
                               unwanted != other,
                               remaining <- bitstr_gen(),
                               input = <<unwanted::binary, remaining::bitstring>>
                             ) do
        assert byte_is_not(unwanted) |> run(input, :binary) ==
                 {
                   :error,
                   %Result.Error{
                     code: :unexpected_byte,
                     parsed: unwanted,
                     message: "@(1P) Found `#{unwanted}`.",
                     cursor: %Result.Binary.Cursor{}
                   }
                 }
      end
    end

    test "errors when no more bytes" do
      assert byte_is_not(<<0xAB>>) |> run(<<>>, :binary) ==
               {
                 :error,
                 %Result.Error{
                   code: :no_more_bytes,
                   message: "No more bytes @(1P)",
                   cursor: %Result.Binary.Cursor{}
                 }
               }
    end
  end
end
