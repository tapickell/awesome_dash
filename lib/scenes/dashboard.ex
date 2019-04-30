defmodule AwesomeDash.Scene.Dashboard do
  use Scenic.Scene

  alias Scenic.Graph
  alias Scenic.ViewPort
  alias Scenic.Sensor

  require Logger

  import Scenic.Primitives
  import AwesomeDash.Components

  @body_offset 80
  @font_size 16

  def init(_, opts) do
    Logger.info("init on dashboard scene")

    {:ok, %ViewPort.Status{size: {vp_width, _}}} =
      opts[:viewport]
      |> ViewPort.info()

    graph =
      Graph.build(font: :roboto, font_size: 16)
      |> group(
        fn graph ->
          graph
          |> battery("BAT0", sensor: :battery0)
          |> battery("BAT1", sensor: :battery1, translate: {0, @font_size + @font_size / 2})
        end,
        translate: {vp_width / 2, @body_offset}
      )

    {:ok, graph, push: graph}
  end
end
