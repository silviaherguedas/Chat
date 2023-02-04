defmodule ChatWeb.PrivateLive do
  use ChatWeb, :live_view

  alias Chat.RoomGenserver

  @impl Phoenix.LiveView
  def mount(params, _session, socket) do
    IO.inspect(params, label: "params")
    name_room =
      [params["username"], params["username_target"]]
      |> Enum.sort()
      |> Enum.join()
    # params["username"] <> "#" <> params["username_target"]
    state =
      case RoomGenserver.create([], name: name_room) do
        {:error, {:already_started, _pid}} ->
          RoomGenserver.join(name_room, params["username"], self())

        {:ok, pid} ->
          IO.inspect(pid, label: "RoomLive.mount.pidRoom")
          RoomGenserver.join(name_room, params["username"], self())
      end

    socket =
      socket
      |> assign(:room, name_room)
      |> assign(:user, params["username"])
      |> assign(:username_target, params["username_target"])
      |> assign(:messages, state.messages)

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_event("send_message", value, socket) do
    IO.inspect(value, label: "PrivateLive.send_message.value")
    IO.inspect(socket.assigns, label: "PrivateLive.send_message.socket.assigns")
    RoomGenserver.send_message(socket.assigns.room, socket.assigns.user, value["send_message"]["message"])
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:new_user, _username}, socket) do
    IO.inspect(socket.assigns, label: "PrivateLive.new_user.socket.assigns")
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({:new_message, username, message}, socket) do
    IO.inspect(socket.assigns, label: "PrivateLive.new_message.socket.assigns")

    {:noreply, assign(socket, :messages, socket.assigns.messages ++ [{username, message}])}
  end
end
