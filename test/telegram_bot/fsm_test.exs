defmodule TelegramBot.FsmTest do

  use WippliBackendWeb.ConnCase
  alias TelegramBot.FlowFsm
  alias TelegramBot.FsmServer
  import Wippli.Factory

  setup do
    insert(:user)
    insert(:zone)
    FsmServer.create("1")
    :ok
  end


  test "initial state is start" do
    fsm = FlowFsm.new
    assert fsm.state == :start
    states = FlowFsm.possible_events_from_state(fsm.state)
    assert states == [:polling]
  end


  test "return to polling if error  " do
    fsm = FlowFsm.new |> FlowFsm.start_polling("1") |> FlowFsm.join_zone("1") |> FlowFsm.return_to_polling()
    assert fsm.state == :polling
  end

  test "test start polling flow " do

    fsm = FlowFsm.new |> FlowFsm.start_polling("1")

    assert fsm.state == :polling
    assert fsm.data == %{telegram_id: "1", db_id: 1 }
  end
end
