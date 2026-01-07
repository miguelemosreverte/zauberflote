
defmodule C4Jobs.Application do
  use Shared.App.Runner, port: 4205

  init_sql """
    CREATE TABLE IF NOT EXISTS jobs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      input TEXT NOT NULL,
      status TEXT NOT NULL,
      result TEXT,
      created_at INTEGER,
      updated_at INTEGER
    );
  """
end

defmodule C4Jobs.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  resource "/jobs" do
    get do
      DB.list(:jobs, order: "id DESC", limit: 10)
    end

    get "/:id", args: [id: :int] do
      DB.get!(:jobs, id)
    end

    post args: [input: :string] do
      validate input != "", "input required"
      now = System.system_time(:second)
      
      job_id = DB.create(:jobs, %{input: input, status: "queued", created_at: now, updated_at: now})
      
      Task.start(fn ->
        Process.sleep(2000)
        res = String.reverse(input)
        Shared.DB.with_db(fn db ->
          Shared.DB.exec(db, "UPDATE jobs SET status = ?, result = ?, updated_at = ? WHERE id = ?", ["done", res, System.system_time(:second), job_id])
        end)
      end)
      
      ok %{id: job_id, status: "queued"}
    end
  end
end