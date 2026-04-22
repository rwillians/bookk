defmodule BookkTest do
  use ExUnit.Case, async: true

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
