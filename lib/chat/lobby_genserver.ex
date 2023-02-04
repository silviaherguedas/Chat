defmodule Chat.LobbyGenserver do
  use GenServer

  # Client
  @spec start(list) :: :ignore | {:error, any} | {:ok, pid}
  def start(args \\ []) do
    GenServer.start(__MODULE__, args, name: __MODULE__)
  end

  @spec create_room(binary) :: :ok
  def create_room(name) do
    GenServer.cast(__MODULE__, {:create_room, name})
  end

  @spec join(pid()) :: :ok
  def join(pid) do
    GenServer.call(__MODULE__, {:join, pid})
  end

  # Callbacks
  @impl GenServer
  def init(_opts) do
    {:ok, %{rooms: MapSet.new(), pids: MapSet.new()}}
  end

  @impl GenServer
  def handle_cast({:create_room, name}, state) do
    IO.inspect(name, label: "LobbyGS.create_room.name")
    name = Chat.Utils.transform_test_to_atom(name)

    if name not in state.rooms do
      state = %{state | rooms: MapSet.put(state.rooms, name)}

      case Chat.RoomGenserver.create([], name: name) do
        {:error, {:already_started, _pid}} -> :error
        {:ok, pid} ->
          IO.inspect(pid, label: "LobbyGS.create_room.pidRoom")
          :ok
      end

      Enum.each(state.pids, &send(&1, {:create_room, name}))
      IO.inspect(state, label: "LobbyGS.create_room.state")
      {:noreply, state}
    else
      IO.inspect(state, label: "LobbyGS.create_room.state")
      {:noreply, state}
    end
  end

  @impl GenServer
  def handle_call({:join, pid}, _from, state) do
    state = %{state | pids: MapSet.put(state.pids, pid)}
    IO.inspect(state, label: "LobbyGS.join.state")
    {:reply, state.rooms, state}
    # if pid not in state.pids do
    #   state = %{state | pids: [pid | state.pids]}
    #   IO.inspect(state, label: "LobbyGS.join.state")
    #   {:noreply, state}
    # else
    #   IO.inspect(state, label: "LobbyGS.join.state")
    #   {:noreply, state}
    # end
  end
end
