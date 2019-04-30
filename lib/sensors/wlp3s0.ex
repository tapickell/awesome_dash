defmodule AwesomeDash.Sensor.Wlp3s0 do
  use GenServer

  require Logger

  alias Scenic.Sensor

  @name :wlp3s0
  @version "0.1.0"
  @description "Wireless sensor publishes data for wlp3s0"

  @timer_ms 10000

  defmodule State do
    defstruct t: nil,
      timer: nil,
      data: %{time: nil, up: 0, down: 0}
  end

  @nic "wlp3s0"
  @spd "mb/s"

  def start_link(_), do: GenServer.start_link(__MODULE__, :ok, name: @name)

  def init(_) do
    Sensor.register(@name, @version, @description)

    {:continue, %State{t: 0}}
  end

  def handle_continue(:continue, state) do
    data = AwesomeDash.NetworkData.fetch(@nic)

    {:ok, timer} = :timer.send_interval(@timer_ms, :tick)

    {:noreply, %{ state | timer: timer, data: data }}
  end

  def handle_info(:tick, %{data: %{time: time, up: up, down: down} = stale_data, t: t} = state) do
    fresh_data = %{up: nup, down: ndown, time: ntime} = AwesomeDash.NetworkData.fetch(@nic)
    Logger.info("wlp3s0: fresh_data :: #{inspect(fresh_data)}")

    if fresh_data != stale_data do
      calc_speed = speed_formula(time, ntime)
      up_speed = calc_speed.(up, nup)
      down_speed = calc_speed.(down, ndown)

      Sensor.publish(@name, {up_speed, down_speed, @spd})

      {:noreply, %{state | data: fresh_data, t: t + 1}}
    else
      {:noreply, %{state | t: t + 1}}
    end
  end

  defp speed_formula(old_time, new_time) do
    time_diff = new_time - old_time
    fn (old, new) ->
      ((new - old) / time_diff) / :math.pow(1024, 2) |> round()
      |> IO.inspect(label: "calculate speed")
    end
  end
end
