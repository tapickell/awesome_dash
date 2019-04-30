defmodule AwesomeDash.NetworkData do
  alias AwesomeDash.Data

  # cat / proc / net / dev | tail(-n(2 | awk('{ print $1 " :: " $2 }')))
  # basically call this to get $2 from each device that is valid (not lo)
  # then store that state with a timestamp, then call again and
  # calculate the speed from the difference in data by the time difference

  @network_path "/proc/net/dev"

  def fetch(nic) do
    time = :os.system_time()
    %{up: up, down: down, time: time}
  end
end
