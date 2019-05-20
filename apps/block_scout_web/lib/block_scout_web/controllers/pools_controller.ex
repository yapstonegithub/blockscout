defmodule BlockScoutWeb.PoolsController do
  use BlockScoutWeb, :controller

  alias Explorer.Counters.AverageBlockTime
  alias Explorer.Chain
  alias Explorer.PagingOptions
  alias Explorer.Staking.EpochCounter
  alias Explorer.Chain.BlockNumberCache

  def validators(conn, params) do
    render_list(:validator, conn, params)
  end

  def active_pools(conn, params) do
    render_list(:active, conn, params)
  end

  def inactive_pools(conn, params) do
    render_list(:inactive, conn, params)
  end

  defp render_list(filter, conn, params) do
    paging_options = %PagingOptions{
      page_size: params["lim"] || 20,
      page_number: params["off"] || 1
    }

    pools = Chain.staking_pools(filter, paging_options)
    average_block_time = AverageBlockTime.average_block_time()
    epoch_number = EpochCounter.epoch_number()
    epoch_end_block = EpochCounter.epoch_end_block()
    block_number = BlockNumberCache.max_number()

    options = [
      pools: pools,
      average_block_time: average_block_time,
      pools_type: filter,
      epoch_number: epoch_number,
      epoch_end_in: epoch_end_block - block_number,
      block_number: block_number
    ]

    render(conn, "index.html", options)
  end
end
