defmodule Breadboard.Gpio.Server do
  use GenServer
  alias Breadboard.Gpio.Supervisor

  @gpio Application.get_env(:breadboard, :gpio)
  @cache Application.get_env(:breadboard, :cache)

  defmodule Component do
    defstruct name: nil,
              pin: nil,
              io: nil,
              group: nil
  end

  # API

  # TODO: return error when providing wrong name, group etc for a function

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def new(name, pin, io, group \\ nil) # function head

  def new(name, pin, io, group)
    when  is_atom(name) and
          is_integer(pin) and
          is_atom(io) and
          is_atom(group) do

    component_valid?(name, pin, io, group)
  end

  def new(_, _, _, _), do: {:error, "Incorrect arguments"}

  def new_output(name, pin, group \\ nil) do
    new(name, pin, :output, group)
  end

  def new_input(name, pin, group \\ nil) do
    new(name, pin, :input, group)
  end

  def new_button(name, pin, group \\ nil) do
    create_button(name, pin, group)
  end

  def switch_on(name) do
    switch(name, :on, 1)
  end

  def switch_off(name) do
    switch(name, :off, 0)
  end

  def status(name) do
    get_status_for_name(name)
  end

  def current_components do
    GenServer.call(__MODULE__, {:components})
  end

  # CALLBACKS

  def init(:ok) do
    state = @cache.get_components()
    {:ok, state}
  end

  def handle_call({:new, name, pin, io, group}, _from, state) do
    case Supervisor.new_gpio(pin, io, name) do
      {:ok, _pid} ->
        comp = struct(Component, [name: name, pin: pin, io: io, group: group])
        state = [comp | state]
        @cache.update_components(state)
        {:reply, {:ok, comp}, state}
      error ->
        {:reply, error, state}
    end
  end

  def handle_call({:components}, _from, state) do
    {:reply, state, state}
  end



  # HELPERS

  defp switch(name, action, value) do
    components = current_components()

    with  %Component{io: :output} <- Enum.find(components, &(&1.name == name)),
          :ok <- @gpio.write(name, value) do
      {:ok, name, action}
    else
      %Component{io: :input} -> {:error, name, "Switch works only for :output components"}
      {:error, error} -> {:error, name, error}
      _ -> {:error, name, "Could not find component #{name}"}
    end
  end

  defp get_status_for_name(name) do
    components = current_components()

    with  %Component{} <- Enum.find(components, &(&1.name == name)),
          status when is_integer(status) <- @gpio.read(name) do
      {:ok, name, get_status(name, status)}
    else
      {:error, error} -> {:error, name, error}
      _ -> {:error, name, "Cannot find component #{name}"}
    end
  end

  defp get_status(_name, 0), do: :off
  defp get_status(_name, status) when is_integer(status), do: :on
  defp get_status(name, _), do: {:error, name, "Wrong status"}

  defp create_button(name, pin, group) do
    case new_input(name, pin, group) do
      response = {:ok, _response} ->
        @gpio.set_int(name, :both)
        response
      error = {:error, _error} ->
        error
      error ->
        {:error, error}
    end
  end

  defp component_valid?(name, pin, io, group) do
    components = current_components()

    with  nil <- Enum.find(components, &(&1.name == name)),
          nil <- Enum.find(components, &(&1.pin == pin)) do
      GenServer.call(__MODULE__, {:new, name, pin, io, group})
    else
      %{name: ^name, pin: pin} ->
        {:error, {:name, "Name must be unique. #{name} already started on pin #{pin}"}}
      %{pin: ^pin, name: name} ->
        {:error, {:pin, "One component per pin. #{name} already started on pin #{pin}"}}
      _ ->
        {:error, "component invalid"}
    end
  end
end
