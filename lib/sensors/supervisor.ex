# a simple supervisor that starts up the Scenic.SensorPubSub server
# and any set of other sensor processes

defmodule AwesomeDash.Sensor.Supervisor do
  use Supervisor

  alias AwesomeDash.Sensor.BatteryZero
  alias AwesomeDash.Sensor.BatteryOne
  alias AwesomeDash.Sensor.Wlp3s0

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      Scenic.Sensor,
      BatteryZero,
      BatteryOne,
      Wlp3s0
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
