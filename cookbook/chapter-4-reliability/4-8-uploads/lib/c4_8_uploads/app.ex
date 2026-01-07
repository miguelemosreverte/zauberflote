defmodule C4Uploads.Application do
  use Shared.App.Runner, port: 4208

  init_sql """
    CREATE TABLE IF NOT EXISTS uploads (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      filename TEXT NOT NULL,
      stored_path TEXT NOT NULL,
      size INTEGER NOT NULL,
      content_type TEXT NOT NULL,
      created_at INTEGER NOT NULL
    );
  """
end

defmodule C4Uploads.Router do
  use Shared.App

  # Extra static plug for the uploaded files
  plug Plug.Static, at: "/files", from: "uploads"

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/uploads" do
    DB.list(:uploads, order: "id DESC")
    |> Enum.map(fn row -> 
      Map.put(row, :url, "/files/#{row.stored_path}")
    end)
  end

  post "/uploads" do
    case conn.params["file"] do
      %Plug.Upload{filename: name, path: tmp_path, content_type: ct} ->
        File.mkdir_p!("uploads")
        ext = Path.extname(name)
        stored = "upload_" <> Base.encode16(:crypto.strong_rand_bytes(6)) <> ext
        dest = Path.join("uploads", stored)
        File.cp!(tmp_path, dest)
        size = File.stat!(dest).size
        
        id = DB.create(:uploads, %{
          filename: name,
          stored_path: stored,
          size: size,
          content_type: ct,
          created_at: System.system_time(:second)
        })
        
        ok %{id: id, filename: name, url: "/files/#{stored}"}
      _ ->
        halt 422, "file required"
    end
  end
end