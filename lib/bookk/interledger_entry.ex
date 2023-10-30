defmodule Bookk.InterledgerEntry do
  @moduledoc """
  An interledger entry is a collection of journal entries affecting multiple
  ledgers that must be transacted under the same accounting transaction. It's
  somewhat analogous to an `Ecto.Multi` or a git commit that affect multiple
  files.

  ## Related

  - `Bookk.Notation`;
  - `Bookk.NaiveState`;
  - `Bookk.JournalEntry`.
  """

  import Enum, only: [all?: 2, map: 2, to_list: 1]
  import List, only: [flatten: 1]
  import Map, only: [values: 1]

  alias __MODULE__, as: InterledgerEntry
  alias Bookk.JournalEntry, as: JournalEntry

  @typedoc """
  The struct that represents an interledger entry.

  ## Fields

  An interledger entry is composed of:
  - `entries_by_ledger`: the map of journal entries that are included in the
    interledger entry, grouped by the name of the ledger against which they
    should be posted.
  """
  @type t :: %Bookk.InterledgerEntry{
          entries_by_ledger: %{
            (ledger_name :: String.t()) => Bookk.JournalEntry.t()
          }
        }

  defstruct entries_by_ledger: %{}

  @doc """
  Checks whether the interledger entry is balanced. It is balance if all of its
  journal entries are balanced.

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

  def balanced?(%InterledgerEntry{entries_by_ledger: %{} = entries_by_ledger}) do
    values(entries_by_ledger)
    |> flatten()
    |> all?(&JournalEntry.balanced?/1)
  end

  @doc """
  Checks whether an interledger entry is empty. It is empty when it has now
  journal entries or when all its journal entries are empty.

  See `Bookk.JournalEntry.empty?/1` to learn more about empty journal entries.

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

  def empty?(%InterledgerEntry{entries_by_ledger: %{} = entries_by_ledger}) do
    values(entries_by_ledger)
    |> flatten()
    |> all?(&JournalEntry.empty?/1)
  end

  @doc """
  Produces a new interledger entry that is equaly opposite of the given
  interledger entry, meaning its capable of reverting all the changes that the
  given entry causes.

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

  @doc """
  Given an interledger entry, it returns all its journal entries in the form
  of a list of tuples where the first element is the ledger's name and the
  second element is a list of journal entries that are meant to be posted to
  such ledger.

  ## Examples

  Returns a list of tuple where the first element is the ledger name and the
  second element is a journal entry:

      iex> user_id = "b13a81cf-ff78-414d-b5b2-042e9ecf2082"
      iex> cash = fixture_account_head(:cash)
      iex> deposits = fixture_account_head(:deposits)
      iex> unspent_cash = fixture_account_head({:unspent_cash, {:user, user_id}})
      iex>
      iex> interledger = %Bookk.InterledgerEntry{
      iex>   entries_by_ledger: %{
      iex>     "acme" => [
      iex>       Bookk.JournalEntry.new([
      iex>         debit(cash, 50_00),
      iex>         credit(unspent_cash, 50_00)
      iex>       ])
      iex>     ],
      iex>     "user(b13a81cf-ff78-414d-b5b2-042e9ecf2082)" => [
      iex>       Bookk.JournalEntry.new([
      iex>         debit(cash, 50_00),
      iex>         credit(deposits, 50_00)
      iex>       ])
      iex>     ]
      iex>   }
      iex> }
      iex>
      iex> Bookk.InterledgerEntry.to_journal_entries(interledger)
      [
        {"acme", Bookk.JournalEntry.new([
          debit(fixture_account_head(:cash), 50_00),
          credit(fixture_account_head({:unspent_cash, {:user, "b13a81cf-ff78-414d-b5b2-042e9ecf2082"}}), 50_00)
        ])},
        {"user(b13a81cf-ff78-414d-b5b2-042e9ecf2082)", Bookk.JournalEntry.new([
          debit(fixture_account_head(:cash), 50_00),
          credit(fixture_account_head(:deposits), 50_00)
        ])}
      ]

  """
  @spec to_journal_entries(t) :: [{ledger_name :: String.t(), Bookk.JournalEntry.t()}]

  def to_journal_entries(%InterledgerEntry{} = interledger) do
    for {ledger_name, entries} <- to_list(interledger.entries_by_ledger),
        entry <- entries,
        do: {ledger_name, entry}
  end
end
