defmodule Parquet.Data.Reader do
  use GenServer
  import Parquet.ThriftCompactProtocol

  # Client

  def start_link(path) do
    GenServer.start_link(__MODULE__, path)
  end

  def get_file_metadata(pid) do
    GenServer.call(pid, :get_file_metadata)
  end

  defp read_file_metadata(file) do
    # Set position to first byte of file metadata footer
    {:ok, <<file_metadata_length::unsigned-integer-32-little>>} = :file.pread(file, {:eof, -8}, 4)
    :file.position(file, {:eof, -(file_metadata_length + 8)})

    # Deserialize binary blob into Thrift data
    raw_file_metadata = read_struct(file)

    # Transform Thrift data into Elixir structs via Ecto schemas
    file_metadata_changeset =
      Parquet.Idl.FileMetadata.changeset(%Parquet.Idl.FileMetadata{}, raw_file_metadata)

    # TODO better error handling for schema validation failures
    Ecto.Changeset.apply_action(file_metadata_changeset, :parse)
  end

  # Server

  @impl true
  def init(path) do
    case File.open(path, [:read, :binary]) do
      {:ok, file} ->
        # FIXME Validate magic numbers at beginning and end of file
        {:ok, file_metadata} = read_file_metadata(file)

        state = %{
          file_metadata: file_metadata
        }

        {:ok, state}

      {:error, reason} ->
        {:stop, {:file_open_error, reason}}
    end
  end

  @impl true
  def handle_call(:get_file_metadata, _from, %{file_metadata: file_metadata} = state) do
    {:reply, file_metadata, state}
  end
end
