defmodule Bookk.Ledger do
  @moduledoc """
  A ledger is a collection of accounts that are grouped togheter for
  a specific purpose. Accounts are unique within a ledger.

  > ### Note {: .note}
  > The proper way to create accounts in a ledger is by posting
  > journal entries to it. See `post/2`.
  """

  alias __MODULE__
  alias Bookk.Account
  alias Bookk.AccountHead
  alias Bookk.JournalEntry

  @opaque t :: %Bookk.Ledger{
          name: String.t(),
          accounts: %{(account_name :: String.t()) => Bookk.Account.t()}
        }

  defstruct name: nil,
            accounts: %{}

  @doc """
  Creates a ledger from a set of accounts.

  Duplicated accounts will be overwritten by the last account with the
  same name, so be sure your accounts are unique.
  """
  @spec new([account]) :: ledger
        when account: Bookk.Account.t(),
             ledger: t

  def new(accounts \\ []) when is_list(accounts) do
    %Ledger{
      accounts: Enum.into(accounts, %{}, &({&1.head.name, &1}))
    }
  end

  @doc """
  Get an account from a ledger from its account head. If the account
  doesn't exist within the ledger, then an empty account is returned.
  """
  @spec get_account(ledger, account_head) :: account
        when ledger: t,
             account_head: Bookk.AccountHead.t(),
             account: Bookk.Account.t()

  def get_account(%Ledger{} = ledger, %AccountHead{} = account_head) do
    case Map.get(ledger.accounts, account_head.name) do
      nil -> %Account{head: account_head}
      account -> account
    end
  end

  @doc """
  Posts the operations of a journal entry into a ledger, updating the
  affected accounts. Accounts that don't exist in the ledger yet get
  created.
  """
  @spec post(ledger, journal_entry) :: ledger
        when ledger: t,
             journal_entry: Bookk.JournalEntry.t()

  def post(%Ledger{} = ledger, %JournalEntry{} = journal_entry) do
    updated_accounts =
      for operation <- journal_entry.operations,
          account = get_account(ledger, operation.account_head),
          do: {account.head.name, Account.post(account, operation)}

    %Ledger{
      accounts: Enum.into(updated_accounts, ledger.accounts)
    }
  end
end
