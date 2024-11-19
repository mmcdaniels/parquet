defmodule Parquet.Idl.SizeStatistics do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    # i64
    field(:unencoded_byte_array_data_bytes, :integer)
    # list<i64>
    field(:repetition_level_histogram, {:array, :integer})
    # list<i64>
    field(:definition_level_histogram, {:array, :integer})
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "unencoded_byte_array_data_bytes"
      2 -> "repetition_level_histogram"
      3 -> "definition_level_histogram"
    end
  end

  def changeset(size_statistics, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    size_statistics
    |> cast(mapped_params, [
      :unencoded_byte_array_data_bytes,
      :repetition_level_histogram,
      :definition_level_histogram
    ])
  end
end
