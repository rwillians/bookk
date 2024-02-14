defmodule Bookk.ChartOfAccounts do
  @moduledoc """
  A Chart of Accounts (abbrv.: CoA) is a mapping of all the accounts
  and all the ledgers that can exist in your system. But instead of
  hard-coding them, Bookk suggests you to define patterns for accounts
  and ledgers that are supported by your application.

  For example, if your application allows ledgers to have an account
  for exampenses for paying salary to an employee, you could define a
  function with a signature the like the one below:

      def account({:salary, {:employee, employee_id}})

  And if your application, following the previous example, allows for
  every employee to have their own ledger, you could define a function
  with a signature like the one below:

      def ledger({:employee, employee_id})

  - See `Bookk.AccountHead` to learn more about account heads;
  - See `Bookk.AccountClass` to learn more about account classes;
  - See `Bookk.Notation.journalize/2` to learn how a chart of accounts
    is used.
  """
  @moduledoc since: "0.1.0"

  @doc ~S"""
  This function maps all possible patterns of ledger names your
  application supports. It's recomended to use pattern matching and
  let it crash in the event of a mismatch.

      def ledger(:acme), do: "acme"
      def ledger({:user, <<id::binary-size(36)>>}), do: "user(#{id})"

  """
  @doc since: "0.1.0"
  @callback ledger(term) :: String.t()

  @doc ~S"""
  This function maps all possible patterns of accounts that your
  application supports. It's recomended to use pattern matching and
  let it crash in the event of a mismatch.

      def account(:cash), do: %Bookk.AccountHead{...}
      def account(:deposits), do: %Bookk.AccountHead{...}
      def account({:payables, {:user, id}}), do: %Bookk.AccountHead{...}
      def account({:receivables, {:user, id}}), do: %Bookk.AccountHead{...}

  """
  @doc since: "0.1.0"
  @callback account(term) :: Bookk.AccountHead.t()
end
