defmodule ElixirSnake.Scene.Game do
  use Scenic.Scene

  alias Scenic.Graph

  import Scenic.Primitives, only: [text: 3]

  @graph Graph.build(font: :roboto, font_size: 36)
  @tile_size 32

  def init(_arg, opts) do
    viewport = opts[:viewport]

    state = %{
      viewport: viewport,
      graph: @graph,
      score: 0,
    }

    state.graph
    |> draw_score(state.score)
    |> push_graph

    {:ok, state}
  end

  defp draw_score(graph, score) do
    graph
    |> text("Score: #{score}", fill: :white, translate: {@tile_size, @tile_size})
  end
end
