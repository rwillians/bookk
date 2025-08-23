defmodule Bookk.Operation do
  @moduledoc ~S"""
  An operation describe a change in balance on a single account
  (`Bookk.Account`). An operation is analogous to a git diff on
  a file, they represent a diff on an account's balance.

  ## Related

  - `Bookk.JournalEntry`;
  - `Bookk.AccountHead`;
  - `Bookk.AccountClass`.
  """

  import Enum, only: [group_by: 2, map: 2]

  alias __MODULE__, as: Op
  alias Bookk.AccountHead, as: AccountHead

  @typedoc ~S"""
  The struct representing an operation.

  ## Fields

  - `direction` (either `:debit` or `:credit`): by itself it means
    nothing -- it's just a lable -- but, once combined with the
    account's natural balance (`account_head.class.natural_balance`),
    then we're able to tell if the operation will result in an
    addition or a subtraction of balance;
  - `account_head`: a `Bookk.AccountHead` struct used to either
    update or create the affected account in the ledger where the
    operation was posted;
  - `amount`: the [positive] amount by which the account's balance
    will be changed. Whether the change will be an addition or a
    subtraction, that depends on `direction` and the account class'
    natural balance.
  """
  @type t :: %Bookk.Operation{
          direction: :credit | :debit,
          account_head: Bookk.AccountHead.t(),
          amount: Decimal.t()
        }

  defstruct [:direction, :account_head, :amount]

  @doc ~S"""
  Creates a credit operation from a `Bookk.AccountHead` and an amount.

  ## Examples

  Crediting a positive amount produces a credit operation:

      iex> head = fixture_account_head(:cash)
      iex> Bookk.Operation.credit(head, Decimal.new(25))
      %Bookk.Operation{
        direction: :credit,
        account_head: fixture_account_head(:cash),
        amount: Decimal.new(25)
      }

  Crediting a negative amount produces a debit operation:

      iex> head = fixture_account_head(:cash)
      iex> Bookk.Operation.credit(head, Decimal.new(-25))
      %Bookk.Operation{
        direction: :debit,
        account_head: fixture_account_head(:cash),
        amount: Decimal.new(25)
      }

  If the given amount is an `integer` or a `float`, it will be converted
  to `Decimal`:

      iex> head = fixture_account_head(:cash)
      iex> Bookk.Operation.credit(head, 10)
      %Bookk.Operation{
        direction: :credit,
        account_head: fixture_account_head(:cash),
        amount: Decimal.new(10)
      }

      iex> head = fixture_account_head(:cash)
      iex> Bookk.Operation.credit(head, 1000.00)
      %Bookk.Operation{
        direction: :credit,
        account_head: fixture_account_head(:cash),
        amount: Decimal.from_float(1000.00)
      }

  """
  @spec credit(Bookk.AccountHead.t(), amount) :: t
        when amount: Decimal.t() | integer() | float()

  def credit(%AccountHead{} = head, %Decimal{} = amount) do
    case Decimal.lt?(amount, 0) do
      true -> debit(head, Decimal.mult(amount, -1))
      false -> %Op{direction: :credit, account_head: head, amount: amount}
    end
  end

  def credit(head, amount) when is_integer(amount), do: credit(head, Decimal.new(amount))
  def credit(head, amount) when is_float(amount), do: credit(head, Decimal.from_float(amount))

  @doc ~S"""
  Creates a debit operation given a `Bookk.AccountHead` and an amount.

  ## Examples

  Debiting a positive amount produces a debit operation:

      iex> head = fixture_account_head(:cash)
      iex> Bookk.Operation.debit(head, Decimal.new(25))
      %Bookk.Operation{
        direction: :debit,
        account_head: fixture_account_head(:cash),
        amount: Decimal.new(25)
      }

  Debiting a negative amount produces a credit operation:

      iex> head = fixture_account_head(:cash)
      iex> Bookk.Operation.debit(head, Decimal.new(-25))
      %Bookk.Operation{
        direction: :credit,
        account_head: fixture_account_head(:cash),
        amount: Decimal.new(25)
      }

  If the given amount is an `integer` or a `float`, it will be converted
  to `Decimal`:

      iex> head = fixture_account_head(:cash)
      iex> Bookk.Operation.debit(head, 10)
      %Bookk.Operation{
        direction: :debit,
        account_head: fixture_account_head(:cash),
        amount: Decimal.new(10)
      }

      iex> head = fixture_account_head(:cash)
      iex> Bookk.Operation.debit(head, 1000.00)
      %Bookk.Operation{
        direction: :debit,
        account_head: fixture_account_head(:cash),
        amount: Decimal.from_float(1000.00)
      }

  """
  @spec debit(Bookk.AccountHead.t(), amount :: integer) :: t

  def debit(%AccountHead{} = head, %Decimal{} = amount) do
    case Decimal.lt?(amount, 0) do
      true -> credit(head, Decimal.mult(amount, -1))
      false -> %Op{direction: :debit, account_head: head, amount: amount}
    end
  end

  def debit(head, amount) when is_integer(amount), do: debit(head, Decimal.new(amount))
  def debit(head, amount) when is_float(amount), do: debit(head, Decimal.from_float(amount))

  @doc ~S"""
  Checks whether an operation is empty. It is considered empty when
  its amount is zero, meaning no changes to the account's balance.

  ## Examples

  Is empty when amount is zero:

      iex> Bookk.Operation.empty?(%Bookk.Operation{amount: Decimal.new(0)})
      true

  Is not empty when amount is different than zero:

      iex> Bookk.Operation.empty?(%Bookk.Operation{amount: Decimal.new(1)})
      false

  """
  @spec empty?(t) :: boolean

  def empty?(%Op{amount: %Decimal{} = amount}), do: Decimal.eq?(amount, 0)

  @doc ~S"""
  Same as {Bookk.Operation.merge/2} but it takes a non-empty list of
  operations, all to the same account (same `account_head`).

  ## Examples

      iex> head = fixture_account_head(:cash)
      iex>
      iex> a = debit(head, Decimal.new(100))
      iex> b = debit(head, Decimal.new(200))
      iex> c = debit(head, Decimal.new(300))
      iex>
      iex> Bookk.Operation.merge([a, b, c])
      %Bookk.Operation{
        direction: :debit,
        account_head: fixture_account_head(:cash),
        amount: Decimal.new(600)
      }

  If you try to merge an empty list of operations, an error will be
  raised.
  """
  @spec merge([t, ...]) :: t

  def merge([%Op{} = op]), do: op
  def merge([%Op{} = head | tail]), do: merge(head, merge(tail))

  @doc ~S"""
  Combines two operation against the same account into one operation.

  ## Examples

  When the two operations have the same direction, the resulting
  operation has the same direction and the sum of the two amounts as
  its amount:

      iex> head = fixture_account_head(:cash)
      iex>
      iex> a = debit(head, Decimal.new(70))
      iex> b = debit(head, Decimal.new(30))
      iex>
      iex> Bookk.Operation.merge(a, b)
      %Bookk.Operation{
        direction: :debit,
        account_head: fixture_account_head(:cash),
        amount: Decimal.new(100)
      }

  When the two operations have different direction, the account's
  natural balance will define the resulting direction. As for the
  resulting amount, the operation that matches the natural balance
  direction will have its amount subtracted by the other operation's
  amount:

      iex> head = fixture_account_head(:cash)
      iex>
      iex> a = debit(head, Decimal.new(70))
      iex> b = credit(head, Decimal.new(30))
      iex>
      iex> Bookk.Operation.merge(a, b)
      %Bookk.Operation{
        direction: :debit,
        account_head: fixture_account_head(:cash),
        amount: Decimal.new(40)
      }

  If the resulting balance is a negative number, then the resulting
  direction will be switched and the amount will be transformed into a
  positive number:

      iex> head = fixture_account_head(:cash)
      iex>
      iex> a = credit(head, Decimal.new(70))
      iex> b = debit(head, Decimal.new(30))
      iex>
      iex> Bookk.Operation.merge(a, b)
      %Bookk.Operation{
        direction: :credit,
        account_head: fixture_account_head(:cash),
        amount: Decimal.new(40)
      }

  If the operations' account heads aren't the same in both operations,
  then an error will be raised:

      iex> a = debit(fixture_account_head(:cash), Decimal.new(10))
      iex> b = credit(fixture_account_head(:deposits), Decimal.new(10))
      iex>
      iex> Bookk.Operation.merge(a, b)
      ** (FunctionClauseError) no function clause matching in Bookk.Operation.merge/2

  """
  @spec merge(t, t) :: t

  # credo:disable-for-lines:10 Credo.Check.Refactor.ABCSize
  def merge(%Op{account_head: same} = a, %Op{account_head: same = head} = b) do
    {direction, amount} =
      case {a.direction, b.direction, head.class.natural_balance} do
        {same, same, _} -> {same, Decimal.add(a.amount, b.amount)}
        {same, _, same} -> {same, Decimal.sub(a.amount, b.amount)}
        {_, same, same} -> {same, Decimal.sub(b.amount, a.amount)}
      end

    new(direction, head, amount)
  end

  @doc ~S"""
  Creates a new operation. Same as `credit/2` and `debit/2` but the
  operation's direction is provided as an atom argument.

  ## Examples

  By default, the amount should be a `Decimal`:

      iex> Bookk.Operation.new(:debit, fixture_account_head(:cash), Decimal.new(10))
      %Bookk.Operation{
        direction: :debit,
        account_head: fixture_account_head(:cash),
        amount: Decimal.new(10)
      }

  """
  @spec new(direction :: :credit | :debit, Bookk.AccountHead.t(), amount) :: t
        when amount: Decimal.t() | integer() | float()

  def new(:credit, head, amount), do: credit(head, amount)
  def new(:debit, head, amount), do: debit(head, amount)

  @doc ~S"""
  Produces a opposite operation from the given operation. The opposite
  operation is capable of reverting the effect of the given operation
  when posted to an account.

  ## Examples

  A credit operation becomes a debit operation:

      iex> entry = %Bookk.Operation{direction: :credit, amount: Decimal.new(10)}
      iex> Bookk.Operation.reverse(entry)
      %Bookk.Operation{direction: :debit, amount: Decimal.new(10)}

  A debit operation becomes a credit operation:

      iex> entry = %Bookk.Operation{direction: :debit, amount: Decimal.new(10)}
      iex> Bookk.Operation.reverse(entry)
      %Bookk.Operation{direction: :credit, amount: Decimal.new(10)}

  """
  @spec reverse(t) :: t

  def reverse(%Op{direction: :credit} = entry), do: %{entry | direction: :debit}
  def reverse(%Op{direction: :debit} = entry), do: %{entry | direction: :credit}

  @doc ~S"""
  Returns the operation's delta amount, which is the real number
  (positive or negative integer) by which the account's balance will
  be changed.

  A negative integer is return in case the account should be
  subtracted, making this value safe to always be used with an
  addition operation against the account's balance.

  ## Examples

  Debiting an account which has a debit natural balance produces a
  positive number:

      iex> account_head = fixture_account_head(:cash)
      iex>
      iex> Bookk.Operation.debit(account_head, Decimal.new(100))
      iex> |> Bookk.Operation.to_delta_amount()
      Decimal.new(100)

  Debiting an account which has a credit natural balance produces a
  negative number:

      iex> account_head = fixture_account_head(:cash)
      iex>
      iex> Bookk.Operation.credit(account_head, Decimal.new(100))
      iex> |> Bookk.Operation.to_delta_amount()
      Decimal.new(-100)

  Crediting an account which has a credit natural balance produces a
  positive number:

      iex> account_head = fixture_account_head(:deposits)
      iex>
      iex> Bookk.Operation.credit(account_head, Decimal.new(100))
      iex> |> Bookk.Operation.to_delta_amount()
      Decimal.new(100)

  Debiting an account which has a credit natural balance produces a
  negative number:

      iex> account_head = fixture_account_head(:deposits)
      iex>
      iex> Bookk.Operation.debit(account_head, Decimal.new(100))
      iex> |> Bookk.Operation.to_delta_amount()
      Decimal.new(-100)

  """
  @spec to_delta_amount(t) :: integer()

  def to_delta_amount(%Op{account_head: head} = op) do
    case {head.class.natural_balance, op.direction} do
      {same, same} -> op.amount
      _ -> Decimal.mult(op.amount, -1)
    end
  end

  @doc ~S"""
  Takes a set of operations and returns a set of uniq operations per
  account. The operations that affect the same account will be merged.

  See `merge/1` and `merge/2` for more information on merging
  operations.

  ## Examples

  When there's more than one operation touching the same account,
  those operations are merged together so that the resulting list
  contains one a single operation thouching each account:

      iex> a = Bookk.Operation.debit(fixture_account_head(:cash), Decimal.new(40))
      iex> b = Bookk.Operation.debit(fixture_account_head(:cash), Decimal.new(60))
      iex> c = Bookk.Operation.credit(fixture_account_head(:deposits), Decimal.new(100))
      iex>
      iex> Bookk.Operation.uniq([a, b, c])
      [
        debit(fixture_account_head(:cash), Decimal.new(100)),
        credit(fixture_account_head(:deposits), Decimal.new(100))
      ]

  When all operations are unique, the list is returned as is:

      iex> a = Bookk.Operation.debit(fixture_account_head(:cash), Decimal.new(100))
      iex> b = Bookk.Operation.credit(fixture_account_head(:deposits), Decimal.new(100))
      iex>
      iex> Bookk.Operation.uniq([a, b])
      [
        debit(fixture_account_head(:cash), Decimal.new(100)),
        credit(fixture_account_head(:deposits), Decimal.new(100))
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
    #                ↓ deterministic sorting so its easier to test
    |> Enum.sort_by(&sort_key/1)
  end

  @directions credit: "b",
              debit: "a"
  defp sort_key(%Op{} = op),
    do: Keyword.fetch!(@directions, op.direction) <> op.account_head.name <> op.account_head.class.id
end
