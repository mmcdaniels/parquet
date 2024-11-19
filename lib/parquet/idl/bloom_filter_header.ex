defmodule Parquet.Idl.BloomFilterHeader do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    # i32
    field(:num_bytes, :integer)
    field(:algorithm, Parquet.Idl.BloomFilterAlgorithm)
    field(:hash, Parquet.Idl.BloomFilterHash)
    field(:compression, Parquet.Idl.BloomFilterCompression)
  end

  defp field__id_to_name(id) do
    case id do
      1 -> "num_bytes"
      2 -> "algorithm"
      3 -> "hash"
      4 -> "compression"
    end
  end

  def changeset(bloom_filter_header, params \\ %{}) do
    mapped_params = for {k, v} <- params, into: %{}, do: {field__id_to_name(k), v}

    bloom_filter_header
    |> cast(mapped_params, [
      :num_bytes,
      :algorithm,
      :hash,
      :compression
    ])
    |> validate_required([
      :num_bytes,
      :algorithm,
      :hash,
      :compression
    ])
  end
end
