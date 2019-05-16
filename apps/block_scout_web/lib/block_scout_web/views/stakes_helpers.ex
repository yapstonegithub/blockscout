defmodule BlockScoutWeb.StakesHelpers do
  alias Explorer.Chain.BlockNumberCache

  def amount_ratio(%{"staked_amount" => staked_amount}) when staked_amount <= 0, do: 0

  def amount_ratio(metadata) do
    metadata["self_staked_amount"] / metadata["staked_amount"] * 100
  end

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
