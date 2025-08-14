defmodule TestChartOfAccounts do
  use Bookk.ChartOfAccounts

  alias Bookk.AccountClass, as: C
  alias Bookk.AccountHead, as: H

  @classes %{
    "CA" => %C{id: "CA", parent_id: "A", natural_balance: :debit},
    "OE" => %C{id: "OE", parent_id: nil, natural_balance: :credit},
    "L" => %C{id: "L", parent_id: nil, natural_balance: :credit}
  }

  @impl Bookk.ChartOfAccounts
  def class(<<id::binary>>), do: Map.get(@classes, id)

  @impl Bookk.ChartOfAccounts
  def ledger(:acme), do: "acme"
  def ledger({:user, user_id}), do: "user(#{user_id})"

  @impl Bookk.ChartOfAccounts
  def account(:cash), do: %H{name: "cash/CA", class: class("CA")}
  def account(:deposits), do: %H{name: "deposits/OE", class: class("OE")}
  def account({:unspent_cash, {:user, user_id}}), do: %H{name: "unspent-cash:user(#{user_id})/L", class: class("L")}

  @impl Bookk.ChartOfAccounts
  def account_id(ledger, account_head), do: "#{ledger}:#{account_head.name}"
end
