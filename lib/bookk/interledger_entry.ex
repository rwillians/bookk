defmodule Bookk.InterledgerEntry do
  @moduledoc false

  import Enum, only: [all?: 2, map: 2, to_list: 1]
  import List, only: [flatten: 1]
  import Map, only: [values: 1]

  alias __MODULE__, as: InterledgerEntry
  alias Bookk.JournalEntry, as: JournalEntry

  @typedoc false
  @type t :: %Bookk.InterledgerEntry{
          entries_by_ledger: %{
            (ledger_name :: String.t()) => Bookk.JournalEntry.t()
          }
        }

  defstruct entries_by_ledger: %{}

  @doc """

  ## Examples

  Balanced entry:

      iex> interledger = %Bookk.InterledgerEntry{
      iex>   entries_by_ledger: %{
      iex>     "acme" => [
      iex>       %Bookk.JournalEntry{
      iex>         operations: [
      iex>           fixture_account_head(:cash) |> debit(30_00),
      iex>           fixture_account_head(:deposits) |> credit(30_00)
      iex>         ]
      iex>       }
      iex>     ]
      iex>   }
      iex> }
      iex>
      iex> Bookk.InterledgerEntry.balanced?(interledger)
      true

  Unbalanced entry:

      iex> interledger = %Bookk.InterledgerEntry{
      iex>   entries_by_ledger: %{
      iex>     "acme" => [
      iex>       %Bookk.JournalEntry{
      iex>         operations: [
      iex>           fixture_account_head(:cash) |> debit(30_00),
      iex>         ]
      iex>       }
      iex>     ]
      iex>   }
      iex> }
      iex>
      iex> Bookk.InterledgerEntry.balanced?(interledger)
      false

  """
  @spec balanced?(t) :: boolean

  def balanced?(%InterledgerEntry{entries_by_ledger: %{} = entries_by_ledger})
      when map_size(entries_by_ledger) == 0,
      do: true

  def balanced?(%InterledgerEntry{entries_by_ledger: %{} = entries_by_ledger}) do
    values(entries_by_ledger)
    |> flatten()
    |> all?(&JournalEntry.balanced?/1)
  end

  @doc """

  ## Examples

  Is empty when there's no entries:

      iex> Bookk.InterledgerEntry.empty?(%Bookk.InterledgerEntry{})
      true

  Is empty when all entries are empty:

      iex> interledger = %Bookk.InterledgerEntry{
      iex>   entries_by_ledger: %{
      iex>     "acme" => [
      iex>       %Bookk.JournalEntry{
      iex>         operations: [%Bookk.Operation{amount: 0}]
      iex>       }
      iex>     ]
      iex>   }
      iex> }
      iex>
      iex> Bookk.InterledgerEntry.empty?(interledger)
      true

  Is not empty when at least one entry isn't empty:

      iex> interledger = %Bookk.InterledgerEntry{
      iex>   entries_by_ledger: %{
      iex>     "acme" => [
      iex>       %Bookk.JournalEntry{
      iex>         operations: [
      iex>           %Bookk.Operation{amount: 0},
      iex>           %Bookk.Operation{amount: 1},
      iex>         ]
      iex>       }
      iex>     ]
      iex>   }
      iex> }
      iex>
      iex> Bookk.InterledgerEntry.empty?(interledger)
      false

  """
  @spec empty?(t) :: boolean

  def empty?(%InterledgerEntry{entries_by_ledger: %{} = map})
      when map_size(map) == 0,
      do: true

  def empty?(%InterledgerEntry{entries_by_ledger: %{} = entries_by_ledger}) do
    values(entries_by_ledger)
    |> flatten()
    |> all?(&JournalEntry.empty?/1)
  end

  @doc """

  ## Examples

  Reverses all of its journal entries:

      iex> interledger = %Bookk.InterledgerEntry{
      iex>   entries_by_ledger: %{
      iex>     "acme" => [
      iex>       %Bookk.JournalEntry{
      iex>         operations: [
      iex>           fixture_account_head(:cash) |> debit(10_00),
      iex>           fixture_account_head(:deposits) |> credit(10_00)
      iex>         ]
      iex>       }
      iex>     ]
      iex>   }
      iex> }
      iex>
      iex> Bookk.InterledgerEntry.reverse(interledger)
      %Bookk.InterledgerEntry{
        entries_by_ledger: %{
          "acme" => [
            %Bookk.JournalEntry{
              operations: [
                fixture_account_head(:deposits) |> debit(10_00),
                fixture_account_head(:cash) |> credit(10_00)
              ]
            }
          ]
        }
      }

  """
  @spec reverse(t) :: t

  def reverse(%InterledgerEntry{entries_by_ledger: %{} = entries_by_ledger} = entry) do
    entries_by_ledger =
      for {ledger, entries} <- to_list(entries_by_ledger),
          into: %{},
          do: {ledger, map(entries, &JournalEntry.reverse/1) |> :lists.reverse()}

    %{entry | entries_by_ledger: entries_by_ledger}
  end
end
