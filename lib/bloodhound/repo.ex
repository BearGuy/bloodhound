defmodule Bloodhound.Repo do
  use Ecto.Repo,
    otp_app: :bloodhound,
    adapter: Ecto.Adapters.Postgres
end
