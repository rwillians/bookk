# credo:disable-for-this-file Credo.Check.Refactor.ABCSize
#
#   NOTE: C'est la vie
#
defmodule Bookk.InterledgerEntry do
  @moduledoc ~S"""
  An interledger entry is a collection of journal entries affecting
  multiple ledgers that must be transacted under the same accounting
  transaction. It's somewhat analogous to an `Ecto.Multi` holding
  multiple operations or a git commit that affect multiple files.

  ## Related

  - `Bookk.Notation`;
  - `Bookk.NaiveState`;
  - `Bookk.JournalEntry`.
  """

  import Enum, only: [all?: 2, map: 2, to_list: 1]
  import List, only: [flatten: 1]
  import Map, only: [values: 1]

  alias __MODULE__, as: InterledgerEntry
  alias Bookk.JournalEntry

  @typedoc ~S"""
  The struct that represents an interledger entry.

  ## Fields

  An interledger entry is composed of:
  - `entries_by_ledger_id`: the map of journal entries that are included
    in the interledger entry, grouped by the name of the ledger
    against which they should be posted.
  """
  @type t :: %Bookk.InterledgerEntry{
          entries_by_ledger_id: %{
            (ledger_id :: String.t()) => Bookk.JournalEntry.t()
          }
        }

  defstruct entries_by_ledger_id: %{}

  @doc ~S"""
  Checks whether the interledger entry is balanced. It is balance if
  all of its journal entries are balanced.

  ## Examples

  Balanced entry:

      iex> interledger_entry = Bookk.InterledgerEntry.new([
      iex>   {"acme", Bookk.JournalEntry.new([
      iex>     debit(fixture_account_head(:cash), Decimal.new(30)),
      iex>     credit(fixture_account_head(:deposits), Decimal.new(30))
      iex>   ])}
      iex> ])
      iex>
      iex> Bookk.InterledgerEntry.balanced?(interledger_entry)
      true

  Unbalanced entry:

      iex> interledger_entry = Bookk.InterledgerEntry.new([
      iex>   {"acme", Bookk.JournalEntry.new([
      iex>     debit(fixture_account_head(:cash), Decimal.new(30))
      iex>   ])},
      iex> ])
      iex>
      iex> Bookk.InterledgerEntry.balanced?(interledger_entry)
      false

  """
  @spec balanced?(t) :: boolean

  def balanced?(%InterledgerEntry{entries_by_ledger_id: %{} = entries_by_ledger_id}) do
    values(entries_by_ledger_id)
    |> flatten()
    |> all?(&JournalEntry.balanced?/1)
  end

  @doc ~S"""
  Raises `Bookk.UnbalancedError` if the interledger entry is
  unbalanced, otherwise returns the entry.

      iex> interledger_entry = Bookk.InterledgerEntry.new([
      iex>   {"acme", Bookk.JournalEntry.new([
      iex>     debit(fixture_account_head(:cash), Decimal.new(30))
      iex>   ])},
      iex> ])
      iex>
      iex> Bookk.InterledgerEntry.balanced!(interledger_entry)
      ** (Bookk.UnbalancedError) The interledger entry is unbalanced!


      iex> interledger_entry = Bookk.InterledgerEntry.new([
      iex>   {"acme", Bookk.JournalEntry.new([
      iex>     debit(fixture_account_head(:cash), Decimal.new(30)),
      iex>     credit(fixture_account_head(:deposits), Decimal.new(30))
      iex>   ])},
      iex> ])
      iex>
      iex> Bookk.InterledgerEntry.balanced!(interledger_entry)
      Bookk.InterledgerEntry.new([
        {"acme", Bookk.JournalEntry.new([
          debit(fixture_account_head(:cash), Decimal.new(30)),
          credit(fixture_account_head(:deposits), Decimal.new(30))
        ])}
      ])

  """
  @spec balanced!(t) :: t

  def balanced!(%InterledgerEntry{} = entry) do
    case InterledgerEntry.balanced?(entry) do
      true -> entry
      false -> raise(Bookk.UnbalancedError, message: "The interledger entry is unbalanced!")
    end
  end

  @doc ~S"""
  Compacts the interledger entry by merging all journal entries that
  target the same ledger into a single journal entry.

  ## Examples

      iex> interledger_entry = Bookk.InterledgerEntry.new([
      iex>   {"acme", Bookk.JournalEntry.new([
      iex>     debit(fixture_account_head(:cash), Decimal.new(10)),
      iex>     credit(fixture_account_head(:deposits), Decimal.new(10))
      iex>   ])},
      iex>   {"acme", Bookk.JournalEntry.new([
      iex>     debit(fixture_account_head(:cash), Decimal.new(10)),
      iex>     credit(fixture_account_head(:deposits), Decimal.new(10))
      iex>   ])}
      iex> ])
      iex>
      iex> Bookk.InterledgerEntry.compact(interledger_entry)
      Bookk.InterledgerEntry.new([
        {"acme", Bookk.JournalEntry.new([
          debit(fixture_account_head(:cash), Decimal.new(20)),
          credit(fixture_account_head(:deposits), Decimal.new(20))
        ])}
      ])

  """
  @spec compact(t) :: t

  def compact(%InterledgerEntry{} = entry) do
    entries_by_ledger_id =
      entry.entries_by_ledger_id
      |> Enum.map(fn {ledger, entries} -> {ledger, [JournalEntry.merge(entries)]} end)
      |> Enum.into(%{})

    %InterledgerEntry{entries_by_ledger_id: entries_by_ledger_id}
  end

  @doc ~S"""
  Calculates a `Bookk.InterledgerEntry` represending the diff between
  two `Bookk.InterledgerEntry` where, if the diff interledger entry
  were to be merged with interledger entry "a", it would become equal
  to interledger entry "b".

  ## Examples

      iex> a = Bookk.InterledgerEntry.new([
      iex>   {"acme", Bookk.JournalEntry.new([
      iex>     debit(fixture_account_head(:cash), Decimal.new(50)),
      iex>     credit(fixture_account_head(:deposits), Decimal.new(50)),
      iex>   ])},
      iex>   {"acme", Bookk.JournalEntry.new([
      iex>     debit(fixture_account_head(:cash), Decimal.new(25)),
      iex>     credit(fixture_account_head(:deposits), Decimal.new(25)),
      iex>   ])},
      iex> ])
      iex>
      iex> b = Bookk.InterledgerEntry.new([
      iex>   {"acme", Bookk.JournalEntry.new([
      iex>     debit(fixture_account_head(:cash), Decimal.new(100)),
      iex>     credit(fixture_account_head(:deposits), Decimal.new(100)),
      iex>   ])},
      iex>   {"acme", Bookk.JournalEntry.new([
      iex>     debit(fixture_account_head(:cash), Decimal.new(50)),
      iex>     credit(fixture_account_head(:deposits), Decimal.new(50)),
      iex>   ])},
      iex> ])
      iex>
      iex> Bookk.InterledgerEntry.diff(a, b)
      Bookk.InterledgerEntry.new([
        {"acme", Bookk.JournalEntry.new([
          debit(fixture_account_head(:cash), Decimal.new(75)),
          credit(fixture_account_head(:deposits), Decimal.new(75)),
        ])}
      ])

  """
  @spec diff(a :: t(), b :: t()) :: t()

  def diff(%InterledgerEntry{} = a, %InterledgerEntry{} = b) do
    a = compact(a)
    b = compact(b)
    #   ↑ so there's at most 1 journal entry per ledger

    ledger_ids =
      []
      |> Enum.concat(Map.keys(a.entries_by_ledger_id))
      |> Enum.concat(Map.keys(b.entries_by_ledger_id))
      |> Enum.uniq()
      #       ↓ so the result has a deterministic order of entries
      |> Enum.sort()

    entries =
      for ledger_id <- ledger_ids do
        lhs = get_journal_entry(a, ledger_id)
        rhs = get_journal_entry(b, ledger_id)

        {ledger_id, JournalEntry.diff(lhs, rhs)}
      end

    new(entries)
  end

  defp get_journal_entry(%InterledgerEntry{} = entry, <<ledger_id::binary>>) do
    case get_journal_entries(entry, ledger_id) do
      # ↓ it's supposed to only ever be called on a compact interledger entry
      [%JournalEntry{} = journal_entry] -> journal_entry
      [] -> Bookk.JournalEntry.new([])
    end
  end

  @doc ~S"""
  Checks whether an interledger entry is empty. It is empty when it
  has now journal entries or when all its journal entries are empty.

  See `Bookk.JournalEntry.empty?/1` to learn more about empty journal
  entries.

  ## Examples

  Is empty when there's no entries:

      iex> Bookk.InterledgerEntry.empty?(%Bookk.InterledgerEntry{})
      true

  Is empty when all entries are empty:

      iex> interledger = Bookk.InterledgerEntry.new([
      iex>   {"acme", Bookk.JournalEntry.new([
      iex>     debit(fixture_account_head(:cash), Decimal.new(0))
      iex>   ])}
      iex> ])
      iex>
      iex> Bookk.InterledgerEntry.empty?(interledger)
      true

  Is not empty when at least one entry isn't empty:

      iex> interledger = Bookk.InterledgerEntry.new([
      iex>   {"acme", Bookk.JournalEntry.new([
      iex>     debit(fixture_account_head(:cash), Decimal.new(1))
      iex>   ])}
      iex> ])
      iex>
      iex> Bookk.InterledgerEntry.empty?(interledger)
      false

  """
  @spec empty?(t) :: boolean

  def empty?(%InterledgerEntry{entries_by_ledger_id: %{} = entries_by_ledger_id}) do
    values(entries_by_ledger_id)
    |> flatten()
    |> all?(&JournalEntry.empty?/1)
  end

  @doc ~S"""
  Get the journal entries for a given ledger id.

  ## Examples

  When exists journal entries for the given ledger id:

      iex> interledger_entry = Bookk.InterledgerEntry.new([
      iex>   {"acme", Bookk.JournalEntry.new([
      iex>     debit(fixture_account_head(:cash), Decimal.new(50)),
      iex>     credit(fixture_account_head({:unspent_cash, {:user, "12345"}}), Decimal.new(50))
      iex>   ])}
      iex> ])
      iex>
      iex> Bookk.InterledgerEntry.get_journal_entries(interledger_entry, "acme")
      [
        Bookk.JournalEntry.new([
          debit(fixture_account_head(:cash), Decimal.new(50)),
          credit(fixture_account_head({:unspent_cash, {:user, "12345"}}), Decimal.new(50))
        ])
      ]

  Returns an empty array when there's no journal entries for the given
  ledger id:

      iex> Bookk.InterledgerEntry.new([])
      iex> |> Bookk.InterledgerEntry.get_journal_entries("acme")
      []

  """
  @spec get_journal_entries(t, ledger_id :: String.t()) :: [Bookk.JournalEntry.t()]

  def get_journal_entries(%InterledgerEntry{} = entry, <<ledger_id::binary>>),
    do: Map.get(entry.entries_by_ledger_id, ledger_id, [])

  @doc ~S"""
  Merges a set of interledger entries into one.

  ## Examples

      iex> a = Bookk.InterledgerEntry.new([
      iex>   {"acme", Bookk.JournalEntry.new([
      iex>     debit(fixture_account_head(:cash), Decimal.new(10)),
      iex>     credit(fixture_account_head(:deposits), Decimal.new(10))
      iex>   ])}
      iex> ])
      iex>
      iex> b = Bookk.InterledgerEntry.new([
      iex>   {"acme", Bookk.JournalEntry.new([
      iex>     debit(fixture_account_head(:cash), Decimal.new(10)),
      iex>     credit(fixture_account_head(:deposits), Decimal.new(10))
      iex>   ])}
      iex> ])
      iex>
      iex> Bookk.InterledgerEntry.merge([a, b])
      Bookk.InterledgerEntry.new([
        {"acme", Bookk.JournalEntry.new([
          debit(fixture_account_head(:cash), Decimal.new(10)),
          credit(fixture_account_head(:deposits), Decimal.new(10))
        ])},
        {"acme", Bookk.JournalEntry.new([
          debit(fixture_account_head(:cash), Decimal.new(10)),
          credit(fixture_account_head(:deposits), Decimal.new(10))
        ])}
      ])

  """
  @spec merge([t]) :: t

  def merge([]), do: new()
  def merge([%InterledgerEntry{} = entry]), do: entry
  def merge([head | tail]), do: merge(head, merge(tail))

  @doc ~S"""
  Merges two interledger entries into one.

  ## Examples

      iex> a = Bookk.InterledgerEntry.new([
      iex>   {"acme", Bookk.JournalEntry.new([
      iex>     debit(fixture_account_head(:cash), Decimal.new(10)),
      iex>     credit(fixture_account_head(:deposits), Decimal.new(10))
      iex>   ])}
      iex> ])
      iex>
      iex> b = Bookk.InterledgerEntry.new([
      iex>   {"acme", Bookk.JournalEntry.new([
      iex>     debit(fixture_account_head(:cash), Decimal.new(10)),
      iex>     credit(fixture_account_head(:deposits), Decimal.new(10))
      iex>   ])}
      iex> ])
      iex>
      iex> Bookk.InterledgerEntry.merge(a, b)
      Bookk.InterledgerEntry.new([
        {"acme", Bookk.JournalEntry.new([
          debit(fixture_account_head(:cash), Decimal.new(10)),
          credit(fixture_account_head(:deposits), Decimal.new(10))
        ])},
        {"acme", Bookk.JournalEntry.new([
          debit(fixture_account_head(:cash), Decimal.new(10)),
          credit(fixture_account_head(:deposits), Decimal.new(10))
        ])}
      ])

  """
  @spec merge(t, t) :: t

  def merge(%InterledgerEntry{} = a, %InterledgerEntry{} = b) do
    entries_by_ledger_id =
      to_journal_entries(a)
      |> Enum.concat(to_journal_entries(b))
      |> Enum.group_by(fn {ledger, _} -> ledger end, fn {_, entries} -> entries end)
      |> Enum.map(fn {ledger, xs} -> {ledger, flatten(xs)} end)
      |> Enum.into(%{})

    %InterledgerEntry{entries_by_ledger_id: entries_by_ledger_id}
  end

  @doc ~S"""
  Creates a new interledger entry from a list of ledger + journal entry
  tuple.

  ## Examples

      iex> Bookk.InterledgerEntry.new([
      iex>   {"acme", Bookk.JournalEntry.new([
      iex>     debit(fixture_account_head(:cash), Decimal.new(50)),
      iex>     credit(fixture_account_head({:unspent_cash, {:user, "12345"}}), Decimal.new(50))
      iex>   ])},
      iex>   {"user(12345)", Bookk.JournalEntry.new([
      iex>     debit(fixture_account_head(:cash), Decimal.new(50)),
      iex>     credit(fixture_account_head(:deposits), Decimal.new(50))
      iex>   ])}
      iex> ])
      %Bookk.InterledgerEntry{
        entries_by_ledger_id: %{
          "acme" => [
            Bookk.JournalEntry.new([
              debit(fixture_account_head(:cash), Decimal.new(50)),
              credit(fixture_account_head({:unspent_cash, {:user, "12345"}}), Decimal.new(50))
            ])
          ],
          "user(12345)" => [
            Bookk.JournalEntry.new([
              debit(fixture_account_head(:cash), Decimal.new(50)),
              credit(fixture_account_head(:deposits), Decimal.new(50))
            ])
          ]
        }
      }

  """
  @spec new([entry]) :: t
        when entry: {ledger_id :: String.t(), Bookk.JournalEntry.t()}

  def new(entries \\ [])
  def new([]), do: %InterledgerEntry{}

  def new([_ | _] = entries) do
    entries_by_ledger_id =
      entries
      |> Enum.group_by(fn {<<ledger::binary>>, _} -> ledger end, fn {_, %JournalEntry{} = entry} -> entry end)
      |> Enum.into(%{})

    %InterledgerEntry{entries_by_ledger_id: entries_by_ledger_id}
  end

  @doc ~S"""
  Produces a new interledger entry that is equaly opposite of the
  given interledger entry, meaning its capable of reverting all the
  changes that the given entry causes.

  ## Examples

  Reverses all of its journal entries:

      iex> interledger = Bookk.InterledgerEntry.new([
      iex>   {"acme", Bookk.JournalEntry.new([
      iex>     debit(fixture_account_head(:cash), Decimal.new(10)),
      iex>     credit(fixture_account_head(:deposits), Decimal.new(10))
      iex>   ])}
      iex> ])
      iex>
      iex> Bookk.InterledgerEntry.reverse(interledger)
      Bookk.InterledgerEntry.new([
        {"acme", Bookk.JournalEntry.new([
          debit(fixture_account_head(:deposits), Decimal.new(10)),
          credit(fixture_account_head(:cash), Decimal.new(10))
        ])}
      ])

  """
  @spec reverse(t) :: t

  def reverse(%InterledgerEntry{entries_by_ledger_id: %{} = entries_by_ledger_id} = entry) do
    entries_by_ledger_id =
      for {ledger, entries} <- to_list(entries_by_ledger_id),
          into: %{},
          do: {ledger, map(entries, &JournalEntry.reverse/1) |> :lists.reverse()}

    %{entry | entries_by_ledger_id: entries_by_ledger_id}
  end

  @doc ~S"""
  Given an interledger entry, it returns all its journal entries in
  the form of a list of tuples where the first element is the ledger's
  name and the second element is a list of journal entries that are
  meant to be posted to such ledger.

  ## Examples

  Returns a list of tuple where the first element is the ledger name
  and the second element is a journal entry:

      iex> interledger = Bookk.InterledgerEntry.new([
      iex>  {"acme", Bookk.JournalEntry.new([
      iex>    debit(fixture_account_head(:cash), Decimal.new(50)),
      iex>    credit(fixture_account_head({:unspent_cash, {:user, "12345"}}), Decimal.new(50))
      iex>  ])},
      iex>  {"user(12345)", Bookk.JournalEntry.new([
      iex>    debit(fixture_account_head(:cash), Decimal.new(50)),
      iex>    credit(fixture_account_head(:deposits), Decimal.new(50))
      iex>  ])},
      iex> ])
      iex>
      iex> Bookk.InterledgerEntry.to_journal_entries(interledger)
      [
        {"acme", Bookk.JournalEntry.new([
          debit(fixture_account_head(:cash), Decimal.new(50)),
          credit(fixture_account_head({:unspent_cash, {:user, "12345"}}), Decimal.new(50))
        ])},
        {"user(12345)", Bookk.JournalEntry.new([
          debit(fixture_account_head(:cash), Decimal.new(50)),
          credit(fixture_account_head(:deposits), Decimal.new(50))
        ])}
      ]

  """
  @spec to_journal_entries(t) :: [{ledger_id :: String.t(), Bookk.JournalEntry.t()}]

  def to_journal_entries(%InterledgerEntry{} = interledger) do
    for {ledger_id, entries} <- to_list(interledger.entries_by_ledger_id),
        entry <- entries,
        do: {ledger_id, entry}
  end
end
