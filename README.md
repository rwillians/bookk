# Bookk

[![Hex.pm](https://img.shields.io/hexpm/v/bookk.svg)](https://hex.pm/packages/bookk)
[![Hex.pm](https://img.shields.io/hexpm/dt/bookk.svg)](https://hex.pm/packages/bookk)
[![Hex.pm](https://img.shields.io/hexpm/l/bookk.svg)](https://hex.pm/packages/bookk)

Bookk is a simple library that provides building blocks for
manipulating ledgers using double-entry bookkeeping.

```elixir
defmodule UserDepositedBalance do
  @typedoc """
  A user deposited balance into their account.
  """
  @type t :: %DepositTransaction{
                user_id: String.t(),
                amount: pos_integer
              }
  defstruct [:user_id, :amount]
end

defimpl Bookk.Transactionable, for: UserDepositedBalance do
  use Bookk.Notation

  @doc """
  A function that returns a description of the changes expected
  from a deposit transaction, written using Bookk's DSL.
  """
  @spec to_interledger_entry(t) :: Bookk.InterledgerEntry.t()

  def to_interledger_entry(tx) do
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
end
```

This library aims to decrease the friction between domain specialists
(mainly accountants) and developers by providing a DSL that enables
developers to write code for journal entries with a syntax that's
familiar to specialists. That way, it should be easy for specialists
to review code for journal entries and, likewise, it should be easier
for developers to implement journal entries based on instructions
provided by specialists.

Persisting state, such as accounts balances and log of transactions
per accounts is considered off scope for this library at the moment —
and honestly, might never becomes part of its scope do to how complex
some distributed use cases can get — but it should be relatively easy
for you to do it on your own.

* 📃 See full documentation at [hexdocs](https://hexdocs.pm/bookk).
* 🤓 For an introduction to Double-Entry Bookkeeping Accounting, see
  [this article](https://dev.to/rwillians/double-entry-bookkeeping-101-for-software-engineers-bk4).
* 🔗 Visit the [API Reference](https://hexdocs.pm/bookk/api-reference.html#modules)
  page for a brief introduction to double-entry bookkeeping concepts
  implemented by this library.
* 👨‍💻 See the [Guides section](pages/guides/create-a-chart-of-accounts.md)
  in the documentation.

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
use yet because I'm **waiting for usage feedback on the API and DSL**,
what means the API and DSL might change in the near future. However,
the library is already usable for testing and learning purposes.
