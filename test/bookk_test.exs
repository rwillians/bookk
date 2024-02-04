defmodule BookkTest do
  use ExUnit.Case, async: true

  doctest Bookk.Account
  doctest Bookk.AccountClass
  doctest Bookk.AccountHead
  doctest Bookk.JournalEntry
  doctest Bookk.Ledger
  doctest Bookk.Operation
end
