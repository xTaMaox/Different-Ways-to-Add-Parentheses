defmodule Solution do
  @typep op :: (integer, integer -> integer)
  @typep token :: integer | op
  @typep ast :: integer | {op, ast, ast}

  @spec diff_ways_to_compute(expression :: String.t) :: [integer]
  def diff_ways_to_compute(expression) do
    tokens = tokenize(expression)
    ast = parse(hd(tokens), tl(tokens))
    Task.async(fn ->
      all_variation_results(ast, &rotate_right/1)
    end)
    |> Task.await(:infinity)
  end

  @spec all_variation_results(ast, (ast -> {:ok, ast} | :error)) :: [integer]
  defp all_variation_results({op, expr1, expr2} = ast, rotate) do
    memoized({rotate, ast}, fn ->
      results =
        for r1 <- all_variation_results(expr1, &rotate_right/1),
            r2 <- all_variation_results(expr2, &rotate_left/1),
            do: op.(r1, r2)

      case rotate.(ast) do
        {:ok, ast2} -> results ++ all_variation_results(ast2, rotate)
        :error -> results
      end
    end)
  end

  defp all_variation_results(num, _) do
    [num]
  end

  @spec rotate_right(ast) :: {:ok, ast} | :error
  defp rotate_right({
    op1,
    {op2, left2, right2},
    right1
  }) do
    {
      :ok,
      {
        op2,
        left2,
        {op1, right2, right1}
      }
    }
  end

  defp rotate_right(_), do: :error

  @spec rotate_left(ast) :: {:ok, ast} | :error
  defp rotate_left({
    op1,
    left1,
    {op2, left2, right2}
  }) do
    {
      :ok,
      {
        op2,
        {op1, left1, left2},
        right2
      }
    }
  end

  defp rotate_left(_), do: :error

  @spec parse(ast, [token]) :: ast
  defp parse(acc, []) do
    acc
  end

  defp parse(acc, [op, num | rest]) do
    parse({op, acc, num}, rest)
  end

  @spec tokenize(String.t) :: [token]
  defp tokenize(expression) do
    expression
    |> String.split(~r/\b/, trim: true)
    |> Enum.map(&to_token/1)
  end

  @spec to_token(String.t) :: token
  defp to_token(s) when s in ~w[+ - *], do: &apply(Kernel, String.to_atom(s), [&1, &2])
  defp to_token(s), do: String.to_integer(s)

  @spec memoized(any, (-> any)) :: any
  defp memoized(key, fun) do
    case Process.get(key) do
      nil ->
        value = fun.()
        Process.put(key, value)
        value
      value ->
        value
    end
  end
end
