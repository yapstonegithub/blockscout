defmodule BlockScoutWeb.StakesView do
  use BlockScoutWeb, :view
  alias Explorer.Chain.BlockNumberCache

  def estimated_unban_day(banned_until, average_block_time) do
    try do
      during_sec = (banned_until - BlockNumberCache.max_number()) * average_block_time
      now = DateTime.utc_now() |> DateTime.to_unix()
      date = DateTime.from_unix!(now + during_sec)
      Timex.format!(date, "%d %b %Y", :strftime)
    rescue
      _e ->
        DateTime.utc_now()
        |> Timex.format!("%d %b %Y", :strftime)
    end
  end
end
