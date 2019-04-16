# a simple supervisor that starts up the Scenic.SensorPubSub server
# and any set of other sensor processes

defmodule AwesomeDash.Sensor.Supervisor do
  use Supervisor

  alias AwesomeDash.Sensor.BatteryZero

  def start_link(_) do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      Scenic.Sensor,
      BatteryZero
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
