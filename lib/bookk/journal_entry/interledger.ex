defmodule Bookk.JournalEntry.Interledger do
  @moduledoc false

  import Enum, only: [all?: 2, map: 2, to_list: 1]
  import List, only: [flatten: 1]
  import Map, only: [values: 1]

  alias __MODULE__, as: InterledgerEntry
  alias Bookk.JournalEntry, as: JournalEntry

  @typedoc false
  @type t :: %Bookk.JournalEntry.Interledger{
          entries_by_ledger: %{
            (ledger_name :: String.t()) => Bookk.JournalEntry.t()
          }
        }

  defstruct entries_by_ledger: %{}

  @doc """

  ## Examples

  Balanced entry:

      iex> interledger = %Bookk.JournalEntry.Interledger{
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
      iex> Bookk.JournalEntry.Interledger.balanced?(interledger)
      true

  Unbalanced entry:

      iex> interledger = %Bookk.JournalEntry.Interledger{
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
      iex> Bookk.JournalEntry.Interledger.balanced?(interledger)
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

      iex> Bookk.JournalEntry.Interledger.empty?(%Bookk.JournalEntry.Interledger{})
      true

      iex> interledger = %Bookk.JournalEntry.Interledger{
      iex>   entries_by_ledger: %{
      iex>     "acme" => [
      iex>       %Bookk.JournalEntry{
      iex>         operations: [%Bookk.Operation{amount: 0}]
      iex>       }
      iex>     ]
      iex>   }
      iex> }
      iex>
      iex> Bookk.JournalEntry.Interledger.empty?(interledger)
      true

      iex> interledger = %Bookk.JournalEntry.Interledger{
      iex>   entries_by_ledger: %{
      iex>     "acme" => [
      iex>       %Bookk.JournalEntry{
      iex>         operations: [%Bookk.Operation{amount: 1}]
      iex>       }
      iex>     ]
      iex>   }
      iex> }
      iex>
      iex> Bookk.JournalEntry.Interledger.empty?(interledger)
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

      iex> interledger = %Bookk.JournalEntry.Interledger{
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
      iex> Bookk.JournalEntry.Interledger.reverse(interledger)
      %Bookk.JournalEntry.Interledger{
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
    enum = to_list(entries_by_ledger)

    entries_by_ledger =
      for {ledger, entries} <- enum,
          into: %{},
          do: {ledger, map(entries, &JournalEntry.reverse/1) |> :lists.reverse()}

    %{entry | entries_by_ledger: entries_by_ledger}
  end
end
