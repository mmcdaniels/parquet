defmodule Parquet.Data.Reader.FileMetadata do
  alias Parquet.Data.ThriftCompactProtocol

  @doc """
  Deserializes Thrift BinaryCompactProtocol-encoded Parquet file metadata from the file footer
  into Elixir structs.
  """
  def read(file) do
    # Set position to first byte of file metadata footer
    {:ok, <<file_metadata_length::unsigned-integer-32-little>>} = :file.pread(file, {:eof, -8}, 4)
    :file.position(file, {:eof, -(file_metadata_length + 8)})

    # Deserialize binary blob into Thrift data
    raw_file_metadata = ThriftCompactProtocol.read_struct(file)

    # Transform Thrift data into Elixir structs via Ecto schemas
    file_metadata_changeset =
      Parquet.Idl.FileMetadata.changeset(%Parquet.Idl.FileMetadata{}, raw_file_metadata)

    # TODO better error handling for schema validation failures
    Ecto.Changeset.apply_action(file_metadata_changeset, :parse)
  end
end
