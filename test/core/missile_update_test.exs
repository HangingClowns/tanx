defmodule Tanx.MissileUpdateTest do
  use ExUnit.Case

  setup do
    structure = %Tanx.Core.Structure{
      height: 20.0, width: 20.0,
      walls: [
        [{-5, -1}, {-5, 1}]
      ]
    }
    {:ok, game} = Tanx.Core.Game.start_link(clock_interval: nil, structure: structure)
    game |> Tanx.Core.Game.manual_clock_tick(1000)
    {:ok, player} = game |> Tanx.Core.Game.connect(name: "Ben")
    :ok = player |> Tanx.Core.Player.new_tank()
    {:ok, game: game, player: player}
  end

  test "missile moves at constant velocity", %{game: game, player: player} do
    :ok = player |> Tanx.Core.Player.new_missile()

    game |> Tanx.Core.Game.manual_clock_tick(2000)

    _check_missile(player, 10.0, 0.0, 0.0)
  end

  test "missile moves on an angle with constant velocity", %{game: game, player: player} do
    :ok = player |> Tanx.Core.Player.control_tank(:right, true)

    game |> Tanx.Core.Game.manual_clock_tick(2000)
    assert :ok = player |> Tanx.Core.Player.new_missile()

    game |> Tanx.Core.Game.manual_clock_tick(2000)

    # Missile has been created at the origin
    _check_missile(player, 0, 0, -2.0)

    game |> Tanx.Core.Game.manual_clock_tick(4000)

    # Missile should have changed position, but maintained the same angle.
    # View rounds to hundredths.
    _check_missile(player, -8.32, -18.19, -2.0)
  end

  # Utils

  defp _check_missile(player, x, y, a) do
    view = player |> Tanx.Core.Player.view_arena_objects()
    IO.inspect view
    assert view != []
    got = view.missiles |> hd()
    want = %Tanx.Core.View.Missile{is_mine: true, x: x, y: y, heading: a}
    assert got == want
  end

end
