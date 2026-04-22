defmodule Bookk.Account do
  @moduledoc ~S"""
  An Account is pretty much like a bucket. It has a single purpose:
  holding a measurable amount of something, in this case it's monetary
  amount.

  ## Related

  - `Bookk.AccountHead`;
  - `Bookk.Ledger`.
  """

  alias __MODULE__, as: Account
  alias Bookk.AccountHead
  alias Bookk.Operation, as: Op

  @typedoc ~S"""
  The struct that represents the state of an account.

  ## Fields

  An account is composed of:
  - `head`: the `Bookk.AccountHead` that identifies the account;
  - `balance`: the monetary amount held by the account, in `Decimal`
    for high precision arithmetic.
  """
  @type t :: %Bookk.Account{
          head: Bookk.AccountHead.t(),
          balance: Decimal.t()
        }

  defstruct [:head, balance: Decimal.new(0)]

  @doc ~S"""
  Checks whether an account is empty (no balance).

  ## Examples

      iex> ACME.ChartOfAccounts.account(:cash)
      iex> |> Bookk.Account.new(Decimal.new(0))
      iex> |> Bookk.Account.empty?()
      true

      iex> ACME.ChartOfAccounts.account(:cash)
      iex> |> Bookk.Account.new(Decimal.new(10))
      iex> |> Bookk.Account.empty?()
      false

  """
  @spec empty?(t) :: boolean()

  def empty?(%Account{} = account), do: Decimal.eq?(account.balance, 0)

  @doc ~S"""
  Merges a non-empty set of accounts into one, where all accounts must
  have the same account head.

  ## Examples

      iex> a = Bookk.Account.new(ACME.ChartOfAccounts.account(:cash), Decimal.new(5))
      iex> b = Bookk.Account.new(ACME.ChartOfAccounts.account(:cash), Decimal.new(15))
      iex> c = Bookk.Account.new(ACME.ChartOfAccounts.account(:cash), Decimal.new(30))
      iex>
      iex> Bookk.Account.merge([a, b, c])
      ACME.ChartOfAccounts.account(:cash)
      |> Bookk.Account.new(Decimal.new(50))

  If you try to merge an empty list of accounts, an error will be
  raised.
  """
  @spec merge([t, ...]) :: t

  def merge([%Account{} = account]), do: account
  def merge([%Account{} = head | tail]), do: merge(head, merge(tail))

  @doc ~S"""
  Merges two accounts into one, where both accounts must have the same
  account head.

  ## Examples

      iex> a = Bookk.Account.new(ACME.ChartOfAccounts.account(:cash), Decimal.new(5))
      iex> b = Bookk.Account.new(ACME.ChartOfAccounts.account(:cash), Decimal.new(15))
      iex> Bookk.Account.merge(a, b)
      Bookk.Account.new(ACME.ChartOfAccounts.account(:cash), Decimal.new(20))

  It raises if one account head is different from the other:

      iex> a = Bookk.Account.new(ACME.ChartOfAccounts.account(:cash), Decimal.new(5))
      iex> b = Bookk.Account.new(ACME.ChartOfAccounts.account(:deposits), Decimal.new(15))
      iex> Bookk.Account.merge(a, b)
      ** (FunctionClauseError) no function clause matching in Bookk.Account.merge/2

  """
  @spec merge(t, t) :: t

  def merge(%Account{head: same} = a, %Account{head: same} = b) do
    %Account{
      head: same,
      balance: Decimal.add(a.balance, b.balance)
    }
  end

  @doc ~S"""
  Creates a new account from a `Bookk.AccountHead`.

  ## Examples

  If no initial balance is provided in the second argument, then balance will be
  set to zero:

      iex> head = ACME.ChartOfAccounts.account(:cash)
      iex> Bookk.Account.new(head)
      %Bookk.Account{
        head: ACME.ChartOfAccounts.account(:cash),
        balance: Decimal.new(0)
      }

  If an initial balance is provided in the second argument, then balance will be
  set to it:

      iex> head = ACME.ChartOfAccounts.account(:cash)
      iex> Bookk.Account.new(head, Decimal.new(50))
      %Bookk.Account{
        head: ACME.ChartOfAccounts.account(:cash),
        balance: Decimal.new(50)
      }

  """
  @spec new(Bookk.AccountHead.t()) :: t
  @spec new(Bookk.AccountHead.t(), balance :: Decimal.t()) :: t

  def new(head, balance \\ Decimal.new(0))

  def new(%AccountHead{} = head, %Decimal{} = balance),
    do: %Account{head: head, balance: balance}

  @doc ~S"""
  Calculates de delta amount of the given operation, then adds it the
  account's balance. See `Bookk.Operation.to_delta_amount/1` for more
  information on delta amount.

  ## Examples

      iex> head = ACME.ChartOfAccounts.account(:cash)
      iex> account = Bookk.Account.new(head)
      iex>
      iex> op = Bookk.Operation.debit(head, Decimal.new(25))
      iex>
      iex> Bookk.Account.post(account, op)
      %Bookk.Account{
        head: ACME.ChartOfAccounts.account(:cash),
        balance: Decimal.new(25)
      }

  The account's head must match the head in the operation, otherwise an error is
  raised:

      iex> head_a = %Bookk.AccountHead{name: "a"}
      iex> head_b = %Bookk.AccountHead{name: "b"}
      iex>
      iex> account = Bookk.Account.new(head_a)
      iex> op = Bookk.Operation.debit(head_b, Decimal.new(25))
      iex>
      iex> Bookk.Account.post(account, op)
      ** (FunctionClauseError) no function clause matching in Bookk.Account.post/2

  """
  @spec post(t, Bookk.Operation.t()) :: t

  def post(
        %Account{head: same, balance: balance},
        %Op{account_head: same = head} = op
      ) do
    %Account{
      head: head,
      balance: Decimal.add(balance, Op.to_delta_amount(op))
    }
  end
end
