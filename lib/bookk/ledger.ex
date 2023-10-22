defmodule Bookk.Ledger do
  @moduledoc false

  import Enum, only: [map: 2, split_with: 2, sum: 1]
  import Map, only: [get: 2, put: 3, values: 1]

  alias __MODULE__, as: Ledger
  alias Bookk.Account, as: Account
  alias Bookk.AccountHead, as: AccountHead
  alias Bookk.JournalEntry.Compound, as: CompoundEntry
  alias Bookk.Operation, as: Op

  @typedoc false
  @type t :: %Bookk.Ledger{
          name: String.t(),
          accounts: %{(name :: String.t()) => Bookk.Account.t()}
        }

  defstruct [:name, accounts: %{}]

  @doc """
  Checks whether the given ledger is balanced by checking if the sum of balances
  from all accounts that grows with `:debit` is equal the sum of balances from
  all accounts that grows with `:credit`.

  **Important**: a balance ledger means that it holds data integrity (it has the
  expected pairing of debits and credits) but its data can still be poorly
  designed such that you wouldn't be able to extract relevant information from
  it.

  ## Examples

  A balanced ledger:

      iex> ledger = Bookk.Ledger.new("acme")
      iex>
      iex> cash = fixture_account_head(:cash)
      iex> deposits = fixture_account_head(:deposits)
      iex>
      iex> journal_entry =
      iex>   %Bookk.JournalEntry.Compound{
      iex>     ledger_name: "acme",
      iex>     entries: [
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
      iex> journal_entry = debit(cash, 50_00)
      iex>
      iex> Bookk.Ledger.post(ledger, journal_entry)
      iex> |> Bookk.Ledger.balanced?()
      false

  """
  @spec balanced?(Bookk.Ledger.t()) :: boolean

  def balanced?(%Ledger{} = ledger) do
    {debits, credits} =
      values(ledger.accounts)
      |> split_with(&(&1.head.class.balance_increases_with == :debit))

    sum_debits = map(debits, & &1.balance) |> sum()
    sum_credits = map(credits, & &1.balance) |> sum()

    sum_debits == sum_credits
  end

  @doc false
  @spec get_account(t, Bookk.AccountHead.t()) :: Bookk.Account.t()

  def get_account(%Ledger{} = ledger, %AccountHead{} = head) do
    case get(ledger.accounts, head.name) do
      nil -> Account.new(head)
      %Account{} = account -> account
    end
  end

  @doc false
  @spec new(name :: String.t()) :: t

  def new(<<name::binary>>), do: %Ledger{name: name}

  @doc """
  Posts either a simple or a compound journal entry into the given ledger,
  upserting accounts as needed.

  For more details about posting changes to accounts, see {Bookk.Account.post/2}.

  ## Examples

  When account doesn't exist, it gets created:

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

  When account exists, it gets updated:

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

  Can post a compound journal entry:

      iex> ledger = Bookk.Ledger.new("acme")
      iex>
      iex> cash = fixture_account_head(:cash)
      iex> deposits = fixture_account_head(:deposits)
      iex>
      iex> journal_entry =
      iex>   %Bookk.JournalEntry.Compound{
      iex>     ledger_name: "acme",
      iex>     entries: [
      iex>       debit(cash, 50_00),
      iex>       credit(deposits, 50_00)
      iex>     ]
      iex>   }
      iex>
      iex> updated_ledger = Bookk.Ledger.post(ledger, journal_entry)
      iex>
      iex> %Bookk.Account{balance: 50_00} = Bookk.Ledger.get_account(updated_ledger, cash)
      iex> %Bookk.Account{balance: 50_00} = Bookk.Ledger.get_account(updated_ledger, deposits)

  """
  @spec post(t, Bookk.JournalEntry.Compound.t()) :: t
  @spec post(t, Bookk.Operation.t()) :: t

  def post(%Ledger{} = ledger, %Op{account_head: head} = op) do
    ledger
    |> get_account(head)
    |> Account.post(op)
    |> put_account(ledger)
  end

  def post(%Ledger{name: same} = ledger, %CompoundEntry{ledger_name: same} = entry),
      do: do_post(ledger, entry.entries)

  defp do_post(ledger, [head | tail]), do: post(ledger, head) |> do_post(tail)
  defp do_post(ledger, []), do: ledger

  defp put_account(account, ledger) do
    accounts = put(ledger.accounts, account.head.name, account)
    %{ledger | accounts: accounts}
  end
end
