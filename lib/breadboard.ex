defmodule Breadboard do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    :ets.new(:cache, [:set, :public, :named_table])
    :ets.insert(:cache, {:gpio, []})

    children = [
      worker(Breadboard.Gpio.Cache, []),
      worker(Breadboard.Gpio.Server, []),
      supervisor(Breadboard.Gpio.Supervisor, [])
    ]

    opts = [strategy: :one_for_one, name: Breadboard.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
