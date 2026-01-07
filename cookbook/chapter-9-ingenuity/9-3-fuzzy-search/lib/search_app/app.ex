defmodule SearchApp.Application do
  use Shared.App.Runner, port: 4903, children: [SearchApp.Seeder]

  init_sql """
    CREATE VIRTUAL TABLE IF NOT EXISTS documents_fts USING fts5(title, content);
  """
end

defmodule SearchApp.Seeder do
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: __MODULE__)

  def init(_) do
    seed_data()
    {:ok, %{}}
  end

  defp seed_data do
    Shared.DB.with_db(fn db ->
      case Shared.DB.all_maps(db, "SELECT COUNT(*) as count FROM documents_fts", []) do
        [%{count: 0}] ->
          docs = [
            {"The Magic Flute", "An opera in two acts by Wolfgang Amadeus Mozart."},
            {"Elixir Language", "A dynamic, functional language designed for building scalable applications."},
            {"SQLite Database", "A C-language library that implements a small, fast, self-contained SQL database engine."},
            {"Reactive UI", "A framework for building user interfaces that react to data changes."}
          ]
          Enum.each(docs, fn {title, content} ->
            Shared.DB.exec(db, "INSERT INTO documents_fts(title, content) VALUES (?, ?)", [title, content])
          end)
        _ ->
          :ok
      end
    end)
  end
end

defmodule SearchApp.Router do
  use Shared.App

  resource "/search" do
    get args: [q: :string] do
      if q == nil or q == "" do
        DB.all("SELECT title, content, 0 as rank FROM documents_fts")
      else
        # Fuzzy match using FTS5 MATCH operator
        DB.all("""
          SELECT title, content, rank
          FROM documents_fts
          WHERE documents_fts MATCH '#{q}*'
          ORDER BY rank
        """)
      end
    end
  end
end
