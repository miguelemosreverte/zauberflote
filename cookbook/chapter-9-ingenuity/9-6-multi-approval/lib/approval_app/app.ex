defmodule ApprovalApp.Application do
  use Shared.App.Runner, port: 4906

  init_sql """
    CREATE TABLE IF NOT EXISTS invoices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount REAL NOT NULL,
      description TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'DRAFT'
    );
    -- Seed invoices in different workflow states
    INSERT OR IGNORE INTO invoices (id, amount, description, status) VALUES (1, 1200.50, 'Server Upgrade', 'PENDING_MANAGER');
    INSERT OR IGNORE INTO invoices (id, amount, description, status) VALUES (2, 450.00, 'Office Supplies', 'PENDING_MANAGER');
    INSERT OR IGNORE INTO invoices (id, amount, description, status) VALUES (3, 2500.00, 'Software Licenses', 'PENDING_ACCOUNTANT');
    INSERT OR IGNORE INTO invoices (id, amount, description, status) VALUES (4, 875.25, 'Marketing Materials', 'PENDING_ACCOUNTANT');
    INSERT OR IGNORE INTO invoices (id, amount, description, status) VALUES (5, 320.00, 'Travel Expenses', 'PAID');
    INSERT OR IGNORE INTO invoices (id, amount, description, status) VALUES (6, 1500.00, 'Consulting Fee', 'PAID');
    INSERT OR IGNORE INTO invoices (id, amount, description, status) VALUES (7, 95.00, 'Domain Renewal', 'REJECTED');
  """
end

defmodule ApprovalApp.Router do
  use Shared.App

  resource "/invoices" do
    get args: [] do
      DB.list(:invoices)
    end

    post args: [amount: :float, description: :string] do
      DB.exec("INSERT INTO invoices (amount, description, status) VALUES (?, ?, 'PENDING_MANAGER')", [amount, description])
      ok()
    end

    resource "/:id" do
      # Persona: Manager
      post "/approve-manager", args: [id: :int] do
        invoice = DB.get!(:invoices, id)
        validate invoice.status == "PENDING_MANAGER", "Must be pending manager approval"
        DB.update!(:invoices, id, status: "PENDING_ACCOUNTANT")
        ok()
      end

      # Persona: Accountant
      post "/pay", args: [id: :int] do
        invoice = DB.get!(:invoices, id)
        validate invoice.status == "PENDING_ACCOUNTANT", "Must be pending accountant approval"
        DB.update!(:invoices, id, status: "PAID")
        ok()
      end

      post "/reject", args: [id: :int] do
        DB.update!(:invoices, id, status: "REJECTED")
        ok()
      end
    end
  end
end
