defmodule AwesomeDash.Component.Battery do
  use Scenic.Component

  alias Scenic.Graph
  alias Scenic.ViewPort
  alias Scenic.Sensor

  require Logger

  import Scenic.Primitives

  @moduledoc """
  Add a simple Battery info display

  ## Data

  `label`

  * `label` - a bitstring describing the text to show above the value readout

  `options[:sensor]`

  * `:sensor` - the sensor to subscribe to and receive data from

  ### Example

    graph
    |> battery("Battery0", sensor: :battery0)
    |> battery("Battery1", sensor: :battery1)
  """

  @font_size 16

  @spc " "
  @div ":"
  @empty_time "00:00"
  @neg "-"
  @percent_sign "%"
  @watt "watts"
  @time_label "time left"
  @missing "N/A"
  @battery_state %{
    "Full" => "↯",
    "Unknown" => "⌁",
    "Charged" => "↯",
    "Charging" => "+",
    "Discharging" => "-"
  }

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
    Logger.info("Battery init called with sensor: #{sensor}")

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

  # this is a simple way to do this
  # if we want to color parts separately then we need different
  # text primitives for each and to translate each horizontally by the
  # index of previous text + length of the previous text
  def handle_info(
        {:sensor, :data, {sensor, data, _}},
        %{graph: graph, label: label, sensor: sensor, translate: translate} = state
      ) do
    Logger.info("handle info for #{sensor} sensor called: #{inspect(data)}")

    {status, percent, time, wear, current_power} = format_data(data)

    new_graph =
      graph
      |> Graph.modify(
        :all,
        &text(
          &1,
          IO.iodata_to_binary([
            label,
            @div,
            @spc,
            status,
            @spc,
            percent,
            @spc,
            time,
            @spc,
            wear,
            @spc,
            current_power,
            @spc
          ])
        )
      )
      |> Graph.modify(:all, &update_opts(&1, translate: translate))

    {:noreply, %{state | graph: new_graph}, push: new_graph}
  end

  def handle_info({:sensor, :registered, {sensor, _v, _d}}, %{sensor: sensor} = s) do
    Logger.info("#{sensor} Sensor Registered")

    {:noreply, s}
  end

  def handle_info({:sensor, :unregistered, sensor}, %{sensor: sensor} = s) do
    Logger.warn("#{sensor} Sensor Unregistered")

    {:noreply, s}
  end

  defp format_data({status, percent, time, wear, current_power}) do
    {
      Map.get(@battery_state, status, @missing),
      [Integer.to_string(percent), @percent_sign],
      time_format(time),
      [Integer.to_string(wear), @percent_sign],
      [Float.to_string(current_power), @spc, @watt]
    }
  end

  defp time_format(0), do: @empty_time

  defp time_format(time) do
    hours = floor(time)
    minutes = floor((time - hours) * 60)

    [
      Integer.to_string(hours),
      @div,
      Integer.to_string(minutes),
      @spc,
      @time_label
    ]
  end
end
