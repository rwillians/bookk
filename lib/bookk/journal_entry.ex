# credo:disable-for-this-file Credo.Check.Refactor.ABCSize
#
#   NOTE: C'est la vie
#
defmodule Bookk.JournalEntry do
  @moduledoc ~S"""
  A Journal Entry is a set of operations that must be transacted under
  the same accounting transaction. Those operations describe a change
  in balance for an account.

  ## Related

  - `Bookk.Ledger`;
  - `Bookk.Operation`;
  - `Bookk.AccountHead`.
  """

  import Enum, only: [all?: 2, map: 2, reduce: 3, split_with: 2]

  alias __MODULE__, as: JournalEntry
  alias Bookk.Operation, as: Op

  @typedoc ~S"""
  The struct that describe a Journal Entry.

  ## Fields

  - `operations`: the list of operations included in the journal entry.
  """
  @type t :: %Bookk.JournalEntry{
          operations: [Bookk.Operation.t()]
        }

  defstruct operations: []

  @doc ~S"""
  Checks whether a journal entry is balanced. It is considered balance
  when tht
  operations.

  ## Examples

  Is balanced when th:

      iex> journal_entry = %Bookk.JournalEntry{
      iex>   operations: [
      iex>     debit(fixture_account_head(:cash), Decimal.new(10_00)),
      iex>     credit(fixture_account_head(:deposits), Decimal.new(10_00))
      iex>   ]
      iex> }
      iex>
      iex> Bookk.JournalEntry.balanced?(journal_entry)
      true

      iex> journal_entry = %Bookk.JournalEntry{
      iex>   operations: [
      iex>     debit(fixture_account_head(:cash), Decimal.new(10_00)),
      iex>     credit(fixture_account_head(:deposits), Decimal.new(7_00)),
      iex>     credit(fixture_account_head(:deposits), Decimal.new(3_00))
      iex>   ]
      iex> }
      iex>
      iex> Bookk.JournalEntry.balanced?(journal_entry)
      true

  Is unbalanced when th:

      iex> journal_entry = %Bookk.JournalEntry{
      iex>   operations: [
      iex>     debit(fixture_account_head(:cash), Decimal.new(10_00))
      iex>   ]
      iex> }
      iex>
      iex> Bookk.JournalEntry.balanced?(journal_entry)
      false

  """
  @spec balanced?(t) :: boolean

  def balanced?(%JournalEntry{operations: ops}) do
    {debits, credits} = split_with(ops, &(&1.direction == :debit))

    sum_debits = reduce(debits, Decimal.new(0), &Decimal.add(&1.amount, &2))
    sum_credits = reduce(credits, Decimal.new(0), &Decimal.add(&1.amount, &2))

    Decimal.eq?(sum_debits, sum_credits)
  end

  @doc ~S"""
  Checks whether a journal entry is empty.

  ## Examples

  Is empty when the journal entry has no operations:

      iex> Bookk.JournalEntry.empty?(%Bookk.JournalEntry{})
      true

  Is empty when all operations in the journal entry are empty:

      iex> journal_entry = %Bookk.JournalEntry{
      iex>   operations: [
      iex>     %Bookk.Operation{amount: Decimal.new(0)}
      iex>   ]
      iex> }
      iex>
      iex> Bookk.JournalEntry.empty?(journal_entry)
      true

  Is not empty when at least one operation in the journal entry isn't
  empty:

      iex> journal_entry = %Bookk.JournalEntry{
      iex>   operations: [
      iex>     %Bookk.Operation{amount: Decimal.new(10_00)}
      iex>   ]
      iex> }
      iex>
      iex> Bookk.JournalEntry.empty?(journal_entry)
      false

  """
  @spec empty?(t) :: boolean

  def empty?(%JournalEntry{operations: []}), do: true
  def empty?(%JournalEntry{operations: ops}), do: all?(ops, &Op.empty?/1)

  @doc ~S"""
  Creates a new journal entry from a set of operations.

  ## Examples

  If there're multiple operations touching the same account, they will
  be merged into a single operation:

      iex> cash = fixture_account_head(:cash)
      iex> deposits = fixture_account_head(:deposits)
      iex>
      iex> Bookk.JournalEntry.new([
      iex>   debit(cash, Decimal.new(80_00)),
      iex>   debit(cash, Decimal.new(20_00)),
      iex>   credit(deposits, Decimal.new(100_00))
      iex> ])
      %Bookk.JournalEntry{
        operations: [
          debit(fixture_account_head(:cash), Decimal.new(100_00)),
          credit(fixture_account_head(:deposits), Decimal.new(100_00))
        ]
      }

  """
  @spec new([Bookk.Operation.t()]) :: t

  def new([]), do: %JournalEntry{}
  def new([_ | _] = ops), do: %JournalEntry{operations: Op.uniq(ops)}

  @doc ~S"""
  Creates a new journal entry that reverses all effects from the given
  journal entry.

  ## Examples

  Reverses all operations in the journal entry:

      iex> journal_entry = %Bookk.JournalEntry{
      iex>   operations: [
      iex>     debit(fixture_account_head(:cash), Decimal.new(10_00)),
      iex>     credit(fixture_account_head(:deposits), Decimal.new(10_00))
      iex>   ]
      iex> }
      iex>
      iex> Bookk.JournalEntry.reverse(journal_entry)
      %Bookk.JournalEntry{
        operations: [
          debit(fixture_account_head(:deposits), Decimal.new(10_00)),
          credit(fixture_account_head(:cash), Decimal.new(10_00))
        ]
      }

  """
  @spec reverse(t) :: t

  def reverse(%JournalEntry{operations: ops} = entry),
    do: %{entry | operations: map(ops, &Op.reverse/1) |> :lists.reverse()}

  @doc ~S"""
  Returns the list of operations inside a journal entry.

  ## Examples

  Returns the journal entry's list of operations:

      iex> Bookk.JournalEntry.new([
      iex>   debit(fixture_account_head(:cash), Decimal.new(50_00)),
      iex>   credit(fixture_account_head(:deposits), Decimal.new(50_00))
      iex> ])
      iex> |> Bookk.JournalEntry.to_operations()
      [
        debit(fixture_account_head(:cash), Decimal.new(50_00)),
        credit(fixture_account_head(:deposits), Decimal.new(50_00))
      ]

  """
  @spec to_operations(t) :: [Bookk.Operation.t()]

  def to_operations(%JournalEntry{operations: ops}), do: ops
end
