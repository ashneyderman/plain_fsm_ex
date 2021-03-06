defmodule PlainFsmTest do
  use ExUnit.Case
  require Logger

  defmodule ExmpleFsm do
    use PlainFsm

    defp do_init(init_state) do
      :erlang.process_flag(:trap_exit, true)
      idle(init_state)
    end

    def spawn_link(init_state) do
      link_fsm(fn -> do_init(init_state) end)
    end

    def spawn(init_state) do
      spawn_fsm(fn -> do_init(init_state) end)
    end

    def idle(%{"timeout" => timeout, "events" => events} = map) do
      ereceive do 
        :stop ->  :ok
        {from, ref, :stop} ->
          send(from, {ref, events})
          :ok
        {:event, event} ->
          idle(update_in(map["events"], fn(evts) -> [event | evts] end))
      after timeout ->
        idle(update_in(map["events"], fn(evts) -> [:idle | evts] end))
      end
    end
  end

  test "assert sys info response" do
    fsm = ExmpleFsm.spawn_link(%{"timeout" => 500, "events" => []})
    sys_info = :sys.get_status(fsm)
    Logger.debug "sys_info: #{inspect sys_info}"
    assert {:status, _, _, _} = sys_info
    send(fsm, :stop)
  end

  test "assert after clause works" do
    fsm = ExmpleFsm.spawn_link(%{"timeout" => 100, "events" => []})
    :timer.sleep(510)
    ref = :erlang.make_ref
    send(fsm, {self(), ref, :stop})
    receive do
      {^ref, result} ->
        Logger.debug("result: #{inspect result}")
        assert 5 == length(result) 
    after 500 ->
      flunk "Unable to fetch final state!"
    end
  end 

  test "assert receive clauses" do
    fsm = ExmpleFsm.spawn_link(%{"timeout" => 5000, "events" => []})
    for _i <- 1..10, do: send(fsm, {:event, :zipp})

    ref = :erlang.make_ref
    send(fsm, {self(), ref, :stop})
    receive do
      {^ref, result} ->
        Logger.debug("result: #{inspect result}")
        assert 10 == length(result) 
    after 500 ->
      flunk "Unable to fetch final state!"
    end
  end


end
