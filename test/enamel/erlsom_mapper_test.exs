defmodule Enamel.ErlsomMapperTest do
  use ExUnit.Case
  doctest Enamel.ErlsomMapper

  alias Enamel.ErlsomMapper, as: ErlsomMapper
  alias Enamel.ErlsomMapperTest

  # Expected type is returned after mapping

  test "default mapping return struct of specificied module" do
    defmodule CustomItem do
      use Enamel.MappingInfo
      defstruct [ :key1 ]
    end

    mapping = parse_with_erslom('<item></item>')

    item = ErlsomMapper.map(mapping, CustomItem)

    # Have to do assertions like this because the module and test is in the same file
    assert item.__struct__ == ErlsomMapperTest.CustomItem
  end


  # Attribute mapping

  test "attributes are mapped to crresponding keys" do
    defmodule ItemWithTwoAttributes do
      use Enamel.MappingInfo
      defstruct [:attr1, :attr2]
      def attributes(), do: %{
        'attr1' => :attr1,
        'attr2' => :attr2
      }
    end

    mapping = parse_with_erslom('<item attr1="value1" attr2="value2" />')

    item = ErlsomMapper.map(mapping, ItemWithTwoAttributes)

    assert item.attr1 == "value1"
    assert item.attr2 == "value2"
  end

  test "no attributes mapped when no attribute mapping present" do
    defmodule ItemWithNoAttributeMapping do
      use Enamel.MappingInfo
      defstruct [:attr]
    end

    mapping = parse_with_erslom('<item attr="value" />')

    item = ErlsomMapper.map(mapping, ItemWithNoAttributeMapping)

    assert item.attr == nil
  end

  test "attributes are converted using provided functions " do
    defmodule ItemWithAttributeConversionFunctions do
      use Enamel.MappingInfo
      defstruct [:number]
      def attributes(), do: %{
        'number' => { :number, &String.to_integer/1 }
      }
    end

    mapping = parse_with_erslom('<item number="123"/>')

    item = ErlsomMapper.map(mapping, ItemWithAttributeConversionFunctions)

    assert item.number == 123
  end

  test "attributes default value is respected" do
    defmodule ItemWithDefaultAttributeValue do
      use Enamel.MappingInfo
      defstruct [number: -1 ]
      def attributes(), do: %{
        'number' => { :number, &String.to_integer/1 }
      }
    end

    mapping = parse_with_erslom('<item />')

    item = ErlsomMapper.map(mapping, ItemWithDefaultAttributeValue)

    assert item.number == -1
  end


  # Item mapping

  test "non-group items are mapped to crresponding keys and types" do
    defmodule ItemWithSubItems do
      use Enamel.MappingInfo
      defstruct [:subitem1, :subitem2]
      def items(), do: %{
        'subitem1' => { :subitem1, __MODULE__.SubItem1 },
        'subitem2' => { :subitem2, __MODULE__.SubItem2 }
      }
      defmodule SubItem1, do: (use Enamel.MappingInfo; defstruct [])
      defmodule SubItem2, do: (use Enamel.MappingInfo; defstruct [])
    end

    mapping = parse_with_erslom(
      '<item> <subitem1/> <subitem2/> </item>')

    item = ErlsomMapper.map(mapping, ItemWithSubItems)

    assert item.subitem1 == struct(ItemWithSubItems.SubItem1)
    assert item.subitem2 == struct(ItemWithSubItems.SubItem2)
  end

  test "error when a non-group mapping has multiple items" do
    defmodule ItemWithNonGroupItem do
      use Enamel.MappingInfo
      defstruct [:single_item]
      def items(), do: %{
        'single_item' => { :single_item, __MODULE__.SingleItem },
      }
      defmodule SingleItem, do: (use Enamel.MappingInfo; defstruct [])
    end

    mapping = parse_with_erslom(
      '<item> <single_item /> <single_item /> </item>')

    assert_raise RuntimeError, fn ->
      ErlsomMapper.map(mapping, ItemWithNonGroupItem)
    end
  end

  test "group items are mapped into arrays" do
    defmodule ItemWithGroupSubItems do
      use Enamel.MappingInfo
      defstruct [:subitem1, :subitem2]
      def items(), do: %{
        'subitem1' => { :subitem1, [__MODULE__.SubItem1] },
        'subitem2' => { :subitem2, [__MODULE__.SubItem2] }
      }
      defmodule SubItem1, do: (use Enamel.MappingInfo; defstruct [])
      defmodule SubItem2, do: (use Enamel.MappingInfo; defstruct [])
    end

    mapping = parse_with_erslom(
      '<item> <subitem1/> <subitem2/> <subitem2/> <subitem1/> <subitem1/> </item>')

    item = ErlsomMapper.map(mapping, ItemWithGroupSubItems)

    subitem1 = struct(ItemWithGroupSubItems.SubItem1)
    subitem2 = struct(ItemWithGroupSubItems.SubItem2)
    assert item.subitem1 == [subitem1, subitem1, subitem1]
    assert item.subitem2 == [subitem2, subitem2]
  end

  test "when no items present, single items are nil and group items are empty arrays" do
    defmodule ItemWithNoSubItems do
      use Enamel.MappingInfo
      defstruct [:subitem1, :subitem2]
      def items(), do: %{
        'subitem1' => { :subitem1, __MODULE__.SubItem1 },
        'subitem2' => { :subitem2, [__MODULE__.SubItem2] }
      }
      defmodule SubItem1, do: (use Enamel.MappingInfo; defstruct [])
      defmodule SubItem2, do: (use Enamel.MappingInfo; defstruct [])
    end

    mapping = parse_with_erslom('<item></item>')

    item = ErlsomMapper.map(mapping, ItemWithNoSubItems)

    assert item.subitem1 == nil
    assert item.subitem2 == []
  end


  # Text mapping

  test "text mapping returns text items as a list of string by default" do
    defmodule ItemWithMultipleTextItems do
      use Enamel.MappingInfo
      defstruct [ :text ]
      def text(), do: :text
    end

    mapping = parse_with_erslom(
      '<item>text1<a/>text2</item>')

    item = ErlsomMapper.map(mapping, ItemWithMultipleTextItems)

    assert item.text == ["text1", "text2"]
  end

  test "text mapping returns empty list if no text items are present" do
    defmodule ItemWithTextMappingButNoTextItems do
      use Enamel.MappingInfo
      defstruct [ :text ]
      def text(), do: :text
    end

    mapping = parse_with_erslom(
      '<item><a/></item>')

    item = ErlsomMapper.map(mapping, ItemWithTextMappingButNoTextItems)

    assert item.text == []
  end

  test "text mapping converts text items using provided mapping function" do
    defmodule ItemWithTextItemsContatenated do
      use Enamel.MappingInfo
      defstruct [ :text ]
      def text(), do: { :text, &Enum.join/1 }
    end

    mapping = parse_with_erslom(
      '<item>text1<a/>text2</item>')

    item = ErlsomMapper.map(mapping, ItemWithTextItemsContatenated)

    assert item.text == "text1text2"
  end

  test "text mapping uses text conversion function even if no text items" do
    defmodule ItemWithTextItemsContatenatedButNoTextItems do
      use Enamel.MappingInfo
      defstruct [ :text ]
      def text(), do: { :text, &Enum.join/1 }
    end

    mapping = parse_with_erslom(
      '<item><a /></item>')

    item = ErlsomMapper.map(mapping, ItemWithTextItemsContatenatedButNoTextItems)

    assert item.text == ""
  end

  test "text is default value if no text items" do
    defmodule ItemWithDefaultTextValue do
      use Enamel.MappingInfo
      defstruct [ text: "abc" ]
      def text(), do: { :text, &Enum.join/1 }
    end

    mapping = parse_with_erslom(
      '<item><a /></item>')

    item = ErlsomMapper.map(mapping, ItemWithDefaultTextValue)

    assert item.text == ""
  end


  # refine application
  test "item refine() is applied when provided" do
    defmodule Person do
      use Enamel.MappingInfo
      defstruct [:first_name, :last_name]
      def items(), do: %{
        'firstName' => { :_first_name, __MODULE__.Name },
        'lastName' => { :_last_name, __MODULE__.Name }
      }
      def refine() do
        fn (person) ->
          person
          |> Map.put(:first_name, person._first_name.value)
          |> Map.put(:last_name, person._last_name.value)
        end
      end

      defmodule Name do
        use Enamel.MappingInfo
        defstruct [:value]
        def attributes(), do: %{ 'value' => :value }
      end
    end

    mapping = parse_with_erslom(
      '<person> <firstName value="John"/> <lastName value="Smith"/> </person>')

    person = ErlsomMapper.map(mapping, Person)

    assert person.first_name == "John"
    assert person.last_name == "Smith"
  end

  defp parse_with_erslom(xml) do
    {:ok, xml_mapping, _} = :erlsom.simple_form(xml)
    xml_mapping
  end

end
