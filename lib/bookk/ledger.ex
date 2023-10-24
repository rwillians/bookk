defmodule Bookk.Ledger do
  @moduledoc """
  TODO

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
  TODO
  """
  @type t :: %Bookk.Ledger{
          name: String.t(),
          accounts: %{(name :: String.t()) => Bookk.Account.t()}
        }

  defstruct [:name, accounts: %{}]

  @doc """
  TODO

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

  def balanced?(%Ledger{accounts: accounts}) do
    {debits, credits} =
      values(accounts)
      |> split_with(&(&1.head.class.natural_balance == :debit))

    sum_debits = map(debits, & &1.balance) |> sum()
    sum_credits = map(credits, & &1.balance) |> sum()

    sum_debits == sum_credits
  end

  @doc """
  TODO

  ## Examples

  Returns the account when it exists in the ledger:

      iex> ledger = %Bookk.Ledger{
      iex>   name: "acme",
      iex>   accounts: %{
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

  def get_account(%Ledger{} = ledger, %AccountHead{} = head) do
    case get(ledger.accounts, head.name) do
      nil -> Account.new(head)
      %Account{} = account -> account
    end
  end

  @doc """
  TODO
  """
  @spec new(name :: String.t()) :: t

  def new(<<name::binary>>), do: %Ledger{name: name}

  @doc """
  TODO

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

  defp put_account(account, ledger) do
    accounts = put(ledger.accounts, account.head.name, account)
    %{ledger | accounts: accounts}
  end
end
