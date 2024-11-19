defmodule Parquet do
  alias Parquet.Data.Reader

  @separator_width 200

  def summarize_sample do
    summarize("parquets/sample.parquet")
  end

  def summarize(path) do
    # Spawn the Parquet reader process
    {:ok, reader_pid} = Parquet.Data.Reader.start_link(path)

    file_metadata = Reader.get_file_metadata(reader_pid)
    print_summary("FILE METADATA", file_metadata)

    schema_tree = Reader.get_schema_tree(reader_pid)
    print_summary("SCHEMA TREE", schema_tree)

    column_order = Reader.get_column_order(reader_pid)
    print_summary("COLUMN ORDER", column_order)

    for column_name <- column_order do
      row_groups = Reader.fetch_column(reader_pid, column_name)
      print_summary("FETCH COLUMN - #{column_name}", fn -> print_row_groups(row_groups) end)
    end
  end

  defp print_summary(header, thing) do
    IO.puts("\n")
    IO.puts(String.duplicate("*", @separator_width))
    IO.puts(header)
    IO.puts(String.duplicate("↓", @separator_width))

    if is_function(thing) do
      thing.()
    else
      IO.inspect(thing, pretty: true)
    end

    IO.puts(String.duplicate("-", @separator_width))
  end

  defp print_row_groups(row_groups) do
    Enum.with_index(row_groups, fn rg, rg_index ->
      Enum.with_index(rg, fn cc, cc_index ->
        IO.puts("")
        IO.puts(String.duplicate("*", floor(@separator_width / 4)))
        IO.puts("Row Group: #{rg_index}")
        IO.puts("Column Chunk: #{cc_index}")
        IO.puts(String.duplicate("*", floor(@separator_width / 4)))
        IO.inspect(cc, pretty: true)
      end)
    end)
  end
end
