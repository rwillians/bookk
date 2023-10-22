defmodule Bookk.JournalEntry do
  @moduledoc false

  import Enum, only: [all?: 2, map: 2, split_with: 2, sum: 1]

  alias __MODULE__, as: JournalEntry
  alias Bookk.Operation, as: Op

  @typedoc false
  @type t :: %Bookk.JournalEntry{
          ledger_name: String.t(),
          operations: [Bookk.Operation.t()]
        }

  defstruct [:ledger_name, operations: []]

  @doc """

  ## Examples

      iex> Bookk.JournalEntry.balanced?(%Bookk.JournalEntry{
      iex>   ledger_name: "acme",
      iex>   operations: [
      iex>     fixture_account_head(:cash) |> debit(10_00)
      iex>   ]
      iex> })
      false

      iex> Bookk.JournalEntry.balanced?(%Bookk.JournalEntry{
      iex>   ledger_name: "acme",
      iex>   operations: [
      iex>     fixture_account_head(:cash) |> debit(10_00),
      iex>     fixture_account_head(:deposits) |> credit(10_00)
      iex>   ]
      iex> })
      true

      iex> Bookk.JournalEntry.balanced?(%Bookk.JournalEntry{
      iex>   ledger_name: "acme",
      iex>   operations: [
      iex>     fixture_account_head(:cash) |> debit(10_00),
      iex>     fixture_account_head(:deposits) |> credit(7_00),
      iex>     fixture_account_head(:deposits) |> credit(3_00),
      iex>   ]
      iex> })
      true

  """
  @spec balanced?(t) :: boolean

  def balanced?(%JournalEntry{operations: ops}) do
    {debits, credits} = split_with(ops, & &1.direction == :debit)

    sum_debits = map(debits, & &1.amount) |> sum()
    sum_credits = map(credits, & &1.amount) |> sum()

    sum_debits == sum_credits
  end

  @doc """

  ## Examples

     iex> Bookk.JournalEntry.empty?(%Bookk.JournalEntry{})
     true

     iex> Bookk.JournalEntry.empty?(%Bookk.JournalEntry{
     iex>   operations: [
     iex>     %Bookk.Operation{amount: 0}
     iex>   ]
     iex> })
     true

     iex> Bookk.JournalEntry.empty?(%Bookk.JournalEntry{
     iex>   operations: [
     iex>     %Bookk.Operation{amount: 10_00}
     iex>   ]
     iex> })
     false

  """
  @spec empty?(t) :: boolean

  def empty?(%JournalEntry{operations: []}), do: true
  def empty?(%JournalEntry{operations: ops}), do: all?(ops, &Op.empty?/1)

  @doc """

  ## Examples

      iex> Bookk.JournalEntry.reverse(%Bookk.JournalEntry{
      iex>   ledger_name: "acme",
      iex>   operations: [
      iex>     fixture_account_head(:cash) |> debit(10_00),
      iex>     fixture_account_head(:deposits) |> credit(10_00)
      iex>   ]
      iex> })
      %Bookk.JournalEntry{
        ledger_name: "acme",
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
