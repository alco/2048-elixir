defmodule SlidingNumbers.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      ## SlidingNumbersWeb.Telemetry,
      # Start the Ecto repository
      ## SlidingNumbers.Repo,
      # Start the PubSub system
      ## {Phoenix.PubSub, name: SlidingNumbers.PubSub},
      # Start the Endpoint (http/https)
      ## SlidingNumbersWeb.Endpoint
      # Start a worker by calling: SlidingNumbers.Worker.start_link(arg)
      # {SlidingNumbers.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
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
