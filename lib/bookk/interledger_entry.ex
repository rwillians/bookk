defmodule Bookk.InterledgerEntry do
  @moduledoc """
  An interledger entry is a special kind of journal entry that can
  affect accounts from multiple ledgers. In pratical term, it's a
  collection of regular journal entries where each journal entry
  has a target ledger.

  - See `Bookk.JournalEntry` to learn more about journal entries;
  - See `Bookk.Operation` to learn more about operations;
  - See `Bookk.NaiveState` to learn more about in-memory state.
  """
  @moduledoc since: "0.1.0"

  alias __MODULE__
  alias Bookk.JournalEntry

  @typedoc """
  A struct describing an interledger entry.
  """
  @typedoc since: "0.1.0"
  @opaque t :: %Bookk.InterledgerEntry{
          journal_entries_by_ledger: [
            {ledger_name :: String.t(), journal_entry :: Bookk.JournalEntry.t()}
          ]
        }

  defstruct journal_entries_by_ledger: []

  @doc """
  Creates a new interledger entry from a set tuples where the first
  element is the name of the targeted ledger and the second element is
  a `Bookk.JournalEntry`.

  > ### Warning {: .warning}
  > Ledger names MUST be a non-empty string and journal entries MUST
  > be a `Bookk.JournalEntry`.

      iex> Bookk.InterledgerEntry.new([{nil, %Bookk.JournalEntry{}}])
      ** (FunctionClauseError) no function clause matching in Bookk.InterledgerEntry.prepend/2

      iex> Bookk.InterledgerEntry.new([{"acme", nil}])
      ** (FunctionClauseError) no function clause matching in Bookk.InterledgerEntry.prepend/2

  """
  @doc since: "0.1.0"
  @spec new([{ledger_name, journal_entry}]) :: interledger_entry
        when ledger_name: String.t(),
             journal_entry: Bookk.JournalEntry.t(),
             interledger_entry: t

  def new(journal_entries_by_ledger \\ [])

  def new(journal_entries_by_ledger) when is_list(journal_entries_by_ledger) do
    entries_by_ledger =
      Enum.reduce(journal_entries_by_ledger, [], &prepend/2)
      |> :lists.reverse()

    %InterledgerEntry{journal_entries_by_ledger: entries_by_ledger}
  end

  def new(%{} = journal_entries_by_ledger) do
    Enum.to_list(journal_entries_by_ledger)
    |> new()
  end

  defp prepend(
         {<<_, _::binary>> = ledger_name, %JournalEntry{} = journal_entry},
         journal_entries
      ),
      do: [{ledger_name, journal_entry} | journal_entries]

  @doc """
  Checks whether the given interledger entry is balanced. It's
  considered balance if all its journal entries are balanced.

      iex> interledger_entry = Bookk.InterledgerEntry.new([
      iex>   {"acme", %Bookk.JournalEntry{
      iex>       operations: [
      iex>         debit(fixture_account_head(:cash), 30_00),
      iex>         credit(fixture_account_head(:deposits), 30_00)
      iex>       ]
      iex>     }}
      iex> ])
      iex>
      iex> Bookk.InterledgerEntry.balanced?(interledger_entry)
      true

  If any of its journal entries are unbalanced, the the interledger
  entry is also unbalanced.

      iex> interledger_entry = Bookk.InterledgerEntry.new([
      iex>   {"acme", %Bookk.JournalEntry{
      iex>       operations: [
      iex>         debit(fixture_account_head(:cash), 30_00)
      iex>       ]
      iex>     }}
      iex> ])
      iex>
      iex> Bookk.InterledgerEntry.balanced?(interledger_entry)
      false

  """
  @spec balanced?(interledger_entry) :: boolean
        when interledger_entry: t

  def balanced?(%InterledgerEntry{} = interledger_entry) do
    interledger_entry.journal_entries_by_ledger
    |> Enum.all?(&JournalEntry.balanced?(elem(&1, 1)))
  end

  @doc """
  Checks whether an interledger entry is empty? It's considered empty
  when there are no journal entries in it.

      iex> Bookk.InterledgerEntry.new()
      iex> |> Bookk.InterledgerEntry.empty?()
      true

      iex> Bookk.InterledgerEntry.new([{"ledger_a", %Bookk.JournalEntry{}}])
      iex> |> Bookk.InterledgerEntry.empty?()
      false

  """
  @doc since: "0.1.0"
  @spec empty?(interledger_entry) :: boolean
        when interledger_entry: t

  def empty?(%InterledgerEntry{journal_entries_by_ledger: []}), do: true
  def empty?(%InterledgerEntry{journal_entries_by_ledger: [_ | _]}), do: false

  @doc """
  Merges multiple interledger entries into one.  Using this function
  has the same effect as reducing your set of interledger entries
  calling `merge/2`.

  > ### Warning {: .warning }
  > At least one interledger entry MUST be given.

      iex> Bookk.InterledgerEntry.merge([])
      ** (FunctionClauseError) no function clause matching in Bookk.InterledgerEntry.merge/1

  > ### Note {: .note}
  > You might want to use `prune/1` after merging the interledger
  > entries so that there's only one journal entry per ledger.
  >
  >     Bookk.InterledgerEntry.merge([a, b, c])
  >     |> Bookk.InterledgerEntry.prune()
  """
  @doc since: "0.1.0"
  @spec merge([interledger_entry]) :: interledger_entry
        when interledger_entry: t

  def merge([head]), do: head
  def merge([first, second | tail] = _interledger_entries), do: merge([merge(first, second) | tail])

  @doc """
  Merges two interledger entries into one.

      iex> interledger_entry_a =
      iex>   Bookk.InterledgerEntry.new([
      iex>     {"ledger_a", %Bookk.JournalEntry{operations: [%Bookk.Operation{amount: 10_00}]}}
      iex>   ])
      iex>
      iex> interledger_entry_b =
      iex>   Bookk.InterledgerEntry.new([
      iex>     {"ledger_b", %Bookk.JournalEntry{operations: [%Bookk.Operation{amount: 20_00}]}}
      iex>   ])
      iex>
      iex> Bookk.InterledgerEntry.merge(interledger_entry_a, interledger_entry_b)
      %Bookk.InterledgerEntry{
        journal_entries_by_ledger: [
          {"ledger_a", %Bookk.JournalEntry{operations: [%Bookk.Operation{amount: 10_00}]}},
          {"ledger_b", %Bookk.JournalEntry{operations: [%Bookk.Operation{amount: 20_00}]}},
        ]
      }

  > ### Note {: .note}
  > You might want to use `prune/1` after merging the interledger
  > entries so that there's only one journal entry per ledger.
  >
  >     Bookk.InterledgerEntry.merge([a, b, c])
  >     |> Bookk.InterledgerEntry.prune()
  """
  @doc since: "0.1.0"
  @spec merge(interledger_entry, interledger_entry) :: interledger_entry
        when interledger_entry: t

  def merge(%InterledgerEntry{} = a, %InterledgerEntry{} = b) do
    %InterledgerEntry{
      journal_entries_by_ledger:
        a.journal_entries_by_ledger ++ b.journal_entries_by_ledger
    }
  end

  @doc """
  Given an interledger entry that may contain multiple journal entries
  targeting the same ledger, prunes the journal entries so that
  there's only one journal entry per ledger.

  This is useful in case you want to reduce the number of database
  operations when persisting state changes.

      iex> interledger_entry = %Bookk.InterledgerEntry{
      iex>   journal_entries_by_ledger: [
      iex>     {"ledger_a", %Bookk.JournalEntry{operations: [debit(%Bookk.AccountHead{name: "foo"}, 10_00)]}},
      iex>     {"ledger_a", %Bookk.JournalEntry{operations: [debit(%Bookk.AccountHead{name: "foo"}, 20_00)]}},
      iex>     {"ledger_b", %Bookk.JournalEntry{operations: [credit(%Bookk.AccountHead{name: "bar"}, 50_00)]}}
      iex>   ]
      iex> }
      iex>
      iex> Bookk.InterledgerEntry.prune(interledger_entry)
      %Bookk.InterledgerEntry{
        journal_entries_by_ledger: [
          {"ledger_a", %Bookk.JournalEntry{operations: [debit(%Bookk.AccountHead{name: "foo"}, 30_00)]}},
          {"ledger_b", %Bookk.JournalEntry{operations: [credit(%Bookk.AccountHead{name: "bar"}, 50_00)]}}
        ]
      }

  Consult `Bookk.JournalEntry.prune/1` to see how merged journal
  entries get pruned.
  """
  @doc since: "0.1.0"
  @spec prune(interledger_entry) :: interledger_entry
        when interledger_entry: t

  def prune(%InterledgerEntry{} = interledger_entry) do
    journal_entries_by_ledger =
      interledger_entry.journal_entries_by_ledger
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
      |> Enum.map(fn {ledger_name, journal_entries} ->
        {ledger_name, JournalEntry.merge(journal_entries) |> JournalEntry.prune()}
      end)

    %InterledgerEntry{
      journal_entries_by_ledger: journal_entries_by_ledger
    }
  end
end
