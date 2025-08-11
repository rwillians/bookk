defmodule TestChartOfAccounts do
  @moduledoc false

  @behaviour Bookk.ChartOfAccounts

  alias Bookk.AccountClass, as: C
  alias Bookk.AccountHead, as: Head

  @classes %{
    "CA" => %C{id: "CA", parent_id: "A", natural_balance: :debit},
    "OE" => %C{id: "OE", parent_id: nil, natural_balance: :credit},
    "L" => %C{id: "L", parent_id: nil, natural_balance: :credit}
  }

  @impl Bookk.ChartOfAccounts
  def ledger(:acme), do: "acme"
  def ledger({:user, user_id}), do: "user(#{user_id})"

  @impl Bookk.ChartOfAccounts
  def account(:cash), do: %Head{name: "cash/CA", class: @classes["CA"]}
  def account(:deposits), do: %Head{name: "deposits/OE", class: @classes["OE"]}

  def account({:unspent_cash, {:user, user_id}}),
    do: %Head{name: "unspent-cash:user(#{user_id})/L", class: @classes["L"]}
end
