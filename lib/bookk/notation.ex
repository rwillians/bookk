# credo:disable-for-this-file Credo.Check.Refactor.ABCSize
#
#   NOTE: C'est la vie
#
defmodule Bookk.Notation do
  @moduledoc """
  DSL notation for describing interledger entries (`Bookk.InterledgerEntry`).

  - See `Bookk.InterledgerEntry` to learn more about interledger entry;
  - See `Bookk.ChartOfAccounts` to learn more about chart of accounts;
  """

  @doc """
  Using this module will import `journalize/2` and `journalize!/2`
  macros.
  """
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [journalize: 2, journalize!: 2]
    end
  end

  @doc """
  Describes an interledger entry.

      iex> import Bookk.Notation, only: [journalize: 2]
      iex>
      iex> interledger_entry =
      iex>   journalize using: TestChartOfAccounts do
      iex>     on ledger(:acme) do
      iex>       debit account(:cash), 150_00
      iex>       credit account(:deposits), 150_00
      iex>     end
      iex>   end
      iex>
      iex> assert not Bookk.InterledgerEntry.empty?(interledger_entry)
      iex> assert Bookk.InterledgerEntry.balanced?(interledger_entry)

  It may produce an unbalanced interledger entry. You can check
  whether the returned entry is balanced by calling
  `Bookk.InterledgerEntry.balanced?/1`.

      iex> import Bookk.Notation, only: [journalize: 2]
      iex>
      iex> interledger_entry =
      iex>   journalize using: TestChartOfAccounts do
      iex>     on ledger(:acme) do
      iex>       debit account(:cash), 150_00
      iex>       credit account(:deposits), 50_00
      iex>     end
      iex>   end
      iex>
      iex> assert not Bookk.InterledgerEntry.empty?(interledger_entry)
      iex> assert not Bookk.InterledgerEntry.balanced?(interledger_entry)

  """
  defmacro journalize([{:using, chart_of_accounts_mod} | _], do: block) do
    coa =
      {:__aliases__, [],
       Macro.expand(chart_of_accounts_mod, __CALLER__)
       |> Module.split()
       |> Enum.map(&String.to_atom/1)}

    to_interledger_journal_entry(__CALLER__, coa, block)
  end

  @doc """
  Same as `journalize/2` but it raises an error if the resulting
  interledger journal entry is unbalanced.

      iex> import Bookk.Notation, only: [journalize!: 2]
      iex>
      iex> journalize! using: TestChartOfAccounts do
      iex>   on ledger(:acme) do
      iex>     debit account(:cash), 150_00
      iex>     credit account(:deposits), 50_00
      iex>   end
      iex> end
      ** (Bookk.UnbalancedError) `journalize!/2` produced an unbalanced journal entry

  """
  defmacro journalize!([{:using, chart_of_accounts_mod} | _], do: block) do
    coa =
      {:__aliases__, [],
       Macro.expand(chart_of_accounts_mod, __CALLER__)
       |> Module.split()
       |> Enum.map(&String.to_atom/1)}

    interledger_entry = to_interledger_journal_entry(__CALLER__, coa, block)

    {:if, [context: __CALLER__, imports: [{2, Kernel}]],
     [
       {{:., [], [{:__aliases__, [alias: false], [Bookk, InterledgerEntry]}, :balanced?]}, [],
        [interledger_entry]},
       [
         do: interledger_entry,
         else:
           {:raise, [context: __CALLER__, imports: [{1, Kernel}, {2, Kernel}]],
            [
              {:__aliases__, [alias: false], [Bookk, UnbalancedError]},
              [
                message: "`journalize!/2` produced an unbalanced journal entry"
              ]
            ]}
       ]
     ]}
  end

  defp to_interledger_journal_entry(caller, coa, block) do
    {statements, meta} =
      case block do
        {:__block__, meta, statements} -> {statements, meta}
        {:on, meta, _} = statement -> {[statement], meta}
      end

    journal_entries_by_ledger =
      for statement <- statements,
        do: to_journal_entry(caller, coa, statement)

    {:%, meta,
     [
       {:__aliases__, [alias: false], [Bookk, InterledgerEntry]},
       {:%{}, [],
        [
          journal_entries_by_ledger: journal_entries_by_ledger
        ]}
     ]}
  end

  defp to_journal_entry(caller, coa, {:on, meta_a, [{:ledger, meta_b, [name]}, [do: block]]}) do
    statements =
      case block do
        {:__block__, _, statements} -> statements
        {direction, _, _} when direction in [:credit, :debit] -> [block]
      end

    {
      {{:., [context: caller], [coa, :ledger]}, meta_b, [name]},
      {{:., [context: caller], [{:__aliases__, [alias: false], [Bookk, JournalEntry]}, :new]},
       meta_a,
       [
         Enum.map(statements, &to_operation(caller, coa, &1))
       ]}
    }
  end

  defp to_operation(caller, coa, {direction, meta_a, [{:account, meta_b, [name]}, amount]})
       when direction in [:credit, :debit] do
    {{:., [context: caller], [{:__aliases__, [alias: false], [Bookk, Operation]}, direction]},
     meta_a, [{{:., [context: caller], [coa, :account]}, meta_b, [name]}, amount]}
  end
end
