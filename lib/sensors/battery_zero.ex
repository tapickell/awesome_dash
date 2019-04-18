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
    with 1 <- read_int_value(@present) do
      state_task = Task.async(fn -> read_string_value(@state) end)
      capacity_task = Task.async(fn -> capacity_data() end)
      power_task = Task.async(fn -> battery_power() end)

      state = Task.await(state_task)
      current_power = Task.await(power_task)
      {percent, time, wear} = Task.await(capacity_task)

      {state, percent, time, wear, current_power}
    end
  end

  defp battery_power() do
    read_int_value(@power_now) / 1_000_000
  end

  defp capacity_data() do
    {remaining, capacity, capacity_design} = charge_or_energy()
    |> capacity_data_for()

    {percent, time, wear}
  end

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

  defp capacity_data_for(prefix) do
    remaining_task = Task.async(fn -> read_int_value([prefix, @now]) end)
    capacity_task = Task.async(fn -> read_int_value([prefix, @full]) end)

    design_task =
      Task.async(fn ->
        case read_int_value([prefix, @full_design]) do
          0 ->
            read_int_value([prefix, @full])

          value ->
            value
        end
      end)

    {Task.await(remaining_task), Task.await(capacity_task), Task.await(design_task)}
  end

  defp charge_or_energy() do
    if exists?(@charge_now),
      do: @charge,
      else: if(exists?(@energy_now), do: @energy)
  end

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
    with file_path <- file_path(filename),
         {:ok, value} <- File.read(file_path),
         {parsed_value, _} <- parse.(value) do
      parsed_value
    else
      :error -> default
    end
  end

  defp exists?(filename) do
    filename
    |> file_path()
    |> File.exists?()
  end

  defp file_path(filename) do
    List.flatten([@battery_path, @battery, filename])
  end
end
