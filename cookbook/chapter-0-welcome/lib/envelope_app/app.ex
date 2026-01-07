
defmodule EnvelopeApp.Application do
  use Shared.App.Runner, port: 4010

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

  resource "/income" do
    get do
      DB.get(:income, 1) || %{amount: 0}
    end

    post "/add", args: [amount: :float] do
      validate amount > 0, "Positive amount required"
      transaction(fn ->
        DB.update!(:income, 1, inc: [amount: amount])
        DB.get!(:income, 1)
      end)
    end
  end

  resource "/envelopes" do
    get do
      DB.list(:envelopes)
    end

    post args: [name: :string] do
      validate name != "", "Name required"
      if DB.exists?(:envelopes, name: name), do: halt(409, "Exists")
      
      DB.create(:envelopes, name: name, amount: 0)
    end

    resource "/:id" do
      post "/allocate", args: [id: :int, amount: :float] do
        validate amount > 0
        transaction(fn ->
          income = DB.get!(:income, 1)
          validate income.amount >= amount, "Insufficient income"
          DB.update!(:income, 1, dec: [amount: amount])
          DB.update!(:envelopes, id, inc: [amount: amount])
          ok()
        end)
      end

      post "/spend", args: [id: :int, amount: :float] do
        validate amount > 0
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
