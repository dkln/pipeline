defmodule PipelineTest do
  use ExUnit.Case

  defmodule TestPipeline do
    use Pipeline

    attributes(order_reference: nil, products: [], line_items: [])

    step :retrieve_products do
      {:ok, %{products: ["Apple", "Pear", "Pineapple"]}}
    end

    step :retrieve_products, [error] do
      {:error, error}
    end

    step :set_order_reference, [reference] do
      {:ok, %{order_reference: reference}}
    end

    step :set_order_reference_with_check, [reference] do
      if is_binary(reference) do
        {:ok, %{order_reference: reference}}
      else
        {:error, :invalid_format}
      end
    end

    step :set_order_reference_without_error, [reference], skip_error: true do
      if is_binary(reference) do
        {:ok, %{order_reference: reference}}
      else
        {:error, :invalid_format}
      end
    end
  end

  test "attributes" do
    assert %TestPipeline{} = pipeline = TestPipeline.new()
    assert pipeline.__pipeline__ == true
    assert pipeline.line_items == []
    assert pipeline.completed_steps == []
    assert pipeline.error == nil
    assert pipeline.last_step == nil
    assert pipeline.order_reference == nil
    assert pipeline.products == []
    assert pipeline.warnings == []
  end

  describe "step" do
    test "retrieve_products" do
      pipeline = TestPipeline.new()
      assert pipeline.completed_steps == []
      assert pipeline.last_step == nil
      assert pipeline.products == []
      assert pipeline.error == nil

      pipeline = TestPipeline.retrieve_products(pipeline)
      assert pipeline.last_step == :retrieve_products
      assert pipeline.completed_steps == [:retrieve_products]
      assert pipeline.products == ["Apple", "Pear", "Pineapple"]
      assert pipeline.error == nil
    end

    test "set_order_reference" do
      pipeline = TestPipeline.new()
      assert pipeline.completed_steps == []
      assert pipeline.last_step == nil
      assert pipeline.products == []
      assert pipeline.error == nil

      pipeline = TestPipeline.set_order_reference(pipeline, "ORDER123")
      assert pipeline.last_step == :set_order_reference
      assert pipeline.completed_steps == [:set_order_reference]
      assert pipeline.order_reference == "ORDER123"
      assert pipeline.error == nil
    end

    test "set_order_reference with error" do
      pipeline = TestPipeline.new()
      assert pipeline.completed_steps == []
      assert pipeline.last_step == nil
      assert pipeline.products == []
      assert pipeline.error == nil

      pipeline = TestPipeline.set_order_reference_with_check(pipeline, nil)
      assert pipeline.last_step == :set_order_reference_with_check
      assert pipeline.completed_steps == []
      assert pipeline.order_reference == nil
      assert pipeline.error == :invalid_format
    end

    test "set_order_reference with ok and error" do
      pipeline = TestPipeline.new()
      assert pipeline.completed_steps == []
      assert pipeline.last_step == nil
      assert pipeline.products == []
      assert pipeline.error == nil

      pipeline = TestPipeline.set_order_reference_with_check(pipeline, "ORDER456")
      assert pipeline.last_step == :set_order_reference_with_check
      assert pipeline.completed_steps == [:set_order_reference_with_check]
      assert pipeline.order_reference == "ORDER456"
      assert pipeline.error == nil

      pipeline = TestPipeline.set_order_reference_with_check(pipeline, nil)
      assert pipeline.last_step == :set_order_reference_with_check
      assert pipeline.completed_steps == [:set_order_reference_with_check]
      assert pipeline.order_reference == "ORDER456"
      assert pipeline.error == :invalid_format
    end

    test "set_order_reference_without_error with ok" do
      pipeline = TestPipeline.new()
      assert pipeline.completed_steps == []
      assert pipeline.last_step == nil
      assert pipeline.products == []
      assert pipeline.error == nil

      pipeline = TestPipeline.retrieve_products(pipeline)
      assert pipeline.last_step == :retrieve_products
      assert pipeline.completed_steps == [:retrieve_products]
      assert pipeline.order_reference == nil
      assert pipeline.error == nil

      pipeline = TestPipeline.set_order_reference_without_error(pipeline, "ORDER456")
      assert pipeline.last_step == :set_order_reference_without_error
      assert pipeline.completed_steps == [:set_order_reference_without_error, :retrieve_products]
      assert pipeline.order_reference == "ORDER456"
      assert pipeline.error == nil
    end

    test "set_order_reference_without_error with error" do
      pipeline = TestPipeline.new()
      assert pipeline.completed_steps == []
      assert pipeline.last_step == nil
      assert pipeline.products == []
      assert pipeline.error == nil

      pipeline = TestPipeline.retrieve_products(pipeline, "internal_server_error")
      assert pipeline.last_step == :retrieve_products
      assert pipeline.completed_steps == []
      assert pipeline.order_reference == nil
      assert pipeline.error == "internal_server_error"

      pipeline = TestPipeline.set_order_reference_without_error(pipeline, "ORDER456")
      assert pipeline.last_step == :retrieve_products
      assert pipeline.completed_steps == []
      assert pipeline.order_reference == nil
      assert pipeline.error == "internal_server_error"
    end
  end
end
