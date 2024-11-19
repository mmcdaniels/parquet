defmodule Parquet.Data.Reader do
  use GenServer
  alias Parquet.Data.Reader

  # Client

  def start_link(path) do
    GenServer.start_link(__MODULE__, path)
  end

  def get_file_metadata(pid) do
    GenServer.call(pid, :get_file_metadata)
  end


  # Server

  @impl true
  def init(path) do
    case File.open(path, [:read, :binary]) do
      {:ok, file} ->
        # FIXME Validate magic numbers at beginning and end of file
        {:ok, file_metadata} = Reader.FileMetadata.read(file)

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
