defmodule TestChartOfAccounts do
  @moduledoc false

  @behaviour Bookk.ChartOfAccounts

  alias Bookk.AccountClass, as: C
  alias Bookk.AccountHead, as: Head

  @classes %{
    current_assets: %C{sigil: "CA", parent_sigil: "A", natural_balance: :debit},
    owners_equity:  %C{sigil: "OE", parent_sigil: nil, natural_balance: :credit},
    liabilities:    %C{sigil: "L",  parent_sigil: nil, natural_balance: :credit}
  }

  @impl Bookk.ChartOfAccounts
  def ledger(:acme), do: "acme"
  def ledger({:user, user_id}), do: "user(#{user_id})"

  @impl Bookk.ChartOfAccounts
  def account(:cash) do
    %Head{
      name: "cash/CA",
      class: @classes.current_assets
    }
  end

  def account(:deposits) do
    %Head{
      name: "deposits/OE",
      class: @classes.owners_equity
    }
  end

  def account({:unspent_cash, {:user, user_id}}) do
    %Head{
      name: "unspent-cash:user(#{user_id})/L",
      class: @classes.liabilities
    }
  end
end
