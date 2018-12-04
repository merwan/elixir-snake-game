defmodule ElixirSnake.Scene.Game do
  use Scenic.Scene

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives, only: [rrect: 3, text: 3]

  @graph Graph.build(font: :roboto, font_size: 36)
  @frame_ms 192
  @tile_size 32
  @tile_radius 8
  @snake_starting_size 3
  @pellet_score 100

  def init(_arg, opts) do
    viewport = opts[:viewport]

    # Get the view port width and height
    {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

    {:ok, timer} = :timer.send_interval(@frame_ms, :frame)

    # calculate number of tiles
    vp_tile_width = trunc(vp_width / @tile_size)
    vp_tile_height = trunc(vp_height / @tile_size)

    # start with snake centered
    snake_start_coords = {
      trunc(vp_tile_width / 2),
      trunc(vp_tile_height / 2),
    }

    pellet_start_coords = {
      vp_tile_width - 2,
      trunc(vp_tile_height / 2),
    }

    state = %{
      viewport: viewport,
      tile_width: vp_tile_width,
      tile_height: vp_tile_height,
      graph: @graph,
      frame_count: 1,
      frame_timer: timer,
      score: 0,
      # Game objects
      objects: %{
        snake: %{
          body: [snake_start_coords],
          size: @snake_starting_size,
          direction: {1, 0},
        },
        pellet: pellet_start_coords,
      }
    }

    state.graph
    |> draw_score(state.score)
    |> draw_game_objects(state.objects)
    |> push_graph

    {:ok, state}
  end

  def handle_info(:frame, %{frame_count: frame_count} = state) do
    state = move_snake(state)

    state.graph
    |> draw_game_objects(state.objects)
    |> draw_score(state.score)
    |> push_graph

    {:noreply, %{state | frame_count: frame_count + 1}}
  end

  def handle_input({:key, {"left", :press, _}}, _context, state) do
    {:noreply, update_snake_direction(state,  {-1, 0})}
  end

  def handle_input({:key, {"right", :press, _}}, _context, state) do
    {:noreply, update_snake_direction(state,  {1, 0})}
  end

  def handle_input({:key, {"up", :press, _}}, _context, state) do
    {:noreply, update_snake_direction(state,  {0, -1})}
  end

  def handle_input({:key, {"down", :press, _}}, _context, state) do
    {:noreply, update_snake_direction(state,  {0, 1})}
  end

  def handle_input(_input, _context, state), do: {:noreply, state}

  defp update_snake_direction(state, direction) do
    put_in(state, [:objects, :snake, :direction], direction)
  end

  defp move_snake(%{objects: %{snake: snake}} = state) do
    [head | _] = snake.body
    new_head_pos = move(state, head, snake.direction)

    new_body = Enum.take([new_head_pos | snake.body], snake.size)

    state
    |> put_in([:objects, :snake, :body], new_body)
    |> maybe_eat_pellet(new_head_pos)
  end

  defp maybe_eat_pellet(%{objects: %{pellet: pellet_coords}} = state, new_head_pos)
  when pellet_coords == new_head_pos do
    state
    |> add_score(@pellet_score)
    |> randomize_pellet
    |> grow_snake
  end

  defp maybe_eat_pellet(state, _), do: state

  defp add_score(state, pellet_score) do
    update_in(state, [:score], &(&1 + pellet_score))
  end

  defp randomize_pellet(%{tile_width: tile_width, tile_height: tile_height} = state) do
    new_pellet_pos = {
      Enum.random(0..tile_width - 1),
      Enum.random(0..tile_height - 1),
    }
    validate_pellet_position(state, new_pellet_pos)
  end

  defp validate_pellet_position(%{objects: %{snake: %{body: snake_body}}} = state, new_pellet_pos) do
    if new_pellet_pos in snake_body do
      randomize_pellet(state)
    else
      put_in(state, [:objects, :pellet], new_pellet_pos)
    end
  end

  defp grow_snake(state) do
    update_in(state, [:objects, :snake, :size], &(&1 + 1))
  end

  defp move(%{tile_width: w, tile_height: h}, {pos_x, pos_y}, {vec_x, vec_y}) do
    {rem(pos_x + vec_x + w, w), rem(pos_y + vec_y + h, h)}
  end

  defp draw_score(graph, score) do
    graph
    |> text("Score: #{score}", fill: :white, translate: {@tile_size, @tile_size})
  end

  defp draw_game_objects(graph, object_map) do
    Enum.reduce(object_map, graph, fn {object_type, object_data}, graph ->
      draw_object(graph, object_type, object_data)
    end)
  end

  defp draw_object(graph, :snake, %{body: snake}) do
    Enum.reduce(snake, graph, fn {x, y}, graph ->
      draw_tile(graph, x, y, fill: :lime)
    end)
  end

  defp draw_object(graph, :pellet, {pellet_x, pellet_y}) do
    draw_tile(graph, pellet_x, pellet_y, fill: :yellow, id: :pellet)
  end

  defp draw_tile(graph, x, y, opts) do
    tile_opts = Keyword.merge([fill: :white, translate: {x * @tile_size, y * @tile_size}], opts)
    graph |> rrect({@tile_size, @tile_size, @tile_radius}, tile_opts)
  end
end
