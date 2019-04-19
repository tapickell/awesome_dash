defmodule AwesomeDash.Scene.Dashboard do
  use Scenic.Scene

  alias Scenic.Graph
  alias Scenic.ViewPort
  alias Scenic.Sensor

  import Scenic.Primitives

  @body_offset 80
  @font_size 16

  @label "BAT0"
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

  def init(_, opts) do
    {:ok, %ViewPort.Status{size: {vp_width, _}}} =
      opts[:viewport]
      |> ViewPort.info()

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

    graph =
      graph
      |> Graph.modify(
        :all,
        &text(
          &1,
          IO.iodata_to_binary([
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
            @spc
          ])
        )
      )

    {:noreply, graph, push: graph}
  end

  def handle_info({:sensor, :registered, {:battery0, _v, _d}}, graph) do
    IO.puts("BAT0 Sensor Registered")

    {:noreply, graph}
  end

  def handle_info({:sensor, :unregistered, :battery0}, graph) do
    IO.puts("BAT0 Sensor Unregistered")

    {:noreply, graph}
  end

  defp format_data({state, percent, time, wear, current_power}) do
    {
      Map.get(@battery_state, state, @missing),
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
