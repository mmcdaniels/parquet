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

  def fetch_column(pid, name) when is_binary(name) do
    GenServer.call(pid, {:fetch_column, name})
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

  @impl true
  def handle_call(
        {:fetch_column, name},
        _from,
        %{file: file, file_metadata: file_metadata, schema_tree: schema_tree} = state
      ) do
    if is_nil(Map.get(schema_tree, name)) do
      raise "Column `#{name}` is not in the schema tree."
    end

    leaf_artifacts = Reader.SchemaTree.build_leaf_artifacts(schema_tree[name])

    row_groups =
      Enum.map(
        file_metadata.row_groups,
        fn row_group ->
          Enum.map(
            leaf_artifacts,
            fn %{
                 index: index,
                 max_repetition_level: max_repetition_level,
                 max_definition_level: max_definition_level,
                 path_info: path_info,
                 definition_level_to_furthest_path_index: definition_level_to_furthest_path_index
               } ->
              column_chunk = Enum.at(row_group.columns, index)
              page_header = Reader.PageHeader.read(file, column_chunk.meta_data.data_page_offset)

              case page_header.type do
                :data_page ->
                  Reader.DataPageV1.read(
                    file,
                    page_header.data_page_header,
                    page_header.uncompressed_page_size,
                    path_info,
                    definition_level_to_furthest_path_index,
                    max_repetition_level,
                    max_definition_level
                  )
              end
            end
          )
        end
      )

    {:reply, row_groups, state}
  end
end
