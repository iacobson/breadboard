defmodule Breadboard.Gpio.Cache do
  use GenServer

  # API

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get_components do
    GenServer.call(__MODULE__, {:get_components})
  end

  def update_components(components) do
    GenServer.cast(__MODULE__, {:update_components, components})
  end

  # CALLBACKS

  def init(:ok) do
    [gpio: state] = :ets.lookup(:cache, :gpio)
    {:ok, state}
  end

  def handle_call({:get_components}, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:update_components, components}, _state) do
    :ets.insert(:cache, {:gpio, components})
    {:noreply, components}
  end
end
