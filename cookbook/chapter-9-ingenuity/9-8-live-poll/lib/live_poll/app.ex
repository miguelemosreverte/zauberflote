defmodule LivePoll.Application do
  use Shared.App.Runner, port: 4908

  init_sql """
    CREATE TABLE IF NOT EXISTS polls (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      question TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      active INTEGER DEFAULT 1
    );
    CREATE TABLE IF NOT EXISTS poll_options (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      poll_id INTEGER REFERENCES polls(id),
      option_text TEXT NOT NULL,
      votes INTEGER DEFAULT 0
    );
    INSERT INTO polls (question)
      SELECT 'What is your favorite programming language?'
      WHERE (SELECT COUNT(*) FROM polls) = 0;
    INSERT INTO poll_options (poll_id, option_text, votes)
      SELECT 1, 'Elixir', 42 WHERE (SELECT COUNT(*) FROM poll_options) = 0;
    INSERT INTO poll_options (poll_id, option_text, votes)
      SELECT 1, 'Python', 38 WHERE (SELECT COUNT(*) FROM poll_options) < 2;
    INSERT INTO poll_options (poll_id, option_text, votes)
      SELECT 1, 'JavaScript', 35 WHERE (SELECT COUNT(*) FROM poll_options) < 3;
  """
end

defmodule LivePoll.Router do
  use Shared.App

  get "/polls", args: [] do
    DB.all("SELECT * FROM polls ORDER BY created_at DESC")
  end

  get "/polls/:id", args: [id: :integer] do
    poll = DB.one("SELECT * FROM polls WHERE id = ?", [id])
    options = DB.all("""
      SELECT
        id, option_text, votes,
        ROUND(votes * 100.0 / NULLIF((SELECT SUM(votes) FROM poll_options WHERE poll_id = ?), 0), 1) as percentage
      FROM poll_options
      WHERE poll_id = ?
      ORDER BY votes DESC
    """, [id, id])

    total = Enum.reduce(options, 0, fn opt, acc -> acc + (opt["votes"] || 0) end)
    Map.put(poll, "options", options) |> Map.put("total_votes", total)
  end

  post "/polls", args: [question: :string, options: :string] do
    validate question != "", "Question required"
    validate options != "", "Options required (comma-separated)"

    poll_id = DB.create(:polls, %{question: question})

    options
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(&1 != ""))
    |> Enum.each(fn opt ->
      DB.create(:poll_options, %{poll_id: poll_id, option_text: opt})
    end)

    %{ok: true, id: poll_id}
  end

  post "/vote/:option_id", args: [option_id: :integer] do
    DB.exec("UPDATE poll_options SET votes = votes + 1 WHERE id = ?", [option_id])
    %{ok: true}
  end

  get "/results/:poll_id", args: [poll_id: :integer] do
    DB.all("""
      SELECT
        id, option_text, votes,
        ROUND(votes * 100.0 / NULLIF((SELECT SUM(votes) FROM poll_options WHERE poll_id = ?), 0), 1) as percentage
      FROM poll_options
      WHERE poll_id = ?
      ORDER BY votes DESC
    """, [poll_id, poll_id])
  end
end
