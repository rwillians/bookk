defmodule Bookk.ChartOfAccounts do
  @moduledoc """
  A Chart of Accounts (abbrv.: CoA) is a mapping of all the accounts
  and all the ledgers that can exist in your system. But instead of
  hard-coding them, you define patterns for accounts and ledgers
  supported by your application using functions and pattern matching.

  For example, if your application allows ledgers to have an account
  for expenses related to paying salary to an employee, you could
  define a function with a signature the like the one below:

      def account({:salary, {:employee, employee_id}})

  And if your application, following the previous example, allows for
  every employee to have their own ledger, you could define a function
  with a signature like the one below:

      def ledger({:employee, employee_id})

  ## Related

  - `Bookk.Notation`;
  - `Bookk.AccountClass`;
  - `Bookk.AccountHead`.
  """

  @doc ~S"""
  Get a `Bookk.AccountClass` definition by its id.

  You are free to choose how and where you define your account classes, but you
  need to provide an implementation for this function so that your classes
  definitions are accessible to other modules.

  ## Example

      @impl Bookk.ChartOfAccounts
      def class("A"), do: %Bookk.AccountClass{id: "A", parent_id: nil, name: "Assets", natural_balance: :debit},
      def class("CA"), do: %Bookk.AccountClass{id: "CA", parent_id: "A", name: "Current Assets", natural_balance: :debit}

  """
  @callback class(id :: String.t()) :: Bookk.AccountClass.t() | nil

  @doc ~S"""
  This function maps all possible patterns of accounts that your
  application supports. It's recomended to use pattern matching and
  let it crash in the event of a mismatch.

  ## Examples

      @impl Bookk.ChartOfAccounts
      def account(:cash), do: %Bookk.AccountHead{name: "cash", class: class("CA")}
      def account({:payables, {:user, id}}), do: %Bookk.AccountHead{name: "payables:user(#{id})", class: class("L")}

  """
  @callback account(term) :: Bookk.AccountHead.t()

  @doc ~S"""
  This function maps all of your ledger codes into a ledger id string.
  It's recomended to use pattern matching and let it crash in the
  event of a mismatch.

  ## Example

      @impl Bookk.ChartOfAccounts
      def ledger_id(:acme), do: "acme"
      def ledger_id({:user, <<id::binary-size(36)>>}), do: "user(#{id})"

  """
  @callback ledger_id(term) :: String.t()

  @doc ~S"""
  Combines a ledger id with an account header, returning a unique id
  for the account.

        id = account_id(ledger_id(:acme), account(:cash))

  """
  @callback account_id(ledger_id, account_head) :: String.t()
            when ledger_id: String.t(),
                 account_head: Bookk.AccountHead.t()

  @doc """
  By using this module, you are declaring that your module implements
  the `Bookk.ChartOfAccounts` behaviour.
  """
  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      @impl Bookk.ChartOfAccounts
      def account_id(<<_, _::binary>> = ledger_id, %Bookk.AccountHead{} = account_head),
        do: "#{ledger_id}:#{account_head.name}/#{account_head.class.id}"

      defoverridable account_id: 2
    end
  end
end
