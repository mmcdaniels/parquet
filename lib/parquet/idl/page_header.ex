defmodule Parquet.Idl.PageHeader do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:type, Parquet.Idl.PageType)
    # i32
    field(:uncompressed_page_size, :integer)
    # i32
    field(:compressed_page_size, :integer)
    # i32
    field(:crc, :integer)
    embeds_one(:data_page_header, Parquet.Idl.DataPageHeader)
    embeds_one(:index_page_header, Parquet.Idl.IndexPageHeader)
    embeds_one(:dictionary_page_header, Parquet.Idl.DictionaryPageHeader)
    embeds_one(:data_page_header_v2, Parquet.Idl.DataPageHeaderV2)
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "type"
      2 -> "uncompressed_page_size"
      3 -> "compressed_page_size"
      4 -> "crc"
      5 -> "data_page_header"
      6 -> "index_page_header"
      7 -> "dictionary_page_header"
      8 -> "data_page_header_v2"
    end
  end

  def changeset(page_header, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    page_header
    |> cast(mapped_params, [
      :type,
      :uncompressed_page_size,
      :compressed_page_size,
      :crc
    ])
    |> cast_embed(:data_page_header,
      required: false,
      with: &Parquet.Idl.DataPageHeader.changeset/2
    )
    |> cast_embed(:index_page_header,
      required: false,
      with: &Parquet.Idl.IndexPageHeader.changeset/2
    )
    |> cast_embed(:dictionary_page_header,
      required: false,
      with: &Parquet.Idl.DictionaryPageHeader.changeset/2
    )
    |> cast_embed(:data_page_header_v2,
      required: false,
      with: &Parquet.Idl.DataPageHeaderV2.changeset/2
    )
    |> validate_required([
      :type,
      :uncompressed_page_size,
      :compressed_page_size
    ])
  end
end
