defmodule Bookk.Operation do
  @moduledoc """
  TODO

  ## Related

  - `Bookk.JournalEntry`;
  - `Bookk.AccountHead`;
  - `Bookk.AccountClass`.
  """

  import Enum, only: [group_by: 2, map: 2]

  alias __MODULE__, as: Op
  alias Bookk.AccountHead, as: AccountHead

  @typedoc """
  TODO
  """
  @type t :: %Bookk.Operation{
          direction: :credit | :debit,
          account_head: Bookk.AccountHead.t(),
          amount: pos_integer
        }

  defstruct [:direction, :account_head, :amount]

  @doc """
  TODO

  ## Examples

  Crediting a positive amount produces a credit operation:

      iex> head = fixture_account_head(:cash)
      iex> Bookk.Operation.credit(head, 25_00)
      %Bookk.Operation{
        direction: :credit,
        account_head: fixture_account_head(:cash),
        amount: 25_00
      }

  Crediting a negative amount produces a debit operation:

      iex> head = fixture_account_head(:cash)
      iex> Bookk.Operation.credit(head, -25_00)
      %Bookk.Operation{
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
      false -> %Op{direction: :credit, account_head: head, amount: amount}
    end
  end

  @doc """
  TODO

  ## Examples

  Debiting a positive amount produces a debit operation:

      iex> head = fixture_account_head(:cash)
      iex> Bookk.Operation.debit(head, 25_00)
      %Bookk.Operation{
        direction: :debit,
        account_head: fixture_account_head(:cash),
        amount: 25_00
      }

  Debiting a negative amount produces a credit operation:

      iex> head = fixture_account_head(:cash)
      iex> Bookk.Operation.debit(head, -25_00)
      %Bookk.Operation{
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
      false -> %Op{direction: :debit, account_head: head, amount: amount}
    end
  end

  @doc """
  TODO

  ## Examples

  Is empty when amount is zero:

      iex> Bookk.Operation.empty?(%Bookk.Operation{amount: 0})
      true

  Is not empty when amount is different than zero:

      iex> Bookk.Operation.empty?(%Bookk.Operation{amount: 1})
      false

  """
  @spec empty?(t) :: boolean

  def empty?(%Op{amount: 0}), do: true
  def empty?(%Op{}), do: false

  @doc """
  Same as {Bookk.Operation.merge/2} but it takes a non-empty list of operations.

  ## Examples

      iex> head = fixture_account_head(:cash)
      iex>
      iex> a = debit(head, 100_00)
      iex> b = debit(head, 200_00)
      iex> c = debit(head, 300_00)
      iex>
      iex> Bookk.Operation.merge([a, b, c])
      %Bookk.Operation{
        direction: :debit,
        account_head: fixture_account_head(:cash),
        amount: 600_00
      }

  If an empty list is provided, then an error will be raised:

      iex> Bookk.Operation.merge([])
      ** (FunctionClauseError) no function clause matching in Bookk.Operation.merge/1

  """
  @spec merge([t, ...]) :: t

  def merge([%Op{} = op]), do: op
  def merge([first, second | tail]), do: merge([merge(first, second) | tail])

  @doc """
  TODO

  ## Examples

  When the two operations have the same direction, the resulting operation has
  the same direction and the sum of the two amounts as its amount:

      iex> head = fixture_account_head(:cash)
      iex>
      iex> a = debit(head, 70_00)
      iex> b = debit(head, 30_00)
      iex>
      iex> Bookk.Operation.merge(a, b)
      %Bookk.Operation{
        direction: :debit,
        account_head: fixture_account_head(:cash),
        amount: 100_00
      }

  When the two operations have different direction, the account's natural
  balance will define the resulting direction. As for the resulting amount,
  the operation that matches the natural balance direction will have its amount
  subtracted by the other operation's amount:

      iex> head = fixture_account_head(:cash)
      iex>
      iex> a = debit(head, 70_00)
      iex> b = credit(head, 30_00)
      iex>
      iex> Bookk.Operation.merge(a, b)
      %Bookk.Operation{
        direction: :debit,
        account_head: fixture_account_head(:cash),
        amount: 40_00
      }

  If the resulting balance is a negative number, then the resulting direction
  will be switched and the amount will be transformed into a positive number:

      iex> head = fixture_account_head(:cash)
      iex>
      iex> a = credit(head, 70_00)
      iex> b = debit(head, 30_00)
      iex>
      iex> Bookk.Operation.merge(a, b)
      %Bookk.Operation{
        direction: :credit,
        account_head: fixture_account_head(:cash),
        amount: 40_00
      }

  If the operations' account heads aren't the same in both operations, then an
  error will be raised:

      iex> a = debit(fixture_account_head(:cash), 10_00)
      iex> b = credit(fixture_account_head(:deposits), 10_00)
      iex>
      iex> Bookk.Operation.merge(a, b)
      ** (FunctionClauseError) no function clause matching in Bookk.Operation.merge/2

  """
  @spec merge(t, t) :: t

  def merge(%Op{account_head: same} = a, %Op{account_head: same = head} = b) do
    {direction, amount} =
      case {a.direction, b.direction, head.class.natural_balance} do
        {same, same, _} -> {same, a.amount + b.amount}
        {same, _, same} -> {same, a.amount - b.amount}
        {_, same, same} -> {same, b.amount - a.amount}
      end

    new(direction, head, amount)
  end

  @doc """
  TODO
  """
  @spec new(direction :: :credit | :debit, Bookk.AccountHead.t(), integer) :: t

  def new(:credit, head, amount), do: credit(head, amount)
  def new(:debit, head, amount), do: debit(head, amount)

  @doc """
  TODO

  ## Examples

  A credit operation becomes a debit operation:

      iex> entry = %Bookk.Operation{direction: :credit, amount: 10_00}
      iex> Bookk.Operation.reverse(entry)
      %Bookk.Operation{direction: :debit, amount: 10_00}

  A debit operation becomes a credit operation:

      iex> entry = %Bookk.Operation{direction: :debit, amount: 10_00}
      iex> Bookk.Operation.reverse(entry)
      %Bookk.Operation{direction: :credit, amount: 10_00}

  """
  @spec reverse(t) :: t

  def reverse(%Op{direction: :credit} = entry), do: %{entry | direction: :debit}
  def reverse(%Op{direction: :debit} = entry), do: %{entry | direction: :credit}

  @doc """
  TODO

  ## Examples

  When there's more than one operation touching the same account, those
  operations are merged together so that the resulting list contains one a
  single operation thouching each account:

      iex> cash = fixture_account_head(:cash)
      iex> deposits = fixture_account_head(:deposits)
      iex>
      iex> a = debit(cash, 40_00)
      iex> b = debit(cash, 60_00)
      iex> c = credit(deposits, 100_00)
      iex>
      iex> Bookk.Operation.uniq([a, b, c])
      [
        fixture_account_head(:cash) |> debit(100_00),
        fixture_account_head(:deposits) |> credit(100_00)
      ]

  When all operations are unique, the list is returned as is:

      iex> cash = fixture_account_head(:cash)
      iex> deposits = fixture_account_head(:deposits)
      iex>
      iex> a = debit(cash, 100_00)
      iex> b = credit(deposits, 100_00)
      iex>
      iex> Bookk.Operation.uniq([a, b])
      [
        fixture_account_head(:cash) |> debit(100_00),
        fixture_account_head(:deposits) |> credit(100_00)
      ]

  When an empty list is given, the result will also be an empty list:

      iex> Bookk.Operation.uniq([])
      []

  """
  @spec uniq([t]) :: [t]

  def uniq([]), do: []

  def uniq([_ | _] = ops) do
    ops
    |> group_by(fn %Op{account_head: %{name: name}} -> name end)
    #               ↑ about 61% faster than `& &1.account_head.name`
    |> map(fn {_, xs} -> merge(xs) end)
  end
end
