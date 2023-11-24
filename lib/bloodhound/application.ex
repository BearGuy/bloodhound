defmodule Bloodhound.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      BloodhoundWeb.Telemetry,
      # Start the Ecto repository
      Bloodhound.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Bloodhound.PubSub},
      # Start Finch
      {Finch, name: Bloodhound.Finch},
      # Start the Endpoint (http/https)
      BloodhoundWeb.Endpoint,
      # Start a worker by calling: Bloodhound.Worker.start_link(arg)
      # {Bloodhound.Worker, arg}
      {Bloodhound.KafkaConsumer, []},
      {Bloodhound.Chains.ChainSupervisor, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bloodhound.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BloodhoundWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
