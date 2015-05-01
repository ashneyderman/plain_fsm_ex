defmodule PlainFsm do

  defmacro __using__(_) do
    quote do
      import Kernel, except: [def: 2]
      import PlainFsm
    end
  end

  defmacro def(definition, do: content) do
    wdefinition = wrap_params(definition)
    quote do
      Kernel.def(unquote(wdefinition)) do
        unquote(content)
      end
    end
  end

  defmacro link_fsm(f) do
    module = __CALLER__.module
    quote do
      :plain_fsm.spawn_link(unquote(module), unquote(f))
    end
  end

  defmacro spawn_fsm(f) do
    module = __CALLER__.module
    quote do
      :plain_fsm.spawn(unquote(module), unquote(f))
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

    z = {:__state_param1, [], :"Elixir"}
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

  defp wrap_params({name, ctx, [param]}) do
    params1 = [param, {:__state_param1,ctx,nil}]
    {name,ctx,[{:=, ctx, params1}]}
  end
  defp wrap_params(definition), do: definition

end
