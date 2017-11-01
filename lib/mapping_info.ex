defmodule Enamel.MappingInfo do
  
  @type struct_key :: atom()

  @type attribute_mapping :: struct_key() | { struct_key() | fun() }
  @type item_mapping      :: module() | [module()]

  @callback attributes() :: %{ charlist() => attribute_mapping }
  @callback items()      :: %{ charlist() => item_mapping }
  @callback text()       :: {atom} | { atom, fun() }
  @callback refine()             :: fun(%{ atom() => any }) :: any

  defmacro __using__(_) do
    quote do
      @behaviour Enamel.MappingInfo

      def attributes(), do: %{}
      def items()     , do: %{}
      def text()      , do: nil
      def refine()    , do: fn x -> x end

      defoverridable [attributes: 0, items: 0, text: 0, refine: 0]
    end
  end
end