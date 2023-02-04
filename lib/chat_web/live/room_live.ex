defmodule ChatWeb.RoomLive do
  use ChatWeb, :live_view

  alias Chat.RoomGenserver

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    IO.inspect(params, label: "params")

    state =
      case RoomGenserver.create([], name: params["room_name"]) do
        {:error, {:already_started, _pid}} ->
          RoomGenserver.join(params["room_name"], params["username"], self())

        {:ok, pid} ->
          IO.inspect(pid, label: "RoomLive.mount.pidRoom")
          RoomGenserver.join(params["room_name"], params["username"], self())
      end

    socket =
      socket
      |> assign(:room, params["room_name"])
      |> assign(:user, params["username"])
      |> assign(:users, state.users)
      |> assign(:messages, state.messages)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("send_message", value, socket) do
    IO.inspect(value, label: "RoomLive.send_message.value")
    IO.inspect(socket.assigns, label: "RoomLive.send_message.socket.assigns")
    RoomGenserver.send_message(socket.assigns.room, socket.assigns.user, value["send_message"]["message"])
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("private_room", value, socket) do
    IO.inspect(value, label: "RoomLive.private_room.value")
    IO.inspect(socket.assigns, label: "RoomLive.private_room.socket.assigns")
    user_name = String.capitalize(socket.assigns.user)
    username_target = value["username_target"]
    name_room = socket.assigns.user <> "#" <> username_target
    message = """
        #{user_name}, wants to talk. <a href="/private/#{username_target}/#{socket.assigns.user}">Go to a room.</a>
        """

    case RoomGenserver.create([], name: name_room) do
      {:error, {:already_started, _pid}} -> :error
      {:ok, pid} ->
        IO.inspect(pid, label: "RoomLive.private_room.pidRoom")
        :ok
    end

    RoomGenserver.send_private_room(socket.assigns.room, username_target, message)
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:new_user, username}, socket) do
    IO.inspect(socket.assigns, label: "RoomLive.new_user.socket.assigns")
    users =
      socket.assigns.users
      |> MapSet.new()
      |> MapSet.put(username)
      |> MapSet.to_list()

    {:noreply, assign(socket, :users, users)}
  end

  @impl Phoenix.LiveView
  def handle_info({:new_message, username, message}, socket) do
    IO.inspect(socket.assigns, label: "RoomLive.new_message.socket.assigns")

    {:noreply, assign(socket, :messages, socket.assigns.messages ++ [{username, message}])}
  end

  @impl Phoenix.LiveView
  def handle_info({:private_room_notification, message}, socket) do
    IO.inspect("RoomLive.private_room_notification")
    {:noreply, put_flash(socket, :info, raw(message))}
  end
end
