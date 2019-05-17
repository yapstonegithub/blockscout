defmodule Indexer.Temporary.MarkDecompiledAndVerifiedSmartContracts do
  @moduledoc """
  Marks addresses that exist in the decompiled_smart_contracts table
  or the smart_contracts table as `decompiled` or `verified`, respectively.
  """

  use Indexer.Fetcher

  require Logger

  import Ecto.Query, only: [from: 2]

  alias Explorer.Chain.Address
  alias Explorer.Repo
  alias Indexer.BufferedTask

  @behaviour BufferedTask

  @defaults [
    flush_interval: :timer.seconds(3),
    max_batch_size: 100,
    max_concurrency: 10,
    task_supervisor: Indexer.Temporary.MarkDecompiledAndVerifiedSmartContracts.TaskSupervisor,
    metadata: [fetcher: :uncles_without_index]
  ]

  @doc false
  def child_spec([init_options, gen_server_options]) when is_list(init_options) do
    {state, mergeable_init_options} = Keyword.pop(init_options, :json_rpc_named_arguments)

    unless state do
      raise ArgumentError,
            ":json_rpc_named_arguments must be provided to `#{__MODULE__}.child_spec " <>
              "to allow for json_rpc calls when running."
    end

    merged_init_options =
      @defaults
      |> Keyword.merge(mergeable_init_options)
      |> Keyword.put(:state, state)

    Supervisor.child_spec({BufferedTask, [{__MODULE__, merged_init_options}, gen_server_options]}, id: __MODULE__)
  end

  @impl BufferedTask
  def init(initial, reducer, _) do
    query =
      from(address in Address,
        where: is_nil(address.verified) or is_nil(address.decompiled),
        left_join: decompiled_smart_contracts in assoc(address, :decompiled_smart_contracts),
        left_join: smart_contract in assoc(address, :smart_contract),
        group_by: address.hash,
        select: %{
          hash: address.hash,
          decompiled: count(decompiled_smart_contracts.address_hash) > 0,
          verified: count(smart_contract.address_hash) > 0
        }
      )

    {:ok, final} =
      Repo.stream_reduce(query, initial, fn address_data, acc ->
        reducer.(address_data, acc)
      end)

    final
  end

  @impl BufferedTask
  def run(data, _json_rpc_named_arguments) do
    data_count = Enum.count(data)
    Logger.metadata(count: data_count)

    {both, not_both} = Enum.split_with(data, fn address -> address.decompiled && address.verified end)
    {decompiled, not_decompiled} = Enum.split_with(not_both, fn address -> address.decompiled end)
    {verified, neither} = Enum.split_with(not_decompiled, fn address -> address.verified end)

    both_hashes = Enum.map(both, & &1.hash)
    decompiled_hashes = Enum.map(decompiled, & &1.hash)
    verified_hashes = Enum.map(verified, & &1.hash)
    neither_hashes = Enum.map(neither, & &1.hash)

    update(both_hashes, verified: true, decompiled: true)
    update(decompiled_hashes, verified: false, decompiled: true)
    update(verified_hashes, verified: true, decompiled: false)
    update(neither_hashes, verified: false, decompiled: false)

    :ok
  end

  defp update(hashes, set) do
    query =
      from(address in Address,
        where: address.hash in ^hashes
      )

    Repo.update_all(query, set: set)
  end
end
