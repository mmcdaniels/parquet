defmodule Parquet.Idl.ColumnChunk do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:file_path, :string)
    # i64
    field(:file_offset, :integer)
    embeds_one(:meta_data, Parquet.Idl.ColumnMetadata)
    # i64
    field(:offset_index_offset, :integer)
    # i32
    field(:offset_index_length, :integer)
    # i64
    field(:column_index_offset, :integer)
    # i32
    field(:column_index_length, :integer)
    field(:crypto_metadata, Parquet.Idl.ColumnCryptoMetadata)
    field(:encrypted_column_metadata, :binary)
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "file_path"
      2 -> "file_offset"
      3 -> "meta_data"
      4 -> "offset_index_offset"
      5 -> "offset_index_length"
      6 -> "column_index_offset"
      7 -> "column_index_length"
      8 -> "crypto_metadata"
      9 -> "encrypted_column_metadata"
    end
  end

  def changeset(column_chunk, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    column_chunk
    |> cast(mapped_params, [
      :file_path,
      :file_offset,
      :offset_index_offset,
      :offset_index_length,
      :column_index_offset,
      :column_index_length,
      :crypto_metadata,
      :encrypted_column_metadata
    ])
    |> cast_embed(:meta_data,
      required: false,
      with: &Parquet.Idl.ColumnMetadata.changeset/2
    )
    |> validate_required([:file_offset])
  end
end
