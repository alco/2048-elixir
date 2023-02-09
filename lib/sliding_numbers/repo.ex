defmodule SlidingNumbers.Repo do
  use Ecto.Repo,
    otp_app: :sliding_numbers,
    adapter: Ecto.Adapters.Postgres
end
