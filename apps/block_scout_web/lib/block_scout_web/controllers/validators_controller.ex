defmodule BlockScoutWeb.ValidatorsController do
  use BlockScoutWeb, :controller

  alias Explorer.Counters.AverageBlockTime
  alias Explorer.Chain

  def index(conn, params) do
    lim = params["lim"] || 20
    off = params["off"] || 0

    validators = Chain.staking_pools(:validator, lim, off)
    average_block_time = AverageBlockTime.average_block_time()
    render(conn, "index.html", validators: validators, average_block_time: average_block_time)
  end
end
