defmodule Bookk.JournalEntry.Simple do
  @moduledoc false

  alias __MODULE__, as: SimpleJournalEntry
  alias Bookk.AccountHead, as: AccountHead

  @typedoc false
  @type t :: %Bookk.JournalEntry.Simple{
          direction: :credit | :debit,
          account_head: Bookk.AccountHead.t(),
          amount: pos_integer
        }

  defstruct [:direction, :account_head, :amount]

  @doc """
  Creates a new simple journal entry with direction `:credit`. If a negative
  amount is given, then it will be transformed into a positive number and the
  resulting entry will have its direction changed to `:debit`.

  ## Examples

  With a positive amount:

      iex> head = fixture_account_head(:cash)
      iex> Bookk.JournalEntry.Simple.credit(head, 25_00)
      %Bookk.JournalEntry.Simple{
        direction: :credit,
        account_head: fixture_account_head(:cash),
        amount: 25_00
      }

  With a negative amount:

      iex> head = fixture_account_head(:cash)
      iex> Bookk.JournalEntry.Simple.credit(head, -25_00)
      %Bookk.JournalEntry.Simple{
        direction: :debit,
        account_head: fixture_account_head(:cash),
        amount: 25_00
      }

  """
  @spec credit(Bookk.AccountHead.t(), amount :: integer) :: t

  def credit(%AccountHead{} = head, amount)
      when is_integer(amount) do
    case amount < 0 do
      true -> debit(head, -amount)
      false -> %SimpleJournalEntry{direction: :credit, account_head: head, amount: amount}
    end
  end

  @doc """
  Creates a new simple journal entry with direction `:debit`. If a negative
  amount is given, then it will be transformed into a positive number and the
  resulting entry will have its direction changed to `:credit`.

  ## Examples

  With a positive amount:

      iex> head = fixture_account_head(:cash)
      iex> Bookk.JournalEntry.Simple.debit(head, 25_00)
      %Bookk.JournalEntry.Simple{
        direction: :debit,
        account_head: fixture_account_head(:cash),
        amount: 25_00
      }

  With a negative amount:

      iex> head = fixture_account_head(:cash)
      iex> Bookk.JournalEntry.Simple.debit(head, -25_00)
      %Bookk.JournalEntry.Simple{
        direction: :credit,
        account_head: fixture_account_head(:cash),
        amount: 25_00
      }

  """
  @spec debit(Bookk.AccountHead.t(), amount :: integer) :: t

  def debit(%AccountHead{} = head, amount)
      when is_integer(amount) do
    case amount < 0 do
      true -> credit(head, -amount)
      false -> %SimpleJournalEntry{direction: :debit, account_head: head, amount: amount}
    end
  end

  @doc """
  Checks whether the given simple journal entry is empty, where it is empty if
  its amount is zero.

  ## Examples

      iex> Bookk.JournalEntry.Simple.empty?(%Bookk.JournalEntry.Simple{amount: 0})
      true

      iex> Bookk.JournalEntry.Simple.empty?(%Bookk.JournalEntry.Simple{amount: 1})
      false

  """
  @spec empty?(t) :: boolean

  def empty?(%SimpleJournalEntry{amount: 0}), do: true
  def empty?(%SimpleJournalEntry{}), do: false
end
