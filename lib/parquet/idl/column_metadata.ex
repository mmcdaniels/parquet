defmodule Parquet.Idl.ColumnMetadata do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:type, Parquet.Idl.Type)
    field(:encodings, {:array, Parquet.Idl.Encoding})
    # list<string>
    field(:path_in_schema, {:array, :string})
    field(:codec, Parquet.Idl.CompressionCodec)
    # i64
    field(:num_values, :integer)
    # i64
    field(:total_uncompressed_size, :integer)
    # i64
    field(:total_compressed_size, :integer)
    embeds_many(:key_value_metadata, Parquet.Idl.KeyValue)
    # i64
    field(:data_page_offset, :integer)
    # i64
    field(:index_page_offset, :integer)
    # i64
    field(:dictionary_page_offset, :integer)
    embeds_one(:statistics, Parquet.Idl.Statistics)
    embeds_many(:encoding_stats, Parquet.Idl.PageEncodingStats)
    # i64
    field(:bloom_filter_offset, :integer)
    # i32
    field(:bloom_filter_length, :integer)
    embeds_one(:size_statistics, Parquet.Idl.SizeStatistics)
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "type"
      2 -> "encodings"
      3 -> "path_in_schema"
      4 -> "codec"
      5 -> "num_values"
      6 -> "total_uncompressed_size"
      7 -> "total_compressed_size"
      8 -> "key_value_metadata"
      9 -> "data_page_offset"
      10 -> "index_page_offset"
      11 -> "dictionary_page_offset"
      12 -> "statistics"
      13 -> "encoding_stats"
      14 -> "bloom_filter_offset"
      15 -> "bloom_filter_length"
      16 -> "size_statistics"
    end
  end

  def changeset(column_metadata, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    column_metadata
    |> cast(mapped_params, [
      :type,
      :encodings,
      :path_in_schema,
      :codec,
      :num_values,
      :total_uncompressed_size,
      :total_compressed_size,
      :data_page_offset,
      :index_page_offset,
      :dictionary_page_offset,
      :bloom_filter_offset,
      :bloom_filter_length
    ])
    |> cast_embed(:key_value_metadata,
      required: false,
      with: &Parquet.Idl.KeyValue.changeset/2
    )
    |> cast_embed(:statistics,
      required: false,
      with: &Parquet.Idl.Statistics.changeset/2
    )
    |> cast_embed(:encoding_stats,
      required: false,
      with: &Parquet.Idl.PageEncodingStats.changeset/2
    )
    |> cast_embed(:size_statistics,
      required: false,
      with: &Parquet.Idl.SizeStatistics.changeset/2
    )
    |> validate_required([
      :type,
      :encodings,
      :path_in_schema,
      :codec,
      :num_values,
      :total_uncompressed_size,
      :total_compressed_size,
      :data_page_offset
    ])
  end
end
