defmodule BlockScoutWeb.InactivePoolsController do
  use BlockScoutWeb, :controller

  alias Explorer.Counters.AverageBlockTime
  alias Explorer.Chain
  alias Explorer.PagingOptions

  def index(conn, params) do
    paging_options =
      %PagingOptions{
        page_size: params["lim"] || 20,
        page_number: params["off"] || 1
      }

    pools = Chain.staking_pools(:inactive, paging_options)
    average_block_time = AverageBlockTime.average_block_time()
    render(conn, "index.html", pools: pools, average_block_time: average_block_time)
  end
end
