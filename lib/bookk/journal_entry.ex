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
  alias Bookk.AccountHead
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
  when the sum of debits is equal the sum of credits.

  ## Examples

  Balanced:

      iex> journal_entry = Bookk.JournalEntry.new([
      iex>   Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(10)),
      iex>   Bookk.Operation.credit(ACME.ChartOfAccounts.account(:deposits), Decimal.new(10))
      iex> ])
      iex>
      iex> Bookk.JournalEntry.balanced?(journal_entry)
      true

      iex> journal_entry = Bookk.JournalEntry.new([
      iex>   Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(10)),
      iex>   Bookk.Operation.credit(ACME.ChartOfAccounts.account(:deposits), Decimal.new(7)),
      iex>   Bookk.Operation.credit(ACME.ChartOfAccounts.account(:deposits), Decimal.new(3))
      iex> ])
      iex>
      iex> Bookk.JournalEntry.balanced?(journal_entry)
      true

  Unbalanced:

      iex> journal_entry = Bookk.JournalEntry.new([
      iex>   Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(10))
      iex> ])
      iex>
      iex> Bookk.JournalEntry.balanced?(journal_entry)
      false

      iex> journal_entry = Bookk.JournalEntry.new([
      iex>   Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(10)),
      iex>   Bookk.Operation.credit(ACME.ChartOfAccounts.account(:deposits), Decimal.new(7)),
      iex>   Bookk.Operation.credit(ACME.ChartOfAccounts.account(:deposits), Decimal.new(5))
      iex> ])
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
  Calculates a `Bookk.JournalEntry` represending the diff between two
  `Bookk.JournalEntries` where, if the diff journal entry were to be
  merged with journal entry "a", it would become equal to journal
  entry "b".

  ## Examples

      iex> a = Bookk.JournalEntry.new([
      iex>   Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(25))
      iex> ])
      iex>
      iex> b = Bookk.JournalEntry.new([
      iex>   Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(100)),
      iex>   Bookk.Operation.credit(ACME.ChartOfAccounts.account(:deposits), Decimal.new(100)),
      iex> ])
      iex>
      iex> Bookk.JournalEntry.diff(a, b)
      Bookk.JournalEntry.new([
        Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(75)),
        Bookk.Operation.credit(ACME.ChartOfAccounts.account(:deposits), Decimal.new(100))
      ])

  """
  @spec diff(a :: t(), b :: t()) :: t()

  def diff(%JournalEntry{} = a, %JournalEntry{} = b) do
    account_heads =
      []
      |> Enum.concat(Enum.map(a.operations, & &1.account_head))
      |> Enum.concat(Enum.map(b.operations, & &1.account_head))
      |> Enum.uniq()
      |> Enum.sort_by(& &1.name)

    operations =
      for %AccountHead{} = account_head <- account_heads do
        op_a = get_op(a, account_head)
        op_b = get_op(b, account_head)
        diff_amount = Decimal.sub(op_b.amount, op_a.amount)

        Op.new(account_head.class.natural_balance, account_head, diff_amount)
      end

    new(operations)
  end

  @doc ~S"""
  Checks whether a journal entry is empty.

  ## Examples

  Is empty when the journal entry has no operations:

      iex> Bookk.JournalEntry.empty?(%Bookk.JournalEntry{})
      true

  Is empty when all operations in the journal entry are empty:

      iex> journal_entry = Bookk.JournalEntry.new([
      iex>   Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(0)),
      iex>   Bookk.Operation.credit(ACME.ChartOfAccounts.account(:deposits), Decimal.new(0)),
      iex> ])
      iex>
      iex> Bookk.JournalEntry.empty?(journal_entry)
      true

  Is not empty when at least one operation in the journal entry isn't
  empty:

      iex> journal_entry = Bookk.JournalEntry.new([
      iex>   Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(10)),
      iex> ])
      iex>
      iex> Bookk.JournalEntry.empty?(journal_entry)
      false

  """
  @spec empty?(t) :: boolean

  def empty?(%JournalEntry{operations: []}), do: true
  def empty?(%JournalEntry{operations: ops}), do: all?(ops, &Op.empty?/1)

  @doc ~S"""
  Get a `Bookk.Operation` from the given `Bookk.JournalEntry` by its
  `Bookk.AccountHead`.

  ## Examples:

  When exists an operation for the given account head, it is returned:

      iex> journal_entry = Bookk.JournalEntry.new([
      iex>   Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(25))
      iex> ])
      iex>
      iex> Bookk.JournalEntry.get_op(journal_entry, ACME.ChartOfAccounts.account(:cash))
      %Bookk.Operation{
        direction: :debit,
        account_head: ACME.ChartOfAccounts.account(:cash),
        amount: Decimal.new(25)
      }

  When there's no operations for the given account head, then a new
  empty operation is returned:

      iex> Bookk.JournalEntry.new([])
      iex> |> Bookk.JournalEntry.get_op(ACME.ChartOfAccounts.account(:cash))
      %Bookk.Operation{
        direction: :debit,
        account_head: ACME.ChartOfAccounts.account(:cash),
        amount: Decimal.new(0)
      }

  """
  @spec get_op(t, Bookk.AccountHead.t()) :: Bookk.Operation.t()

  def get_op(%JournalEntry{} = entry, %AccountHead{} = account_head) do
    case Enum.find(entry.operations, &(&1.account_head == account_head)) do
      %Op{} = op -> op
      nil -> Op.new(account_head.class.natural_balance, account_head, Decimal.new(0))
    end
  end

  @doc ~S"""
  Merges a set or journal entries into one.

  ## Examples

      iex> cash = ACME.ChartOfAccounts.account(:cash)
      iex> deposits = ACME.ChartOfAccounts.account(:deposits)
      iex>
      iex> a = Bookk.JournalEntry.new([
      iex>   Bookk.Operation.debit(cash, Decimal.new(80)),
      iex>   Bookk.Operation.debit(cash, Decimal.new(20)),
      iex>   Bookk.Operation.credit(deposits, Decimal.new(100))
      iex> ])
      iex>
      iex> b = Bookk.JournalEntry.new([
      iex>   Bookk.Operation.debit(cash, Decimal.new(80)),
      iex>   Bookk.Operation.debit(cash, Decimal.new(20)),
      iex>   Bookk.Operation.credit(deposits, Decimal.new(100))
      iex> ])
      iex>
      iex> Bookk.JournalEntry.merge([a, b])
      Bookk.JournalEntry.new([
        Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(200)),
        Bookk.Operation.credit(ACME.ChartOfAccounts.account(:deposits), Decimal.new(200))
      ])

  """
  @spec merge([t]) :: t

  def merge([]), do: new([])
  def merge([%JournalEntry{} = a]), do: a
  def merge([head | tail]), do: merge(head, merge(tail))

  @doc ~S"""
  Merges two journal entries into one.

  ## Examples

      iex> a = Bookk.JournalEntry.new([
      iex>   Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(80)),
      iex>   Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(20)),
      iex>   Bookk.Operation.credit(ACME.ChartOfAccounts.account(:deposits), Decimal.new(100))
      iex> ])
      iex>
      iex> b = Bookk.JournalEntry.new([
      iex>   Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(80)),
      iex>   Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(20)),
      iex>   Bookk.Operation.credit(ACME.ChartOfAccounts.account(:deposits), Decimal.new(100))
      iex> ])
      iex>
      iex> Bookk.JournalEntry.merge(a, b)
      %Bookk.JournalEntry{
        operations: [
          Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(200)),
          Bookk.Operation.credit(ACME.ChartOfAccounts.account(:deposits), Decimal.new(200))
        ]
      }

  """
  @spec merge(t, t) :: t

  def merge(%JournalEntry{} = a, %JournalEntry{} = b) do
    to_operations(a)
    |> Enum.concat(to_operations(b))
    |> Enum.group_by(& &1.account_head)
    |> Enum.map(fn {_, ops} -> Op.merge(ops) end)
    |> new()
  end

  @doc ~S"""
  Creates a new journal entry from a set of operations.

  ## Examples

  If there're multiple operations touching the same account, they will
  be merged into a single operation:

      iex> Bookk.JournalEntry.new([
      iex>   Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(80)),
      iex>   Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(20)),
      iex>   Bookk.Operation.credit(ACME.ChartOfAccounts.account(:deposits), Decimal.new(100))
      iex> ])
      %Bookk.JournalEntry{
        operations: [
          Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(100)),
          Bookk.Operation.credit(ACME.ChartOfAccounts.account(:deposits), Decimal.new(100))
        ]
      }

  Empty operations will be dropped:

      iex> Bookk.JournalEntry.new([
      iex>   Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(80)),
      iex>   Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(20)),
      iex>   Bookk.Operation.credit(ACME.ChartOfAccounts.account(:deposits), Decimal.new(100)),
      iex>   Bookk.Operation.credit(ACME.ChartOfAccounts.account({:unspent_cash, {:user, "12345"}}), Decimal.new(0))
      iex> ])
      %Bookk.JournalEntry{
        operations: [
          Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(100)),
          Bookk.Operation.credit(ACME.ChartOfAccounts.account(:deposits), Decimal.new(100))
        ]
      }

  """
  @spec new([Bookk.Operation.t()]) :: t

  def new([]), do: %JournalEntry{}

  def new([_ | _] = ops) do
    uniq_ops =
      ops
      |> Enum.reject(&Op.empty?/1)
      |> Op.uniq()

    %JournalEntry{operations: uniq_ops}
  end

  @doc ~S"""
  Creates a new journal entry that reverses all effects from the given
  journal entry.

  ## Examples

  Reverses all operations in the journal entry:

      iex> journal_entry = Bookk.JournalEntry.new([
      iex>   Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(10)),
      iex>   Bookk.Operation.credit(ACME.ChartOfAccounts.account(:deposits), Decimal.new(10))
      iex> ])
      iex>
      iex> Bookk.JournalEntry.reverse(journal_entry)
      Bookk.JournalEntry.new([
        Bookk.Operation.debit(ACME.ChartOfAccounts.account(:deposits), Decimal.new(10)),
        Bookk.Operation.credit(ACME.ChartOfAccounts.account(:cash), Decimal.new(10))
      ])

  """
  @spec reverse(t) :: t

  def reverse(%JournalEntry{operations: ops} = entry),
    do: %{entry | operations: map(ops, &Op.reverse/1) |> :lists.reverse()}

  @doc ~S"""
  Returns the list of operations inside a journal entry.

  ## Examples

  Returns the journal entry's list of operations:

      iex> journal_entry = Bookk.JournalEntry.new([
      iex>   Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(50)),
      iex>   Bookk.Operation.credit(ACME.ChartOfAccounts.account(:deposits), Decimal.new(50))
      iex> ])
      iex>
      iex> Bookk.JournalEntry.to_operations(journal_entry)
      [
        Bookk.Operation.debit(ACME.ChartOfAccounts.account(:cash), Decimal.new(50)),
        Bookk.Operation.credit(ACME.ChartOfAccounts.account(:deposits), Decimal.new(50))
      ]

  """
  @spec to_operations(t) :: [Bookk.Operation.t()]

  def to_operations(%JournalEntry{operations: ops}), do: ops
end
