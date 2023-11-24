defmodule Bloodhound.KafkaConsumer do
  use Broadway

  alias Broadway.Message
  alias Bloodhound.Chains.{ChainService, ChainSupervisor}

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {BroadwayKafka.Producer,
           [
             hosts: [localhost: 9094],
             group_id: "group_1",
             topics: ["test"]
           ]},
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 2
        ]
      ]
    )
  end

  def handle_message(_, %Message{data: event_value} = message, _context) do
    # Assuming event_value is a map with the structure %{type: event_type, attempt_id: attempt_id}
    event_value
    |> Jason.decode!()
    |> ChainService.normalize_chain_event()
    |> ChainService.process_event()

    # Let our chain supervisor decide if the event kickstarts
    # chains = ChainService.get_chains_by_initial_event_type(event_type)
    # if Enum.empty?(chains) do
    #   IO.puts("WE HAVE FOUND NO CHAINS")
    #   chain_run_id = String.to_atom(attempt_id)
    #   if Process.whereis(chain_run_id) do
    #     GenServer.cast(chain_run_id, {:event_received, event})
    #   end
    # else
    #   for chain <- chains do
    #     IO.puts("Starting a new chain")
    #     {:ok, chain_run } = ChainService.create_chain_run(chain, attempt_id)
    #     {:ok, chain_run_pid} = ChainSupervisor.start_chain_run(chain_run)
    #     IO.puts("PID of new process")
    #     IO.inspect(chain_run_pid)
    #     GenServer.cast(chain_run_pid, {:event_received, event})
    #   end
    # end

    message
  end
end
