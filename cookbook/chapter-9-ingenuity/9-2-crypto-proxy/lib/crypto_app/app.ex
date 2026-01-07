defmodule CryptoApp.Application do
  use Shared.App.Runner, port: 4902, children: [CryptoApp.Store, CryptoApp.Poller]
end

defmodule CryptoApp.Store do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{btc: 45000.0, eth: 2500.0, last_update: nil} end, name: __MODULE__)
  end

  def get_prices, do: Agent.get(__MODULE__, & &1)

  def update_prices(btc, eth) do
    Agent.update(__MODULE__, fn _ ->
      %{btc: Float.round(btc, 2), eth: Float.round(eth, 2), last_update: DateTime.utc_now() |> to_string()}
    end)
  end
end

defmodule CryptoApp.Poller do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    schedule_poll()
    {:ok, state}
  end

  def handle_info(:poll, state) do
    new_btc = 45000.0 + (:rand.uniform(1000) - 500)
    new_eth = 2500.0 + (:rand.uniform(100) - 50)
    CryptoApp.Store.update_prices(new_btc, new_eth)
    schedule_poll()
    {:noreply, state}
  end

  defp schedule_poll do
    Process.send_after(self(), :poll, 5000)
  end
end

defmodule CryptoApp.Router do
  use Shared.App

  resource "/prices" do
    get args: [] do
      CryptoApp.Store.get_prices()
    end
  end
end
