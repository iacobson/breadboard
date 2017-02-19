defmodule Dev.Gpio do
  use GenServer

  defmodule State do
    defstruct pin: nil,
              direction: nil,
              status: 0
  end

  # HELPER FUNTCTIONS FOR DEV & TEST

  # transition should be :rising or :falling to simulate set_int
  def interrupt(pid, transition) do
    GenServer.cast(pid, {:interrupt, transition, self()})
  end


  # API

  def start_link(pin, direction, opts \\ []) do
    GenServer.start_link(__MODULE__, [pin, direction], opts)
  end

  def write(pid, value) do
    GenServer.call(pid, {:write, value})
  end

  def read(pid) do
    GenServer.call(pid, {:read})
  end

  def set_int(_pid, _transition) do
    :ok
  end

  # CALLBACKS

  def init([pin, direction]) do
    state = %State{pin: pin, direction: direction}
    {:ok, state}
  end

  def handle_call({:write, value}, _from, state) do
    state = %{state | status: value}
    {:reply, :ok, state}
  end

  def handle_call({:read}, _from, state) do
    {:reply, state.status, state}
  end

  def handle_cast({:interrupt, transition, pid}, state) do
    send(pid, {:gpio_interrupt, state.pin, transition})
    {:noreply, state}
  end

end
