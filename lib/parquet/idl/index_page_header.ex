defmodule Parquet.Idl.IndexPageHeader do
  use Ecto.Schema

  @primary_key false
  embedded_schema do
  end

  def changeset(index_page_header, %{}) do
    index_page_header
  end
end
