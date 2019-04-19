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

  @int_default 0
  @float_default 0.0
  @string_default "Unkown"

  @nl "\n"

  # do we trap exits from tasks and then return defaults on failure

  def fetch(battery) when battery in @batteries do
    with 1 <- battery_present(battery) do
      capacity_task = Task.async(fn -> capacity_data(battery) end)
      power_task = Task.async(fn -> battery_power(battery) end)
      state_task = Task.async(fn -> state_data(battery) end)

      state = Task.await(state_task)
      current_power = Task.await(power_task)
      {percent, time, wear} = Task.await(capacity_task)

      {state, percent, time, wear, current_power}
    end
  end

  defp battery_present(battery) do
    Data.read_value([@power_path, battery], @present, &Integer.parse/1, @int_default)

    defp battery_state(battery) do
      Data.read_value(
        [@power_path, battery],
        @state,
        fn s -> String.trim(s, @nl) end,
        @string_default
      )
    end

    defp battery_power(battery) do
      Data.read_value([@power_path, battery], @power_now, &Integer.parse/1, @int_default) /
        1_000_000
    end

    defp capacity_data(battery) do
      {remaining, capacity, capacity_design} =
        battery
        |> charge_or_energy()
        |> capacity_data_for()

      {percent, time, wear}
    end

    defp capacity_calculations({remaining, capacity, capacity_design})
         when capacity > 0 and capacity_design > 0 do
      percent_task =
        Task.async(fn ->
          min(floor(remaining / capacity * 100), 100)
        end)

      wear_task =
        Task.async(fn ->
          math.floor(100 - capacity / capacity_design * 100)
        end)

      {Task.await(percent_task), Task.await(time_task), Task.await(wear_task)}
    end

    #
    # rate is battery.current_now or battery.power_now
    #
    # calc remaining charge or discharge time

    defp capacity_data_for(prefix, battery) do
      remaining_task =
        Task.async(fn ->
          Data.read_value([@power_path, battery], [prefix, @now], &Integer.parse/1, @int_default)
        end)

      capacity_task =
        Task.async(fn ->
          Data.read_value([@power_path, battery], [prefix, @full], &Integer.parse/1, @int_default)
        end)

      design_task =
        Task.async(fn ->
          case Data.read_value(
                 [@power_path, battery],
                 [prefix, @full_design],
                 &Integer.parse/1,
                 @int_default
               ) do
            0 ->
              Data.read_value(
                [@power_path, battery],
                [prefix, @full],
                &Integer.parse/1,
                @int_default
              )

            value ->
              value
          end
        end)

      {Task.await(remaining_task), Task.await(capacity_task), Task.await(design_task)}
    end

    defp charge_or_energy(battery) do
      if Data.exists?([@power_path, battery], [@charge_, @now]),
        do: @charge_,
        else: if(Data.exists?([@power_path, battery], [@energy_, @now]), do: @energy_)
    end
  end
end
