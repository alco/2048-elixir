defmodule SlidingNumbers.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the PubSub system
      {Phoenix.PubSub, name: SlidingNumbers.PubSub},
      # Start the Endpoint (http/https)
      SlidingNumbersWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: SlidingNumbers.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SlidingNumbersWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
