# credo:disable-for-this-file Credo.Check.Refactor.ABCSize
#
#   NOTE: C'est la vie
#
defmodule Bookk.Ledger do
  @moduledoc ~S"""
  A ledger is a book that holds accounts. Traditionally, ledgers would
  also hold the journal entries that changed the accounts but, in this
  library, persisting those journal entries is considered off scope.
  You may persist state the way the best fits your needs.

  ## Related

  - `Bookk.Account`;
  - `Bookk.JournalEntry`.
  """

  import Enum, only: [reduce: 3, split_with: 2]
  import Map, only: [get: 2, put: 3, values: 1]

  alias __MODULE__, as: Ledger
  alias Bookk.Account
  alias Bookk.AccountHead
  alias Bookk.JournalEntry
  alias Bookk.Operation, as: Op

  @typedoc ~S"""
  The struct that represents a ledger.

  ## Fields

  - `id`: the id of the ledger;
  - `accounts_by_name`: a map of the accounts known by the ledger,
    grouped by their name.
  """
  @type t :: %Bookk.Ledger{
          id: String.t(),
          accounts_by_name: %{(name :: String.t()) => Bookk.Account.t()}
        }

  defstruct [:id, accounts_by_name: %{}]

  @doc ~S"""
  Checks whether the ledger is balanced.

  A ledger is considered balance when the sum of balance from its
  debit accounts is equal the sum of balance from its credit accounts.
  You know if an account is a "debit account" or a "credit account" by
  the natural balance of its class.

  See `Bookk.AccountClass` for more information on natural balance.

  ## Examples

  Is balanced when the ledger is empty:

      iex> Bookk.Ledger.new("acme")
      iex> |> Bookk.Ledger.balanced?()
      true

  Is balanced when the sum of debit accounts balances is equal the sum
  of credit accounts balances:

      iex> ledger = Bookk.Ledger.new("acme")
      iex>
      iex> journal_entry = %Bookk.JournalEntry{
      iex>   operations: [
      iex>     debit(fixture_account_head(:cash), Decimal.new(50)),
      iex>     credit(fixture_account_head(:deposits), Decimal.new(50))
      iex>   ]
      iex> }
      iex>
      iex> Bookk.Ledger.post(ledger, journal_entry)
      iex> |> Bookk.Ledger.balanced?()
      true

  Is unbalanced when the sum of debit accounts balances isn't equal
  the sum of credit accounts balances:

      iex> ledger = Bookk.Ledger.new("acme")
      iex>
      iex> journal_entry = %Bookk.JournalEntry{
      iex>   operations: [
      iex>     debit(fixture_account_head(:cash), Decimal.new(50))
      iex>   ]
      iex> }
      iex>
      iex> Bookk.Ledger.post(ledger, journal_entry)
      iex> |> Bookk.Ledger.balanced?()
      false

  """
  @spec balanced?(Bookk.Ledger.t()) :: boolean

  def balanced?(%Ledger{accounts_by_name: accounts_by_name}) do
    {debits, credits} =
      values(accounts_by_name)
      |> split_with(&(&1.head.class.natural_balance == :debit))

    sum_debits = reduce(debits, Decimal.new(0), &Decimal.add(&1.balance, &2))
    sum_credits = reduce(credits, Decimal.new(0), &Decimal.add(&1.balance, &2))

    Decimal.eq?(sum_debits, sum_credits)
  end

  @doc ~S"""
  Calculates a `Bookk.JournalEntry` represending the diff between two
  ledgers where, if such journal entry were to be applied to ledger "a",
  its state would become equal to ledger "b".

  ## Examples

      iex> a = Bookk.Ledger.new("acme", [
      iex>   Bookk.Account.new(fixture_account_head(:cash), Decimal.new(10)),
      iex>   Bookk.Account.new(fixture_account_head(:deposits), Decimal.new(10)),
      iex> ])
      iex>
      iex> b = Bookk.Ledger.new("acme", [
      iex>   Bookk.Account.new(fixture_account_head(:cash), Decimal.new(50)),
      iex>   Bookk.Account.new(fixture_account_head({:unspent_cash, {:user, "1234"}}), Decimal.new(50))
      iex> ])
      iex>
      iex> Bookk.Ledger.diff(a, b)
      Bookk.JournalEntry.new([
        Bookk.Operation.debit(fixture_account_head(:cash), Decimal.new(40)),
        Bookk.Operation.debit(fixture_account_head(:deposits), Decimal.new(10)),
        Bookk.Operation.credit(fixture_account_head({:unspent_cash, {:user, "1234"}}), Decimal.new(50)),
      ])

  """
  @spec diff(a :: t(), b :: t()) :: Bookk.JournalEntry.t()

  def diff(%Ledger{} = a, %Ledger{} = b) do
    account_heads =
      [a.accounts_by_name, b.accounts_by_name]
      |> Enum.flat_map(&Map.values/1)
      |> Enum.map(& &1.head)
      |> Enum.uniq()
      |> Enum.sort_by(& &1.name)

    operations =
      for %AccountHead{} = account_head <- account_heads do
        account_a = Ledger.get_account(a, account_head)
        account_b = Ledger.get_account(b, account_head)
        diff_amount = Decimal.sub(account_b.balance, account_a.balance)

        Op.new(account_head.class.natural_balance, account_head, diff_amount)
      end

    JournalEntry.new(operations)
  end

  @doc ~S"""
  Checks whether the given ledger is empty (no accounts with balance).

  ## Examples

      iex> Bookk.Ledger.new("acme")
      iex> |> Bookk.Ledger.empty?()
      true

      iex> ledger = Bookk.Ledger.new("acme", [
      iex>   Bookk.Account.new(fixture_account_head(:cash), Decimal.new(0)),
      iex>   Bookk.Account.new(fixture_account_head(:deposits), Decimal.new(0)),
      iex> ])
      iex>
      iex> Bookk.Ledger.empty?(ledger)
      true

      iex> ledger = Bookk.Ledger.new("acme", [
      iex>   Bookk.Account.new(fixture_account_head(:cash), Decimal.new(10))
      iex> ])
      iex>
      iex> Bookk.Ledger.empty?(ledger)
      false

  """
  @spec empty?(t) :: boolean()

  def empty?(%Ledger{} = ledger) do
    ledger.accounts_by_name
    |> Map.values()
    |> Enum.all?(&Account.empty?/1)
  end

  @doc ~S"""
  Get an account from the ledger by its `Bookk.AccountHead`. If the
  account doesn't exist yet, then an account will be returned with
  empty state.

  ## Examples

  Returns the account when it exists in the ledger:

      iex> ledger = Bookk.Ledger.new("acme", [
      iex>   %Bookk.Account{
      iex>     head: fixture_account_head(:cash),
      iex>     balance: Decimal.new(25)
      iex>   }
      iex> ])
      iex>
      iex> Bookk.Ledger.get_account(ledger, fixture_account_head(:cash))
      %Bookk.Account{
        head: fixture_account_head(:cash),
        balance: Decimal.new(25)
      }

  Returns an empty account when the it doesn't exist in the ledger:

      iex> Bookk.Ledger.new("acme")
      iex> |> Bookk.Ledger.get_account(fixture_account_head(:cash))
      %Bookk.Account{
        head: fixture_account_head(:cash),
        balance: Decimal.new(0)
      }

  """
  @spec get_account(t, Bookk.AccountHead.t()) :: Bookk.Account.t()

  def get_account(
        %Ledger{accounts_by_name: %{} = accounts_by_name},
        %AccountHead{name: name} = head
      ) do
    case get(accounts_by_name, name) do
      nil -> Account.new(head)
      %Account{} = account -> account
    end
  end

  @doc ~S"""
  Merges a non-empty set of Ledgers into one (ledger id MUST be the same).

  ## Examples

      iex> a = Bookk.Ledger.new("acme", [
      iex>   Bookk.Account.new(fixture_account_head(:cash), Decimal.new(5)),
      iex>   Bookk.Account.new(fixture_account_head(:deposits), Decimal.new(5)),
      iex> ])
      iex>
      iex> b = Bookk.Ledger.new("acme", [
      iex>   Bookk.Account.new(fixture_account_head(:cash), Decimal.new(15)),
      iex>   Bookk.Account.new(fixture_account_head(:deposits), Decimal.new(15)),
      iex> ])
      iex>
      iex> c = Bookk.Ledger.new("acme", [
      iex>   Bookk.Account.new(fixture_account_head(:cash), Decimal.new(30)),
      iex>   Bookk.Account.new(fixture_account_head(:deposits), Decimal.new(30)),
      iex> ])
      iex>
      iex> Bookk.Ledger.merge([a, b, c])
      Bookk.Ledger.new("acme", [
        Bookk.Account.new(fixture_account_head(:cash), Decimal.new(50)),
        Bookk.Account.new(fixture_account_head(:deposits), Decimal.new(50))
      ])

  If you try to merge an empty list of ledgers, an error will be
  raised.

  """
  @spec merge([t, ...]) :: t

  def merge([%Ledger{} = ledger]), do: ledger
  def merge([%Ledger{} = head | tail]), do: merge(head, merge(tail))

  @doc ~S"""
  Merges two ledgers into one (ledger id MUST be the same).

  ## Examples

      iex> a = Bookk.Ledger.new("acme", [
      iex>   Bookk.Account.new(fixture_account_head(:cash), Decimal.new(5)),
      iex>   Bookk.Account.new(fixture_account_head(:deposits), Decimal.new(5)),
      iex> ])
      iex>
      iex> b = Bookk.Ledger.new("acme", [
      iex>   Bookk.Account.new(fixture_account_head(:cash), Decimal.new(15)),
      iex>   Bookk.Account.new(fixture_account_head(:deposits), Decimal.new(15)),
      iex> ])
      iex>
      iex> Bookk.Ledger.merge(a, b)
      Bookk.Ledger.new("acme", [
        Bookk.Account.new(fixture_account_head(:cash), Decimal.new(20)),
        Bookk.Account.new(fixture_account_head(:deposits), Decimal.new(20))
      ])

  It will raise if ledgers have different ids:

      iex> a = Bookk.Ledger.new("acme")
      iex> b = Bookk.Ledger.new("foo")
      iex> Bookk.Ledger.merge(a, b)
      ** (FunctionClauseError) no function clause matching in Bookk.Ledger.merge/2

  """
  @spec merge(t, t) :: t

  def merge(%Ledger{id: same} = a, %Ledger{id: same} = b) do
    account_heads =
      []
      |> Enum.concat(Enum.map(a.accounts_by_name, fn {_, account} -> account.head end))
      |> Enum.concat(Enum.map(b.accounts_by_name, fn {_, account} -> account.head end))
      |> Enum.uniq()
      |> Enum.sort_by(& &1.name)

    accounts =
      for %AccountHead{} = account_head <- account_heads do
        account_a = Ledger.get_account(a, account_head)
        account_b = Ledger.get_account(b, account_head)

        Account.merge(account_a, account_b)
      end

    new(same, accounts)
  end

  @doc ~S"""
  Creates a new `Bookk.Ledger` from its id and, optionally, a list
  of `Bookk.Account`.
  """
  @spec new(id :: String.t()) :: t
  @spec new(id :: String.t(), [Bookk.Account.t()]) :: t

  def new(id, accounts \\ [])
  def new(<<id::binary>>, []), do: %Ledger{id: id}

  def new(<<id::binary>>, accounts)
      when is_list(accounts),
      do: Enum.into(accounts, %Ledger{id: id})

  @doc ~S"""
  Posts a `Bookk.JournalEntry` to a ledger. This means that the
  balance change described in each operation of the journal entry will
  be applied to their respective accounts of the ledger. If there's a
  change to an account that doesn't exist yet, then the account is
  first created.

  ## Examples

  When account doesn't exist then it gets created:

      iex> ledger = Bookk.Ledger.new("acme")
      iex>
      iex> journal_entry = %Bookk.JournalEntry{
      iex>   operations: [
      iex>     debit(fixture_account_head(:cash), Decimal.new(50)),
      iex>     credit(fixture_account_head(:deposits), Decimal.new(50))
      iex>   ]
      iex> }
      iex>
      iex> updated_ledger = Bookk.Ledger.post(ledger, journal_entry)
      iex>
      iex> [
      iex>   Bookk.Ledger.get_account(updated_ledger, fixture_account_head(:cash)),
      iex>   Bookk.Ledger.get_account(updated_ledger, fixture_account_head(:deposits))
      iex> ]
      [
        %Bookk.Account{head: fixture_account_head(:cash), balance: Decimal.new(50)},
        %Bookk.Account{head: fixture_account_head(:deposits), balance: Decimal.new(50)}
      ]

  When account exists then it gets updated:

      iex> ledger = Bookk.Ledger.new("acme")
      iex>
      iex> journal_entry = %Bookk.JournalEntry{
      iex>   operations: [
      iex>     debit(fixture_account_head(:cash), Decimal.new(50)),
      iex>     credit(fixture_account_head(:deposits), Decimal.new(50))
      iex>   ]
      iex> }
      iex>
      iex> updated_ledger =
      iex>   ledger
      iex>   |> Bookk.Ledger.post(journal_entry)
      iex>   |> Bookk.Ledger.post(journal_entry) # post twice
      iex>
      iex> [
      iex>   Bookk.Ledger.get_account(updated_ledger, fixture_account_head(:cash)),
      iex>   Bookk.Ledger.get_account(updated_ledger, fixture_account_head(:deposits))
      iex> ]
      [
        %Bookk.Account{head: fixture_account_head(:cash), balance: Decimal.new(100)},
        %Bookk.Account{head: fixture_account_head(:deposits), balance: Decimal.new(100)}
      ]

  """
  @spec post(t, Bookk.JournalEntry.t()) :: t

  def post(%Ledger{} = ledger, %JournalEntry{operations: ops}),
    do: post_reduce(ledger, ops)

  defp post_reduce(ledger, [head | tail]), do: post_op(ledger, head) |> post_reduce(tail)
  defp post_reduce(ledger, []), do: ledger

  defp post_op(%Ledger{} = ledger, %Op{account_head: head} = op) do
    ledger
    |> get_account(head)
    |> Account.post(op)
    |> put_account(ledger)
  end

  defp put_account(
         %Account{head: %{name: account_name}} = account,
         %Ledger{accounts_by_name: accounts_by_name} = ledger
       ) do
    %{
      ledger
      | accounts_by_name: put(accounts_by_name, account_name, account)
    }
  end
end

defimpl Collectable, for: Bookk.Ledger do
  import Map, only: [put: 3]

  alias Bookk.Account
  alias Bookk.Ledger

  @impl Collectable
  def into(ledger), do: {ledger, &collector/2}

  defp collector(
         %Ledger{accounts_by_name: accounts_by_name} = ledger,
         {:cont, %Account{head: %{name: account_name}} = account}
       ) do
    %{
      ledger
      | accounts_by_name: put(accounts_by_name, account_name, account)
    }
  end

  defp collector(ledger, :done), do: ledger
end
