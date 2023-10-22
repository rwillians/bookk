defmodule Bookk.Operation do
  @moduledoc false

  alias __MODULE__, as: Op
  alias Bookk.AccountHead, as: AccountHead

  @typedoc false
  @type t :: %Bookk.Operation{
          direction: :credit | :debit,
          account_head: Bookk.AccountHead.t(),
          amount: pos_integer
        }

  defstruct [:direction, :account_head, :amount]

  @doc """

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
end
