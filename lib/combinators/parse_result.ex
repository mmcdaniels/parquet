defmodule ParseResult.Text.Cursor do
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
end

defimpl String.Chars, for: ParseResult.Text.Cursor do
  def to_string(cursor), do: "@(#{cursor.line}L:#{cursor.column}C)"
end

defmodule ParseResult.Ok do
  @enforce_keys [:parsed, :remaining, :cursor]
  defstruct parsed: nil,
            remaining: nil,
            cursor: %ParseResult.Text.Cursor{}

  @type t :: %__MODULE__{
          parsed: any(),
          remaining: String.t(),
          # position after parsing
          cursor: ParseResult.Text.Cursor.t()
        }
end

defmodule ParseResult.Error do
  @enforce_keys [:code, :message, :cursor]
  defstruct [:code, :message, :parsed, :cursor]

  @type t :: %__MODULE__{
          code: atom(),
          message: String.t(),
          parsed: any(),
          # position just before the error occurred
          cursor: ParseResult.Text.Cursor.t()
        }
end
