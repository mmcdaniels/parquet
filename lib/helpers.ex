defmodule Helpers do
  def peek([h | _]) do
    h
  end

  def peek([]), do: raise("peeked list is empty")

  def pop([h | t]) do
    {h, t}
  end

  def pop([]), do: raise("popped list is empty")
end
