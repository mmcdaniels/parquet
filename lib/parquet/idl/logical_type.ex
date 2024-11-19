defmodule Parquet.Idl.LogicalType do
  use Ecto.Type

  @impl Ecto.Type
  def type, do: :map

  @impl Ecto.Type
  def cast(value) do
    changeset =
      case value do
        %{1 => %{}} ->
          Ecto.Changeset.change(%Parquet.Idl.LogicalType.StringType{})

        %{2 => %{}} ->
          Ecto.Changeset.change(%Parquet.Idl.LogicalType.MapType{})

        %{3 => %{}} ->
          Ecto.Changeset.change(%Parquet.Idl.LogicalType.ListType{})

        %{4 => %{}} ->
          Ecto.Changeset.change(%Parquet.Idl.LogicalType.EnumType{})

        %{5 => params} ->
          %Parquet.Idl.LogicalType.DecimalType{}
          |> Parquet.Idl.LogicalType.DecimalType.changeset(params)

        %{6 => %{}} ->
          Ecto.Changeset.change(%Parquet.Idl.LogicalType.DateType{})

        %{7 => params} ->
          %Parquet.Idl.LogicalType.TimeType{}
          |> Parquet.Idl.LogicalType.TimeType.changeset(params)

        %{8 => params} ->
          %Parquet.Idl.LogicalType.TimestampType{}
          |> Parquet.Idl.LogicalType.TimestampType.changeset(params)

        %{10 => params} ->
          %Parquet.Idl.LogicalType.IntType{}
          |> Parquet.Idl.LogicalType.IntType.changeset(params)

        %{11 => %{}} ->
          Ecto.Changeset.change(%Parquet.Idl.LogicalType.NullType{})

        %{12 => %{}} ->
          Ecto.Changeset.change(%Parquet.Idl.LogicalType.JsonType{})

        %{13 => %{}} ->
          Ecto.Changeset.change(%Parquet.Idl.LogicalType.BsonType{})

        %{14 => %{}} ->
          Ecto.Changeset.change(%Parquet.Idl.LogicalType.UUIDType{})

        %{15 => %{}} ->
          Ecto.Changeset.change(%Parquet.Idl.LogicalType.Float16Type{})
      end

    value = Ecto.Changeset.apply_action!(changeset, :parse)
    {:ok, value}
  end

  @impl Ecto.Type
  def dump(_), do: :error

  @impl Ecto.Type
  def load(_), do: :error
end
