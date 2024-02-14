defmodule Bookk.Ledger do
  @moduledoc """
  A ledger is a collection of accounts that are grouped togheter for
  a specific purpose. Accounts are unique within a ledger.

  > ### Note {: .note}
  > The proper way to create accounts in a ledger is by posting
  > journal entries to it. See `post/2`.
  """
  @moduledoc since: "0.1.0"

  alias __MODULE__
  alias Bookk.Account
  alias Bookk.AccountHead
  alias Bookk.JournalEntry

  @typedoc """
  A struct representing a ledger's state, where accounts are indexed
  by their name.
  """
  @typedoc since: "0.1.0"
  @opaque t :: %Bookk.Ledger{
          name: String.t(),
          accounts_by_name: %{(account_name :: String.t()) => Bookk.Account.t()}
        }

  defstruct name: nil,
            accounts_by_name: %{}

  @doc """
  Creates a ledger from a set of accounts.

      iex> Bookk.Ledger.new([
      iex>   %Bookk.Account{head: %Bookk.AccountHead{name: "cash"}, balance: 10_00}
      iex> ])
      %Bookk.Ledger{
        accounts_by_name: %{
          "cash" => %Bookk.Account{head: %Bookk.AccountHead{name: "cash"}, balance: 10_00}
        }
      }

  > ### Warning {: .warning}
  > Duplicated accounts will be overwritten by the last account with
  > the same name, so be sure your accounts are unique.

      iex> Bookk.Ledger.new([
      iex>   %Bookk.Account{head: %Bookk.AccountHead{name: "cash"}, balance: 10_00},
      iex>   %Bookk.Account{head: %Bookk.AccountHead{name: "cash"}, balance: 30_00}
      iex> ])
      %Bookk.Ledger{
        accounts_by_name: %{
          "cash" => %Bookk.Account{head: %Bookk.AccountHead{name: "cash"}, balance: 30_00}
        }
      }

  """
  @doc since: "0.1.0"
  @spec new([account]) :: ledger
        when account: Bookk.Account.t(),
             ledger: t

  def new(accounts \\ []) when is_list(accounts) do
    %Ledger{
      accounts_by_name: Enum.into(accounts, %{}, &({&1.head.name, &1}))
    }
  end

  @doc """
  Get an account from a ledger from its account head. If the account
  doesn't exist within the ledger, then an empty account is returned.
  """
  @doc since: "0.1.0"
  @spec get_account(ledger, account_head) :: account
        when ledger: t,
             account_head: Bookk.AccountHead.t(),
             account: Bookk.Account.t()

  def get_account(%Ledger{} = ledger, %AccountHead{} = account_head) do
    case Map.get(ledger.accounts_by_name, account_head.name) do
      nil -> %Account{head: account_head}
      account -> account
    end
  end

  @doc """
  Posts the operations of a journal entry into a ledger, updating the
  affected accounts. Accounts that don't exist in the ledger yet get
  created.
  """
  @doc since: "0.1.0"
  @spec post(ledger, journal_entry) :: ledger
        when ledger: t,
             journal_entry: Bookk.JournalEntry.t()

  def post(%Ledger{} = ledger, %JournalEntry{} = journal_entry) do
    updated_accounts =
      for operation <- JournalEntry.prune(journal_entry.operations),
          account = get_account(ledger, operation.account_head),
          do: {account.head.name, Account.post(account, operation)}

    %Ledger{
      accounts_by_name: Enum.into(updated_accounts, ledger.accounts_by_name)
    }
  end
end
