defmodule OrgApp.Application do
  use Shared.App.Runner, port: 4901

  init_sql """
    CREATE TABLE IF NOT EXISTS employees (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      role TEXT NOT NULL,
      manager_id INTEGER REFERENCES employees(id)
    );
    -- Seed org chart hierarchy
    INSERT OR IGNORE INTO employees (id, name, role, manager_id) VALUES (1, 'Alice', 'CEO', NULL);
    INSERT OR IGNORE INTO employees (id, name, role, manager_id) VALUES (2, 'Bob', 'CTO', 1);
    INSERT OR IGNORE INTO employees (id, name, role, manager_id) VALUES (3, 'Carol', 'CFO', 1);
    INSERT OR IGNORE INTO employees (id, name, role, manager_id) VALUES (4, 'David', 'Engineering Lead', 2);
    INSERT OR IGNORE INTO employees (id, name, role, manager_id) VALUES (5, 'Eve', 'Product Lead', 2);
    INSERT OR IGNORE INTO employees (id, name, role, manager_id) VALUES (6, 'Frank', 'Senior Developer', 4);
    INSERT OR IGNORE INTO employees (id, name, role, manager_id) VALUES (7, 'Grace', 'Developer', 4);
    INSERT OR IGNORE INTO employees (id, name, role, manager_id) VALUES (8, 'Henry', 'Designer', 5);
  """
end

defmodule OrgApp.Router do
  use Shared.App

  resource "/employees" do
    get args: [] do
      DB.list(:employees)
    end

    post args: [name: :string, role: :string, manager_id: :integer] do
      validate name != "", "Name required"
      validate role != "", "Role required"
      DB.create(:employees, %{name: name, role: role, manager_id: manager_id})
      %{ok: true}
    end

    get "/tree", args: [] do
      DB.all("""
        WITH RECURSIVE org_tree AS (
          SELECT id, name, role, manager_id, 0 as depth
          FROM employees
          WHERE manager_id IS NULL
          UNION ALL
          SELECT e.id, e.name, e.role, e.manager_id, ot.depth + 1
          FROM employees e
          JOIN org_tree ot ON e.manager_id = ot.id
        )
        SELECT * FROM org_tree ORDER BY depth, id
      """)
    end
  end
end
