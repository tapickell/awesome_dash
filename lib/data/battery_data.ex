defmodule AwesomeDash.BatteryData do
  alias AwesomeDash.Data

  @power_path "/sys/class/power_supply/"
  @batteries ["BAT0", "BAT1"]

  @charge_ "charge_"
  @energy_ "energy_"
  @now "now"
  @full "full"
  @full_design "full_design"
  @current_now "current_now"
  @power_now "power_now"
  @present "present"
  @status "status"

  @int_default 0
  @float_default 0.0
  @string_default "Unknown"
  @chargning "Charging"
  @dischargning "Discharging"

  @nl "\n"

  @docnotes """
   TODO - do we trap exits from tasks and then return defaults on failure

   It would be nice to only check some of the file exists?
   calls on initial run then store that state and check that
   instead of always seeing if the files exists?
   these checks are OS specific and your OS is not going to
   change which file it writes the data to during runtime
   the only weirdness is when a new battery is added w/out reboot
   then some of the files are not written too.
   this may be a small edge case I believe as the device would have to have
   power bridge and also internal and external batteries
   my X240 does and I saw this bug using Vicious battery widget
   when I added a new battery while the system was running of
   the internal battery. It could not get a value from one of
   the files that was not checked before reading from
   that lib assumes that the file will always exist
   after fully charging the new battery and then rebooting the system
   that file then was existing and the widget / and desktop worked again
  """

  def fetch(battery) when battery in @batteries do
    with 1 <- battery_present(battery) do
      capacity_task = Task.async(fn -> capacity_data(battery) end)
      power_task = Task.async(fn -> battery_power(battery) end)
      state_task = Task.async(fn -> battery_state(battery) end)

      state = Task.await(state_task)
      current_power = Task.await(power_task)
      {percent, time, wear} = Task.await(capacity_task)

      {state, percent, time, wear, current_power}
    end
  end

  defp battery_present(battery) do
    read_int(battery, @present)
  end

  defp battery_state(battery) do
    read_value(
      battery,
      @status,
      fn s -> String.trim(s, @nl) |> IO.inspect(label: "status") end,
      @string_default
    )
  end

  defp battery_power(battery) do
    Float.floor(read_float(battery, @power_now) / 1_000_000, 2)
  end

  defp capacity_data(battery) do
    # {remaining, capacity, capacity_design, rate}
    {percent, time, wear} =
      battery
      |> charge_or_energy()
      |> capacity_data_for(battery)
      |> capacity_calculations(battery)

    {percent, time, wear}
  end

  defp percent_task(remaining, capacity) when capacity > 0 do
    Task.async(fn ->
      min(floor(remaining / capacity * 100), 100)
    end)
  end

  defp percent_task(_, _), do: Task.async(no_op())

  defp wear_task(capacity, capacity_design) when capacity_design > 0 do
    Task.async(fn ->
      floor(100 - capacity / capacity_design * 100)
    end)
  end

  defp wear_task(_, _), do: Task.async(no_op())

  defp time_task(remaining, capacity, rate, battery) when rate > 0 do
    Task.async(fn ->
      case battery_state(battery) do
        @chargning ->
          (capacity - remaining) / rate

        @dischargning ->
          remaining / rate

        _ ->
          0
      end
    end)
  end

  defp time_task(_, _, _, _), do: Task.async(no_op())

  defp no_op() do
    fn -> 0 end
  end

  defp capacity_calculations({remaining, capacity, capacity_design, rate}, battery) do
    percent_task = percent_task(remaining, capacity)
    wear_task = wear_task(capacity, capacity_design)
    time_task = time_task(remaining, capacity, rate, battery)

    {Task.await(percent_task), Task.await(time_task), Task.await(wear_task)}
  end

  defp capacity_data_for(prefix, battery) do
    remaining_task = Task.async(fn -> read_int(battery, [prefix, @now]) end)
    capacity_task = Task.async(fn -> read_int(battery, [prefix, @full]) end)

    design_task =
      Task.async(fn ->
        case read_int(battery, [prefix, @full_design]) do
          0 ->
            read_int(battery, [prefix, @full])

          value ->
            value
        end
      end)

    rate_task =
      Task.async(fn ->
        case read_int(battery, @current_now) do
          0 ->
            read_int(battery, @power_now)

          value ->
            value
        end
      end)

    {Task.await(remaining_task), Task.await(capacity_task), Task.await(design_task),
     Task.await(rate_task)}
  end

  defp read_int(battery, filename) do
    read_value(battery, filename, &Integer.parse/1, @int_default)
  end

  defp read_float(battery, filename) do
    read_value(battery, filename, &Float.parse/1, @float_default)
  end

  defp read_value(battery, filename, parse, default) do
    Data.read_value([@power_path, battery], filename, parse, default)
  end

  defp charge_or_energy(battery) do
    if Data.exists?([@power_path, battery], [@charge_, @now]),
      do: @charge_,
      else: if(Data.exists?([@power_path, battery], [@energy_, @now]), do: @energy_)
  end
end
