defmodule Breadboard.Gpio.ServerTest do
  use ExUnit.Case, async: true
  alias Breadboard.Gpio.Server

  setup do
    on_exit(fn() ->
      Supervisor.terminate_child(Breadboard.Supervisor, Server)
      Supervisor.restart_child(Breadboard.Supervisor, Server)
      Supervisor.terminate_child(Breadboard.Supervisor, Breadboard.Gpio.Supervisor)
      Supervisor.restart_child(Breadboard.Supervisor, Breadboard.Gpio.Supervisor)
      # Using Supervisor.terminate_child & Supervisor.restart_child
      # instead of GenServer.stop() as stop is not waiting for restart
      #
      # Need to restart Server as it holds state form previous test
      #
      # Need to restart the Supervisor as well in order to terminate the
      # created GPIO processes
    end)
    :ok
  end

  describe "component level functions" do
    test "new/4" do
      Server.new(:led_1, 17, :output)
      assert Server.current_components ==
        [%Server.Component{
          name: :led_1,
          pin: 17,
          io: :output,
          group: nil}
        ]
      assert :led_1 |> Process.whereis |> is_pid()
    end

    test "cannot create 2 components with the same name" do
      Server.new(:led_1, 17, :output)
      Server.new(:led_2, 18, :output)
      Server.new(:led_3, 19, :output)

      assert {:error, {:name, _error}} =
        Server.new(:led_2, 20, :output)
      assert Enum.count(Server.current_components()) == 3
    end

    test "cannot create 2 components on the same pin" do
      Server.new(:led_1, 17, :output)
      Server.new(:led_2, 18, :output)
      Server.new(:led_3, 19, :output)

      assert {:error, {:pin, _error}} =
        Server.new(:led_4, 18, :output)
      assert Enum.count(Server.current_components()) == 3
    end

    test "new_output/3" do
      Server.new_output(:led_2, 17)
      assert Server.current_components ==
        [%Server.Component{
          name: :led_2,
          pin: 17,
          io: :output,
          group: nil}
        ]
      assert :led_2 |> Process.whereis |> is_pid()
    end

    test "new_input/3" do
      Server.new_input(:button_1, 22)
      assert Server.current_components ==
        [%Server.Component{
          name: :button_1,
          pin: 22,
          io: :input,
          group: nil}
        ]
      assert :button_1 |> Process.whereis |> is_pid()
    end

    test "switch_on/1" do
      Server.new_output(:led_1, 17)
      assert Server.switch_on(:led_1) ==
        {:ok, :led_1, :on}
    end

    test "switch_off/1" do
      Server.new_output(:led_1, 17)
      assert Server.switch_off(:led_1) ==
        {:ok, :led_1, :off}
    end

    test "status/1" do
      Server.new_output(:led_1, 17)
      Server.switch_on(:led_1)
      assert Server.status(:led_1) ==
        {:ok, :led_1, :on}
    end

    test "create a button" do
      assert {:ok, %Server.Component{}} =
        Server.new_button(:button_1, 22)

      assert Server.current_components ==
        [%Breadboard.Gpio.Server.Component{
          name: :button_1,
          pin: 22,
          io: :input,
          group: nil}
        ]
      assert :button_1 |> Process.whereis |> is_pid()
    end

    test "cannot create a button when another component is started on the same pin" do
      Server.new_input(:button_1, 22)
      assert Server.new_button(:button_2, 22) ==
        {:error, {:pin, "One component per pin. button_1 already started on pin 22"}}

      assert :button_1 |> Process.whereis |> is_pid()
      refute :button_2 |> Process.whereis |> is_pid()
    end
  end

  describe "group level functions" do

  end

  describe "general functions" do
    # components

  end
end
