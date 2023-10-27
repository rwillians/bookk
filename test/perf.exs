defmodule PerfTest do
  use ExUnit.Case

  import Bookk.Notation, only: [journalize!: 2]

  @opts [
    warmup: 1,
    time: 10,
    memory_time: 2,
    reduction_time: 2,
    profile_after: true,
    measure_function_call_overhead: true,
    print: [benchmarking: true],
    formatters: [
      {Benchee.Formatters.Console, comparison: true, extended_statistics: true}
    ]
  ]

  @tag timeout: 120_000
  test "journalize/2 vs journalize!/2" do
    user_id = "e28f7406-c442-4594-882d-86dff3bb0ef7"
    amount = 615_27

    cases = %{
      "journalize/2": fn -> deposit_balance(user_id, amount) end,
      "journalize!/2": fn -> deposit_balance!(user_id, amount) end
    }

    Benchee.run(cases, @opts)
  end

  @tag timeout: 120_000
  test "NaiveState.post/2 & Ledger.post/2 & Account.post/2" do
    naive_state =
      gen_interledger_entries(1_000_000)
      |> Enum.reduce(Bookk.NaiveState.empty(), &Bookk.NaiveState.post(&2, &1))

    [interledger_entry] = gen_interledger_entries(1)
    [{_, journal_entry} | _] = Bookk.InterledgerEntry.to_journal_entries(interledger_entry)
    [operation | _] = Bookk.JournalEntry.to_operations(journal_entry)

    ledger = Bookk.NaiveState.get_ledger(naive_state, TestChartOfAccounts.ledger(:acme))
    account = Bookk.Ledger.get_account(ledger, operation.account_head)

    account_count = Map.values(ledger.accounts) |> length()

    cases = %{
      "Bookk.NaiveState.post/2 (preloaded 1M entries)": fn -> Bookk.NaiveState.post(naive_state, interledger_entry) end,
      "Bookk.Ledger.post/2 (preloaded #{account_count} accounts)": fn -> Bookk.Ledger.post(ledger, journal_entry) end,
      "Bookk.Account.post/2": fn -> Bookk.Account.post(account, operation) end
    }

    Benchee.run(cases, @opts)
  end

  #
  #   DEPOSIT BALANCE
  #

  defp deposit_balance(user_id, amount) do
    journalize! using: TestChartOfAccounts do
      on ledger(:acme) do
        debit account(:cash), amount
        credit account({:unspent_cash, {:user, user_id}}), amount
      end

      on ledger({:user, user_id}) do
        debit account(:cash), amount
        credit account(:deposits), amount
      end
    end
  end

  defp deposit_balance!(user_id, amount) do
    journalize! using: TestChartOfAccounts do
      on ledger(:acme) do
        debit account(:cash), amount
        credit account({:unspent_cash, {:user, user_id}}), amount
      end

      on ledger({:user, user_id}) do
        debit account(:cash), amount
        credit account(:deposits), amount
      end
    end
  end

  #
  #
  #

  def gen_interledger_entries(n) do
    for _ <- 1..n do
      user_id = Enum.random(1..10_000) |> to_string() |> String.pad_leading(36, "0")
      amount = Enum.random(10_00..1500_00)

      deposit_balance!(user_id, amount)
    end
  end
end
