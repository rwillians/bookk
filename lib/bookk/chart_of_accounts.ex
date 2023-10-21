defmodule Bookk.ChartOfAccounts do
  @moduledoc false

  @doc ~S"""
  This function maps all possible patterns of ledger names your application
  supports. It's recomended to use pattern matching and let it crash in the
  event of a mismatch.

  ## Example

      def ledger(:acme), do: "acme
      def ledger({:user, <<id::binary-size(36)>>}), do: "user(#{id})"

  """
  @callback ledger(term) :: String.t()

  @doc """
  This function maps all possible combinations of {Bookk.AccountHead} your
  application supports. It's recomended to use pattern matching and let it crash
  in the event of a mismatch.

  ## Examples

      def account(:cash), do: %Bookk.AccountHead{...}
      def account(:deposits), do: %Bookk.AccountHead{...}
      def account({:payables, {:user, id}}), do: %Bookk.AccountHead{...}
      def account({:receivables, {:user, id}}), do: %Bookk.AccountHead{...}

  """
  @callback account(term) :: Bookk.AccountHead.t()
end
