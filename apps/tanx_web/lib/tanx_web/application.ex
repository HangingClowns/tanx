defmodule TanxWeb.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the endpoint when the application starts
      supervisor(TanxWeb.Endpoint, [])
      # Start your own worker by calling: TanxWeb.Worker.start_link(arg1, arg2, arg3)
      # worker(TanxWeb.Worker, [arg1, arg2, arg3]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TanxWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def start_game(display_name) do
    game_spec = Tanx.ContinuousGame.create(maze: :standard)
    {:ok, game_id} = Tanx.GameSwarm.start_game(game_spec, display_name: display_name)

    {:ok, meta} = Tanx.Game.get_meta({:via, :swarm, game_id})

    TanxWeb.Endpoint.broadcast!("lobby", "started", meta)
    Tanx.Game.add_callback({:via, :swarm, game_id}, Tanx.ContinuousGame.PlayersChanged, :tanxweb, fn event ->
      TanxWeb.Endpoint.broadcast!("game:" <> game_id, "view_players", event)
      if Enum.empty?(event.players) do
        spawn(fn ->
          Tanx.Game.terminate({:via, :swarm, game_id})
        end)
      else
        nil
      end
    end)
    Tanx.Game.add_callback({:via, :swarm, game_id}, Tanx.Game.Notifications.Ended, :tanxweb, fn _event ->
      TanxWeb.Endpoint.broadcast!("lobby", "ended", %{id: game_id})
    end)

    {:ok, meta}
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TanxWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end