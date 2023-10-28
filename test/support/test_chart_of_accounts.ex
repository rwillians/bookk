defmodule TestChartOfAccounts do
  @moduledoc false

  @behaviour Bookk.ChartOfAccounts

  @impl Bookk.ChartOfAccounts
  def ledger(:acme), do: "acme"
  def ledger({:user, user_id}), do: "user(#{user_id})"

  @impl Bookk.ChartOfAccounts
  def account(:cash) do
    %Bookk.AccountHead{
      name: "cash/CA",
      class: %Bookk.AccountClass{
        id: "CA",
        parent_id: "A",
        name: "Current Assets",
        natural_balance: :debit
      }
    }
  end

  def account(:deposits) do
    %Bookk.AccountHead{
      name: "deposits/OE",
      class: %Bookk.AccountClass{
        id: "OE",
        name: "Owner's Equity",
        natural_balance: :credit
      }
    }
  end

  def account({:unspent_cash, {:user, user_id}}) do
    %Bookk.AccountHead{
      name: "unspent-cash:user(#{user_id})/L",
      class: %Bookk.AccountClass{
        id: "L",
        name: "Liabilities",
        natural_balance: :credit
      }
    }
  end
end
