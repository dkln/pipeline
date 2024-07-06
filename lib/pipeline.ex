defmodule Pipeline do
  @moduledoc """
  Module to formalize flow

  ## Examples

  ```elixir
  defmodule OrderFlow do
    use Pipeline

    attributes reference: nil,
      items: []
  end
  ```
  """

  alias WuunderUtils.Results

  defmacro __using__(_opts) do
    quote do
      import Pipeline, only: [attributes: 1, step: 2, step: 3, step: 4]
    end
  end

  @doc """
  Defines struct for Pipeline module
  """
  defmacro attributes(attrs) do
    default_struct_attrs = [
      __pipeline__: true,
      completed_steps: [],
      error: nil,
      last_step: nil,
      warnings: []
    ]

    struct_attrs = default_struct_attrs ++ attrs

    quote do
      Kernel.defstruct(unquote(struct_attrs))

      @type t() :: %__MODULE__{}

      @spec new() :: t()
      def new, do: %__MODULE__{}
    end
  end

  @doc """
  Defines a step
  """
  defmacro step(name, do: expression), do: define_step(name, [], [], expression)

  defmacro step(name, args, do: expression), do: define_step(name, args, [], expression)

  defmacro step(name, args, options, do: expression),
    do: define_step(name, args, options, expression)

  defp define_step(name, args, options, expression) do
    quote do
      def unquote(name)(pipeline, unquote_splicing(args)) do
        if pipeline.error && unquote(options[:skip_error]) do
          pipeline
        else
          result =
            (fn ->
               unquote(expression)
             end).()

          pipeline =
            if Results.all_ok?(result) do
              Map.merge(
                %__MODULE__{
                  pipeline
                  | completed_steps: [:"#{unquote(name)}" | pipeline.completed_steps]
                },
                Results.get_ok(result)
              )
            else
              %__MODULE__{pipeline | error: Results.get_error(result)}
            end

          %__MODULE__{pipeline | last_step: :"#{unquote(name)}"}
        end
      end
    end
  end
end
