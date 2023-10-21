defmodule TestChartOfAccounts do
  def ledger(:acme), do: "acme"

  def account(:cash) do
    %Bookk.AccountHead{
      name: "cash/CA",
      class: %Bookk.AccountClass{
        sigil: "CA",
        parent_sigil: "A",
        name: "Current Asset",
        balance_increases_with: :debit
      }
    }
  end

  def account(:deposits) do
    %Bookk.AccountHead{
      name: "deposits/OE",
      class: %Bookk.AccountClass{
        sigil: "OE",
        parent_sigil: nil,
        name: "Owner's Equity",
        balance_increases_with: :credit
      }
    }
  end
end
