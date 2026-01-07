defmodule AuditApp.Application do
  use Shared.App.Runner, port: 4909

  init_sql """
    CREATE TABLE IF NOT EXISTS settings (
      id INTEGER PRIMARY KEY,
      site_name TEXT NOT NULL,
      active INTEGER NOT NULL
    );
    INSERT OR IGNORE INTO settings (id, site_name, active) VALUES (1, 'My Awesome Site', 1);

    CREATE TABLE IF NOT EXISTS audit_log (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      data_json TEXT NOT NULL,
      ts DATETIME DEFAULT CURRENT_TIMESTAMP
    );
  """
end

defmodule AuditApp.Router do
  use Shared.App

  resource "/settings" do
    get args: [] do
      DB.get!(:settings, 1)
    end

    post args: [site_name: :string, active: :int] do
      current = DB.get!(:settings, 1)
      DB.exec("INSERT INTO audit_log (data_json) VALUES (?)", [Jason.encode!(current)])

      DB.update!(:settings, 1, site_name: site_name, active: active)
      DB.get!(:settings, 1)
    end

    get "/diff", args: [] do
      current = DB.get!(:settings, 1)
      last_audit = DB.one("SELECT data_json FROM audit_log ORDER BY id DESC LIMIT 1")

      if last_audit do
        old = Jason.decode!(last_audit[:data_json])
        keys = Map.keys(current)
        diff = Enum.reduce(keys, [], fn k, acc ->
          old_val = Map.get(old, k) || Map.get(old, to_string(k))
          new_val = Map.get(current, k)
          if new_val != old_val do
            [{k, %{old: old_val, new: new_val}} | acc]
          else
            acc
          end
        end)
        %{has_diff: diff != [], changes: Map.new(diff)}
      else
        %{has_diff: false, changes: %{}}
      end
    end
  end
end
