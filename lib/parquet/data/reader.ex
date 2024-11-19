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

  def get_column_order(pid) do
    GenServer.call(pid, :get_column_order)
  end

  def get_schema_tree(pid) do
    GenServer.call(pid, :get_schema_tree)
  end

  # Server

  @impl true
  def init(path) do
    case File.open(path, [:read, :binary]) do
      {:ok, file} ->
        # FIXME Validate magic numbers at beginning and end of file
        {:ok, file_metadata} = Reader.FileMetadata.read(file)
        {:ok, column_order, schema_tree} = Reader.SchemaTree.build(file_metadata.schema)

        state = %{
          file: file,
          file_metadata: file_metadata,
          schema_tree: schema_tree,
          column_order: column_order
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

  @impl true
  def handle_call(:get_schema_tree, _from, %{schema_tree: schema_tree} = state) do
    {:reply, schema_tree, state}
  end

  @impl true
  def handle_call(:get_column_order, _from, %{column_order: column_order} = state) do
    {:reply, column_order, state}
  end
end
