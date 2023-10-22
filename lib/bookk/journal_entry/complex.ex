defmodule Bookk.JournalEntry.Complex do
  @moduledoc false

  import Enum, only: [all?: 2, map: 2]

  alias __MODULE__, as: ComplexEntry
  alias Bookk.JournalEntry, as: JournalEntry

  @typedoc false
  @type t :: %Bookk.JournalEntry.Complex{
          entries: [Bookk.JournalEntry.t()]
        }

  defstruct entries: []

  @doc """

  ## Examples

  Balanced entry:

      iex> complex = %Bookk.JournalEntry.Complex{
      iex>   entries: [
      iex>     %Bookk.JournalEntry{
      iex>       ledger_name: "acme",
      iex>       operations: [
      iex>         fixture_account_head(:cash) |> debit(30_00),
      iex>         fixture_account_head(:deposits) |> credit(30_00)
      iex>       ]
      iex>     }
      iex>   ]
      iex> }
      iex>
      iex> Bookk.JournalEntry.Complex.balanced?(complex)
      true

  Unbalanced entry:

      iex> complex = %Bookk.JournalEntry.Complex{
      iex>   entries: [
      iex>     %Bookk.JournalEntry{
      iex>       operations: [
      iex>         fixture_account_head(:cash) |> debit(30_00),
      iex>       ]
      iex>     }
      iex>   ]
      iex> }
      iex>
      iex> Bookk.JournalEntry.Complex.balanced?(complex)
      false

  """
  @spec balanced?(t) :: boolean

  def balanced?(%ComplexEntry{} = entry),
    do: all?(entry.entries, &JournalEntry.balanced?/1)

  @doc """

  ## Examples

      iex> Bookk.JournalEntry.Complex.empty?(%Bookk.JournalEntry.Complex{})
      true

      iex> Bookk.JournalEntry.Complex.empty?(%Bookk.JournalEntry.Complex{
      iex>   entries: [
      iex>     %Bookk.JournalEntry{
      iex>       operations: [%Bookk.Operation{amount: 0}]
      iex>     }
      iex>   ]
      iex> })
      true

      iex> Bookk.JournalEntry.Complex.empty?(%Bookk.JournalEntry.Complex{
      iex>   entries: [
      iex>     %Bookk.JournalEntry{
      iex>       operations: [%Bookk.Operation{amount: 1}]
      iex>     }
      iex>   ]
      iex> })
      false

  """
  @spec empty?(t) :: boolean

  def empty?(%ComplexEntry{entries: []}), do: true
  def empty?(%ComplexEntry{entries: entries}), do: all?(entries, &JournalEntry.empty?/1)

  @doc """

  ## Examples

      iex> Bookk.JournalEntry.Complex.reverse(%Bookk.JournalEntry.Complex{
      iex>   entries: [
      iex>     %Bookk.JournalEntry{
      iex>       operations: [
      iex>         fixture_account_head(:cash) |> debit(10_00),
      iex>         fixture_account_head(:deposits) |> credit(10_00)
      iex>       ]
      iex>     }
      iex>   ]
      iex> })
      %Bookk.JournalEntry.Complex{
        entries: [
          %Bookk.JournalEntry{
            operations: [
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
      |> map(&JournalEntry.reverse/1)
      |> :lists.reverse()

    %{entry | entries: entries}
  end
end
