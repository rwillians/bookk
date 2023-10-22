defmodule Bookk.Ledger do
  @moduledoc false

  import Enum, only: [map: 2, split_with: 2, sum: 1]
  import Map, only: [get: 2, put: 3, values: 1]

  alias __MODULE__, as: Ledger
  alias Bookk.Account, as: Account
  alias Bookk.AccountHead, as: AccountHead
  alias Bookk.JournalEntry, as: JournalEntry
  alias Bookk.Operation, as: Op

  @typedoc false
  @type t :: %Bookk.Ledger{
          name: String.t(),
          accounts: %{(name :: String.t()) => Bookk.Account.t()}
        }

  defstruct [:name, accounts: %{}]

  @doc """

  ## Examples

  Balanced ledger:

      iex> ledger = Bookk.Ledger.new("acme")
      iex>
      iex> cash = fixture_account_head(:cash)
      iex> deposits = fixture_account_head(:deposits)
      iex>
      iex> journal_entry =
      iex>   %Bookk.JournalEntry{
      iex>     ledger_name: "acme",
      iex>     operations: [
      iex>       debit(cash, 50_00),
      iex>       credit(deposits, 50_00)
      iex>     ]
      iex>   }
      iex>
      iex> Bookk.Ledger.post(ledger, journal_entry)
      iex> |> Bookk.Ledger.balanced?()
      true

  An unbalanced ledger:

      iex> ledger = Bookk.Ledger.new("acme")
      iex>
      iex> cash = fixture_account_head(:cash)
      iex> op = debit(cash, 50_00)
      iex>
      iex> Bookk.Ledger.post(ledger, op)
      iex> |> Bookk.Ledger.balanced?()
      false

  """
  @spec balanced?(Bookk.Ledger.t()) :: boolean

  def balanced?(%Ledger{accounts: accounts}) do
    {debits, credits} =
      values(accounts)
      |> split_with(&(&1.head.class.balance_increases_with == :debit))

    sum_debits = map(debits, & &1.balance) |> sum()
    sum_credits = map(credits, & &1.balance) |> sum()

    sum_debits == sum_credits
  end

  @doc """

  ## Examples

  When the account exists in the ledger:

      iex> ledger =
      iex>   %Bookk.Ledger{
      iex>     name: "acme",
      iex>     accounts: %{
      iex>       "cash/CA" => %Bookk.Account{
      iex>         head: fixture_account_head(:cash),
      iex>         balance: 25_00
      iex>       }
      iex>     }
      iex>   }
      iex>
      iex> Bookk.Ledger.get_account(ledger, fixture_account_head(:cash))
      %Bookk.Account{
        head: fixture_account_head(:cash),
        balance: 25_00
      }

  When account doesn't exist:

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
  Creates a new empty ledger.

  ## Examples

      iex> Bookk.Ledger.new("acme")
      %Bookk.Ledger{name: "acme", accounts: %{}}

  """
  @spec new(name :: String.t()) :: t

  def new(<<name::binary>>), do: %Ledger{name: name}

  @doc """

  ## Examples

  When account doesn't exist then it gets created:

      iex> ledger = Bookk.Ledger.new("acme")
      iex>
      iex> head = fixture_account_head(:cash)
      iex> entry = debit(head, 30_00)
      iex>
      iex> Bookk.Ledger.post(ledger, entry)
      iex> |> Bookk.Ledger.get_account(head)
      %Bookk.Account{
        head: fixture_account_head(:cash),
        balance: 30_00
      }

  When account exists then it gets updated:

      iex> ledger = Bookk.Ledger.new("acme")
      iex>
      iex> head = fixture_account_head(:cash)
      iex> entry_1 = debit(head, 30_00)
      iex> entry_2 = debit(head, 70_00)
      iex>
      iex> ledger
      iex> |> Bookk.Ledger.post(entry_1)
      iex> |> Bookk.Ledger.post(entry_2)
      iex> |> Bookk.Ledger.get_account(head)
      %Bookk.Account{
        head: fixture_account_head(:cash),
        balance: 100_00
      }

  Can post a journal entry:

      iex> ledger = Bookk.Ledger.new("acme")
      iex>
      iex> cash = fixture_account_head(:cash)
      iex> deposits = fixture_account_head(:deposits)
      iex>
      iex> journal_entry =
      iex>   %Bookk.JournalEntry{
      iex>     ledger_name: "acme",
      iex>     operations: [
      iex>       debit(cash, 50_00),
      iex>       credit(deposits, 50_00)
      iex>     ]
      iex>   }
      iex>
      iex> updated_ledger = Bookk.Ledger.post(ledger, journal_entry)
      iex>
      iex> %Bookk.Account{balance: 50_00} = Bookk.Ledger.get_account(updated_ledger, cash)
      iex> %Bookk.Account{balance: 50_00} = Bookk.Ledger.get_account(updated_ledger, deposits)

  Can post an operation:

      iex> ledger = Bookk.Ledger.new("acme")
      iex>
      iex> cash = fixture_account_head(:cash)
      iex> op = debit(cash, 50_00)
      iex>
      iex> updated_ledger = Bookk.Ledger.post(ledger, op)
      iex>
      iex> %Bookk.Account{balance: 50_00} = Bookk.Ledger.get_account(updated_ledger, cash)

  """
  @spec post(t, Bookk.JournalEntry.t()) :: t
  @spec post(t, Bookk.Operation.t()) :: t

  def post(%Ledger{} = ledger, %Op{account_head: head} = op) do
    ledger
    |> get_account(head)
    |> Account.post(op)
    |> put_account(ledger)
  end

  def post(%Ledger{name: same} = ledger, %JournalEntry{ledger_name: same} = entry),
      do: do_post(ledger, entry.operations)

  defp do_post(ledger, [head | tail]), do: post(ledger, head) |> do_post(tail)
  defp do_post(ledger, []), do: ledger

  defp put_account(account, ledger) do
    accounts = put(ledger.accounts, account.head.name, account)
    %{ledger | accounts: accounts}
  end
end
