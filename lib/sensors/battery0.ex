defmodule AwesomeDash.Sensor.BatteryZero do
  use GenServer

  alias Scenic.Sensor

  @name :battery0
  @version "0.1.0"
  @description "Simulated battery sensor"

  @timer_ms 10000

  defmodule State do
    defstruct t: nil,
              timer: nil,
              data: %{state: nil, percent: nil, time: nil, wear: nil, current_power: nil}
  end

  @battery "BAT0"
  @battery_path "/sys/class/power_supply/"
  @charge_full "charge_full"
  @charge_full_design "charge_full_design"
  @charge_now "charge_now"
  @current_now "current_now"
  @energy_full "energy_full"
  @energy_full_design "energy_full_design"
  @energy_now "energy_now"
  @power_now "power_now"
  @present "present"
  @int_default 0
  @float_default 0.0
  @string_default "Unkown"

  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: @name)

  def init(_) do
    Sensor.register(@name, @version, @description)

    {:ok, timer} = :timer.send_interval(@timer_ms, :tick)

    {:ok, %State{t: 0, timer: timer}}
  end

  def handle_info(:tick, %{data: stale_data, t: t} = state) do
    fresh_data = battery_data()

    if fresh_data != stale_data do
      Sensor.publish(@name, fresh_data)
      {:noreply, %{state | data: fresh_data, t: t + 1}}
    else
      {:noreply, %{state | t: t + 1}}
    end
  end

  defp battery_data() do
    with 1 <- read_int_value(@present),
         state <- read_string_value(@state),
         percent <- battery_percent(),
         {:ok, time} <- time_till(),
         {:ok, wear} <- battery_wear(),
         {:ok, current_power} <- battery_power() do
      {state, percent, time, wear, curpower}
    end
  end

    # current_power is if battery.power_now / 1_000_000 or N/A
    # state is battery.state or Unkown
    # if battery.charge_now
    #   remaining is battery.charge_now
    #   capacity is battery.charge_full
    #   capacity_design is battery.charge_full_design or capacity
    # elseif battery.energy_now  MINE
    #   remaining is battery.energy_now
    #   capacity is battery.energy_full
    #   capacity_design is battery.energy_full_design or capacity
    #
    # rate is battery.current_now or battery.power_now
    #
    # calc remaining charge or discharge time
    #
    # Integer.parse or Float.parse everything except state

  defp read_int_value(filename) do
    read_value(filename, &Integer.parse/1, @int_default)
  end

  defp read_float_value(filename) do
    read_value(filename, &Float.parse/1, @float_default)
  end

  defp read_string_value(filename) do
    read_value(filename, fn s -> String.trim(s, "\n") end, @string_default)
  end

  defp read_value(filename, parse, default) do
    with {:ok, value} <- File.read([@battery_path, @battery, filename]),
         {parsed_value, _} <- parse.(value) do
      parsed_value
    else
      :error -> default
    end
  end

  defp battery_state() do
  end

  defp capacity_data() do
    if File.exists?([@battery_path, @battery, @current_now]) do
    end
  end
end
