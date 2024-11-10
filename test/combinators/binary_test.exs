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
end
