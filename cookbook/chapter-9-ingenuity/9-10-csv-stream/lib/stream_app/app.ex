defmodule StreamApp.Application do
  use Shared.App.Runner, port: 4910, children: [StreamApp.Seeder]

  init_sql """
    CREATE TABLE IF NOT EXISTS measurements (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sensor_id TEXT NOT NULL,
      reading REAL NOT NULL,
      ts DATETIME DEFAULT CURRENT_TIMESTAMP
    );
  """
end

defmodule StreamApp.Seeder do
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def init(_) do
    seed_data()
    {:ok, %{}}
  end

  defp seed_data do
    Shared.DB.with_db(fn db ->
      case Shared.DB.one(db, "SELECT COUNT(*) FROM measurements", []) do
        [0] ->
          Enum.each(1..1000, fn i ->
            Shared.DB.exec(db, "INSERT INTO measurements (sensor_id, reading) VALUES (?, ?)",
              ["S-#{rem(i, 5)}", :rand.uniform() * 100])
          end)
        _ ->
          :ok
      end
    end)
  end
end

defmodule StreamApp.Router do
  use Shared.App

  get "/", args: [] do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/stats", args: [] do
    %{total_records: DB.one("SELECT COUNT(*) as count FROM measurements")[:count]}
  end

  get "/export", args: [] do
    data = DB.all("SELECT id, sensor_id, reading, ts FROM measurements ORDER BY id ASC")
    headers = ["id", "sensor_id", "reading", "timestamp"]
    csv = [headers | Enum.map(data, fn row -> [row[:id], row[:sensor_id], row[:reading], row[:ts]] end)]
          |> Enum.map(&Enum.join(&1, ","))
          |> Enum.join("\n")

    conn
    |> put_resp_header("content-disposition", "attachment; filename=measurements.csv")
    |> put_resp_content_type("text/csv")
    |> send_resp(200, csv)
  end
end
