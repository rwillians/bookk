defmodule Bookk.ChartOfAccounts do
  @moduledoc """
  A Chart of Accounts (abbrv.: CoA) is a mapping of all the ledgers and accounts
  that exist in a system.

  ## Related

  - `Bookk.Notation`.
  """

  @doc ~S"""
  This function maps all possible patterns of ledger names your application
  supports. It's recomended to use pattern matching and let it crash in the
  event of a mismatch.

  ## Example

      def ledger(:acme), do: "acme"
      def ledger({:user, <<id::binary-size(36)>>}), do: "user(#{id})"

  """
  @callback ledger(term) :: String.t()

  @doc ~S"""
  This function maps all possible patterns of accounts that your application
  supports. It's recomended to use pattern matching and let it crash in the
  event of a mismatch.

  ## Examples

      def account(:cash), do: %Bookk.AccountHead{...}
      def account(:deposits), do: %Bookk.AccountHead{...}
      def account({:payables, {:user, id}}), do: %Bookk.AccountHead{...}
      def account({:receivables, {:user, id}}), do: %Bookk.AccountHead{...}

  """
  @callback account(term) :: Bookk.AccountHead.t()
end
