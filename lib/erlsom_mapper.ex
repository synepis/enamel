defmodule Enamel.ErlsomMapper do
  
  ## Public API 

  def map({_tag, attrs, items}, module) do
    {module_items, text_items} = Enum.split_with(items, &is_tuple/1)

    struct_map = %{}
    |> Map.merge(map_attributes(attrs, module.attributes))
    |> Map.merge(map_items(module_items, module.items))
    |> Map.merge(map_text(text_items, module.text))
    |> module.refine.()
    
    struct(module, struct_map)
  end
  
  ## Internals

  # Attribute mapping
  defp map_attribute({_name, value}, {keyword, value_map_func}) do
    {keyword, value_map_func.(to_string(value))}
  end

  defp map_attribute({_name, value}, keyword) do
    {keyword, to_string(value)}
  end

  defp map_attributes(_attrs, nil), do: %{}

  defp map_attributes(attrs, attrs_mapping) do
    attrs
    |> Enum.filter(fn ({name, _value}) -> 
      Map.has_key?(attrs_mapping, name)
    end)
    |> Enum.map(fn ({name, value}) -> 
      map_attribute({name, value}, attrs_mapping[name])
    end)
    |> Enum.into(%{})
  end

  # Item mapping
  defp item_defaults_map(item_mapping) do
    item_mapping
    |> Enum.map(fn ({_tag, {key, module_mapping}}) -> 
      case is_list(module_mapping) do
        true -> {key, []}
        false -> {key, nil}
      end
    end)
    |> Enum.into(%{})
  end

  defp map_item_group([item], module) when is_atom(module) do
    map(item, module)
  end

  defp map_item_group([item, _], module) when is_atom(module) do
    raise RuntimeError, message: "Item #{inspect item} has single mapping to #{module}, but multiple items found"
  end

  defp map_item_group(item_group, [module]) do
    item_group |> Enum.map(fn item -> map(item, module) end)
  end

  defp map_items(_items, nil), do: %{}

  defp map_items(items, item_mapping) do
    default_map = item_defaults_map(item_mapping)
    item_map = items
    |> Enum.group_by(fn {tag, _, _} -> tag end)
    |> Enum.filter(fn ({tag, _}) -> 
      Map.has_key?(item_mapping, tag)
    end)
    |> Enum.reduce(%{}, fn ({tag, item_group}, acc) ->
      {key, module} = item_mapping[tag]
      Map.put(acc, key, map_item_group(item_group, module))
    end)
    Map.merge(default_map, item_map)
  end

  # Text mapping
  defp map_text(_items, nil), do: %{}
  
  defp map_text(items, key) when is_atom(key) do
    map_text(items, {key, fn x -> x end})
  end

  defp map_text(items, {keyword, text_map_func}) do
    text = items
    |> Enum.filter(fn item -> is_list(item) end)
    |> Enum.map(fn text -> to_string(text) end)
    |> text_map_func.()
    %{keyword => text}
  end
end