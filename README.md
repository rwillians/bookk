# Bookk

> **Warning**
> Not ready for production, this is a work in progress.

**TODO: Add description**

See full documentation at [hexdocs](#).


## Installation

The package can be installed by adding `bookk` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bookk, "~> 0.1.0"}
  ]
end
```


## Examples

### Chart of Accounts

```elixir
defmodule ChartOfAccounts do
  @behaviour Bookk.ChartOfAccounts

  alias Bookk.AccountClass, as: C
  alias Bookk.AccountHead, as: H

  # some of the most common account classes
  @classes %{
     A: %C{id:  "A", parent_id: nil, natural_balance:  :debit, name: "Assets"},
    CA: %C{id: "CA", parent_id: "A", natural_balance:  :debit, name: "Current Assets"},
    AR: %C{id: "AR", parent_id: "A", natural_balance:  :debit, name: "Accounts Receivables"},
     E: %C{id:  "E", parent_id: nil, natural_balance:  :debit, name: "Expenses"},
    OE: %C{id: "OE", parent_id: nil, natural_balance: :credit, name: "Owner's Equity"},
     L: %C{id:  "L", parent_id: nil, natural_balance: :credit, name: "Liabilities"},
    AP: %C{id: "AP", parent_id: "L", natural_balance: :credit, name: "Accounts Payables"},
     I: %C{id:  "I", parent_id: nil, natural_balance: :credit, name: "Income"},
     G: %C{id:  "G", parent_id: "I", natural_balance: :credit, name: "Gains"},
     R: %C{id:  "R", parent_id: "I", natural_balance: :credit, name: "Revenue"}
  }

  @impl Bookk.ChartOfAccounts
  def ledger(:cumbuca), do: "cumbuca"
  def ledger({:user, <<id::binary>>}), do: "user(#{id})"

  @impl Bookk.ChartOfAccounts
  def account(:cash), do: %H{name: "cash/CA", class: @classes.CA}
  def account(:deposits), do: %H{name: "deposits/OE", class: @classes.OE}
  def account({:unspent_cash, {:user, id}}), do: %H{name: "unspent-cash:user(#{id})/L", class: @classes.L}
  def account({:deposit_expenses, provider}), do: %H{name: "deposit-expenses:#{provider}/E", class: @classes.E}
end
```

### User deposited balance (single ledger)

```elixir
import Bookk.Notation, only: [journalize!: 2]

interledger_entry =
  journalize! using: ChartOfAccounts do
    on ledger(:acme) do
      debit account(:cash), deposited_amount
      credit account({:unspent_cash, {:user, user_id}}), deposited_amount
    end
  end

state = Bookk.NaiveState.empty()
updated_state = Bookk.NaiveState.post(state, interledger_entry)

Bookk.inspect(updated_state)
```

### User deposited balance (multiple ledgers)

```elixir
import Bookk.Notation, only: [journalize!: 2]

interledger_entry =
  journalize! using: ChartOfAccounts do
    on ledger(:acme) do
      debit account(:cash), deposited_amount
      credit account({:unspent_cash, {:user, user_id}}), deposited_amount
    end

    on ledger({:user, user_id}) do
      debit account(:cash), deposited_amount
      credit account(:deposits), deposited_amount
    end
  end

state = Bookk.NaiveState.empty()
updated_state = Bookk.NaiveState.post(state, interledger_entry)

Bookk.inspect(updated_state)
```
