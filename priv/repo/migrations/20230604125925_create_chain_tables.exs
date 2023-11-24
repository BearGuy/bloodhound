defmodule Bloodhound.Repo.Migrations.CreateChainTables do
  use Ecto.Migration

  def change do
    create table(:chains) do
      add :name, :string
      add :description, :string
      add :timeout, :integer
      add :initial_event_type, :string

      timestamps()
    end

    create table(:chain_events) do
      add :event_type, :string
      add :type, :string
      add :key_field, :string
      add :chain_id, references(:chains, on_delete: :delete_all)

      timestamps()
    end
    create index(:chain_events, [:chain_id])

    create table(:chain_runs) do
      add :status, :string
      add :run_duration, :integer
      add :start_time, :utc_datetime
      add :end_time, :utc_datetime
      add :attempt_id, :string
      add :chain_id, references(:chains, on_delete: :delete_all)

      timestamps()
    end
    create index(:chain_runs, [:chain_id])

    create table(:chain_run_events) do
      add :status, :string
      add :event_type, :string
      add :event, :map
      add :timestamp, :bigint
      add :chain_run_id, references(:chain_runs, on_delete: :delete_all)

      timestamps()
    end
  end
end
