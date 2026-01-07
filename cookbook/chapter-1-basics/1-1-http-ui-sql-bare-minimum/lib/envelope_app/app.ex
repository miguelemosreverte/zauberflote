defmodule EnvelopeApp.Application do
  use Shared.App.Runner, port: 4001

  init_sql """
    CREATE TABLE IF NOT EXISTS income (
      id INTEGER PRIMARY KEY,
      amount REAL NOT NULL DEFAULT 0
    );
    INSERT OR IGNORE INTO income (id, amount) VALUES (1, 0);

    CREATE TABLE IF NOT EXISTS envelopes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      amount REAL NOT NULL DEFAULT 0
    );
  """
end

defmodule EnvelopeApp.Router do
  use Shared.App

  # Income Resource
  resource "/income" do
    get do
      # Fetch singleton (id=1), default to 0 if missing (though init_sql handles this)
      DB.get(:income, 1) || %{amount: 0}
    end

    post "/add", args: [amount: :float] do
      validate amount > 0, "Amount must be positive"
      
      transaction(fn ->
        DB.update!(:income, 1, inc: [amount: amount])
        DB.get!(:income, 1)
      end)
    end
  end

  # Envelopes Resource
  resource "/envelopes" do
    get do
      DB.list(:envelopes, order: :id)
    end

    post args: [name: :string] do
      validate name != "", "Name required"
      
      # Implicit check using DB constraints or explicit check
      if DB.exists?(:envelopes, name: name) do
        halt 409, "Name already exists"
      end
      
      DB.create(:envelopes, name: name, amount: 0)
    end

    # Item actions
    resource "/:id" do
      post "/allocate", args: [id: :int, amount: :float] do
        validate amount > 0, "Positive amount required"
        
        transaction(fn ->
          income = DB.get!(:income, 1)
          validate income.amount >= amount, "Insufficient income"
          
          DB.update!(:income, 1, dec: [amount: amount])
          DB.update!(:envelopes, id, inc: [amount: amount])
          ok()
        end)
      end

      post "/spend", args: [id: :int, amount: :float] do
        validate amount > 0, "Positive amount required"
        
        transaction(fn ->
          env = DB.get!(:envelopes, id)
          validate env.amount >= amount, "Insufficient funds"
          
          DB.update!(:envelopes, id, dec: [amount: amount])
          ok()
        end)
      end
    end
  end
end
