defmodule Express.Helpers.MapHelper do
  @moduledoc "Helper functions for a Map module."

  @spec reduce_keys(map(), fun()) :: map()
  def reduce_keys(map, fun) when is_map(map) and is_function(fun) do
    Enum.reduce(map, %{}, fn({k, v}, new_map) ->
      key = fun.(k)
      Map.put(new_map, key, v)
    end)
  end
  def reduce_keys(map, _), do: map

  @spec deep_reduce_keys(map(), fun()) :: map()
  def deep_reduce_keys(map, fun) when is_map(map) and is_function(fun) do
    Enum.reduce(map, %{}, fn({k, v}, new_map) ->
      key = fun.(k)

      if is_map(v) do
        Map.put(new_map, key, deep_reduce_keys(v, fun))
      else
        Map.put(new_map, key, v)
      end
    end)
  end
  def deep_reduce_keys(map, _), do: map

  @spec stringify_keys(map()) :: map()
  def stringify_keys(map) when is_map(map) do
    reduce_keys(map, fn(k)->
      if is_atom(k), do: Atom.to_string(k), else: k
    end)
  end
  def stringify_keys(map), do: map

  @spec deep_stringify_keys(map()) :: map()
  def deep_stringify_keys(map) when is_map(map) do
    deep_reduce_keys(map, fn(k) ->
      if is_atom(k), do: Atom.to_string(k), else: k
    end)
  end
  def deep_stringify_keys(map), do: map

  @spec dasherize_keys(map()) :: map()
  def dasherize_keys(map) when is_map(map) do
    reduce_keys(map, fn(k) ->
      k = if is_atom(k), do: Atom.to_string(k), else: k
      String.replace(k, "_", "-")
    end)
  end
  def dasherize_keys(map), do: map

  @spec deep_dasherize_keys(map()) :: map()
  def deep_dasherize_keys(map) when is_map(map) do
    deep_reduce_keys(map, fn(k) ->
      k = if is_atom(k), do: Atom.to_string(k), else: k
      String.replace(k, "_", "-")
    end)
  end
  def deep_dasherize_keys(map), do: map

  @spec underscorize_keys(map()) :: map()
  def underscorize_keys(map) when is_map(map) do
    reduce_keys(map, fn(k) ->
      k = if is_atom(k), do: Atom.to_string(k), else: k
      String.replace(k, "-", "_")
    end)
  end
  def underscorize_keys(map), do: map

  @spec deep_underscorize_keys(map()) :: map()
  def deep_underscorize_keys(map) when is_map(map) do
    deep_reduce_keys(map, fn(k) ->
      k = if is_atom(k), do: Atom.to_string(k), else: k
      String.replace(k, "-", "_")
    end)
  end
  def deep_underscorize_keys(map), do: map
end
