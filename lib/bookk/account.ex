defmodule Bookk.Account do
  @moduledoc false

  alias __MODULE__, as: Account
  alias Bookk.AccountHead, as: AccountHead
  alias Bookk.Operation, as: Op

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

  ## Examples

  Adding balance:

      iex> class = %Bookk.AccountClass{balance_increases_with: :debit}
      iex> head = %Bookk.AccountHead{class: class}
      iex> account = Bookk.Account.new(head)
      iex>
      iex> op = debit(head, 25_00)
      iex>
      iex> Bookk.Account.post(account, op)
      %Bookk.Account{
        head: %Bookk.AccountHead{class: %Bookk.AccountClass{balance_increases_with: :debit}},
        balance: 25_00
      }

  Subtracting balance:

      iex> class = %Bookk.AccountClass{balance_increases_with: :debit}
      iex> head = %Bookk.AccountHead{class: class}
      iex> account = Bookk.Account.new(head)
      iex>
      iex> op = credit(head, 25_00)
      iex>
      iex> Bookk.Account.post(account, op)
      %Bookk.Account{
        head: %Bookk.AccountHead{class: %Bookk.AccountClass{balance_increases_with: :debit}},
        balance: -25_00
      }

  Mismatching account headers:

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
        %Op{account_head: same = head, amount: amount} = entry
      ) do
    balance_after =
      case {head.class.balance_increases_with, entry.direction} do
        {same, same} -> balance + amount
        {_, _} -> balance - amount
      end

    %Account{head: head, balance: balance_after}
  end
end
