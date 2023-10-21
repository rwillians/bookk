defmodule BookkTest do
  use ExUnit.Case

  doctest Bookk.Account
  doctest Bookk.AccountClass
  doctest Bookk.AccountHead
  doctest Bookk.JournalEntry
  doctest Bookk.JournalEntry.Complex
  doctest Bookk.JournalEntry.Compound
  doctest Bookk.JournalEntry.Simple
  doctest Bookk.Ledger

  #
  #   FIXTURES
  #

  defdelegate credit(account_head, amount), to: Bookk.JournalEntry.Simple
  defdelegate debit(account_head, amount), to: Bookk.JournalEntry.Simple

  def fixture_account_head(:cash) do
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

  def fixture_account_head(:deposits) do
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
