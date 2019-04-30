defmodule AwesomeDash.NetworkData do
  alias AwesomeDash.Data

  @network_path "/proc/net/dev"

  defmodule State do
    defstruct time: nil, up: 0, down: 0
  end

  def fetch(nic) do
    %{Map.merge(%State{}, fetch_bytes()) | time: :os.system_time()}
  end

  defp fetch_data() do
    File.stream!("/proc/net/dev")
    |> Stream.filter(fn(l) -> String.starts_with?(l, "wlp3s0") end)
    |> Stream.flat_map(fn(l) -> String.split(l) end)
    |> Stream.drop(1)
    |> Stream.reject(fn(e) -> e == "0" end)
    |> Stream.map(&String.to_integer/1)
    |> Enum.to_list()
  end

  defp fetch_bytes() do
    [up_bytes, _up_packets, down_bytes, _down_packets] = fetch_data()
    %{up: up_bytes, down: down_bytes}
  end

  defp fetch_packets() do
    [_up_bytes, up_packets, _down_bytes, down_packets] = fetch_data()
    %{up: up_packets, down: down_packets}
  end
end
