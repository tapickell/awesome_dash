defmodule AwesomeDash.Sensor.BatteryZero do
  use GenServer

  alias Scenic.Sensor

  @name :battery0
  @version "0.1.0"
  @description "Simulated battery sensor"

  @timer_ms 400
  @initial_temp 295.372
  @amplitude 1.5
  @frequency 0.001
  @tau :math.pi() * 2

  @initial_battery {"Charging", 70, 97, 100, 42, 1234560}
  @battery_path "/sys/class/power_supply/"

  # --------------------------------------------------------
  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: @name)

  # --------------------------------------------------------
  def init(_) do
    # register this sensor
    Sensor.register(:battery0, @version, @description)

    # data {state, remaining, capacity, capacity_design, rate, current_power}
    Sensor.publish(:battery0, @initial_battery)

    # start the timer so that it simulates a changing temperature
    # {:ok, timer} = :timer.send_interval(@timer_ms, :tick)

    {:ok, %{battery: @initial_battery, t: 0}}
  end

  # --------------------------------------------------------
  # in a real sensor you would use a timer like this to read from a real device.
  # this one just fakes it with a sine wave
  def handle_info(:tick, %{battery: bat0} = state) do
    # Sensor.publish(:battery0, @initial_battery)
    # check old state sent against new state
    # only trigger if a difference

    {:noreply, state}
  end
end
