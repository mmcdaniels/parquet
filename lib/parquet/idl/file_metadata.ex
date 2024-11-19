defmodule Parquet.Idl.FileMetadata do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    # i32
    field(:version, :integer)
    embeds_many(:schema, Parquet.Idl.SchemaElement)
    # i64
    field(:num_rows, :integer)
    embeds_many(:row_groups, Parquet.Idl.RowGroup)
    embeds_many(:key_value_metadata, Parquet.Idl.KeyValue)
    field(:created_by, :string)
    field(:column_orders, {:array, Parquet.Idl.ColumnOrder})
    field(:encryption_algorithm, Parquet.Idl.EncryptionAlgorithm)
    field(:footer_signing_key_metadata, :binary)
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "version"
      2 -> "schema"
      3 -> "num_rows"
      4 -> "row_groups"
      5 -> "key_value_metadata"
      6 -> "created_by"
      7 -> "column_orders"
      8 -> "encryption_algorithm"
      9 -> "footer_signing_key_metadata"
    end
  end

  def changeset(file_metadata, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    file_metadata
    |> cast(mapped_params, [
      :version,
      :num_rows,
      :created_by,
      :column_orders,
      :encryption_algorithm,
      :footer_signing_key_metadata
    ])
    |> cast_embed(:schema, required: true, with: &Parquet.Idl.SchemaElement.changeset/2)
    |> cast_embed(:row_groups, required: true, with: &Parquet.Idl.RowGroup.changeset/2)
    |> cast_embed(:key_value_metadata, required: false, with: &Parquet.Idl.KeyValue.changeset/2)
    |> validate_required([:version, :num_rows])
  end
end
