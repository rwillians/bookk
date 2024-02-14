defmodule Bookk.JournalEntry do
  @moduledoc """
  A journal entry is a record of operations of a financial transaction
  in a ledger. For transactions involving accounts from multiple
  ledgers, see `Bookk.InterledgerEntry`.

  - See `Bookk.Operation` to learn more about operations;
  - See `Bookk.Account` to learn more about accounts;
  - See `Bookk.Ledger` to learn more about ledgers.
  """
  @moduledoc since: "0.1.0"

  alias __MODULE__
  alias Bookk.Operation

  @typedoc """
  A struct describing a journal entry.
  """
  @typedoc since: "0.1.0"
  @opaque t :: %Bookk.JournalEntry{
          operations: [Bookk.Operation.t()]
        }

  defstruct operations: []

  @doc """
  Creates a new journal entry from a set of operations that affect
  accounts of a single ledger.

  For recording a transaction that affects accounts from multiple
  ledger, see `Bookk.InterledgerEntry.new/1`.
  """
  @doc since: "0.1.0"
  @spec new([operation]) :: journal_entry
        when operation: Bookk.Operation.t(),
             journal_entry: t

  def new(operations \\ []) when is_list(operations) do
    %JournalEntry{
      operations:
        operations
        |> Enum.reduce([], &prepend/2)
        |> :lists.reverse()
    }
  end

  defp prepend(%Operation{} = operation, operations), do: [operation | operations]

  @doc """
  Checks whether a journal entry is balanced. It's considered balanced
  when the sum of the debit operations is equal to the sum of the
  credit operations.

      iex> operation_a = %Bookk.Operation{amount: 10_00, direction: :debit}
      iex> operation_b = %Bookk.Operation{amount: 10_00, direction: :credit}
      iex> journal_entry = Bookk.JournalEntry.new([operation_a, operation_b])
      iex>
      iex> Bookk.JournalEntry.balanced?(journal_entry)
      true

      iex> operation_a = %Bookk.Operation{amount: 20_00, direction: :debit}
      iex> operation_b = %Bookk.Operation{amount: 30_00, direction: :credit}
      iex> journal_entry = Bookk.JournalEntry.new([operation_a, operation_b])
      iex>
      iex> Bookk.JournalEntry.balanced?(journal_entry)
      false

  """
  @doc since: "0.1.0"
  @spec balanced?(journal_entry) :: boolean
        when journal_entry: t

  def balanced?(%JournalEntry{} = journal_entry) do
    {debit_entries, credit_entries} =
      journal_entry.operations
      |> Enum.split_with(&(&1.direction == :debit))

    sum_debits = Enum.reduce(debit_entries, 0, &(&1.amount + &2))
    sum_credits = Enum.reduce(credit_entries, 0, &(&1.amount + &2))

    sum_debits == sum_credits
  end

  @doc """
  Checks whether a journal entry is empty. It's considered empty if
  there are no operations in it.

      iex> Bookk.JournalEntry.empty?(%Bookk.JournalEntry{})
      true

      iex> Bookk.JournalEntry.new([%Bookk.Operation{}])
      iex> |> Bookk.JournalEntry.empty?()
      false

  """
  @doc since: "0.1.0"
  @spec empty?(journal_entry) :: boolean
        when journal_entry: t

  def empty?(%JournalEntry{operations: []}), do: true

  def empty?(%JournalEntry{operations: [_ | _] = operations}),
    do: Enum.all?(operations, &Operation.empty?/1)

  @doc """
  Merges a set of journal entries into one. Using this function has
  the same effect as reducing your set of journal entries calling
  `merge/2`.

  > ### Warning {: .warning}
  > At least one journal entry MUST be given.

      iex> Bookk.JournalEntry.merge([])
      ** (FunctionClauseError) no function clause matching in Bookk.JournalEntry.merge/1

  > ### Note {: .note}
  > You might want to use `prune/1` after merging the journal entries
  > so that there's only one operation per account.
  >
  >     Bookk.JournalEntry.merge([a, b, c])
  >     |> Bookk.JournalEntry.prune()
  """
  @doc since: "0.1.0"
  @spec merge([journal_entry, ...]) :: journal_entry
        when journal_entry: t

  def merge([head]), do: head
  def merge([first, second | tail] = _journal_entries), do: merge([merge(first, second) | tail])

  @doc """
  Merges two journal entries into one.

      iex> journal_entry_a = Bookk.JournalEntry.new([%Bookk.Operation{amount: 10_00}])
      iex> journal_entry_b = Bookk.JournalEntry.new([%Bookk.Operation{amount: 20_00}])
      iex>
      iex> Bookk.JournalEntry.merge(journal_entry_a, journal_entry_b)
      %Bookk.JournalEntry{
        operations: [
          %Bookk.Operation{amount: 10_00},
          %Bookk.Operation{amount: 20_00}
        ]
      }

  > ### Note {: .note}
  > You might want to use `prune/1` after merging the journal entries
  > so that there's only one operation per account.
  >
  >     Bookk.JournalEntry.merge(a, b)
  >     |> Bookk.JournalEntry.prune()
  """
  @doc since: "0.1.0"
  @spec merge(journal_entry, journal_entry) :: journal_entry
        when journal_entry: t

  def merge(%JournalEntry{} = a, %JournalEntry{} = b),
    do: %JournalEntry{operations: a.operations ++ b.operations}

  @doc """
  Given a journal entry that may contain multiple operations affecting
  the same account, it returns a new journal entry where those
  operations are merged into one.

  This is useful in case you want to reduce the number of database
  operations when persisting state changes.

      iex> cash_head = %Bookk.AccountHead{name: "cash"}
      iex> contributions_head = %Bookk.AccountHead{name: "contributions"}
      iex>
      iex> journal_entry = Bookk.JournalEntry.new([
      iex>   Bookk.Operation.debit(cash_head, 10_00),
      iex>   Bookk.Operation.debit(cash_head, 20_00),
      iex>   Bookk.Operation.credit(contributions_head, 50_00)
      iex> ])
      iex>
      iex> Bookk.JournalEntry.prune(journal_entry)
      %Bookk.JournalEntry{
        operations: [
          %Bookk.Operation{direction: :debit, amount: 30_00, account_head: %Bookk.AccountHead{name: "cash"}},
          %Bookk.Operation{direction: :credit, amount: 50_00, account_head: %Bookk.AccountHead{name: "contributions"}}
        ]
      }

  The operations also gets sorted, see the sorting priority at
  `Bookk.Operation.sort/1`.
  """
  @doc since: "1.0.0"
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

  @doc """
  Returns the set of operations that make up a journal entry.

      iex> cash_head = %Bookk.AccountHead{name: "cash"}
      iex> contributions_head = %Bookk.AccountHead{name: "contributions"}
      iex>
      iex> journal_entry = Bookk.JournalEntry.new([
      iex>   Bookk.Operation.debit(cash_head, 10_00),
      iex>   Bookk.Operation.debit(cash_head, 20_00),
      iex>   Bookk.Operation.credit(contributions_head, 50_00)
      iex> ])
      iex>
      iex> Bookk.JournalEntry.to_operations(journal_entry)
      [
        Bookk.Operation.debit(cash_head, 10_00),
        Bookk.Operation.debit(cash_head, 20_00),
        Bookk.Operation.credit(contributions_head, 50_00)
      ]

  If you want a list of operations where there's only one operation
  per account, consider using `prune/1` before `to_operations/1`.
  """
  @doc since: "0.1.0"
  @spec to_operations(journal_entry) :: [operation]
        when journal_entry: t,
             operation: Bookk.Operation.t()

  def to_operations(%JournalEntry{} = journal_entry),
    do: journal_entry.operations
end
