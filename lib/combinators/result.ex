defmodule Combinators.Result.Text.Cursor do
  @moduledoc """
  A text cursor is the location from the start of the parser input measured in line and columns.

  A line(L) is the vertical location of lines in a string.
  A column(C) is the horizontal location between characters in a string.
  Note that columns exist...
    ...between the start-of-string and the first char
    ...between normal chars in a string
    ...between the last char and the end-of-string.
  The origin of a cursor is 1L,1C.

  Example:
  STRING   -> L,C
  "|ab\nc" -> 1,1
  "a|b\nc" -> 1,2
  "ab|\nc" -> 1,3
  "ab\n|c" -> 2,1
  "ab\nc|" -> 2,2
  """

  defstruct line: 1,
            column: 1

  @type t :: %__MODULE__{
          line: non_neg_integer(),
          column: non_neg_integer()
        }

  defimpl String.Chars, for: __MODULE__ do
    def to_string(cursor), do: "@(#{cursor.line}L:#{cursor.column}C)"
  end
end

defmodule Combinators.Result.Binary.Cursor do
  @moduledoc """
  A binary cursor is the location from the start of the parser input measured in bits.

  A position(P) is the location between bits in a bitstring.
  Note that positions exist...
    ...between the start-of-bitstring and the first bit
    ...between normal bits in a bitstring
    ...between the last bit and the end-of-bitstring.
  The origin of a cursor is 1P.

  Example:
  BITSTRING -> P
  <<|010>>  -> 1
  <<0|10>>  -> 2
  <<01|0>>  -> 3
  <<010|>>  -> 4
  """
  defstruct position: 1

  @type t :: %__MODULE__{
          position: non_neg_integer()
        }

  defimpl String.Chars, for: __MODULE__ do
    def to_string(cursor), do: "@(#{cursor.position}P)"
  end
end

defmodule Combinators.Result.Ok do
  @enforce_keys [:parsed, :remaining, :cursor]
  defstruct parsed: nil,
            remaining: nil,
            cursor: %Combinators.Result.Text.Cursor{}

  @type t :: %__MODULE__{
          parsed: String.t() | binary(),
          remaining: String.t() | binary(),
          # position after parsing
          cursor: Combinators.Result.Text.Cursor.t() | Combinators.Result.Binary.Cursor.t()
        }
end

defmodule Combinators.Result.Error do
  @enforce_keys [:code, :message, :cursor]
  defstruct [:code, :message, :parsed, :cursor]

  @type t :: %__MODULE__{
          code: atom(),
          message: String.t(),
          parsed: String.t() | binary() | nil,
          # position just before the error occurred
          cursor: Combinators.Result.Text.Cursor.t() | Combinators.Result.Binary.Cursor.t()
        }
end

# FIXME This works to allow non-binary bitstring parsed values to be printed as strings.
#       However, it is not recommended because it redefines a built-in implmentation.
#       Should instead wrap the parsed value in a datatype (eg. struct) and implement String.Chars
#       for that datatype.
defimpl String.Chars, for: BitString do
  def to_string(v) do
    if(is_binary(v)) do
      Kernel.to_string(v)
    else
      inspect(v)
    end
  end
end
