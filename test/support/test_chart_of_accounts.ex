defmodule TestChartOfAccounts do
  @behaviour Bookk.ChartOfAccounts

  @impl Bookk.ChartOfAccounts
  def ledger(:acme), do: "acme"

  @impl Bookk.ChartOfAccounts
  def account(:cash) do
    %Bookk.AccountHead{
      name: "cash/CA",
      class: %Bookk.AccountClass{
        id: "CA",
        parent_id: "A",
        name: "Current Asset",
        natural_balance: :debit
      }
    }
  end

  def account(:deposits) do
    %Bookk.AccountHead{
      name: "deposits/OE",
      class: %Bookk.AccountClass{
        id: "OE",
        parent_id: nil,
        name: "Owner's Equity",
        natural_balance: :credit
      }
    }
  end
end
