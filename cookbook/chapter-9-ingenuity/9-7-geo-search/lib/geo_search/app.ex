defmodule GeoSearch.Application do
  use Shared.App.Runner, port: 4907

  init_sql """
    CREATE TABLE IF NOT EXISTS locations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      lat REAL NOT NULL,
      lng REAL NOT NULL,
      category TEXT DEFAULT 'place'
    );
    INSERT INTO locations (name, description, lat, lng, category)
      SELECT 'San Francisco', 'Tech hub', 37.7749, -122.4194, 'city'
      WHERE (SELECT COUNT(*) FROM locations) = 0;
    INSERT INTO locations (name, description, lat, lng, category)
      SELECT 'New York', 'Financial center', 40.7128, -74.0060, 'city'
      WHERE (SELECT COUNT(*) FROM locations) < 2;
    INSERT INTO locations (name, description, lat, lng, category)
      SELECT 'London', 'European hub', 51.5074, -0.1278, 'city'
      WHERE (SELECT COUNT(*) FROM locations) < 3;
  """
end

defmodule GeoSearch.Router do
  use Shared.App

  get "/locations", args: [] do
    DB.all("SELECT * FROM locations ORDER BY name")
  end

  get "/locations/near", args: [lat: :float, lng: :float, radius: :float] do
    # Simple bounding box approximation for nearby locations
    # radius in degrees (roughly 111km per degree at equator)
    delta = (radius || 5000) / 111.0
    DB.all("""
      SELECT * FROM locations
      WHERE lat BETWEEN ? AND ?
        AND lng BETWEEN ? AND ?
      ORDER BY name
    """, [lat - delta, lat + delta, lng - delta, lng + delta])
  end

  post "/locations", args: [name: :string, description: :string, lat: :float, lng: :float, category: :string] do
    validate name != "", "Name required"
    validate lat != nil, "Latitude required"
    validate lng != nil, "Longitude required"

    DB.create(:locations, %{
      name: name,
      description: description || "",
      lat: lat,
      lng: lng,
      category: category || "place"
    })
    %{ok: true}
  end

  get "/search", args: [q: :string] do
    query = "%#{q}%"
    DB.all("""
      SELECT * FROM locations
      WHERE name LIKE ? OR description LIKE ? OR category LIKE ?
      ORDER BY name
    """, [query, query, query])
  end
end
