defmodule BookkTest do
  use ExUnit.Case, async: true

  import Bookk.Operation, only: [credit: 2, debit: 2]

  defdelegate fixture_account_head(term), to: TestChartOfAccounts, as: :account

  doctest Bookk.Account
  doctest Bookk.AccountClass
  doctest Bookk.AccountHead
  doctest Bookk.ChartOfAccounts
  doctest Bookk.InterledgerEntry
  doctest Bookk.JournalEntry
  doctest Bookk.Ledger
  doctest Bookk.NaiveState
  doctest Bookk.Notation
  doctest Bookk.Operation
end
