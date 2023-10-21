defmodule BookkTest do
  use ExUnit.Case, async: true

  import Bookk.JournalEntry.Simple, only: [credit: 2, debit: 2]

  defdelegate fixture_account_head(term), to: TestChartOfAccounts, as: :account

  doctest Bookk.Account
  doctest Bookk.AccountClass
  doctest Bookk.AccountHead
  doctest Bookk.JournalEntry
  doctest Bookk.JournalEntry.Complex
  doctest Bookk.JournalEntry.Compound
  doctest Bookk.JournalEntry.Simple
  doctest Bookk.Ledger
  doctest Bookk.Notation
end