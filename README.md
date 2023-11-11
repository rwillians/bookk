# Bookk

Bookk is a simple library that provides building blocks for operating journal entries and manipulating double-entry bookkeeping accounting ledgers.

See full documentation at [hexdocs](https://hexdocs.pm/bookk).

This library aims to decrease the friction between domain specialists (mainly accountants) and developers by providing a DSL that enables developers to write code for journal entries with a syntax that's familiar to specialists. That way, it should be easy for specialists to review code for journal entries and, likewise, it whould be easy for developers to implement journal entries based on instructions provided by specialists.

```elixir
def to_interledger_entry(%Deposit{} = tx) do
  journalize! using: ACME.ChartOfAccounts do
    on ledger(:acme) do
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
_(A journal entry from a deposit operation affecting two ledgers written with
Bookk's DSL)_

Persisting state, such as accounts balances and log of transactions per accounts is considered off scope for this library at the moment — and honestly, might never becomes part of its scope — but you can still do it own your own. An example of how to persist state using `Ecto` is provided in section **Examples** at [Persist State using Ecto](#persist-state-using-ecto).

Visit page **API Reference** for a brief introduction to double-entry bookkeeping concepts implemented by this library.


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

> **Warning**
> The snipets in this section are meant to be taken as a pseudocode, they haven't been tested yet.

### Chart of Accounts

```elixir
defmodule ACME.ChartOfAccounts do
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
  def ledger(:acme), do: "acme"
  def ledger({:user, <<id::binary>>}), do: "user(#{id})"

  @impl Bookk.ChartOfAccounts
  def account(:cash), do: %H{name: "cash/CA", class: @classes.CA}
  def account(:deposits), do: %H{name: "deposits/OE", class: @classes.OE}
  def account({:unspent_cash, {:user, <<id::binary>>}}), do: %H{name: "unspent-cash:user(#{id})/L", class: @classes.L}
  def account({:deposit_expenses, <<provider::binary>>}), do: %H{name: "deposit-expenses:#{provider}/E", class: @classes.E}

  @doc false
  def account_id(ledger_name, %H{} = account_head), do: ledger_name <> ":" <> account_head.name
end
```

### (DSL) Interledger Entry

Here's demonstrated how to journalize (create a journal entry template, if you may) for an specific accounting transaction. Examples are using `ACME.ChartOfAccounts` from the previous section.

**When user deposits balance (using a single ledger):**

```elixir
import Bookk.Notation, only: [journalize!: 2]

interledger_entry =
  journalize! using: ACME.ChartOfAccounts do
    on ledger(:acme) do
      debit account(:cash), deposited_amount
      credit account({:unspent_cash, {:user, user_id}}), deposited_amount
    end
  end

updated_state =
  Bookk.NaiveState.empty()
  |> Bookk.NaiveState.post(interledger_entry)
```

**When user deposited balance (using multiple ledgers):**

```elixir
import Bookk.Notation, only: [journalize!: 2]

interledger_entry =
  journalize! using: ACME.ChartOfAccounts do
    on ledger(:acme) do
      debit account(:cash), deposited_amount
      credit account({:unspent_cash, {:user, user_id}}), deposited_amount
    end

    on ledger({:user, user_id}) do
      debit account(:cash), deposited_amount
      credit account(:deposits), deposited_amount
    end
  end

updated_state =
  Bookk.NaiveState.empty()
  |> Bookk.NaiveState.post(interledger_entry)
```


### Persist state using Ecto

This section demostrantes how state can be persisted to a database using `Ecto` instead of posting (apply side-effects) to the in-memory structs provided by the library (such as `Bookk.Ledger` and `Bookk.NaiveState`).

First, we'll need two models.

1.  **Account**, which holds the account's balance:

    ```elixir
    defmodule Account do
      use Ecto.Schema

      import Ecto.Changeset

      @primary_key false
      schema "accounts" do
        field :id, :string, primary_key: true
        field :ledger_id, :string
        field :balance, :integer
        field :created_at, :utc_datetime_usec
        field :updated_at, :utc_datetime_usec
      end

      @doc false
      @spec changeset(t, map) :: Ecto.Changeset.t()

      def changeset(account \\ %__MODULE__{}, %{} = fields) do
        account
        |> cast(fields, [:id, :ledger_id, :balance, :created_at, :udpated_at])
        |> validate_required([:id, :ledger_id, :balance, :created_at, :udpated_at])
      end
    end
    ```

2.  **AccountTransaction**, which serves as a log of changes to an accounts:

    ```elixir
    defmodule AccountTransaction do
      use Ecto.Schema

      import Ecto.Changeset

      @primary_key false
      schema "accounts_transactions" do
        field :account_id, :string, primary_key: true
        field :transaction_id, Ecto.UUID, primary_key: true
        field :delta_amount, :integer
        field :balance_after, :integer
        field :created_at, :utc_datetime_usec
      end

      @doc false
      @spec changeset(t, map) :: Ecto.Changeset.t()

      def changeset(account_transfer \\ %__MODULE__{}, %{} = fields) do
        account_transfer
        |> cast(fields, [:account_id, :transaction_id, :delta_amount, :balance, :created_at])
        |> validate_required([:account_id, :transaction_id, :delta_amount, :balance, :created_at])
      end
    end
    ```

We'll also have a `Transactionable` protocol that specifies what functions are
expected from structs that describe side effects to our accounting system:

```elixir
defprotocol Transactionable do
  @moduledoc false

  @typedoc false
  @type t :: %{
              required(__struct__) => atom,
              required(:id) => String.t(),
              optional(atom) => any
            }

  @doc false
  @spec to_interledger_entry(t) :: Bookk.InterledgerEntry.t()

  def to_interledger_entry(tx)
end
```

Now we have a `DepositTransaction` describing that a user deposited balance into
their account — note that it implements `Transactionable` protocol:

```elixir
defmodule DepositTransaction do
  @moduledoc false

  @typedoc false
  @type t :: %DepositTransaction{
              id: String.t(),
              user_id: String.t(),
              amount: pos_integer
            }

  defstruct [:id, :user_id, :amount]
end

defimpl Transactionable, for: DepositTransaction do
  use Bookk.Notation

  @impl Transactionable
  def to_interledger_entry(tx) do
    journalize! using: ACME.ChartOfAccounts do
      on ledger(:acme) do
        debit account(:cash), tx.amount
        credit account({:unspent_cash, {:user, tx.user_id}})
      end

      on ledger({:user, tx.user_id}) do
        debit account(:cash), tx.amount
        credit account(:deposits), tx.amount
      end
    end
  end
end
```

And finally, we have our `Accounting` module that knows how to take a `Transactionable` struct and persist its side-effects to the database using `Ecto`:

```elixir
defmodule Accounting do
  @moduledoc false

  @doc false
  @spec transact(Transactionable.t()) :: {:ok, Ecto.Multi.t()} | {:error, term}

  def transact(tx) do
    interledger_entry = Transactionable.to_interledger_entry(tx)
    now = DateTime.utc_now()

    multis =
      for {ledger_name, journal_entry} <- Bookk.InterledgerEntry.to_journal_entries(interledger_entry),
          op <- Bookk.JournalEntry.to_operations(journal_entry),
          do: op_to_multi(op, leder_name, tx.id, now)

    multis
    |> Enum.reduce(Ecto.Multi.new(), &Ecto.Multi.append(&2, &1))
    |> ACME.Repo.transaction()
  end

  defp op_to_multi(%Bookk.Operation{} = op, ledger_name, tx_id, now) do
    #   we need uniq names for each multi operation, there will be 2 of them for
    # ↓ each `Bookk.Operation`
    multi_a_name = Ecto.UUID.generate()
    multi_b_name = Ecto.UUID.generate()

    #   the amount by which the account's balance should change (either a
    #   positive or negative integer — in cents or the smallest fraction of the
    # ↓ currency you're using)
    delta_amount = Bookk.Operations.to_delta_amount(op)
    account_id = ACME.ChartOfAccounts.account_id(ledger_name, op.account_head)

    account_changeset =
      Account.changeset(%{
        id: account_id,
        ledger_id: ledger_name,
        balance: delta_amount,
        created_at: now,
        updated_at: now
      })

    Ecto.Multi.new()
    #  ↓ upserts the account
    |> Ecto.Multi.insert(multi_a_name, account_changeset, [
      conflict_target: :id,
      on_conflict: [
        inc: [balance: delta_amount],
        set: [updated_at: now]
      ],
      returning: [:balance]
    ])
    #    creates the log entry recording the amount by which the account's
    #  ↓ balance changed in this accounting transaction
    |> Ecto.Multi.insert(multi_b_name, fn %{^multi_a_name => updated_accocunt} ->
      AccountTransaction.changeset(%{
        account_id: account_id,
        transaction_id: tx_id,
        delta_amount: delta_amount,
        balance_after: updated_account.balance,
        created_at: now
      })
    end)
  end
end
```
