defmodule Bloodhound.Schemas.Chains.ChainRun do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chain_runs" do
    field :run_duration, :integer
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime
    field :attempt_id, :string
    field :status, Ecto.Enum, values: [:waiting, :processing, :completed, :failed, :timeout]
    has_many :steps, Bloodhound.Schemas.Chains.ChainRunEvent
    belongs_to :chain, Bloodhound.Schemas.Chains.Chain
    timestamps()
  end

  @required_fields ~w(attempt_id start_time status chain_id)a
  @optional_fields ~w(end_time run_duration)a

  def changeset(chain_run, attrs) do
    chain_run
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> cast_assoc(:steps)
  end
end
