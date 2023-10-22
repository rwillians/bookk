defmodule Bookk.Account do
  @moduledoc false

  alias __MODULE__, as: Account
  alias Bookk.AccountHead, as: AccountHead
  alias Bookk.JournalEntry.Simple, as: SimpleEntry

  @typedoc false
  @type t :: %Bookk.Account{
          head: Bookk.AccountHead.t(),
          balance: integer
        }

  defstruct [:head, balance: 0]

  @doc false
  @spec new(Bookk.AccountHead.t()) :: t

  def new(%AccountHead{} = head), do: %Account{head: head}

  @doc """
  Posts a simple journal entry to an account, changing its balance and
  prepending a copy of the journal entry in its history.

  If the journal entry's direction (`:credit` or `:debit`) matches the value of
  account's class `:balance_increases_with` property, then the account's balance
  will be added to; otherwise, it will be subtracted from.

  The account head in the journal entry MUST be the same as the account's head.
  If the are different, then that means you're posting a journal entry to the
  wrong account. These kinda of errors are almost always a development mistake
  therefore they cause an error to be raised so that you can catch them early on.

  ## Examples

  Adding balance:

      iex> class = %Bookk.AccountClass{balance_increases_with: :debit}
      iex> head = %Bookk.AccountHead{class: class}
      iex> account = Bookk.Account.new(head)
      iex>
      iex> journal_entry = Bookk.JournalEntry.Simple.debit(head, 25_00)
      iex>
      iex> Bookk.Account.post(account, journal_entry)
      %Bookk.Account{
        head: %Bookk.AccountHead{class: %Bookk.AccountClass{balance_increases_with: :debit}},
        balance: 25_00
      }

  Subtracting balance:

      iex> class = %Bookk.AccountClass{balance_increases_with: :debit}
      iex> head = %Bookk.AccountHead{class: class}
      iex> account = Bookk.Account.new(head)
      iex>
      iex> journal_entry = Bookk.JournalEntry.Simple.credit(head, 25_00)
      iex>
      iex> Bookk.Account.post(account, journal_entry)
      %Bookk.Account{
        head: %Bookk.AccountHead{class: %Bookk.AccountClass{balance_increases_with: :debit}},
        balance: -25_00
      }

  Mismatching account headers:

      iex> head_a = %Bookk.AccountHead{name: "a"}
      iex> head_b = %Bookk.AccountHead{name: "b"}
      iex>
      iex> account = Bookk.Account.new(head_a)
      iex> journal_entry = Bookk.JournalEntry.Simple.debit(head_b, 25_00)
      iex>
      iex> Bookk.Account.post(account, journal_entry)
      ** (FunctionClauseError) no function clause matching in Bookk.Account.post/2

  """
  @spec post(t, Bookk.JournalEntry.Simple.t()) :: t

  def post(
        %Account{head: same, balance: balance},
        %SimpleEntry{account_head: same = head, amount: amount} = entry
      ) do
    balance_after =
      case {head.class.balance_increases_with, entry.direction} do
        {same, same} -> balance + amount
        {_, _} -> balance - amount
      end

    %Account{head: head, balance: balance_after}
  end
end
