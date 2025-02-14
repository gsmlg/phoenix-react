defmodule Phoenix.React.Server do
  @moduledoc """
  The React Render Server

  Start React Render server by setting.

  ```
  config :phoenix_react_server, Phoenix.React,
    runtime: Phoenix.React.Runtime.Bun,
    component_base: Path.expand("../assets/component", __DIR__),
    cache_ttl: 10
  ```

  """
  require Logger

  alias Phoenix.React.Cache
  alias Phoenix.React.Runtime

  use GenServer

  @type second() :: integer()
  @type millisecond() :: integer()

  def set_runtime_process(pid) do
    GenServer.cast(__MODULE__, {:set_runtime_process, pid})
  end

  @doc """
  Return the configuration of the React Render Server from `Application.get_env(:phoenix_react_server, Phoenix.React)`
  """
  @spec config() :: [
          {:cache_ttl, second()}
          | {:component_base, binary()}
          | {:render_timeout, millisecond()}
          | {:runtime, module()},
          ...
        ]
  def config() do
    config = Application.get_env(:phoenix_react_server, Phoenix.React)

    [
      runtime: config[:runtime] || Phoenix.React.Runtime.Bun,
      component_base: config[:component_base],
      cache_ttl: config[:cache_ttl] || 600,
      render_timeout: config[:render_timeout] || 300_000
    ]
  end

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init([]) do
    cfg = config()

    runtime = cfg[:runtime]
    component_base = cfg[:component_base]
    render_timeout = cfg[:render_timeout]
    args = [component_base: component_base, render_timeout: render_timeout]

    Runtime.start_runtime(runtime, args)

    {:ok,
     %{
       runtime: runtime,
       component_base: component_base,
       render_timeout: render_timeout
     }}
  end

  @impl true
  def handle_cast({:set_runtime_process, pid}, state) do
    {:noreply, Map.put(state, :runtiem_process, pid)}
  end

  @impl true
  def handle_call(
        {:render_to_readable_stream, component, props},
        _from,
        %{runtiem_process: runtiem_process} = state
      ) do
    reply =
      case Cache.get(component, props, :render_to_readable_stream) do
        nil ->
          render_timeout = config()[:render_timeout]

          case GenServer.call(
                 runtiem_process,
                 {:render_to_readable_stream, component, props},
                 render_timeout
               ) do
            {:ok, html} = reply ->
              Cache.put(component, props, :render_to_readable_stream, html)
              reply

            reply ->
              reply
          end

        html ->
          {:ok, html}
      end

    {:reply, reply, state}
  end

  def handle_call(
        {:render_to_string, component, props},
        _from,
        %{runtiem_process: runtiem_process} = state
      ) do
    reply =
      case Cache.get(component, props, :render_to_string) do
        nil ->
          render_timeout = config()[:render_timeout]

          case GenServer.call(
                 runtiem_process,
                 {:render_to_string, component, props},
                 render_timeout
               ) do
            {:ok, html} = reply ->
              Cache.put(component, props, :render_to_string, html)
              reply

            reply ->
              reply
          end

        html ->
          {:ok, html}
      end

    {:reply, reply, state}
  end

  def handle_call(
        {:render_to_static_markup, component, props},
        _from,
        %{runtiem_process: runtiem_process} = state
      ) do
    reply =
      case Cache.get(component, props, :render_to_static_markup) do
        nil ->
          render_timeout = config()[:render_timeout]

          case GenServer.call(
                 runtiem_process,
                 {:render_to_static_markup, component, props},
                 render_timeout
               ) do
            {:ok, html} = reply ->
              Cache.put(component, props, :render_to_static_markup, html)
              reply

            reply ->
              reply
          end

        html ->
          {:ok, html}
      end

    {:reply, reply, state}
  end

  def handle_call(:stop_runtime, _from, %{runtiem_process: runtiem_process} = state) do
    ok = GenServer.cast(runtiem_process, :shutdown)
    {:reply, ok, state}
  end
end
