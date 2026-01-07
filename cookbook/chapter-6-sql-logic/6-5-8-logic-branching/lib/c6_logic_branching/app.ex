
defmodule C6LogicBranching.Application do
  use Shared.App.Runner, port: 4418

  init_sql """
    CREATE TABLE IF NOT EXISTS applications (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      score INTEGER,
      status TEXT
    );
  """
end

defmodule C6LogicBranching.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/applications" do
    DB.list(:applications, order: "id DESC")
  end

  post "/applications", args: [name: :string, score: :int] do
    validate name != "", "name required"
    id = DB.create(:applications, %{name: name, score: score, status: "pending"})
    %{id: id, name: name, score: score, status: "pending"}
  end

  post "/applications/:id/decide", args: [id: :int] do
    transaction(fn ->
      app = DB.get!(:applications, id)
      status = cond do
        app.score >= 80 -> "approved"
        app.score >= 50 -> "manual_review"
        true -> "declined"
      end
      DB.update!(:applications, id, status: status)
      ok %{status: status}
    end)
  end
end