defmodule TrackApp.Application do
  use Shared.App.Runner, port: 4912

  init_sql """
    CREATE TABLE IF NOT EXISTS orders (
      tracking_id TEXT PRIMARY KEY,
      product TEXT NOT NULL,
      current_status TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS order_events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tracking_id TEXT NOT NULL,
      status TEXT NOT NULL,
      note TEXT,
      ts DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY(tracking_id) REFERENCES orders(tracking_id)
    );
  """
end

defmodule TrackApp.Router do
  use Shared.App

  resource "/orders" do
    get args: [] do
      DB.all("SELECT * FROM orders ORDER BY tracking_id DESC", [])
    end

    post args: [product: :string] do
      tracking_id = "TRK-#{:rand.uniform(99999)}"
      transaction(fn ->
        DB.create(:orders, %{tracking_id: tracking_id, product: product, current_status: "CREATED"})
        DB.create(:order_events, %{tracking_id: tracking_id, status: "CREATED", note: "Order placed successfully"})
      end)
      %{tracking_id: tracking_id}
    end

    # IMPORTANT: /track must be defined BEFORE /:tracking_id to avoid route shadowing
    get "/track", args: [id: :string] do
      id_val = if id == "", do: nil, else: id
      events = if id_val, do: DB.all("SELECT * FROM order_events WHERE tracking_id = ? ORDER BY id DESC", [id_val]), else: []
      %{tracking_id: id_val, events: events}
    end

    resource "/:tracking_id" do
      post "/update", args: [tracking_id: :string, status: :string, note: :string] do
        transaction(fn ->
          DB.update_where!(:orders, [tracking_id: tracking_id], current_status: status)
          DB.create(:order_events, %{tracking_id: tracking_id, status: status, note: note})
        end)
        ok()
      end
    end
  end
end
