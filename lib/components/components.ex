defmodule AwesomeDash.Components do
  alias Scenic.Graph
  alias Scenic.Primitive
  alias Scenic.SceneRef

  require Logger

  def battery(graph, data, options \\ [])

  def battery(%Graph{} = g, data, options) do
    Logger.info("Battery add_to_graph helper called: #{inspect(options)}")
    add_to_graph(g, AwesomeDash.Component.Battery, data, options)
  end

  def net_speed(graph, data, options \\ [])

  def net_speed(%Graph{} = g, data, options) do
    Logger.info("NetSpeed add_to_graph helper called: #{inspect(options)}")
    add_to_graph(g, AwesomeDash.Component.NetSpeed, data, options)
  end

  defp add_to_graph(%Graph{} = g, mod, data, options) do
    Logger.info("Components add_to_graph helper called: #{inspect(options)}")
    mod.verify!(data)
    mod.add_to_graph(g, data, options)
  end
end
