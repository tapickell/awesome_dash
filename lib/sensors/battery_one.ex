defmodule AwesomeDash.Sensor.BatteryOne do
  use GenServer

  require Logger

  alias Scenic.Sensor

  @name :battery1
  @version "0.1.0"
  @description "Battery sensor publishes data for BAT1"

  @timer_ms 10000

  defmodule State do
    defstruct t: nil,
              timer: nil,
              data: %{state: nil, percent: nil, time: nil, wear: nil, current_power: nil}
  end

  @battery "BAT1"

  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: @name)

  def init(_) do
    Sensor.register(@name, @version, @description)

    {:ok, timer} = :timer.send_interval(@timer_ms, :tick)

    {:ok, %State{t: 0, timer: timer}}
  end

  def handle_info(:tick, %{data: stale_data, t: t} = state) do
    fresh_data = AwesomeDash.BatteryData.fetch(@battery)

    Logger.info("BAT1 fresh_data")

    if fresh_data != stale_data do
      Sensor.publish(@name, fresh_data)
      {:noreply, %{state | data: fresh_data, t: t + 1}}
    else
      {:noreply, %{state | t: t + 1}}
    end
  end
end
