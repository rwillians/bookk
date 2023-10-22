defmodule Bookk.JournalEntry.Complex do
  @moduledoc false

  import Enum, only: [all?: 2, map: 2]

  alias __MODULE__, as: ComplexEntry
  alias Bookk.JournalEntry.Compound, as: CompoundEntry

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

  def balanced?(%ComplexEntry{} = entry),
    do: all?(entry.entries, &CompoundEntry.balanced?/1)

  @doc """
  Checks whether the given complex journal entry is empty, where it is empty
  when it has no entries or when all its entries are empty.

  ## Examples

      iex> Bookk.JournalEntry.Complex.empty?(%Bookk.JournalEntry.Complex{})
      true

      iex> Bookk.JournalEntry.Complex.empty?(%Bookk.JournalEntry.Complex{
      iex>   entries: [
      iex>     %Bookk.JournalEntry.Compound{
      iex>       entries: [%Bookk.Operation{amount: 0}]
      iex>     }
      iex>   ]
      iex> })
      true

      iex> Bookk.JournalEntry.Complex.empty?(%Bookk.JournalEntry.Complex{
      iex>   entries: [
      iex>     %Bookk.JournalEntry.Compound{
      iex>       entries: [%Bookk.Operation{amount: 1}]
      iex>     }
      iex>   ]
      iex> })
      false
  """
  @spec empty?(t) :: boolean

  def empty?(%ComplexEntry{entries: []}), do: true
  def empty?(%ComplexEntry{entries: entries}), do: all?(entries, &CompoundEntry.empty?/1)

  @doc """
  Given a complex journal entry, it returns an opposite journal entry capable of
  reverting the effects of the given entry.

  ## Examples

      iex> Bookk.JournalEntry.Complex.reverse(%Bookk.JournalEntry.Complex{
      iex>   entries: [
      iex>     %Bookk.JournalEntry.Compound{
      iex>       entries: [
      iex>         fixture_account_head(:cash) |> debit(10_00),
      iex>         fixture_account_head(:deposits) |> credit(10_00)
      iex>       ]
      iex>     }
      iex>   ]
      iex> })
      %Bookk.JournalEntry.Complex{
        entries: [
          %Bookk.JournalEntry.Compound{
            entries: [
              fixture_account_head(:deposits) |> debit(10_00),
              fixture_account_head(:cash) |> credit(10_00)
            ]
          }
        ]
      }

  """
  @spec reverse(t) :: t

  def reverse(%ComplexEntry{} = entry) do
    entries =
      entry.entries
      |> map(&CompoundEntry.reverse/1)
      |> :lists.reverse()

    %{entry | entries: entries}
  end
end
