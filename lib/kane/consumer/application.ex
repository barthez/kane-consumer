defmodule Kane.Consumer.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: Kane.Consumer.PullSupervisor}
    ]

    opts = [strategy: :one_for_one, name: Kane.Consumer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
