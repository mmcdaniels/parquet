defmodule Parquet.Idl.SchemaElement do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:type, Parquet.Idl.Type)
    # i32
    field(:type_length, :integer)
    field(:repetition_type, Parquet.Idl.FieldRepetitionType)
    field(:name, :string)
    # i32
    field(:num_children, :integer)
    field(:converted_type, Parquet.Idl.ConvertedType)
    # i32
    field(:scale, :integer)
    # i32
    field(:precision, :integer)
    # i32
    field(:field_id, :integer)
    field(:logical_type, Parquet.Idl.LogicalType)
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "type"
      2 -> "type_length"
      3 -> "repetition_type"
      4 -> "name"
      5 -> "num_children"
      6 -> "converted_type"
      7 -> "scale"
      8 -> "precision"
      9 -> "field_id"
      10 -> "logical_type"
    end
  end

  def changeset(schema_element, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    schema_element
    |> cast(mapped_params, [
      :type,
      :type_length,
      :repetition_type,
      :name,
      :num_children,
      :converted_type,
      :scale,
      :precision,
      :field_id,
      :logical_type
    ])
    |> validate_required([:name])
  end
end
