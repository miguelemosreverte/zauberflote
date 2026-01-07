
defmodule Example02HttpBasics.Application do
  use Shared.App.Runner, port: 4002

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

defmodule Example02HttpBasics.Router do
  use Shared.App

  get "/state" do
    %{
      income: DB.get(:income, 1).amount,
      envelopes: DB.list(:envelopes)
    }
  end

  resource "/income" do
    get do
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

  resource "/envelopes" do
    get args: [q: :string, limit: :int, offset: :int] do
      limit = if limit <= 0, do: 50, else: limit
      where = if q != "", do: [name: {:like, "%#{q}%"}], else: []
      
      %{
        items: DB.list(:envelopes, where: where, limit: limit, offset: offset),
        total: DB.count(:envelopes, where: where),
        limit: limit,
        offset: offset
      }
    end

    get "/by-name", args: [name: :string] do
      validate name != "", "Name required"
      DB.one(:envelopes, where: [name: name]) || halt(404, "Not found")
    end

    post args: [name: :string] do
      validate name != "", "Name required"
      if DB.exists?(:envelopes, name: name), do: halt(409, "Exists")
      
      id = DB.create(:envelopes, name: name, amount: 0)
      created %{id: id, name: name, amount: 0}
    end

    put "/by-name", args: [name: :string, new_name: :string] do
      validate name != "" and new_name != "", "Names required"
      if DB.exists?(:envelopes, name: new_name), do: halt(409, "Exists")
      
      DB.update_where!(:envelopes, [name: name], name: new_name)
      ok %{name: new_name}
    end

    delete "/by-name", args: [name: :string] do
      validate name != "", "Name required"
      DB.delete_where!(:envelopes, name: name)
      ok()
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
