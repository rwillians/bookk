defmodule Bookk.Operation do
  @moduledoc """
  An operation is essentially an Either type that can be either a
  Debit or a Credit construct. Debit and credit means nothing but a
  label. Unlike belief, they don't mean positive or negative, instead
  they represent the direction of the operation.

  It takes the account class' natural balance and the operation's
  direction to evaluate whether the operation will increase or
  decrease an account's balance.

  See `Bookk.Account.post/2` for more information on increasing and
  decreasing accounts balances.
  """

  alias __MODULE__
  alias Bookk.AccountHead

  @opaque t :: %Bookk.Operation{
            direction: :credit | :debit,
            account_head: Bookk.AccountHead.t(),
            amount: non_neg_integer
          }

  defstruct [:direction, :account_head, :amount]

  @doc """
  Creates a new operation given a direction, the head of the account
  that should be affected and the amount by which the account should
  be affected.
  """
  @spec new(direction, account_head, amount) :: operation
        when direction: :credit | :debit,
             account_head: Bookk.AccountHead.t(),
             amount: integer,
             operation: t

  def new(direction, %AccountHead{} = account_head, amount)
      when direction in [:credit, :debit] and amount > -1,
      do: %Operation{direction: direction, account_head: account_head, amount: amount}

  def new(:credit, account_head, amount)
      when amount < 0,
      do: new(:debit, account_head, -amount)

  def new(:debit, account_head, amount)
      when amount < 0,
      do: new(:credit, account_head, -amount)

  @doc """
  Alias to `new/3`.
  """
  @spec credit(account_head, amount) :: operation
        when account_head: Bookk.AccountHead.t(),
             amount: integer,
             operation: t

  def credit(account_head, amount), do: new(:credit, account_head, amount)

  @doc """
  Alias to `new/3`.
  """
  @spec debit(account_head, amount) :: operation
        when account_head: Bookk.AccountHead.t(),
             amount: integer,
             operation: t

  def debit(account_head, amount), do: new(:debit, account_head, amount)

  @doc """
  Merges multiple operations that affect the same account into one
  operation.

  > ### Warning {: .warning}
  > The given set of operations MUST contain at least one element and
  > they all MUST affect the same account.

  If you have a set of operations affecting multiple accounts and you
  want to merge the operations that are affecting the same account
  into one, see `uniq/1`.
  """
  @spec merge([operation, ...]) :: operation
        when operation: t

  def merge([head]), do: head
  def merge([first, second | tail] = _operations), do: merge([merge(first, second) | tail])

  @doc """
  Merges two operations affecting the same account into one operation.

  > ### Warning {: .warning}
  > Both operations MUST affect the same account.
  """
  @spec merge(operation, operation) :: operation
        when operation: t

  def merge(
        %Operation{direction: dir, account_head: account_head} = a,
        %Operation{direction: dir, account_head: account_head} = b
      ),
      do: new(dir, account_head, a.amount + b.amount)

  def merge(
        %Operation{direction: dir, account_head: account_head} = a,
        %Operation{account_head: account_head} = b
      ),
      do: new(dir, account_head, a.amount - b.amount)

  @doc """
  Takes a set of operations where there might be multiple operations
  affecting the same account and returns a new set of operations where
  there's only one operation per account, merged using `merge/1`.
  """
  @spec uniq([operation]) :: [operation]
        when operation: t

  def uniq([]), do: []

  def uniq([_ | _] = operations) do
    operations
    |> Enum.group_by(& &1.account_head.name)
    |> Enum.flat_map(fn {_, operations} -> merge(operations) end)
  end

  @doc """
  Sorts a set of operations with the following priority:
  - `:debit` first than `:credit`;
  - account name ascending;
  - operation amount descending;
  """
  @spec sort([operation]) :: [operation]
        when operation: t

  def sort([_ | _] = operations), do: Enum.sort_by(operations, &to_sort_key/1)
  def sort([]), do: []

  @sort_priority %{debit: 0, credit: 1}
  @one_billion 1_000_000_000

  defp to_sort_key(%Operation{} = operation) do
    direction_priority = Map.fetch!(@sort_priority, operation.direction)
    account_name = operation.account_head.name

    amount =
      @one_billion - operation.amount
      |> Integer.to_string()
      |> String.pad_leading("0", 10)

    "#{direction_priority}#{account_name}#{amount}"
  end
end
