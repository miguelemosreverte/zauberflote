
defmodule C6LogicSimple.Application do
  use Shared.App.Runner, port: 4411

  init_sql """
    CREATE TABLE IF NOT EXISTS tickets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      status TEXT
    );
  """
end

defmodule C6LogicSimple.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/tickets" do
    DB.list(:tickets, order: "id DESC")
  end

  post "/tickets", args: [title: :string] do
    validate title != "", "title required"
    DB.create(:tickets, %{title: title, status: "open"})
    ok()
  end

  post "/tickets/:id/close", args: [id: :int] do
    transaction(fn ->
      ticket = DB.get!(:tickets, id)
      validate ticket.status != "closed", "already closed"
      
      DB.update!(:tickets, id, status: "closed")
      ok()
    end)
  end
end