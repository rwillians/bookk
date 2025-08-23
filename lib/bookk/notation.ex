# credo:disable-for-this-file Credo.Check.Refactor.ABCSize
#
#   NOTE: C'est la vie
#
defmodule Bookk.Notation do
  @moduledoc ~S"""
  DSL notation for describing an interledger entries
  (`Bookk.InterledgerEntry`).

  ## Related

  - `Bookk.ChartOfAccounts`;
  - `Bookk.InterledgerEntry`;
  - `Bookk.NaiveState`.
  """

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [journalize: 2]
    end
  end

  @doc ~S"""
  DSL notation for describing an interledger entries
  (`Bookk.InterledgerEntry`).

  ## Options

  - `using` (required): your chart of accounts module;
  - `compact`: whether the resulting interledger entry should be
    compacted, where postings to the same account are merged,
    guaranteeing a single post per account. Defaults to `false`.
  - `on_unbalanced`: either `:nothing` or `:raise`, controls the
    desired behaviour for when `journalize/2` produces a unbalanced
    interledger entry. Defaults to `:nothing`.

  ## Examples

  Returns a balanced interledger journal entry:

      iex> use Bookk.Notation
      iex>
      iex> %Bookk.InterledgerEntry{} = journal_entry =
      iex>   journalize using: DummyChartOfAccounts do
      iex>     on ledger(:acme) do
      iex>       debit account(:cash), Decimal.new(150)
      iex>       credit account(:deposits), Decimal.new(150)
      iex>     end
      iex>   end
      iex>
      iex> assert not Bookk.InterledgerEntry.empty?(journal_entry)
      iex> assert Bookk.InterledgerEntry.balanced?(journal_entry)

  Returns an unbalanced interledger journal entry:

      iex> use Bookk.Notation
      iex>
      iex> %Bookk.InterledgerEntry{} = journal_entry =
      iex>   journalize using: DummyChartOfAccounts do
      iex>     on ledger(:acme) do
      iex>       debit account(:cash), Decimal.new(150)
      iex>       credit account(:deposits), Decimal.new(50)
      iex>     end
      iex>   end
      iex>
      iex> assert not Bookk.InterledgerEntry.empty?(journal_entry)
      iex> assert not Bookk.InterledgerEntry.balanced?(journal_entry)

  You can do basic arithmetic operations with amounts even though they
  are most likely `Decimal` structs. The supported operations are
  addition, subtraction, multiplication and division where you can mix
  and match the use of `Decimal` amounts with integer or float amounts
  since they will automatically be converted into `Decimal`. These
  operations will be replaced by `Decimal.add/2`, `Decimal.sub/2`,
  `Decimal.mul/2` and `Decimal.div/2` respectively.

      iex> use Bookk.Notation
      iex>
      iex> foo = %{amount: 50}
      iex>
      iex> journalize using: DummyChartOfAccounts do
      iex>   on ledger(:acme) do
      iex>     debit account(:cash), ((%Decimal{exp: 0, sign: 1, coef: 100} + Decimal.new(100) - foo.amount) * 2) / 2
      iex>     credit account(:deposits), ((Decimal.new(100) + foo.amount) * Decimal.new(2)) / Decimal.new(2)
      iex>   end
      iex> end
      Bookk.InterledgerEntry.new([
        {"acme", Bookk.JournalEntry.new([
          debit(fixture_account_head(:cash), Decimal.new(150)),
          credit(fixture_account_head(:deposits), Decimal.new(150))
        ])}
      ])

  It's possible to post multiple times to the same ledger inside the
  interledger entry:

      iex> use Bookk.Notation
      iex>
      iex> journalize using: DummyChartOfAccounts do
      iex>   on ledger(:acme) do
      iex>     debit account(:cash), 50
      iex>     credit account(:deposits), 50
      iex>   end
      iex>
      iex>   on ledger(:acme) do
      iex>     debit account(:cash), 100
      iex>     credit account(:deposits), 100
      iex>   end
      iex> end
      Bookk.InterledgerEntry.new([
        {"acme", Bookk.JournalEntry.new([
          debit(fixture_account_head(:cash), Decimal.new(50)),
          credit(fixture_account_head(:deposits), Decimal.new(50))
        ])},
        {"acme", Bookk.JournalEntry.new([
          debit(fixture_account_head(:cash), Decimal.new(100)),
          credit(fixture_account_head(:deposits), Decimal.new(100))
        ])}
      ])

  You can compact multiple postings to the same ledger into a single
  post:

      iex> use Bookk.Notation
      iex>
      iex> journalize using: DummyChartOfAccounts, compact: true do
      iex>   on ledger(:acme) do
      iex>     debit account(:cash), 50
      iex>     credit account(:deposits), 50
      iex>   end
      iex>
      iex>   on ledger(:acme) do
      iex>     debit account(:cash), 100
      iex>     credit account(:deposits), 100
      iex>   end
      iex> end
      Bookk.InterledgerEntry.new([
        {"acme", Bookk.JournalEntry.new([
          debit(fixture_account_head(:cash), Decimal.new(150)),
          credit(fixture_account_head(:deposits), Decimal.new(150))
        ])}
      ])

  You can define the behaviour for when your `journalize/2` produces
  a unbalanced interledger entry. The default is doing `:nothing`, but
  your can set it to `:raise`:

      iex> use Bookk.Notation
      iex>
      iex> journalize using: DummyChartOfAccounts, on_unbalanced: :raise do
      iex>   on ledger(:acme) do
      iex>     debit account(:cash), 50
      iex>   end
      iex> end
      ** (Bookk.UnbalancedError) The interledger entry is unbalanced!

  """

  defmacro journalize([{_, _} | _] = opts, do: block) do
    {chart_of_accounts, opts} =
      opts
      |> Keyword.put_new(:compact, false)
      |> Keyword.put_new(:on_unbalanced, :nothing)
      |> Keyword.pop!(:using)

    __CALLER__
    |> to_interledger_entry(Macro.expand(chart_of_accounts, __CALLER__), block)
    |> apply_opts(opts)
  end

  #
  #   PRIVATE
  #

  defp to_statements({:__block__, _, statements}), do: statements
  defp to_statements({:on, _, _} = statement), do: [statement]
  defp to_statements({:debit, _, _} = statement), do: [statement]
  defp to_statements({:credit, _, _} = statement), do: [statement]

  defp to_interledger_entry(caller, coa, block) do
    {{:., [context: caller], [{:__aliases__, [alias: false], [Bookk, InterledgerEntry]}, :new]}, [],
     [
       block
       |> to_statements()
       |> Enum.map(&to_journal_entry(caller, coa, &1))
     ]}
  end

  defp to_journal_entry(caller, coa, {:on, meta_a, [{:ledger, meta_b, [ledger_code]}, [do: block]]}) do
    {
      {{:., [context: caller], [coa, :ledger_id]}, meta_b, [ledger_code]},
      {{:., [context: caller], [{:__aliases__, [alias: false], [Bookk, JournalEntry]}, :new]}, meta_a,
       [
         block
         |> to_statements()
         |> Enum.map(&to_operation(caller, coa, &1))
       ]}
    }
  end

  defp to_operation(caller, coa, {direction, meta_a, [{:account, meta_b, [account_code]}, amount_expr]})
       when direction in [:credit, :debit] do
    {{:., [context: caller], [{:__aliases__, [alias: false], [Bookk, Operation]}, direction]}, meta_a,
     [
       {{:., [context: caller], [coa, :account]}, meta_b, [account_code]},
       to_amount(amount_expr)
     ]}
  end

  defp to_amount({:+, meta, [a, b]}), do: {{:., [], [{:__aliases__, [], [Decimal]}, :add]}, meta, [to_amount(a), to_amount(b)]}
  defp to_amount({:-, meta, [a, b]}), do: {{:., [], [{:__aliases__, [], [Decimal]}, :sub]}, meta, [to_amount(a), to_amount(b)]}
  defp to_amount({:*, meta, [a, b]}), do: {{:., [], [{:__aliases__, [], [Decimal]}, :mult]}, meta, [to_amount(a), to_amount(b)]}
  defp to_amount({:/, meta, [a, b]}), do: {{:., [], [{:__aliases__, [], [Decimal]}, :div]}, meta, [to_amount(a), to_amount(b)]}
  defp to_amount(value) when is_integer(value), do: {{:., [], [{:__aliases__, [], [Decimal]}, :new]}, [], [value]}
  defp to_amount(value) when is_float(value), do: {{:., [], [{:__aliases__, [], [Decimal]}, :from_float]}, [], [value]}
  defp to_amount(var), do: {{:., [], [{:__aliases__, [], [Bookk.Utils]}, :to_decimal]}, [], [var]}

  defp apply_opts(expr, []),
    do: expr

  defp apply_opts(expr, [{:compact, true} | tail]) do
    {{:., [], [{:__aliases__, [], [Bookk.InterledgerEntry]}, :compact]}, [], [expr]}
    |> apply_opts(tail)
  end

  defp apply_opts(expr, [{:compact, false} | tail]),
    do: apply_opts(expr, tail)

  defp apply_opts(expr, [{:on_unbalanced, :raise} | tail]) do
    {{:., [], [{:__aliases__, [], [Bookk.InterledgerEntry]}, :balanced!]}, [], [expr]}
    |> apply_opts(tail)
  end

  defp apply_opts(expr, [{:on_unbalanced, :nothing} | tail]),
    do: apply_opts(expr, tail)

  defp apply_opts(_, [{:on_unbalanced, value} | _]),
    do: raise(ArgumentError, "unsupported value #{inspect(value)} for option :on_unbalanced")

  defp apply_opts(_, [{key, _} | _]),
    do: raise(ArgumentError, "unsupported option #{inspect(key)}")
end
