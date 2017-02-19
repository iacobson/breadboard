defmodule Breadboard.Gpio.Supervisor do
  use Supervisor

  @gpio Application.get_env(:breadboard, :gpio)
  @cache Application.get_env(:breadboard, :cache)

  def start_link do
    result = Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    start_cached_components()
    result
  end

  def init(:ok) do
    children = [
      worker(@gpio, [], restart: :transient)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end

  def new_gpio(pin, io, name) do
    Supervisor.start_child(__MODULE__, [pin, io, [name: name]])
  end

  defp start_cached_components do
    @cache.get_components
    |> Enum.each(&start_cached_component/1)
  end

  defp start_cached_component(%{pin: pin, io: io, name: name}) do
    new_gpio(pin, io, name)
  end

end
