defmodule Parquet.Data.Reader.PageHeader do
  alias Parquet.Data.ThriftCompactProtocol
  alias Parquet.Idl

  @doc """
  Deserializes Thrift BinaryCompactProtocol-encoded Parquet page header
  into Elixir structs.
  """
  def read(file, page_offset) do
    {:ok, _} = :file.position(file, {:bof, page_offset})
    raw_page_header = ThriftCompactProtocol.read_struct(file)

    page_header_changeset =
      Idl.PageHeader.changeset(%Idl.PageHeader{}, raw_page_header)

    {:ok, page_header} = Ecto.Changeset.apply_action(page_header_changeset, :parse)
    page_header
  end
end
