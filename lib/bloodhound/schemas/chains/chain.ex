defmodule Bloodhound.Schemas.Chains.Chain do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chains" do
    field :name, :string
    field :description, :string
    field :timeout, :integer
    field :initial_event_type, :string
    has_many :chain_events, Bloodhound.Schemas.Chains.ChainEvent
    has_many :chain_runs, Bloodhound.Schemas.Chains.ChainRun
    timestamps()
  end

  def changeset(chain, attrs) do
    chain
    |> cast(attrs, [:name, :description, :timeout, :initial_event_type])
    |> validate_required([:name, :description, :timeout, :initial_event_type])
    |> unique_constraint(:name)
    |> cast_assoc(:chain_events)
  end
end
