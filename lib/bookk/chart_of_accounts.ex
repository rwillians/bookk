defmodule Bookk.ChartOfAccounts do
  @moduledoc """
  A Chart of Accounts (abbrv.: CoA) is a mapping of all the ledgers and all
  accounts that can exist in your system.

  ## Related

  - `Bookk.Notation`;
  - `Bookk.AccountClass`;
  - `Bookk.AccountHead`.
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
