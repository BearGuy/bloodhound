defmodule Bloodhound.Chains.ChainService do
  alias Bloodhound.Repo
  alias Bloodhound.Chains.ChainSupervisor
  alias Bloodhound.Schemas.Chains.{
    Chain,
    ChainEvent,
    ChainRun,
    ChainRunEvent
  }

  import Ecto.Query

  # Fetch chains based on their initial_event_type and an events event_type
  def get_chains_by_initial_event_type(event_type) do
    query = from c in Chain,
            where: c.initial_event_type == ^event_type,
            preload: :chain_events

    Repo.all(query)
  end

  def get_chains_for_event(event) do
    query = from c in Chain,
            join: e in ChainEvent,
              as: :chain_event,
              on: e.chain_id == c.id,
            where: e.event_type == ^event.type,
            preload: :chain_events

    Repo.all(query)
  end

  def create_chain_run(chain, attempt_id, attrs \\ %{}) do
    steps = Enum.map(chain.chain_events, fn chain_event ->
      %{event_type: chain_event.event_type, status: :waiting}
    end)

    attrs = Map.merge(attrs, %{
      chain_id: chain.id,
      status: :waiting,
      start_time: DateTime.utc_now(),
      attempt_id: attempt_id,
      steps: steps
    })

    chain_run_changeset = %ChainRun{} |> ChainRun.changeset(attrs)
    Repo.insert(chain_run_changeset)
  end

  def update_chain_run(chain_run, attrs) do
    chain_run
    |> ChainRun.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:steps, chain_run.steps)
    |> Repo.update()
  end

  # Record ChainRun events as ChainRunEvent in our process logic
  def create_chain_run_event(chain_run, attrs \\ %{}) do
    %ChainRunEvent{}
    |> ChainRunEvent.changeset(Map.merge(attrs, %{chain_run_id: chain_run.id}))
    |> Repo.insert()
  end

  def update_chain_run_event(chain_run_event, attrs) do
    chain_run_event
    |> ChainRunEvent.changeset(attrs)
    |> Repo.update()
  end

  def process_event(event_params) do
    event_type = Map.get(event_params, :type)
    attempt_id = Map.get(event_params, :attempt_id)

    # Check first if this event will kickstart any new chains
    for chain <- get_chains_by_initial_event_type(event_type) do
      with {:ok, chain_run} <- create_chain_run(chain, attempt_id),
            {:ok, chain_run_pid} <- ChainSupervisor.start_chain_run(chain_run),
            :ok <- GenServer.cast(chain_run_pid, {:event_received, event_params}) do
        IO.puts("Starting a new chain")
        IO.puts("PID of new process")
        IO.inspect(chain_run_pid)
      else
        error ->
          IO.puts("Failed to process chain: #{inspect(error)}")
      end
    end

    # Check to see if this event exists in any other chains
    # and then send them to existing processes
    for _chain <- get_chains_for_event(event_params) do
      chain_run_id = String.to_atom(attempt_id)
      if Process.whereis(chain_run_id) do
        GenServer.cast(chain_run_id, {:event_received, event_params})
      end
    end

    {:ok, []}
  end

  def normalize_chain_event(event) do
    for {k, v} <- event, into: %{}, do: {String.to_atom(k), v}
  end

  # More operations related to Chain, ChainRun, and ChainRunEvent can be added here
end
