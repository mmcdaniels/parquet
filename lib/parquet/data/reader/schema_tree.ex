defmodule Parquet.Data.Reader.SchemaTree do
  import Helpers
  alias Parquet.Idl.LogicalType

  @doc """
  Traverses the depth-first-serialized tree of schema elements from the Parquet file metadata,
  inflates it into a full tree, and normalizes the branches.
  """
  def build([root | schema_elements]) do
    case root.num_children do
      0 ->
        raise "The schema indicates that there are no columns in the parquet"

      n ->
        # Start tracking depth-first recursion after the root schema element
        build(
          schema_elements,
          [],
          %{},
          n,
          0
        )
    end
  end

  defp build(
         schema_elements,
         column_order_rev,
         schema_tree,
         columns_remaining,
         leaf_count
       ) do
    case columns_remaining do
      0 ->
        column_order = Enum.reverse(column_order_rev)
        {:ok, column_order, schema_tree}

      n ->
        %{name: column_name} = peek(schema_elements)

        {column_tree, schema_elements, leaf_count} =
          build_column_tree(
            schema_elements,
            leaf_count
          )

        schema_tree = Map.put(schema_tree, column_name, column_tree)

        column_order_rev = [column_name | column_order_rev]

        build(
          schema_elements,
          column_order_rev,
          schema_tree,
          n - 1,
          leaf_count
        )
    end
  end

  defp build_column_tree(
         schema_elements,
         leaf_count
       ) do
    {schema_element, schema_elements} = pop(schema_elements)

    case schema_element do
      # group element
      %{type: nil} ->
        normalized_type = normalize_group_type(schema_element)

        case normalized_type do
          :list ->
            outer_tree = %{}
            outer_element = schema_element

            # Validate outer element
            if outer_element.repetition_type not in [:optional, :required],
              do: raise("Invalid repetition type for list outer element.")

            if outer_element.num_children != 1,
              do: raise("Outer element for list must have one child.")

            outer_tree = Map.put(outer_tree, :name, outer_element.name)
            outer_tree = Map.put(outer_tree, :type, normalized_type)
            outer_tree = Map.put(outer_tree, :repetition_type, outer_element.repetition_type)

            # Validate middle element
            {middle_element, schema_elements} = pop(schema_elements)

            if middle_element.repetition_type not in [:repeated],
              do: raise("Invalid repetition type for list middle element.")

            if middle_element.name != "list",
              do: raise("Middle element of list type must be named `list`")

            if middle_element.num_children != 1,
              do: raise("Middle element for list must have one child.")

            middle_tree = %{}
            middle_tree = Map.put(middle_tree, :name, middle_element.name)
            middle_tree = Map.put(middle_tree, :type, normalize_group_type(middle_element))
            middle_tree = Map.put(middle_tree, :repetition_type, middle_element.repetition_type)

            # Parse and validate inner element
            %{repetition_type: inner_repetition_type} = peek(schema_elements)

            if inner_repetition_type not in [:optional, :required],
              do: raise("Invalid repetition type for list inner element.")

            {inner_tree, schema_elements, leaf_count} =
              build_column_tree(
                schema_elements,
                leaf_count
              )

            middle_tree = Map.put(middle_tree, :children, [inner_tree])
            outer_tree = Map.put(outer_tree, :children, [middle_tree])

            {outer_tree, schema_elements, leaf_count}
        end

      # leaf element
      %{type: _type} ->
        leaf_tree = %{}
        leaf_tree = Map.put(leaf_tree, :leaf_index, leaf_count)
        leaf_tree = Map.put(leaf_tree, :name, schema_element.name)
        leaf_tree = Map.put(leaf_tree, :type, normalize_leaf_type(schema_element))
        leaf_tree = Map.put(leaf_tree, :repetition_type, schema_element.repetition_type)
        leaf_tree = Map.put(leaf_tree, :children, [])
        leaf_count = leaf_count + 1

        {leaf_tree, schema_elements, leaf_count}
    end
  end

  defp normalize_group_type(schema_element) do
    cond do
      not is_nil(schema_element.logical_type) ->
        case schema_element.logical_type do
          %LogicalType.ListType{} ->
            :list

          logical_type ->
            raise "Unsupported logical type #{inspect(logical_type)}"
        end

      not is_nil(schema_element.converted_type) ->
        cond do
          schema_element.converted_type in {:list} ->
            schema_element.converted_type

          true ->
            raise "Unsupported logical type #{inspect(schema_element.converted_type)}"
        end

      true ->
        # No type is filled out, so the type is nil
        nil
    end
  end

  # TODO Consider all 3 type specifications when normalizing the leaf type:
  #   LogicalType, ConvertedType, and Type.
  defp normalize_leaf_type(schema_element) do
    cond do
      schema_element.type in [:int32, :byte_array] -> schema_element.type
      true -> raise "Unsupported  type #{inspect(schema_element.type)}"
    end
  end
end
