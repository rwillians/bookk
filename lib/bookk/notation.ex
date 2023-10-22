defmodule Bookk.Notation do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__), only: [journalize: 2, journalize!: 2]
    end
  end

  @doc """
  A DSL macro for journalizing complex journal entries.

  ## Examples

  Balanced entry:

      iex> import Bookk.Notation, only: [journalize: 2]
      iex>
      iex> %Bookk.JournalEntry.Complex{} = journal_entry =
      iex>   journalize using: TestChartOfAccounts do
      iex>     on ledger(:acme) do
      iex>       debit account(:cash), 150_00
      iex>       credit account(:deposits), 150_00
      iex>     end
      iex>   end
      iex>
      iex> assert not Bookk.JournalEntry.Complex.empty?(journal_entry)
      iex> assert Bookk.JournalEntry.Complex.balanced?(journal_entry)

      iex> import Bookk.Notation, only: [journalize: 2]
      iex>
      iex> %Bookk.JournalEntry.Complex{} = journal_entry =
      iex>   journalize using: TestChartOfAccounts do
      iex>     on ledger(:acme) do
      iex>       debit account(:cash), 150_00
      iex>       credit account(:deposits), 50_00
      iex>       credit account(:deposits), 100_00
      iex>     end
      iex>   end
      iex>
      iex> assert not Bookk.JournalEntry.Complex.empty?(journal_entry)
      iex> assert Bookk.JournalEntry.Complex.balanced?(journal_entry)

  Unbalanced entry:

      iex> import Bookk.Notation, only: [journalize: 2]
      iex>
      iex> %Bookk.JournalEntry.Complex{} = journal_entry =
      iex>   journalize using: TestChartOfAccounts do
      iex>     on ledger(:acme) do
      iex>       debit account(:cash), 150_00
      iex>       credit account(:deposits), 50_00
      iex>     end
      iex>   end
      iex>
      iex> assert not Bookk.JournalEntry.Complex.empty?(journal_entry)
      iex> assert not Bookk.JournalEntry.Complex.balanced?(journal_entry)

  """

  defmacro journalize([{:using, chart_of_accounts_mod} | _] = _opts, do: block) do
    coa =
      {:__aliases__, [],
       Macro.expand(chart_of_accounts_mod, __CALLER__)
       |> Module.split()
       |> Enum.map(&String.to_atom/1)}

    transform_complex(__CALLER__, coa, block)
  end

  @doc """
  Same as `journalize/2` but it raises an error if the produced complex journal
  entry is unbalanced.

  ## Examples

  Balanced entry:

      iex> import Bookk.Notation, only: [journalize!: 2]
      iex>
      iex> %Bookk.JournalEntry.Complex{} = journal_entry =
      iex>   journalize! using: TestChartOfAccounts do
      iex>     on ledger(:acme) do
      iex>       debit account(:cash), 150_00
      iex>       credit account(:deposits), 150_00
      iex>     end
      iex>   end
      iex>
      iex> assert not Bookk.JournalEntry.Complex.empty?(journal_entry)
      iex> assert Bookk.JournalEntry.Complex.balanced?(journal_entry)

  Unbalanced entry:

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

  defmacro journalize!([{:using, chart_of_accounts_mod} | _] = _opts, do: block) do
    coa =
      {:__aliases__, [],
       Macro.expand(chart_of_accounts_mod, __CALLER__)
       |> Module.split()
       |> Enum.map(&String.to_atom/1)}

    complex_entry = transform_complex(__CALLER__, coa, block)

    {:if, [context: __CALLER__, imports: [{2, Kernel}]],
     [
       {{:., [], [{:__aliases__, [alias: false], [Bookk, JournalEntry, Complex]}, :balanced?]}, [],
        [complex_entry]},
       [
         do: complex_entry,
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

  #
  #   PRIVATE
  #

  defp transform_complex(caller, coa, block) do
    {statements, meta} =
      case block do
        {:__block__, meta, statements} -> {statements, meta}
        {:on, meta, _} = statement -> {[statement], meta}
      end

    {:%, meta,
     [
       {:__aliases__, [alias: false], [Bookk, JournalEntry, Complex]},
       {:%{}, [],
        [
          entries: Enum.map(statements, &transform_compound(caller, coa, &1))
        ]}
     ]}
  end

  defp transform_compound(caller, coa, {:on, meta_a, [{:ledger, meta_b, [name]}, [do: block]]}) do
    statements =
      case block do
        {:__block__, _, statements} -> statements
        {direction, _, _} when direction in [:credit, :debit] -> [block]
      end

    {:%, meta_a,
     [
       {:__aliases__, [alias: false], [Bookk, JournalEntry, Compound]},
       {:%{}, [],
        [
          ledger_name: {{:., [context: caller], [coa, :ledger]}, meta_b, [name]},
          entries: Enum.map(statements, &transform_simple(caller, coa, &1))
        ]}
     ]}
  end

  defp transform_simple(caller, coa, {direction, meta_a, [{:account, meta_b, [name]}, amount]})
       when direction in [:credit, :debit] do
    {{:., [context: caller],
      [{:__aliases__, [alias: false], [Bookk, Operation]}, direction]}, meta_a,
     [{{:., [context: caller], [coa, :account]}, meta_b, [name]}, amount]}
  end
end
