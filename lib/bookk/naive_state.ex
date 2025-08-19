defmodule Bookk.NaiveState do
  @moduledoc ~S"""
  A state struct that holds multiple ledgers. It's considered "naive"
  because it doesn't hold any information regarding the events that
  led to the current state.

  ## Related

  - `Bookk.Notation`;
  - `Bookk.InterledgerEntry`;
  - `Bookk.Ledger`.
  """

  import Enum, only: [to_list: 1]
  import Map, only: [get: 2, put: 3]

  alias __MODULE__, as: NaiveState
  alias Bookk.InterledgerEntry
  alias Bookk.Ledger

  @typedoc ~S"""
  The struct representing a naive state.

  ## Fields

  - `ledgers_by_id`: the ledgers known by the state, grouped by their id.
  """
  @type t :: %Bookk.NaiveState{
          ledgers_by_id: %{(id :: String.t()) => Bookk.Ledger.t()}
        }

  defstruct ledgers_by_id: %{}

  @doc ~S"""
  Calculates a `Bookk.InterledgerEntry` represending the diff between
  two `Bookk.NaiveState` where, if such interledger entry were to be
  posted to state "a", it would become equal to state "b".

  ## Examples

      iex> a = Bookk.NaiveState.new([
      iex>   Bookk.Ledger.new("acme", [
      iex>     Bookk.Account.new(fixture_account_head(:cash), Decimal.new(25)),
      iex>     Bookk.Account.new(fixture_account_head(:deposits), Decimal.new(25)),
      iex>   ])
      iex> ])
      iex>
      iex> b = Bookk.NaiveState.new([
      iex>   Bookk.Ledger.new("acme", [
      iex>     Bookk.Account.new(fixture_account_head(:cash), Decimal.new(100)),
      iex>     Bookk.Account.new(fixture_account_head(:deposits), Decimal.new(25)),
      iex>     Bookk.Account.new(fixture_account_head({:unspent_cash, {:user, "12345"}}), Decimal.new(75))
      iex>   ]),
      iex>   Bookk.Ledger.new("foo", [
      iex>     Bookk.Account.new(fixture_account_head(:cash), Decimal.new(75)),
      iex>     Bookk.Account.new(fixture_account_head(:deposits), Decimal.new(75)),
      iex>   ])
      iex> ])
      iex>
      iex> Bookk.NaiveState.diff(a, b)
      Bookk.InterledgerEntry.new([
        {"acme", Bookk.JournalEntry.new([
          debit(fixture_account_head(:cash), Decimal.new(75)),
          credit(fixture_account_head({:unspent_cash, {:user, "12345"}}), Decimal.new(75))
        ])},
        {"foo", Bookk.JournalEntry.new([
          debit(fixture_account_head(:cash), Decimal.new(75)),
          credit(fixture_account_head(:deposits), Decimal.new(75))
        ])}
      ])

  """
  @spec diff(a :: t(), b :: t()) :: Bookk.InterledgerEntry.t()

  def diff(%NaiveState{} = a, %NaiveState{} = b) do
    ledger_ids =
      []
      |> Enum.concat(Map.keys(a.ledgers_by_id))
      |> Enum.concat(Map.keys(b.ledgers_by_id))
      |> Enum.uniq()
      |> Enum.sort()

    entries =
      for ledger_id <- ledger_ids do
        ledger_a = get_ledger(a, ledger_id)
        ledger_b = get_ledger(b, ledger_id)

        {ledger_id, Ledger.diff(ledger_a, ledger_b)}
      end

    InterledgerEntry.new(entries)
  end

  @doc ~S"""
  Checks wether the given state is empty (no ledgers with balance).

  ## Examples

      iex> Bookk.NaiveState.new()
      iex> |> Bookk.NaiveState.empty?()
      true

      iex> state = Bookk.NaiveState.new([
      iex>   Bookk.Ledger.new("acme", [
      iex>     Bookk.Account.new(fixture_account_head(:cash), Decimal.new(0)),
      iex>     Bookk.Account.new(fixture_account_head(:deposits), Decimal.new(0))
      iex>   ])
      iex> ])
      iex>
      iex> Bookk.NaiveState.empty?(state)
      true

      iex> state = Bookk.NaiveState.new([
      iex>   Bookk.Ledger.new("acme", [
      iex>     Bookk.Account.new(fixture_account_head(:cash), Decimal.new(10)),
      iex>     Bookk.Account.new(fixture_account_head(:deposits), Decimal.new(10))
      iex>   ])
      iex> ])
      iex>
      iex> Bookk.NaiveState.empty?(state)
      false

  """
  @spec empty?(t) :: boolean()

  def empty?(%NaiveState{} = state) do
    state.ledgers_by_id
    |> Map.values()
    |> Enum.all?(&Ledger.empty?/1)
  end

  @doc ~S"""
  Get's a ledger from the state by its id. If the ledger doesn't exist
  in the state yet, then a new empty ledger will be returned.

  ## Examples

  Returns an empty ledger when requested ledger doesn't exist in
  state:

      iex> Bookk.NaiveState.get_ledger(%Bookk.NaiveState{}, "acme")
      %Bookk.Ledger{id: "acme"}

  Returns the ledger when it exists in state:

      iex> state = Bookk.NaiveState.new([
      iex>   Bookk.Ledger.new("foo", [
      iex>     Bookk.Account.new(fixture_account_head(:cash))
      iex>   ])
      iex> ])
      iex>
      iex> Bookk.NaiveState.get_ledger(state, "foo")
      Bookk.Ledger.new("foo", [
        Bookk.Account.new(fixture_account_head(:cash))
      ])

  """
  @spec get_ledger(t, String.t()) :: Bookk.Ledger.t()

  def get_ledger(
        %NaiveState{ledgers_by_id: %{} = ledgers_by_id},
        <<ledger_id::binary>>
      ) do
    case get(ledgers_by_id, ledger_id) do
      nil -> Ledger.new(ledger_id)
      %Ledger{} = ledger -> ledger
    end
  end

  @doc ~S"""
  Produces a new state struct from a set of ledgers.
  """
  @spec new([Bookk.Ledger.t()]) :: t

  def new(ledgers \\ [])
  def new([]), do: %NaiveState{}

  def new(ledgers)
      when is_list(ledgers),
      do: Enum.into(ledgers, %NaiveState{})

  @doc ~S"""
  Posts a `Bookk.InterledgerEntry` to the state, appling changes in
  balance to multiple accounts accross multiple ledgers.

  ## Examples

      iex> use Bookk.Notation
      iex>
      iex> user_id = "123"
      iex> deposited_amount = Decimal.new(500)
      iex>
      iex> journal_entry =
      iex>   journalize! using: DummyChartOfAccounts do
      iex>     on ledger(:acme) do
      iex>       debit account(:cash), deposited_amount
      iex>       credit account({:unspent_cash, {:user, user_id}}), deposited_amount
      iex>     end
      iex>
      iex>     on ledger({:user, user_id}) do
      iex>       debit account(:cash), deposited_amount
      iex>       credit account(:deposits), deposited_amount
      iex>     end
      iex>   end
      iex>
      iex> Bookk.NaiveState.new()
      iex> |> Bookk.NaiveState.post(journal_entry)
      Bookk.NaiveState.new([
        Bookk.Ledger.new("acme", [
          Bookk.Account.new(fixture_account_head(:cash), Decimal.new(500)),
          Bookk.Account.new(fixture_account_head({:unspent_cash, {:user, "123"}}), Decimal.new(500))
        ]),
        Bookk.Ledger.new("user(123)", [
          Bookk.Account.new(fixture_account_head(:cash), Decimal.new(500)),
          Bookk.Account.new(fixture_account_head(:deposits), Decimal.new(500))
        ])
      ])

  """
  @spec post(t, Bookk.InterledgerEntry.t()) :: t

  def post(%NaiveState{} = state, %InterledgerEntry{} = entry),
    do: post_reduce(state, to_list(entry.entries_by_ledger_id))

  defp post_reduce(state, [{y_ledger_name, [y_journal_entry | y_tail]} | x_tail]) do
    do_post(state, y_ledger_name, y_journal_entry)
    |> post_reduce([{y_ledger_name, y_tail} | x_tail])
  end

  defp post_reduce(state, [{_, []} | x_tail]), do: post_reduce(state, x_tail)
  defp post_reduce(state, []), do: state

  defp do_post(state, ledger_id, journal_entry) do
    get_ledger(state, ledger_id)
    |> Ledger.post(journal_entry)
    |> put_ledger(state)
  end

  defp put_ledger(
         %Ledger{id: id} = ledger,
         %NaiveState{ledgers_by_id: ledgers_by_id} = state
       ),
       do: %{state | ledgers_by_id: put(ledgers_by_id, id, ledger)}
end

defimpl Collectable, for: Bookk.NaiveState do
  import Map, only: [put: 3]

  alias Bookk.Ledger
  alias Bookk.NaiveState

  @impl Collectable
  def into(state), do: {state, &collector/2}

  defp collector(
         %NaiveState{ledgers_by_id: ledgers_by_id} = state,
         {:cont, %Ledger{id: id} = ledger}
       ) do
    %{
      state
      | ledgers_by_id: put(ledgers_by_id, id, ledger)
    }
  end

  defp collector(state, :done), do: state
end
