defmodule Bookk.JournalEntry do
  @moduledoc false

  import Enum, only: [all?: 2, map: 2, split_with: 2, sum: 1]

  alias __MODULE__, as: JournalEntry
  alias Bookk.Operation, as: Op

  @typedoc false
  @type t :: %Bookk.JournalEntry{
          operations: [Bookk.Operation.t()]
        }

  defstruct operations: []

  @doc """

  ## Examples

  Is balanced when the sum of debits is equal the sum of credits:

      iex> journal_entry = %Bookk.JournalEntry{
      iex>   operations: [
      iex>     fixture_account_head(:cash) |> debit(10_00),
      iex>     fixture_account_head(:deposits) |> credit(10_00)
      iex>   ]
      iex> }
      iex>
      iex> Bookk.JournalEntry.balanced?(journal_entry)
      true

      iex> journal_entry = %Bookk.JournalEntry{
      iex>   operations: [
      iex>     fixture_account_head(:cash) |> debit(10_00),
      iex>     fixture_account_head(:deposits) |> credit(7_00),
      iex>     fixture_account_head(:deposits) |> credit(3_00),
      iex>   ]
      iex> }
      iex>
      iex> Bookk.JournalEntry.balanced?(journal_entry)
      true

  Is unbalanced when the sum of debits isn't equal the sum of credits:

      iex> journal_entry = %Bookk.JournalEntry{
      iex>   operations: [
      iex>     fixture_account_head(:cash) |> debit(10_00)
      iex>   ]
      iex> }
      iex>
      iex> Bookk.JournalEntry.balanced?(journal_entry)
      false

  """
  @spec balanced?(t) :: boolean

  def balanced?(%JournalEntry{operations: ops}) do
    {debits, credits} = split_with(ops, &(&1.direction == :debit))

    sum_debits = map(debits, & &1.amount) |> sum()
    sum_credits = map(credits, & &1.amount) |> sum()

    sum_debits == sum_credits
  end

  @doc """

  ## Examples

  Is empty when the journal entry has no operations:

     iex> Bookk.JournalEntry.empty?(%Bookk.JournalEntry{})
     true

  Is empty when all operations in the journal entry are empty:

     iex> journal_entry = %Bookk.JournalEntry{
     iex>   operations: [
     iex>     %Bookk.Operation{amount: 0}
     iex>   ]
     iex> }
     iex>
     iex> Bookk.JournalEntry.empty?(journal_entry)
     true

  Is not empty when at least one operation in the journal entry isn't empty:

     iex> journal_entry = %Bookk.JournalEntry{
     iex>   operations: [
     iex>     %Bookk.Operation{amount: 10_00}
     iex>   ]
     iex> }
     iex>
     iex> Bookk.JournalEntry.empty?(journal_entry)
     false

  """
  @spec empty?(t) :: boolean

  def empty?(%JournalEntry{operations: []}), do: true
  def empty?(%JournalEntry{operations: ops}), do: all?(ops, &Op.empty?/1)

  @doc """

  ## Examples

  If there're multiple operations touching the same account, they will be merged
  into a single operation:

      iex> cash = fixture_account_head(:cash)
      iex> deposits = fixture_account_head(:deposits)
      iex>
      iex> Bookk.JournalEntry.new([
      iex>   debit(cash, 80_00),
      iex>   debit(cash, 20_00),
      iex>   credit(deposits, 100_00)
      iex> ])
      %Bookk.JournalEntry{
        operations: [
          fixture_account_head(:cash) |> debit(100_00),
          fixture_account_head(:deposits) |> credit(100_00)
        ]
      }

  """
  @spec new([Bookk.Operation.t()]) :: t

  def new([]), do: %JournalEntry{}
  def new([_ | _] = ops), do: %JournalEntry{operations: Op.uniq(ops)}

  @doc """

  ## Examples

  Reverses all operations in the journal entry:

      iex> journal_entry = %Bookk.JournalEntry{
      iex>   operations: [
      iex>     fixture_account_head(:cash) |> debit(10_00),
      iex>     fixture_account_head(:deposits) |> credit(10_00)
      iex>   ]
      iex> }
      iex>
      iex> Bookk.JournalEntry.reverse(journal_entry)
      %Bookk.JournalEntry{
        operations: [
          fixture_account_head(:deposits) |> debit(10_00),
          fixture_account_head(:cash) |> credit(10_00)
        ]
      }

  """
  @spec reverse(t) :: t

  def reverse(%JournalEntry{operations: ops} = entry),
    do: %{entry | operations: map(ops, &Op.reverse/1) |> :lists.reverse()}
end
