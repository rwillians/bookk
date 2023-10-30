defmodule Bookk.Ledger do
  @moduledoc """
  A ledger is a book that holds accounts. Traditionally, ledgers would also hold
  the journal entries that changed the accounts but, in this library, persisting
  those journal entries is considered off its scope -- you can persistem them on
  your own though.

  ## Related

  - `Bookk.Account`;
  - `Bookk.JournalEntry`.
  """

  import Enum, only: [map: 2, split_with: 2, sum: 1]
  import Map, only: [get: 2, put: 3, values: 1]

  alias __MODULE__, as: Ledger
  alias Bookk.Account, as: Account
  alias Bookk.AccountHead, as: AccountHead
  alias Bookk.JournalEntry, as: JournalEntry
  alias Bookk.Operation, as: Op

  @typedoc """
  The struct that represents a ledger.

  ## Fields

  - `name`: the name of the ledger;
  - `accounts_by_name`: a map of the accounts known by the ledger, grouped by
    their name.
  """
  @type t :: %Bookk.Ledger{
          name: String.t(),
          accounts_by_name: %{(name :: String.t()) => Bookk.Account.t()}
        }

  defstruct [:name, accounts_by_name: %{}]

  @doc """
  Checks whether the ledger is balanced. It is considered balance whe the sum of
  balance of its accounts that has a debit natural balance is equal the sum of
  balance of its accounts that has a credit natural balance.

  See `Bookk.AccountClass` for more information on natural balance.

  ## Examples

  Is balanced when the ledger is empty:

      iex> Bookk.Ledger.new("acme")
      iex> |> Bookk.Ledger.balanced?()
      true

  Is balanced when the sum of debit accounts balances is equal the sum of credit
  accounts balances:

      iex> ledger = Bookk.Ledger.new("acme")
      iex> cash = fixture_account_head(:cash)
      iex> deposits = fixture_account_head(:deposits)
      iex>
      iex> journal_entry = %Bookk.JournalEntry{
      iex>   operations: [
      iex>     debit(cash, 50_00),
      iex>     credit(deposits, 50_00)
      iex>   ]
      iex> }
      iex>
      iex> Bookk.Ledger.post(ledger, journal_entry)
      iex> |> Bookk.Ledger.balanced?()
      true

  Is unbalanced when the sum of debit accounts balances isn't equal the sum of
  credit accounts balances:

      iex> ledger = Bookk.Ledger.new("acme")
      iex> cash = fixture_account_head(:cash)
      iex>
      iex> journal_entry = %Bookk.JournalEntry{
      iex>   operations: [
      iex>     debit(cash, 50_00)
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

    sum_debits = map(debits, & &1.balance) |> sum()
    sum_credits = map(credits, & &1.balance) |> sum()

    sum_debits == sum_credits
  end

  @doc """
  Get an account from the ledger by its `Bookk.AccountHead`. If the account
  doesn't exist yet, then an account will be returned with empty state.

  ## Examples

  Returns the account when it exists in the ledger:

      iex> ledger = %Bookk.Ledger{
      iex>   name: "acme",
      iex>   accounts_by_name: %{
      iex>     "cash/CA" => %Bookk.Account{
      iex>       head: fixture_account_head(:cash),
      iex>       balance: 25_00
      iex>     }
      iex>   }
      iex> }
      iex>
      iex> Bookk.Ledger.get_account(ledger, fixture_account_head(:cash))
      %Bookk.Account{
        head: fixture_account_head(:cash),
        balance: 25_00
      }

  Returns an empty account when the it doesn't exist in the ledger:

      iex> Bookk.Ledger.new("acme")
      iex> |> Bookk.Ledger.get_account(fixture_account_head(:cash))
      %Bookk.Account{
        head: fixture_account_head(:cash),
        balance: 0
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

  @doc """
  Creates a new `Bookk.Ledger` from its name and, optionally, a list of
  `Bookk.Account`.
  """
  @spec new(name :: String.t()) :: t
  @spec new(name :: String.t(), [Bookk.Account.t()]) :: t

  def new(name, accounts \\ [])
  def new(<<name::binary>>, []), do: %Ledger{name: name}

  def new(<<name::binary>>, accounts)
      when is_list(accounts),
      do: Enum.into(accounts, %Ledger{name: name})

  @doc """
  Posts a `Bookk.JournalEntry` to a ledger. This means that the balance change
  described in each operation of the journal entry will be applied to their
  respective accounts of the ledger. If there's a change to an account that
  doesn't exist yet, then the account is first created.

  ## Examples

  When account doesn't exist then it gets created:

      iex> ledger = Bookk.Ledger.new("acme")
      iex>
      iex> cash = fixture_account_head(:cash)
      iex> deposits = fixture_account_head(:deposits)
      iex>
      iex> journal_entry = %Bookk.JournalEntry{
      iex>   operations: [
      iex>     debit(cash, 50_00),
      iex>     credit(deposits, 50_00)
      iex>   ]
      iex> }
      iex>
      iex> updated_ledger = Bookk.Ledger.post(ledger, journal_entry)
      iex>
      iex> %Bookk.Account{balance: 50_00} = Bookk.Ledger.get_account(updated_ledger, cash)
      iex> %Bookk.Account{balance: 50_00} = Bookk.Ledger.get_account(updated_ledger, deposits)

  When account exists then it gets updated:

      iex> ledger = Bookk.Ledger.new("acme")
      iex>
      iex> cash = fixture_account_head(:cash)
      iex> deposits = fixture_account_head(:deposits)
      iex>
      iex> journal_entry = %Bookk.JournalEntry{
      iex>   operations: [
      iex>     debit(cash, 50_00),
      iex>     credit(deposits, 50_00)
      iex>   ]
      iex> }
      iex>
      iex> updated_ledger =
      iex>   ledger
      iex>   |> Bookk.Ledger.post(journal_entry)
      iex>   |> Bookk.Ledger.post(journal_entry) # post twice
      iex>
      iex> %Bookk.Account{balance: 100_00} = Bookk.Ledger.get_account(updated_ledger, cash)
      iex> %Bookk.Account{balance: 100_00} = Bookk.Ledger.get_account(updated_ledger, deposits)

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
