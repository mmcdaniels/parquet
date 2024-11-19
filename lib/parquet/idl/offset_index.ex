defmodule Parquet.Idl.OffsetIndex do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    embeds_many(:page_locations, Parquet.Idl.PageLocation)
    # list<i64>
    field(:unencoded_byte_array_data_bytes, {:array, :integer})
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "page_locations"
      2 -> "unencoded_byte_array_data_bytes"
    end
  end

  def changeset(offset_index, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    offset_index
    |> cast(mapped_params, [
      :page_locations,
      :unencoded_byte_array_data_bytes
    ])
    |> cast_embed(:columns, required: true, with: &Parquet.Idl.PageLocation.changeset/2)
    |> validate_required([:page_locations])
  end
end
