defmodule Bookk.JournalEntry.Complex do
  @moduledoc false

  import Enum, only: [all?: 2]

  alias __MODULE__, as: ComplexJournalEntry
  alias Bookk.JournalEntry.Compound, as: CompoundJournalEntry

  @typedoc false
  @type t :: %Bookk.JournalEntry.Complex{
          entries: [Bookk.JournalEntry.Compound.t()]
        }

  defstruct entries: []

  @doc """
  Checks whether the given complex journal entry is balanced, where it is
  balance if all of its compound journal entries are balanced.
  """
  @spec balanced?(t) :: boolean

  def balanced?(%ComplexJournalEntry{} = entry),
    do: all?(entry.entries, &CompoundJournalEntry.balanced?/1)

  @doc """
  Checks whether the given complex journal entry is empty, where it is empty
  when it has no entries or when all its entries are empty.

  ## Examples

      iex> Bookk.JournalEntry.Complex.empty?(%Bookk.JournalEntry.Complex{})
      true

      iex> Bookk.JournalEntry.Complex.empty?(%Bookk.JournalEntry.Complex{
      iex>   entries: [
      iex>     %Bookk.JournalEntry.Compound{
      iex>       entries: [%Bookk.JournalEntry.Simple{amount: 0}]
      iex>     }
      iex>   ]
      iex> })
      true

      iex> Bookk.JournalEntry.Complex.empty?(%Bookk.JournalEntry.Complex{
      iex>   entries: [
      iex>     %Bookk.JournalEntry.Compound{
      iex>       entries: [%Bookk.JournalEntry.Simple{amount: 1}]
      iex>     }
      iex>   ]
      iex> })
      false
  """
  @spec empty?(t) :: boolean

  def empty?(%ComplexJournalEntry{entries: []}), do: true
  def empty?(%ComplexJournalEntry{entries: entries}), do: all?(entries, &CompoundJournalEntry.empty?/1)
end
