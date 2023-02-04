defmodule Chat.RoomGenserver do
  use GenServer

  # Client
  @spec create(list, Keyword.t()) :: :ignore | {:error, any} | {:ok, pid}
  def create(args \\ [], opts \\ []) do
    name = Keyword.get(opts, :name)
    name = Chat.Utils.transform_test_to_atom(name)

    GenServer.start(__MODULE__, args, name: name)
  end

  @spec send_message(binary | atom, binary, binary) :: :ok
  def send_message(name_room, username, message) do
    {name_room, username} = transform_test(name_room, username)

    GenServer.cast(name_room, {:send_message, username, message})
  end

  @spec join(binary | atom, binary, pid) :: term()
  def join(name_room, username, pid) do
    {name_room, username} = transform_test(name_room, username)

    GenServer.call(name_room, {:join, username, pid})
  end

  @spec send_private_room(binary | atom, binary, binary) :: :ok
  def send_private_room(name_room, username_target, message) do
    {name_room, username_target} = transform_test(name_room, username_target)

    GenServer.cast(name_room, {:send_private_room, username_target, message})
  end

  # Callbacks
  @impl GenServer
  def init(_opts) do
    {:ok, %{users: %{}, messages: []}}
  end

  @impl GenServer
  def handle_call({:join, username, pid}, _from,  state) do
    state = %{state | users: Map.put(state.users, username, pid)}
    IO.inspect(state, label: "RoomGenserver.join.state")

    send_event(state.users, {:new_user, username})

    response = %{users: get_users(state.users), messages: state.messages}
    {:reply, response, state}
  end

  @impl GenServer
  def handle_cast({:send_message, username, message}, state) do
    state = %{state | messages: [{username, message} | state.messages]}
    IO.inspect(state, label: "RoomGenserver.send_message.state")

    send_event(state.users, {:new_message, username, message})

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:send_private_room, username_target, message}, state) do
    IO.inspect("RoomGenserver.send_private_room")

    state.users
    |> get_pid(username_target)
    |> send({:private_room_notification, message})

    {:noreply, state}
  end

  # private functions
  @spec send_event(map, any) :: :ok
  defp send_event(users, event) do
    users
    |> get_pids()
    |> Enum.each(&send(&1, event))
  end

  @spec get_users(map) :: [pid]
  defp get_users(users) do
    Enum.map(users, fn {user, _pid} -> user end)
  end

  @spec get_pids(map) :: [pid]
  defp get_pids(users) do
    Enum.map(users, fn {_user, pid} -> pid end)
  end

  @spec get_pid(map, atom) :: pid
  defp get_pid(users, username_target) do
    users
    |> Enum.filter(fn {user, _pid} -> user == username_target end)
    |> Enum.map(fn {_user, pid} -> pid end)
    |> List.first()
  end

  @spec transform_test(binary | atom, binary) :: tuple
  defp transform_test(name_room, username) when is_binary(name_room) and is_binary(username) do
    name_room = Chat.Utils.transform_test_to_atom(name_room)
    username = Chat.Utils.transform_test_to_atom(username)

    {name_room, username}
  end

  defp transform_test(name_room, username) when is_atom(name_room) and is_binary(username) do
    username = Chat.Utils.transform_test_to_atom(username)
    {name_room, username}
  end

  defp transform_test(name_room, username) when is_binary(name_room) and is_atom(username) do
    name_room = Chat.Utils.transform_test_to_atom(name_room)
    {name_room, username}
  end
end
