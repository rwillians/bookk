defmodule Bookk.Account do
  @moduledoc """
  An account is pretty much like a bucked. It has a single purpose: holding a
  measurable amount of something (currency).

  ## Related

  - `Bookk.AccountHead`;
  - `Bookk.Operation`;
  - `Bookk.Ledger`.
  """

  alias __MODULE__, as: Account
  alias Bookk.AccountHead, as: AccountHead
  alias Bookk.Operation, as: Op

  @typedoc """
  The struct that describes the state of an account.

  ## Fields

  An account is composed of:
  - `head`: the `Bookk.AccountHead` that identifies the account;
  - `balance`: the amount of currency held by the account, in cents or the
    smallest fraction supported by the currency you're using.
  """
  @type t :: %Bookk.Account{
          head: Bookk.AccountHead.t(),
          balance: integer
        }

  defstruct [:head, balance: 0]

  @doc """
  TODO

  ## Examples

  If no initial balance is provided in the second argument, then balance will be
  set to zero:

      iex> head = fixture_account_head(:cash)
      iex> Bookk.Account.new(head)
      %Bookk.Account{
        head: fixture_account_head(:cash),
        balance: 0
      }

  If an initial balance is provided in the second argument, then balance will be
  set to it:

      iex> head = fixture_account_head(:cash)
      iex> Bookk.Account.new(head, 50_00)
      %Bookk.Account{
        head: fixture_account_head(:cash),
        balance: 50_00
      }

  """
  @spec new(Bookk.AccountHead.t()) :: t
  @spec new(Bookk.AccountHead.t(), balance :: pos_integer) :: t

  def new(%AccountHead{} = head, balance \\ 0)
      when is_integer(balance),
      do: %Account{head: head, balance: balance}

  @doc """
  Applies the change described in a `Bookk.Operation` into the given account.

  ## Examples

  When the direction of the operation matches the account's natural balance,
  then balance is added:

      iex> class = %Bookk.AccountClass{natural_balance: :debit}
      iex> head = %Bookk.AccountHead{class: class}
      iex> account = Bookk.Account.new(head)
      iex>
      iex> op = debit(head, 25_00)
      iex>
      iex> Bookk.Account.post(account, op)
      %Bookk.Account{
        head: %Bookk.AccountHead{class: %Bookk.AccountClass{natural_balance: :debit}},
        balance: 25_00
      }

  When the direction of the operation doesn't match the account's natural
  balance, the balance is subtracted:

      iex> class = %Bookk.AccountClass{natural_balance: :debit}
      iex> head = %Bookk.AccountHead{class: class}
      iex> account = Bookk.Account.new(head)
      iex>
      iex> op = credit(head, 25_00)
      iex>
      iex> Bookk.Account.post(account, op)
      %Bookk.Account{
        head: %Bookk.AccountHead{class: %Bookk.AccountClass{natural_balance: :debit}},
        balance: -25_00
      }

  When the account's head doesn't match the head in the operation, then an error
  is raised:

      iex> head_a = %Bookk.AccountHead{name: "a"}
      iex> head_b = %Bookk.AccountHead{name: "b"}
      iex>
      iex> account = Bookk.Account.new(head_a)
      iex> op = debit(head_b, 25_00)
      iex>
      iex> Bookk.Account.post(account, op)
      ** (FunctionClauseError) no function clause matching in Bookk.Account.post/2

  """
  @spec post(t, Bookk.Operation.t()) :: t

  def post(
        %Account{head: same, balance: balance},
        %Op{account_head: same = head, amount: amount} = op
      ) do
    balance_after =
      case {head.class.natural_balance, op.direction} do
        {same, same} -> balance + amount
        _ -> balance - amount
      end

    %Account{head: head, balance: balance_after}
  end
end
