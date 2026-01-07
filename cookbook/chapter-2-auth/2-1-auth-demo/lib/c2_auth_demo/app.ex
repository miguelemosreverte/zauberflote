defmodule C2AuthDemo.Application do
  use Shared.App.Runner, port: 4021

  init_sql """
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      role TEXT DEFAULT 'user',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      status TEXT DEFAULT 'pending',
      priority INTEGER DEFAULT 1,
      user_id INTEGER,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    INSERT OR IGNORE INTO users (id, username, password, role) VALUES
      (1, 'admin', 'admin123', 'admin'),
      (2, 'alice', 'alice123', 'user'),
      (3, 'bob', 'bob123', 'user');

    INSERT OR IGNORE INTO tasks (id, title, status, priority, user_id) VALUES
      (1, 'Set up development environment', 'completed', 3, 1),
      (2, 'Design database schema', 'completed', 2, 1),
      (3, 'Implement CRUD operations', 'in_progress', 3, 2),
      (4, 'Write API documentation', 'pending', 1, 2),
      (5, 'Add unit tests', 'pending', 2, 3);
  """
end

defmodule C2AuthDemo.Router do
  use Shared.App

  get "/" do
    conn |> put_resp_header("cache-control", "no-store") |> send_file(200, "priv/static/index.html")
  end

  # Auth endpoints
  get "/users" do
    DB.all("SELECT id, username, role, created_at FROM users ORDER BY id", [])
  end

  post "/register", args: [username: :string, password: :string] do
    validate username != "", "Username is required"
    validate String.length(password) >= 6, "Password must be at least 6 characters"
    validate !DB.exists?(:users, username: username), "Username already taken"
    DB.create(:users, %{username: username, password: password, role: "user"})
    ok(%{message: "Registration successful!"})
  end

  post "/login", args: [username: :string, password: :string] do
    user = DB.one(:users, where: [username: username, password: password])
    validate user != nil, "Invalid username or password"
    ok(%{user: %{id: user[:id], username: user[:username], role: user[:role]}})
  end

  # Tasks endpoints
  get "/tasks" do
    DB.all("SELECT t.*, u.username FROM tasks t LEFT JOIN users u ON t.user_id = u.id ORDER BY t.priority DESC, t.created_at DESC", [])
  end

  post "/tasks", args: [title: :string, priority: :int, user_id: :int] do
    validate title != "", "Title is required"
    validate priority >= 1 and priority <= 3, "Priority must be 1-3"
    DB.create(:tasks, %{title: title, priority: priority, status: "pending", user_id: user_id})
    ok()
  end

  post "/tasks/:id/start", args: [id: :int] do
    DB.update!(:tasks, id, %{status: "in_progress"})
    ok()
  end

  post "/tasks/:id/complete", args: [id: :int] do
    DB.update!(:tasks, id, %{status: "completed"})
    ok()
  end

  post "/tasks/:id/reopen", args: [id: :int] do
    DB.update!(:tasks, id, %{status: "pending"})
    ok()
  end

  delete "/tasks/:id", args: [id: :int] do
    DB.delete!(:tasks, id)
    ok()
  end
end
