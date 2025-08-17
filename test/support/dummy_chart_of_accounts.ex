defmodule DummyChartOfAccounts do
  use Bookk.ChartOfAccounts

  alias Bookk.AccountClass, as: C
  alias Bookk.AccountHead, as: H

  @impl Bookk.ChartOfAccounts
  def class("CA"), do: %C{id: "CA", parent_id: "A", natural_balance: :debit}
  def class("OE"), do: %C{id: "OE", parent_id: nil, natural_balance: :credit}
  def class("L"), do: %C{id: "L", parent_id: nil, natural_balance: :credit}

  @impl Bookk.ChartOfAccounts
  def account(:cash), do: %H{name: "cash/CA", class: class("CA")}
  def account(:deposits), do: %H{name: "deposits/OE", class: class("OE")}
  def account({:unspent_cash, {:user, user_id}}), do: %H{name: "unspent-cash:user(#{user_id})/L", class: class("L")}

  @impl Bookk.ChartOfAccounts
  def ledger_id(:acme), do: "acme"
  def ledger_id({:user, user_id}), do: "user(#{user_id})"
end
