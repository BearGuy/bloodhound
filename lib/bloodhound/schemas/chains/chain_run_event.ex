defmodule Bloodhound.Schemas.Chains.ChainRunEvent do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chain_run_events" do
    field :event_type, :string
    field :event, :map
    field :timestamp, :integer
    field :status, Ecto.Enum, values: [:waiting, :processing, :completed, :failed, :timeout]
    belongs_to :chain_run, Bloodhound.Schemas.Chains.ChainRun
    timestamps()
  end

  @required_fields ~w(status event_type)a
  @optional_fields ~w(chain_run_id event timestamp)a

  def changeset(chain_run_event, attrs) do
    chain_run_event
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
