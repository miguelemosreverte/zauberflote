defmodule WizardApp.Application do
  use Shared.App.Runner, port: 4911

  init_sql """
    CREATE TABLE IF NOT EXISTS registrations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT UNIQUE,
      fullname TEXT,
      password_hash TEXT,
      plan TEXT,
      step INTEGER DEFAULT 1
    );
  """
end

defmodule WizardApp.Router do
  use Shared.App

  resource "/register" do
    get args: [email: :string] do
      DB.one("SELECT * FROM registrations WHERE email = ?", params: [email]) || %{step: 1}
    end

    post "/step1", args: [email: :string, fullname: :string] do
      validate email != "" and fullname != "", "Email and name required"
      # Upsert
      if DB.exists?(:registrations, email: email) do
        DB.exec("UPDATE registrations SET fullname = ?, step = 2 WHERE email = ?", [fullname, email])
      else
        DB.create(:registrations, %{email: email, fullname: fullname, step: 2})
      end
      %{email: email, step: 2}
    end

    post "/step2", args: [email: :string, plan: :string] do
      DB.exec("UPDATE registrations SET plan = ?, step = 3 WHERE email = ?", [plan, email])
      %{email: email, step: 3}
    end

    post "/complete", args: [email: :string] do
      DB.exec("UPDATE registrations SET step = 4 WHERE email = ?", [email])
      %{message: "Welcome to the magic flute!"}
    end
  end
end
