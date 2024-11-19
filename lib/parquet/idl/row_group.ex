defmodule Parquet.Idl.RowGroup do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    embeds_many(:columns, Parquet.Idl.ColumnChunk)
    # i64
    field(:total_byte_size, :integer)
    # i64
    field(:num_rows, :integer)
    embeds_many(:sorting_columns, Parquet.Idl.SortingColumn)
    # i64
    field(:file_offset, :integer)
    # i64
    field(:total_compressed_size, :integer)
    # i16
    field(:ordinal, :integer)
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "columns"
      2 -> "total_byte_size"
      3 -> "num_rows"
      4 -> "sorting_columns"
      5 -> "file_offset"
      6 -> "total_compressed_size"
      7 -> "ordinal"
    end
  end

  def changeset(row_group, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    row_group
    |> cast(mapped_params, [
      :total_byte_size,
      :num_rows,
      :file_offset,
      :total_compressed_size,
      :ordinal
    ])
    |> cast_embed(:columns, required: true, with: &Parquet.Idl.ColumnChunk.changeset/2)
    |> cast_embed(:sorting_columns, required: false, with: &Parquet.Idl.SortingColumn.changeset/2)
    |> validate_required([:total_byte_size, :num_rows])
  end
end
