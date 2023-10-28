defmodule Bookk.NaiveState do
  @moduledoc """
  State holds multiple ledgers. A NaiveState is considered "naive" because it
  doesn't hold any information regarding the journal entries that put the state
  into its current value.

  ## Related

  - `Bookk.Notation`;
  - `Bookk.InterledgerEntry`;
  - `Bookk.Ledger`.
  """

  import Enum, only: [to_list: 1]
  import Map, only: [get: 2, put: 3]

  alias __MODULE__, as: NaiveState
  alias Bookk.InterledgerEntry, as: InterledgerEntry
  alias Bookk.Ledger

  @typedoc """
  The struct representing a naive state.
  """
  @type t :: %Bookk.NaiveState{
          ledgers: %{(name :: String.t()) => Bookk.Ledger.t()}
        }

  defstruct ledgers: %{}

  @doc """
  Produces a empty naive state.
  """
  @spec empty() :: t

  def empty, do: %NaiveState{}

  @doc """
  Get's a ledger from the state by its name. If the ledger doesn't exist in the
  state yet, then a new empty ledger will be returned.

  ## Examples

  Returns an empty ledger when requested ledger doesn't exist in state:

      iex> Bookk.NaiveState.get_ledger(%Bookk.NaiveState{}, "acme")
      %Bookk.Ledger{name: "acme"}

  Returns the ledger when it exists in state:

      iex> state = %Bookk.NaiveState{
      iex>   ledgers: %{
      iex>     "foo" => %Bookk.Ledger{accounts: %{"cash" => %Bookk.Account{}}}
      iex>   }
      iex> }
      iex>
      iex> Bookk.NaiveState.get_ledger(state, "foo")
      %Bookk.Ledger{accounts: %{"cash" => %Bookk.Account{}}}

  """
  @spec get_ledger(t, String.t()) :: Bookk.Ledger.t()

  def get_ledger(%NaiveState{ledgers: %{} = ledgers}, <<name::binary>>) do
    case get(ledgers, name) do
      nil -> Ledger.new(name)
      %Ledger{} = ledger -> ledger
    end
  end

  @doc """
  Produces a new state struct from a set of ledgers.
  """
  @spec new([Bookk.Ledger.t()]) :: t

  def new([]), do: empty()

  def new(ledgers)
      when is_list(ledgers),
      do: Enum.into(ledgers, empty())

  @doc """
  Posts a `Bookk.InterledgerEntry` to the state, appling changes in balance to
  multiple accounts accross multiple ledgers.

  ## Examples

      iex> import Bookk.Notation, only: [journalize!: 2]
      iex>
      iex> user_id = "123"
      iex> deposited_amount = 500_00
      iex>
      iex> journal_entry =
      iex>   journalize! using: TestChartOfAccounts do
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
      iex> Bookk.NaiveState.empty()
      iex> |> Bookk.NaiveState.post(journal_entry)
      %Bookk.NaiveState{
        ledgers: %{
          "acme" => %Bookk.Ledger{
            name: "acme",
            accounts: %{
              fixture_account_head(:cash).name => %Bookk.Account{
                head: fixture_account_head(:cash),
                balance: 500_00
              },
              fixture_account_head({:unspent_cash, {:user, "123"}}).name => %Bookk.Account{
                head: fixture_account_head({:unspent_cash, {:user, "123"}}),
                balance: 500_00
              }
            }
          },
          "user(123)" => %Bookk.Ledger{
            name: "user(123)",
            accounts: %{
              fixture_account_head(:cash).name => %Bookk.Account{
                head: fixture_account_head(:cash),
                balance: 500_00
              },
              fixture_account_head(:deposits).name => %Bookk.Account{
                head: fixture_account_head(:deposits),
                balance: 500_00
              }
            }
          }
        }
      }

  """
  @spec post(t, Bookk.InterledgerEntry.t()) :: t

  def post(%NaiveState{} = state, %InterledgerEntry{} = entry),
    do: post_reduce(state, to_list(entry.entries_by_ledger))

  defp post_reduce(state, [{ledger_name, [journal_entry | x_tail]} = _x | xs_tail]) do
    do_post(state, ledger_name, journal_entry)
    |> post_reduce([{ledger_name, x_tail} | xs_tail])
  end

  defp post_reduce(state, [{_, []} | xs_tail]), do: post_reduce(state, xs_tail)
  defp post_reduce(state, []), do: state

  defp do_post(state, ledger_name, journal_entry) do
    get_ledger(state, ledger_name)
    |> Ledger.post(journal_entry)
    |> put_ledger(state)
  end

  defp put_ledger(
         %Ledger{name: name} = ledger,
         %NaiveState{ledgers: ledgers} = state
       ),
       do: %{state | ledgers: put(ledgers, name, ledger)}
end

defimpl Collectable, for: Bookk.NaiveState do
  import Map, only: [put: 3]

  alias Bookk.Ledger
  alias Bookk.NaiveState

  def into(state), do: {state, &collector/2}

  defp collector(
         %NaiveState{ledgers: ledgers} = state,
         {:cont, %Ledger{name: name} = ledger}
       ) do
    %{
      state
      | ledgers: put(ledgers, name, ledger)
    }
  end

  defp collector(state, :done), do: state
end
