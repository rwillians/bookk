# Bookk

[![Hex.pm](https://img.shields.io/hexpm/v/bookk.svg)](https://hex.pm/packages/bookk)
[![Hex.pm](https://img.shields.io/hexpm/dt/bookk.svg)](https://hex.pm/packages/bookk)
[![Hex.pm](https://img.shields.io/hexpm/l/bookk.svg)](https://hex.pm/packages/bookk)

Bookk is a simple library that provides building blocks manipulating
ledgers using double-entry bookkeeping.

```elixir
@doc """
Creates an journal entry for a deposit operation.
"""
@spec deposit_journal_entry(tx :: map) :: Bookk.InterledgerEntry.t()

def deposit_journal_entry(tx) do
  journalize! using: ACMEBank.ChartOfAccounts do
    on ledger(:acme_bank) do
      debit account(:cash), tx.amount
      credit account({:unspent_cash, {:user, tx.user_id}}), tx.amount
    end

    on ledger({:user, tx.user_id}) do
      debit account(:cash), tx.amount
      credit account(:deposits), tx.amount
    end
  end
end
```
_An interledger entry for a deposit operation affecting two ledgers, written with Bookk's DSL_

This library aims to decrease the friction between domain specialists
(mainly accountants) and developers by providing a DSL that enables
developers to write code for journal entries with a syntax that's
familiar to specialists. That way, it should be easy for specialists
to review code for journal entries and, likewise, it should be easy
for developers to implement journal entries based on instructions
provided by specialists.

* 📃 See full documentation at [hexdocs](https://hexdocs.pm/bookk).
* 🤓 For an introduction to Double-Entry Bookkeeping Accounting, see
  [this article](https://dev.to/rwillians/double-entry-bookkeeping-101-for-software-engineers-bk4).

Persisting state, such as accounts balances and log of transactions
per accounts is considered off scope for this library at the moment —
and honestly, might never becomes part of its scope — but it should be
relatively easy for you to do it on your own. An example of how to
persist state using `Ecto` is provided at [Persist State using Ecto](#persist-state-using-ecto).

Visit the [API Reference](https://hexdocs.pm/bookk/api-reference.html) page for a brief introduction to double-entry bookkeeping concepts implemented by this library.


## Summary

* [Installation](#installation)
* [Status of the project](#status-of-the-project)
* [Chart of Accounts](#chart-of-accounts)
* [Interledger Entries](#interledger-entries)
* [DSL](#dsl)
* [Persist state using Ecto](#persist-state-using-ecto)
* [Guides](#guides)


## Installation

The package can be installed by adding `bookk` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bookk, "~> 0.2.0"}
  ]
end
```


## Status of the project

This project is a work in progress and not recommended for production
use yet because I'm waiting for usage feedback on the API and DSL,
what means the API and DSL might change in the near future. However,
the library is already usable for testing and learning purposes.

**Milestones to v1.0.0**
- [x] Can update an Account using either a Credit or a Debit operation;
- [x] Can update a Ledger using a Journal Entry. Affected accounts
      that don't exist gets created;
- [x] Can update a State (in-memory) using an Interledger Entry.
      Affected ledgers that don't exist gets created;
- [x] Has DSL for writing interledger entries;
- [ ] Wait for feedback on the API and DSL;


## Chart of Accounts

**TODO**


## Interledger Entries

**TODO**


## DSL

**TODO**


## Persist state using Ecto

**TODO**


## Guides

**TODO**
