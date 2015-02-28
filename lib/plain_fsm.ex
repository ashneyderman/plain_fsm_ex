defmodule PlainFsm do

  defmacro __using__(_) do
    quote do
      import PlainFsm
    end
  end

  defmacro ereceive(opts) do
    parent_frag = quote do
      __fsm_parent = :plain_fsm.info(:parent)
    end

    {state_fun, arity} = __CALLER__.function
    unless arity == 1 do
      raise ArgumentError, state_fun_arity_msg(__CALLER__)
    end

    state_fun_args = Keyword.keys(__CALLER__.vars)
    unless length(state_fun_args) == 1 do
      raise ArgumentError, matched_args_limitation_msg
    end

    [state_var] = state_fun_args

    z = {state_var, [], :"Elixir"}
    [exit_frag] = quote do
        {:"EXIT",__fsm_parent,__fsm_reason} ->
          :plain_fsm.parent_EXIT(__fsm_reason, var!(unquote(z)))
    end

    [system_frag] = quote do
        {:"system",__fsm_from,__fsm_req} ->
          :plain_fsm.handle_system_msg(__fsm_req,
                                       __fsm_from,
                                       var!(unquote(z)),
                                       fn(__fsm_sx) ->
                                         unquote(state_fun)(__fsm_sx)
                                       end)
    end

    l = opts[:do] 
          |> List.insert_at(0, exit_frag)
          |> List.insert_at(0, system_frag)
    opts = Keyword.put(opts, :do, l)
    receive_frag = {:receive, [],[opts]}
    quote do
      unquote(parent_frag)
      unquote(receive_frag)
    end
  end

  defmacro hibernate(m,state_name,args) do
    quote do
      :erlang.hibernate(:plain_fsm,
                        :wake_up,
                        [data_vsn(),unquote(m),unquote(m),unquote(state_name),unquote(args)])
    end
  end

  defp state_fun_arity_msg(%{function: {state_fun,arity}}) do
    "State function has to be of arity 1. Your state function is #{state_fun}/#{arity}"
  end 

  defp matched_args_limitation_msg do
    """
    At present ereceive is not able to differentiate between matched and passed 
    arguments, so something like this 
      
    def idle(%{"timeout" => t}=state) do
      ...
    end

    is not yet possible. Please, declare your state function like so

    def idle(state) do
      %{"timeout" => t} = state
      ...
    end
    """ 
  end

end
