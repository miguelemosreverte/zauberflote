
defmodule C6SqlJoins.Application do
  use Shared.App.Runner, port: 4404

  init_sql """
    CREATE TABLE IF NOT EXISTS authors (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT
    );
    CREATE TABLE IF NOT EXISTS tags (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT UNIQUE
    );
    CREATE TABLE IF NOT EXISTS books (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      author_id INTEGER,
      title TEXT
    );
    CREATE TABLE IF NOT EXISTS book_tags (
      book_id INTEGER,
      tag_id INTEGER
    );
  """
end

defmodule C6SqlJoins.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/authors" do
    DB.list(:authors)
  end

  get "/tags" do
    DB.list(:tags)
  end

  post "/authors", args: [name: :string] do
    validate name != ""
    id = DB.create(:authors, %{name: name})
    %{id: id, name: name}
  end

  get "/books" do
    DB.all("SELECT b.id, b.title, a.name as author FROM books b JOIN authors a ON a.id = b.author_id ORDER BY b.id DESC")
  end

  post "/books", args: [author_id: :int, title: :string] do
    validate title != "" and author_id > 0
    id = DB.create(:books, %{author_id: author_id, title: title})
    %{id: id, title: title}
  end

  post "/books/:id/tags", args: [id: :int, tag: :string] do
    validate tag != ""
    transaction(fn ->
      DB.exec("INSERT OR IGNORE INTO tags (name) VALUES (?)", [tag])
      tag_row = DB.one!("SELECT id FROM tags WHERE name = ?", [tag])
      tag_id = tag_row.id
      DB.exec("INSERT INTO book_tags (book_id, tag_id) VALUES (?, ?)", [id, tag_id])
      %{book_id: id, tag: tag}
    end)
  end

  get "/books_with_tags" do
    DB.all("""
      SELECT b.id, b.title, a.name as author, GROUP_CONCAT(t.name) as tags
      FROM books b
      JOIN authors a ON a.id = b.author_id
      LEFT JOIN book_tags bt ON bt.book_id = b.id
      LEFT JOIN tags t ON t.id = bt.tag_id
      GROUP BY b.id
      ORDER BY b.id DESC
    """)
    |> Enum.map(fn row -> 
      Map.update!(row, :tags, &String.split(&1 || "", ",", trim: true))
    end)
  end

  get "/search", args: [author: :string, tag: :string, q: :string] do
    sql = """
      SELECT b.id, b.title, a.name as author, GROUP_CONCAT(t.name) as tags
      FROM books b
      JOIN authors a ON a.id = b.author_id
      LEFT JOIN book_tags bt ON bt.book_id = b.id
      LEFT JOIN tags t ON t.id = bt.tag_id
      WHERE (? = '' OR a.name = ?)
        AND (? = '' OR t.name = ?)
        AND (? = '' OR b.title LIKE ?)
      GROUP BY b.id
      ORDER BY b.id DESC
    """
    DB.all(sql, [author, author, tag, tag, q, "%#{q}%"])
    |> Enum.map(fn row -> 
      Map.update!(row, :tags, &String.split(&1 || "", ",", trim: true))
    end)
  end
end