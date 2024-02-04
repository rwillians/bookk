defmodule Bookk.JournalEntry do
  @moduledoc """
  A journal entry is a record of operations of a financial transaction
  in a ledger. For transactions involving accounts from multiple
  ledgers, see `Bookk.InterledgerEntry`.

  - See `Bookk.Operation` to learn more about operations;
  - See `Bookk.Account` to learn more about accounts;
  - See `Bookk.Ledger` to learn more about ledgers.
  """

  alias __MODULE__
  alias Bookk.Operation

  @typedoc """
  A struct representing a journal entry, which is a record of
  operations against a ledger.
  """
  @type t :: %Bookk.JournalEntry{
          operations: [Bookk.Operation.t()]
        }

  defstruct operations: []

  @doc """
  Creates a new journal entry from a set of operations that affect
  accounts of a single ledger.

  For recording a transaction that affects accounts from multiple
  ledger, see `Bookk.InterledgerEntry.new/1`.
  """
  @spec new([operation]) :: journal_entry
        when operation: Bookk.Operation.t(),
             journal_entry: t

  def new(operations \\ []) when is_list(operations) do
    %JournalEntry{
      operations: operations
    }
  end

  @doc """
  Merges a set of journal entries into one.

  > ### Note {: .note}
  > You might want to use `prune/1` after merging the journal entries
  > so that there's only one operation per account.
  >
  >     Bookk.JournalEntry.merge([a, b, c])
  >     |> Bookk.JournalEntry.prune()
  """
  @spec merge([journal_entry, ...]) :: journal_entry
        when journal_entry: t

  def merge([head]), do: head
  def merge([first, second | tail] = _journal_entries), do: merge([merge(first, second) | tail])

  @doc """
  Merges two journal entries into one.

  > ### Note {: .note}
  > You might want to use `prune/1` after merging the journal entries
  > so that there's only one operation per account.
  >
  >     Bookk.JournalEntry.merge(a, b)
  >     |> Bookk.JournalEntry.prune()
  """
  @spec merge(journal_entry, journal_entry) :: journal_entry
        when journal_entry: t

  def merge(%JournalEntry{} = a, %JournalEntry{} = b),
    do: %JournalEntry{operations: a.operations ++ b.operations}

  @doc """
  Given a journal entry that may contain multiple operations affecting
  the same account, it returns a new journal entry where those
  operations are merged into one.

  This is useful in case you want to reduce the number of database
  operations when persisting state changes to a persisted ledger.
  """
  @spec prune(journal_entry) :: journal_entry
        when journal_entry: t

  def prune(%JournalEntry{} = journal_entry) do
    %JournalEntry{
      operations:
        journal_entry.operations
        |> Operation.uniq()
        |> Operation.sort()
    }
  end
end
