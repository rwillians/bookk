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
  @moduledoc since: "0.1.0"

  alias __MODULE__
  alias Bookk.AccountClass
  alias Bookk.AccountHead

  @doc """
  A struct describing an operation in an account.
  """
  @typedoc since: "0.1.0"
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
  @doc since: "0.1.0"
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
  @doc since: "0.1.0"
  @spec credit(account_head, amount) :: operation
        when account_head: Bookk.AccountHead.t(),
             amount: integer,
             operation: t

  def credit(account_head, amount), do: new(:credit, account_head, amount)

  @doc """
  Alias to `new/3`.
  """
  @doc since: "0.1.0"
  @spec debit(account_head, amount) :: operation
        when account_head: Bookk.AccountHead.t(),
             amount: integer,
             operation: t

  def debit(account_head, amount), do: new(:debit, account_head, amount)

  @doc """
  Check whether an operation is empty, i.e., it doesn't affect the
  account's balance.

      iex> Bookk.Operation.empty?(%Bookk.Operation{amount: 0})
      true

      iex> Bookk.Operation.empty?(%Bookk.Operation{amount: 10_00})
      false

      iex> Bookk.Operation.empty?(%Bookk.Operation{amount: -10_00})
      false

  """
  @doc since: "0.1.0"
  @spec empty?(operation) :: boolean
        when operation: t

  def empty?(%Operation{amount: 0}), do: true
  def empty?(%Operation{}), do: false

  @doc """
  Merges multiple operations that affect the same account into one
  operation. Using this function has the same effect as reducing your
  set of operations calling `merge/2`.

  > ### Warning {: .warning}
  > At least one operation MUST be given.

      iex> Bookk.Operation.merge([])
      ** (FunctionClauseError) no function clause matching in Bookk.Operation.merge/1

  > ### Warning {: .warning}
  > All given operations MUST affect the same account.

      iex> account_head_a = %Bookk.AccountHead{name: "foo"}
      iex> account_head_b = %Bookk.AccountHead{name: "bar"}
      iex>
      iex> operation_a = Bookk.Operation.debit(account_head_a, 10_00)
      iex> operation_b = Bookk.Operation.debit(account_head_b, 20_00)
      iex>
      iex> Bookk.Operation.merge([operation_a, operation_b])
      ** (FunctionClauseError) no function clause matching in Bookk.Operation.merge/2

  If you have a set of operations affecting multiple accounts and you
  want to merge only the operations that are affecting the same
  account, then use `uniq/1`.
  """
  @doc since: "0.1.0"
  @spec merge([operation, ...]) :: operation
        when operation: t

  def merge([head]), do: head
  def merge([first, second | tail] = _operations), do: merge([merge(first, second) | tail])

  @doc """
  Merges two operations affecting the same account into one operation.

  If the operations' directions are the same, then the resulting
  amount is the sum of the two operations' amount:

      iex> asset = %Bookk.AccountClass{natural_balance: :debit}
      iex> account_head = %Bookk.AccountHead{name: "cash", class: asset}
      iex>
      iex> operation_a = Bookk.Operation.debit(account_head, 10_00)
      iex> operation_b = Bookk.Operation.debit(account_head, 20_00)
      iex>
      iex> Bookk.Operation.merge(operation_a, operation_b)
      %Bookk.Operation{
        direction: :debit,
        account_head: %Bookk.AccountHead{
          name: "cash",
          class: %Bookk.AccountClass{natural_balance: :debit}
        },
        amount: 30_00
      }

  Otherwise, we preserve the direction of the first operation and we
  subtract the second operation's amount from the first's. If the
  resulting amount is a negative number, then we flip the direction
  and make the amount positive:

      iex> asset = %Bookk.AccountClass{natural_balance: :debit}
      iex> account_head = %Bookk.AccountHead{name: "cash", class: asset}
      iex>
      iex> operation_a = Bookk.Operation.debit(account_head, 20_00)
      iex> operation_b = Bookk.Operation.credit(account_head, 30_00)
      iex>
      iex> Bookk.Operation.merge(operation_a, operation_b)
      %Bookk.Operation{
        direction: :credit,
        account_head: %Bookk.AccountHead{
          name: "cash",
          class: %Bookk.AccountClass{natural_balance: :debit}
        },
        amount: 10_00
      }

  > ### Warning {: .warning}
  > Both operations MUST affect the same account.

      iex> account_head_a = %Bookk.AccountHead{name: "foo"}
      iex> account_head_b = %Bookk.AccountHead{name: "bar"}
      iex>
      iex> operation_a = Bookk.Operation.debit(account_head_a, 10_00)
      iex> operation_b = Bookk.Operation.debit(account_head_b, 20_00)
      iex>
      iex> Bookk.Operation.merge(operation_a, operation_b)
      ** (FunctionClauseError) no function clause matching in Bookk.Operation.merge/2

  """
  @doc since: "0.1.0"
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
  Sorts a set of operations with the following priority:
  - `:debit` first than `:credit`;
  - account name ascending;
  - operation amount descending;
  """
  @doc since: "0.1.0"
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
      (@one_billion - operation.amount)
      |> Integer.to_string()
      |> String.pad_leading(10, "0")

    "#{direction_priority}#{account_name}#{amount}"
  end

  @doc """
  Returns either a positive or a negative number representing the
  delta change in the account's balance, where positive means an
  increase in balance and negative means a decrease in balance.

      iex> asset = %Bookk.AccountClass{natural_balance: :debit}
      iex> account_head = %Bookk.AccountHead{name: "cash", class: asset}
      iex>
      iex> operation = Bookk.Operation.debit(account_head, 20_00)
      iex>
      iex> Bookk.Operation.to_delta_amount(operation)
      20_00

      iex> asset = %Bookk.AccountClass{natural_balance: :debit}
      iex> account_head = %Bookk.AccountHead{name: "cash", class: asset}
      iex>
      iex> operation = Bookk.Operation.credit(account_head, 20_00)
      iex>
      iex> Bookk.Operation.to_delta_amount(operation)
      -20_00

  When the operation type is the same as the account's natural
  balance, then the account's balance is increasing, meaning the
  result will be a positive number. Otherwise, the account's balance
  will decrease, resulting in a negative number.
  """
  @doc since: "0.1.0"
  @spec to_delta_amount(operation) :: integer
        when operation: t

  def to_delta_amount(
        %Operation{
          direction: dir,
          account_head: %AccountHead{class: %AccountClass{natural_balance: dir}}
        } = operation
      ),
      do: operation.amount

  def to_delta_amount(%Operation{} = operation), do: -operation.amount

  @doc """
  Takes a set of operations where there might be multiple operations
  affecting the same account and returns a new set of operations where
  there's only one operation per account, merged using `merge/1`.
  """
  @doc since: "0.1.0"
  @spec uniq([operation]) :: [operation]
        when operation: t

  def uniq([]), do: []

  def uniq([_ | _] = operations) do
    operations
    |> Enum.group_by(& &1.account_head.name)
    |> Enum.map(fn {_name, operations} -> merge(operations) end)
  end
end
