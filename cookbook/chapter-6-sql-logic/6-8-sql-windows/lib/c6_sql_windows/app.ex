
defmodule C6SqlWindows.Application do
  use Shared.App.Runner, port: 4408

  init_sql """
    CREATE TABLE IF NOT EXISTS scores (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      team TEXT,
      member TEXT,
      score INTEGER
    );
  """
end

defmodule C6SqlWindows.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/rankings" do
    DB.all("SELECT team, member, score, RANK() OVER (PARTITION BY team ORDER BY score DESC) as rank FROM scores ORDER BY team, rank")
  end

  post "/scores", args: [team: :string, member: :string, score: :int] do
    validate team != "" and member != "", "team and member required"
    DB.create(:scores, %{team: team, member: member, score: score})
    ok()
  end
end