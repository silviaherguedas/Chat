defmodule Chat.Utils do
  @spec transform_test_to_atom(binary) :: atom
  def transform_test_to_atom(name) when is_binary(name) do
    name
    |> String.replace(" ", "_")
    |> String.to_atom()
  end
  
  def transform_test_to_atom(name),do: name
end
