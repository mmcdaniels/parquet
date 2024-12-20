defmodule Combinators.Binary do
  import Combinators.Base
  alias Combinators.Result

  @doc """
  Parses a bit from the input.
  """
  def bit do
    fn input, cursor ->
      with <<bit::size(1), remaining::bitstring>> <- input do
        cursor = %Result.Binary.Cursor{
          cursor
          | position: cursor.position + 1
        }

        {:ok, %Result.Ok{parsed: <<bit::size(1)>>, remaining: remaining, cursor: cursor}}
      else
        _ ->
          message = "No more bits #{cursor}"

          {
            :error,
            %Result.Error{
              code: :no_more_bits,
              message: message,
              cursor: cursor
            }
          }
      end
    end
  end

  @doc """
  Parses a byte from the input.
  """
  def byte do
    fn input, cursor ->
      with <<byte::size(8), remaining::bitstring>> <- input do
        cursor = %Result.Binary.Cursor{
          cursor
          | position: cursor.position + 8
        }

        {:ok, %Result.Ok{parsed: <<byte::size(8)>>, remaining: remaining, cursor: cursor}}
      else
        _ ->
          message = "No more bytes #{cursor}"

          {
            :error,
            %Result.Error{
              code: :no_more_bytes,
              message: message,
              cursor: cursor
            }
          }
      end
    end
  end

  @doc """
  Parses when bit is 1
  """
  def bit1, do: bit_is(<<1::size(1)>>)

  @doc """
  Parses when bit is 0
  """
  def bit0, do: bit_is(<<0::size(1)>>)

  defp bit_is(<<_::size(1)>> = bit) do
    fn input, cursor ->
      res = check(bit(), fn b -> b == bit end, invert: false).(input, cursor)

      with {:error, %Result.Error{code: :predicate_not_satisfied, parsed: parsed}} <- res do
        {
          :error,
          %Result.Error{
            code: :unexpected_bit,
            message: "#{cursor} Expected `#{bit}` but found `#{parsed}`.",
            parsed: parsed,
            cursor: cursor
          }
        }
      end
    end
  end

  @doc """
  Parses a byte from the input if it matches `byte`.
  """
  def byte_is(<<_::size(8)>> = byte) do
    fn input, cursor ->
      res = check(byte(), fn b -> b == byte end, invert: false).(input, cursor)

      with {:error, %Result.Error{code: :predicate_not_satisfied, parsed: parsed}} <- res do
        {
          :error,
          %Result.Error{
            code: :unexpected_byte,
            message: "#{cursor} Expected `#{byte}` but found `#{parsed}`.",
            parsed: parsed,
            cursor: cursor
          }
        }
      end
    end
  end

  @doc """
  Parses a byte from the input if it does not match `byte`.
  """
  def byte_is_not(byte) do
    fn input, cursor ->
      res = check(byte(), fn b -> b != byte end, invert: false).(input, cursor)

      with {:error, %Result.Error{code: :predicate_not_satisfied, parsed: parsed}} <- res do
        {
          :error,
          %Result.Error{
            code: :unexpected_byte,
            message: "#{cursor} Found `#{byte}`.",
            parsed: parsed,
            cursor: cursor
          }
        }
      end
    end
  end
end
