defmodule Bookk.ChartOfAccounts do
  @moduledoc """
  A Chart of Accounts (abbrv.: CoA) is a mapping of all the accounts
  and all the ledgers that can exist in your system. But instead of
  hard-coding them, you define patterns for accounts and ledgers
  supported by your application using functions and pattern matching.

  For example, if your application allows ledgers to have an account
  for exampenses from paying salary to an employee, you could define a
  function with a signature the like the one below:

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
  This function maps all possible patterns of ledger names your
  application supports. It's recomended to use pattern matching and
  let it crash in the event of a mismatch.

  ## Example

      def ledger(:acme), do: "acme"
      def ledger({:user, <<id::binary-size(36)>>}), do: "user(#{id})"

  """
  @callback ledger(term) :: String.t()

  @doc ~S"""
  This function maps all possible patterns of accounts that your
  application supports. It's recomended to use pattern matching and
  let it crash in the event of a mismatch.

  ## Examples

      def account(:cash), do: %Bookk.AccountHead{...}
      def account(:deposits), do: %Bookk.AccountHead{...}
      def account({:payables, {:user, id}}), do: %Bookk.AccountHead{...}
      def account({:receivables, {:user, id}}), do: %Bookk.AccountHead{...}

  """
  @callback account(term) :: Bookk.AccountHead.t()

  @doc """
  Returns the account id for a given account head on a given ledger.

  ## Examples

      ledger_name = "acme"
      account_head = %Bookk.AccountHead{name: "cash/CA"}
      account_id(ledger_name, account_head)
      # `"acme:cash/CA"`

  """
  @callback account_id(ledger_name :: String.t(), Bookk.AccountHead.t()) :: String.t()
end
