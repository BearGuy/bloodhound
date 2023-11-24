defmodule BloodhoundWeb.EventController do
  use BloodhoundWeb, :controller
  alias Bloodhound.Chains.ChainService

  def create(conn, %{"event" => event_params}) do
    event = ChainService.normalize_chain_event(event_params)
    case ChainService.process_event(event) do
      {:ok, _chain_run} ->
        conn
        |> put_status(:created)
        |> json(%{message: "Event processed successfully"})
      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{message: "Error processing events", details: reason})
    end
  end
end
