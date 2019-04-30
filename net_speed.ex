defmodule AwesomeDash.Component.NetSpeed do
  use Scenic.Component

  alias Scenic.Graph
  alias Scenic.ViewPort
  alias Scenic.Sensor

  require Logger

  import Scenic.Primitives

  @font_size 16
  @spc " "

  @graph Graph.build()
         |> group(fn g ->
           g
           |> text(
             @spc,
             id: :all,
             text_align: :center,
             font_size: @font_size
           )
         end)

  def info(data),
    do: """
    #{IO.ANSI.red()}#{__MODULE__} data must be a bitstring
    #{IO.ANSI.yellow()}Received: #{inspect(data)}
    #{IO.ANSI.default_color()}
    """

  def verify(label) when is_bitstring(label), do: {:ok, label}
  def verify(_), do: :invalid_data

  def init(label, options) do
    Logger.info("Options keys should contain :sensor #{inspect(options)}")
    opts = options[:styles]
    sensor = opts[:sensor]
    translate = Map.get(opts, :translate, {0, 0})
    Logger.info("NetSpeed init called with sensor: #{sensor}")

    if sensor do
      Logger.info("Battery Sensor.subscribe called with sensor: #{sensor}")
      Sensor.subscribe(sensor)
    end

    state = %{
      graph: @graph,
      label: label,
      sensor: sensor,
      translate: translate
    }

    {:ok, state, push: @graph}
  end
end
