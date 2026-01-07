defmodule ActivityHeatmap.Application do
  use Shared.App.Runner, port: 4905

  init_sql """
    CREATE TABLE IF NOT EXISTS activities (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      activity_date DATE NOT NULL,
      count INTEGER DEFAULT 1,
      category TEXT DEFAULT 'default'
    );
    -- Seed rich activity data for the past 90 days
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-1 days'), 8, 'commits' WHERE (SELECT COUNT(*) FROM activities) = 0;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-2 days'), 12, 'commits' WHERE (SELECT COUNT(*) FROM activities) < 2;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-3 days'), 5, 'reviews' WHERE (SELECT COUNT(*) FROM activities) < 3;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-4 days'), 15, 'commits' WHERE (SELECT COUNT(*) FROM activities) < 4;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-5 days'), 3, 'reviews' WHERE (SELECT COUNT(*) FROM activities) < 5;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-7 days'), 9, 'commits' WHERE (SELECT COUNT(*) FROM activities) < 6;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-8 days'), 11, 'commits' WHERE (SELECT COUNT(*) FROM activities) < 7;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-10 days'), 7, 'reviews' WHERE (SELECT COUNT(*) FROM activities) < 8;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-12 days'), 14, 'commits' WHERE (SELECT COUNT(*) FROM activities) < 9;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-14 days'), 6, 'commits' WHERE (SELECT COUNT(*) FROM activities) < 10;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-15 days'), 10, 'reviews' WHERE (SELECT COUNT(*) FROM activities) < 11;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-18 days'), 4, 'commits' WHERE (SELECT COUNT(*) FROM activities) < 12;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-21 days'), 13, 'commits' WHERE (SELECT COUNT(*) FROM activities) < 13;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-22 days'), 8, 'reviews' WHERE (SELECT COUNT(*) FROM activities) < 14;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-25 days'), 16, 'commits' WHERE (SELECT COUNT(*) FROM activities) < 15;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-28 days'), 5, 'commits' WHERE (SELECT COUNT(*) FROM activities) < 16;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-30 days'), 11, 'reviews' WHERE (SELECT COUNT(*) FROM activities) < 17;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-35 days'), 9, 'commits' WHERE (SELECT COUNT(*) FROM activities) < 18;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-40 days'), 7, 'commits' WHERE (SELECT COUNT(*) FROM activities) < 19;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-45 days'), 12, 'reviews' WHERE (SELECT COUNT(*) FROM activities) < 20;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-50 days'), 6, 'commits' WHERE (SELECT COUNT(*) FROM activities) < 21;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-55 days'), 14, 'commits' WHERE (SELECT COUNT(*) FROM activities) < 22;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-60 days'), 8, 'reviews' WHERE (SELECT COUNT(*) FROM activities) < 23;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-65 days'), 10, 'commits' WHERE (SELECT COUNT(*) FROM activities) < 24;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-70 days'), 5, 'commits' WHERE (SELECT COUNT(*) FROM activities) < 25;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-75 days'), 9, 'reviews' WHERE (SELECT COUNT(*) FROM activities) < 26;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-80 days'), 13, 'commits' WHERE (SELECT COUNT(*) FROM activities) < 27;
    INSERT INTO activities (activity_date, count, category) SELECT date('now', '-85 days'), 7, 'commits' WHERE (SELECT COUNT(*) FROM activities) < 28;
  """
end

defmodule ActivityHeatmap.Router do
  use Shared.App

  get "/activities", args: [] do
    # Aggregate activities by date for the past 365 days
    DB.all("""
      SELECT
        activity_date as date,
        SUM(count) as total,
        GROUP_CONCAT(DISTINCT category) as categories
      FROM activities
      WHERE activity_date >= date('now', '-365 days')
      GROUP BY activity_date
      ORDER BY activity_date
    """)
  end

  post "/activities", args: [date: :string, count: :integer, category: :string] do
    validate date != "", "Date required"
    validate count > 0, "Count must be positive"
    DB.create(:activities, %{activity_date: date, count: count, category: category || "default"})
    %{ok: true}
  end

  get "/stats", args: [] do
    DB.one("""
      SELECT
        COUNT(*) as total_entries,
        SUM(count) as total_activities,
        MAX(count) as max_daily,
        AVG(count) as avg_daily
      FROM activities
      WHERE activity_date >= date('now', '-365 days')
    """)
  end
end
