
defmodule C6LogicDependent.Application do
  use Shared.App.Runner, port: 4417

  init_sql """
    CREATE TABLE IF NOT EXISTS projects (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      status TEXT
    );
    CREATE TABLE IF NOT EXISTS tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      project_id INTEGER,
      name TEXT,
      done INTEGER
    );
  """
end

defmodule C6LogicDependent.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/projects" do
    DB.list(:projects, order: "id DESC")
  end

  post "/projects", args: [name: :string] do
    validate name != "", "name required"
    DB.create(:projects, %{name: name, status: "open"})
    ok()
  end

  get "/tasks" do
    DB.list(:tasks, order: "id DESC")
  end

  resource "/projects/:id" do
    post "/tasks", args: [id: :int, name: :string] do
      validate name != "", "name required"
      DB.create(:tasks, %{project_id: id, name: name, done: 0})
      ok()
    end

    post "/complete", args: [id: :int] do
      transaction(fn ->
        open_count = DB.count(:tasks, where: [project_id: id, done: 0])
        validate open_count == 0, "tasks still open"
        DB.update!(:projects, id, status: "complete")
        ok()
      end)
    end
  end

  post "/tasks/:id/complete", args: [id: :int] do
    DB.update!(:tasks, id, done: 1)
    ok()
  end
end