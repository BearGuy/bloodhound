defmodule Bloodhound.Chains.ChainSupervisor do
  use DynamicSupervisor, restart: :transient

  alias Bloodhound.Chains.ChainRunner

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_chain_run(chain_run) do
    # Name the chain process using the attempt_id
    case DynamicSupervisor.start_child(
        __MODULE__,
        %{
          id: ChainRunner,
          start: {ChainRunner, :start_link, [chain_run]},
          restart: :transient
        }
    ) do
      {:ok, pid} ->
        IO.puts("Successfully started Chain with PID: #{inspect(pid)}")
        {:ok, pid}

      {:error, reason} ->
        IO.puts("Failed to start Chain: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
