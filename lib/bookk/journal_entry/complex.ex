defmodule Bookk.JournalEntry.Complex do
  @moduledoc false

  import Enum, only: [all?: 2, map: 2, to_list: 1]
  import List, only: [flatten: 1]
  import Map, only: [values: 1]

  alias __MODULE__, as: ComplexEntry
  alias Bookk.JournalEntry, as: JournalEntry

  @typedoc false
  @type t :: %Bookk.JournalEntry.Complex{
          entries_by_ledger: %{
            (ledger_name :: String.t()) => Bookk.JournalEntry.t()
          }
        }

  defstruct entries_by_ledger: %{}

  @doc """

  ## Examples

  Balanced entry:

      iex> complex = %Bookk.JournalEntry.Complex{
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
      iex> Bookk.JournalEntry.Complex.balanced?(complex)
      true

  Unbalanced entry:

      iex> complex = %Bookk.JournalEntry.Complex{
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
      iex> Bookk.JournalEntry.Complex.balanced?(complex)
      false

  """
  @spec balanced?(t) :: boolean

  def balanced?(%ComplexEntry{entries_by_ledger: %{} = entries_by_ledger})
      when map_size(entries_by_ledger) == 0,
      do: true

  def balanced?(%ComplexEntry{entries_by_ledger: %{} = entries_by_ledger}) do
    values(entries_by_ledger)
    |> flatten()
    |> all?(&JournalEntry.balanced?/1)
  end

  @doc """

  ## Examples

      iex> Bookk.JournalEntry.Complex.empty?(%Bookk.JournalEntry.Complex{})
      true

      iex> complex = %Bookk.JournalEntry.Complex{
      iex>   entries_by_ledger: %{
      iex>     "acme" => [
      iex>       %Bookk.JournalEntry{
      iex>         operations: [%Bookk.Operation{amount: 0}]
      iex>       }
      iex>     ]
      iex>   }
      iex> }
      iex>
      iex> Bookk.JournalEntry.Complex.empty?(complex)
      true

      iex> complex = %Bookk.JournalEntry.Complex{
      iex>   entries_by_ledger: %{
      iex>     "acme" => [
      iex>       %Bookk.JournalEntry{
      iex>         operations: [%Bookk.Operation{amount: 1}]
      iex>       }
      iex>     ]
      iex>   }
      iex> }
      iex>
      iex> Bookk.JournalEntry.Complex.empty?(complex)
      false

  """
  @spec empty?(t) :: boolean

  def empty?(%ComplexEntry{entries_by_ledger: %{} = map})
      when map_size(map) == 0,
      do: true

  def empty?(%ComplexEntry{entries_by_ledger: %{} = entries_by_ledger}) do
    values(entries_by_ledger)
    |> flatten()
    |> all?(&JournalEntry.empty?/1)
  end

  @doc """

  ## Examples

      iex> complex = %Bookk.JournalEntry.Complex{
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
      iex> Bookk.JournalEntry.Complex.reverse(complex)
      %Bookk.JournalEntry.Complex{
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

  def reverse(%ComplexEntry{entries_by_ledger: %{} = entries_by_ledger} = entry) do
    enum = to_list(entries_by_ledger)

    entries_by_ledger =
      for {ledger, entries} <- enum,
          into: %{},
          do: {ledger, map(entries, &JournalEntry.reverse/1) |> :lists.reverse()}

    %{entry | entries_by_ledger: entries_by_ledger}
  end
end
