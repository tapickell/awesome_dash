defmodule AwesomeDash.Scene.Dashboard do
  use Scenic.Scene

  alias Scenic.Graph
  alias Scenic.ViewPort
  alias Scenic.Sensor

  import Scenic.Primitives
  import Scenic.Components

  @body_offset 80
  @font_size 16

  @label "BAT0"
  @spc " "
  @div ":"
  @neg "-"
  @percent_sign "%"
  @watt "watts"
  @time_label "time left"
  @missing "N/A"
  @battery_state %{
    "Full"        => "↯",
    "Unknown"     => "⌁",
    "Charged"     => "↯",
    "Charging"    => "+",
    "Discharging" => "-"
  }

  def init(_, opts) do
    {:ok, %ViewPort.Status{size: {vp_width, _}}} =
      opts[:viewport]
      |> ViewPort.info()

    col = vp_width / 6
    graph =
      Graph.build(font: :roboto, font_size: 16, theme: :dark)
      |> group(
        fn graph ->
          graph
          |> text(
            @spc,
            id: :all,
            text_align: :center,
            font_size: @font_size,
            translate: {vp_width / 2, @font_size}
          )
        end,
        translate: {0, @body_offset}
      )

    Sensor.subscribe(:battery0)

    {:ok, graph, push: graph}
  end

  # this is a simple way to do this
  # if we want to color parts separately then we need different
  # text primitives for each and to translate each horizontally by the
  # index of previous text + length of the previous text
  def handle_info({:sensor, :data, {:battery0, data, _}}, graph) do
    {state, percent, time, wear, current_power} = format_data(data)
    graph = graph
    |> Graph.modify(:all, &text(&1, IO.iodata_to_binary([
              @label,
              @div,
              @spc,
              state,
              @spc,
              percent,
              @spc,
              time,
              @spc,
              wear,
              @spc,
              current_power,
              @spc,
            ])))

    {:noreply, graph, push: graph}
  end

  @spec format_data({String.t(), integer(), integer(), integer(), integer(), integer()}) :: {String.t(), integer(), String.t(), integer(), integer()}
  defp format_data({state, remaining, capacity, capacity_design, rate, current_power}) do
    {
      Map.get(@battery_state, state, @missing),
      percentage(remaining, capacity),
      time_left(state, remaining, capacity, rate),
      wear(capacity, capacity_design),
      current_power(current_power)
    }
  end

  defp percentage(remaining, capacity) when capacity > 0 do
    [
      Integer.to_string(floor(remaining / capacity * 100)),
      @percent_sign
    ]
  end
  defp percentage(_, _), do: @missing

  defp time_left("Charging", remaining, capacity, rate) when rate > 0 do
    (capacity - remaining) / rate |> time_format()
  end
  defp time_left("Discharging", remaining, capacity, rate) when rate > 0 do
    remaining / rate |> time_format()
  end
  defp time_left(_, _, _, _), do: @missing

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

  defp wear(capacity, capacity_design) when capacity_design > 0 do
    wear = floor(100 - capacity / capacity_design * 100)
    [
      @neg,
      Integer.to_string(wear),
      @percent_sign
    ]
  end
  defp wear(_, _), do: @missing

  defp current_power(current_power) do
    power = Float.floor(current_power /1_000_000, 2)
    [
      Float.to_string(power),
      @spc,
      @watt
    ]
  end
  defp current_power(_), do: @missing

end
