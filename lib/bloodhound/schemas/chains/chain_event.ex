defmodule Bloodhound.Schemas.Chains.ChainEvent do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chain_events" do
    field :event_type, :string
    field :type, :string
    field :key_field, :string
    belongs_to :chain, Bloodhound.Schemas.Chains.Chain
    timestamps()
  end

  @types ~w(kafka http)a

  def changeset(chain_event, attrs) do
    chain_event
    |> cast(attrs, [:chain_id, :event_type, :type, :key_field])
    |> validate_required([:chain_id, :event_type, :type, :key_field])
    |> validate_inclusion(:type, @types)
  end
end
