defmodule Bookk.JournalEntry.Compound do
  @moduledoc false

  import Enum, only: [all?: 2, map: 2, split_with: 2, sum: 1]

  alias __MODULE__, as: CompoundJournalEntry
  alias Bookk.JournalEntry.Simple, as: SimpleJournalEntry

  @typedoc false
  @type t :: %Bookk.JournalEntry.Compound{
          ledger_name: String.t(),
          entries: [Bookk.JournalEntry.Simple.t()]
        }

  defstruct [:ledger_name, entries: []]

  @doc """
  Checks whether the given compound journal entry is balance, where it is
  balanced if the sum of its debit entries is equal the sum of its credit
  entries.
  """
  @spec balanced?(t) :: boolean

  def balanced?(%CompoundJournalEntry{} = entry) do
    {debits, credits} = split_with(entry.entries, & &1.direction == :debit)

    sum_debits = map(debits, & &1.amount) |> sum()
    sum_credits = map(credits, & &1.amount) |> sum()

    sum_debits == sum_credits
  end

  @doc """
  Checks whether the given compound journal entry is empty, where it is empty if
  it has no entries or if all entries are empty.

  ## Examples

     iex> Bookk.JournalEntry.Compound.empty?(%Bookk.JournalEntry.Compound{})
     true

     iex> Bookk.JournalEntry.Compound.empty?(%Bookk.JournalEntry.Compound{
     iex>   entries: [%Bookk.JournalEntry.Simple{amount: 0}]
     iex> })
     true

     iex> Bookk.JournalEntry.Compound.empty?(%Bookk.JournalEntry.Compound{
     iex>   entries: [%Bookk.JournalEntry.Simple{amount: 10_00}]
     iex> })
     false

  """
  @spec empty?(t) :: boolean

  def empty?(%CompoundJournalEntry{entries: []}), do: true
  def empty?(%CompoundJournalEntry{entries: entries}), do: all?(entries, &SimpleJournalEntry.empty?/1)
end
