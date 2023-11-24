defmodule Bloodhound.Chains.ChainRunner do
  use GenServer
  alias Bloodhound.Chains.ChainService

  def start_link(chain_run) do
    IO.puts("STARTING CHAIN GEN SERVER")
    IO.inspect(chain_run)
    GenServer.start_link(
      __MODULE__,
      chain_run,
      name: String.to_atom(chain_run.attempt_id)
    )
  end

  def init(chain_run) do
    {:ok, chain_run}
  end

  # define your callbacks here. For example:
  def handle_cast({:event_received, event}, chain_run) do
    chain_run
    |> process_event(event)
    |> format_response
  end

  defp format_response(%{status: :completed} = chain_run) do
    {:stop, :normal, chain_run}
  end

  defp format_response(chain_run) do
    {:noreply, chain_run}
  end

  #def terminate(reason, _status) do
    #IO.inspect(reason)
  #end

  defp process_event(%{status: :waiting} = chain_run, event) do
    first_step = Enum.at(chain_run.steps, 0)

    if is_matching_event(event, first_step) do
      chain_run
      |> update_step(0, %{status: :completed, timestamp: get_timestamp(event)})
      |> set_chain_run_status(:processing)
    else
      chain_run
    end
  end

  defp process_event(%{status: :processing} = chain_run, event) do
    waiting_step_index = Enum.find_index(chain_run.steps, &(&1.status == :waiting))
    waiting_step = Enum.at(chain_run.steps, waiting_step_index)

    if is_matching_event(event, waiting_step) do
      updated_chain_run = update_step(chain_run, waiting_step_index, %{status: :completed, timestamp: get_timestamp(event)})

      if all_steps_completed?(updated_chain_run) do
        updated_chain_run = updated_chain_run
        |> complete_chain_run

        IO.puts("chain_run complete")
        IO.inspect(updated_chain_run)
        updated_chain_run
      else
        updated_chain_run
      end
    else
      chain_run
    end
  end

  defp set_chain_run_status(chain_run, status) do
    case ChainService.update_chain_run(chain_run, %{status: status}) do
      {:ok, chain_run} ->
        chain_run

      {:error, changeset} ->
        IO.puts("Failed to update ChainRun status: #{inspect(changeset.errors)}")
        {:error, changeset.errors}
    end
  end

  defp update_step(chain_run, index, updates) do
    {:ok, updated_step} = ChainService.update_chain_run_event(
      Enum.at(chain_run.steps, index), updates
    )
    %{chain_run | steps: List.replace_at(chain_run.steps, index, updated_step)}
  end

  defp complete_chain_run(%{steps: steps} = chain_run) do
    start_timestamp = steps |> Enum.at(0) |> Map.get(:timestamp)
    end_timestamp = steps |> Enum.at(-1) |> Map.get(:timestamp)
    duration = end_timestamp - start_timestamp

    attrs = %{
      run_duration: duration,
      end_timestamp: DateTime.utc_now(),
      status: :completed
    }

    case ChainService.update_chain_run(chain_run, attrs) do
      {:ok, chain_run} ->
        chain_run

      {:error, changeset} ->
        IO.puts("Failed to update ChainRun status: #{inspect(changeset.errors)}")
        changeset.errors
    end
  end

  defp all_steps_completed?(chain_run) do
    Enum.all?(chain_run.steps, &(&1.status == :completed))
  end

  defp is_matching_event(event, step) do
    event.type == step.event_type
  end

  defp get_timestamp(%{timestamp: timestamp}) when is_binary(timestamp) do
    case DateTime.from_iso8601(timestamp) do
      {:ok, dt, _} -> DateTime.to_unix(dt, :millisecond)
      _ -> generate_timestamp()
    end
  end

  defp get_timestamp(%{timestamp: timestamp}) when is_integer(timestamp) do
    case timestamp do
      ts when is_integer(ts) and ts < 1_000_000_000_000 -> ts * 1_000 # Convert seconds to milliseconds
      _ -> timestamp # Already in milliseconds
    end
  end

  defp generate_timestamp(), do: DateTime.to_unix(DateTime.utc_now(), :millisecond)
end
