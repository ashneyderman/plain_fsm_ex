defmodule FsmExample do
  use PlainFsm
  require Logger

  def spawn_link do
    link_fsm(fn ->
                  :erlang.process_flag(:trap_exit, true)
                  idle(:mystate)
                 end)
  end

  def spawn do
    spawn_fsm(fn ->
                  :erlang.process_flag(:trap_exit, true)
                  idle(:mystate)
                 end)
  end

  def idle(s) do
    ereceive do
      :a ->
        Logger.debug "going from idle state to state a"
        hibernate(__MODULE__,:a,[s])
      :b ->
        Logger.debug "going from idle state to state b"
        b(s)
      after 10000 ->
        Logger.debug "timeout in idle, going to idle"
        idle(s)
    end
  end

  def a(s) do
    receive do
      :b ->
        Logger.debug "going from state a to state b"
        eventually_b(s);
      :idle ->
        Logger.debug "going from state a to idle state"
        idle(s)
    end
  end

  def b(s) do
    receive do
      :a ->
        Logger.debug "going from state b to state a"
        a(s)
      :idle ->
        Logger.debug "going from state b to idle state"
        idle(s)
      after 10000 ->
        Logger.debug "timeout in b, going to idle state"
        idle(s)
    end
  end

  def data_vsn, do: 5

  def code_change(_OldVsn, _State, _Extra) do
    {:ok, {:newstate, data_vsn}}
  end

  def eventually_b(s), do: hibernate(__MODULE__,:b,[s])
  
end
