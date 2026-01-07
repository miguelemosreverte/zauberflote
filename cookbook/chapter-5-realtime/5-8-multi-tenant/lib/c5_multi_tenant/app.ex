
defmodule C5MultiTenant.Application do
  use Shared.App.Runner, port: 4308

  init_sql """
    CREATE TABLE IF NOT EXISTS items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tenant TEXT,
      name TEXT
    );
  """
end

defmodule C5MultiTenant.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/items" do
    tenant = current_tenant(conn)
    items = DB.list(:items, where: [tenant: tenant])
    ok %{tenant: tenant, items: items}
  end

  post "/items", args: [name: :string] do
    tenant = current_tenant(conn)
    validate name != "", "name required"
    DB.create(:items, %{tenant: tenant, name: name})
    ok()
  end

  defp current_tenant(conn) do
    get_req_header(conn, "x-tenant-id") |> List.first() || halt(400, "X-Tenant-ID required")
  end
end