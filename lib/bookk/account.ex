defmodule Bookk.Account do
  @moduledoc """
  An account is simply a bucket that holds a measurable amount of
  something, in this case money.

  | class | name | balance  |
  |:------|:-----|---------:|
  | Asset | Cash | $6000.00 |

  Just like in a bucket of water, you can't tell apart where each drop
  of water came from. Therefore, if you need to track the origin of
  the some amount of money, then you need to have an account designed
  specifically for that purpose.

    | class   | name         | balance  |
    |:--------|:-------------|---------:|
    | Asset   | Cash         | $6000.00 |
    | Income  | Salary       | $5000.00 |
    | Revenue | Garage Sales | $1000.00 |

  In the first example we couln't tell the origin of those $6000.00,
  but now, with the help of Salara and Garage Sales accounts, we can.

  An account can have any balance, including a negative amount.

  That being said, it's recommended to avoid negative balances because
  that's usually a sign that you're missing accounts designed
  specifically to track that missing amount, for example one or more
  accounts that tracks debt.

  So instead of doing this:

  | class   | name | balance   |
  | Asset   | Cash | -$1000.00 |
  | Expense | Rent |  $1000.00 |

  You should prefer this:

  | class     | name             | balance  |
  | Asset     | Cash             |       $0 |
  | Expense   | Rent             | $1000.00 |
  | Liability | Accounts Payable | $1000.00 |

  - See `Bookk.AccountHead` to learn more about the properties needed
    to create an account;
  - See `Bookk.Operation` to lear more about Credit and Debit;
  - See `Bookk.Ledger` to learn more about balancing Credit and Debit;
  - See `Bookk.AccountClass` to learn more about account's natural
    balance.
  """

  alias __MODULE__
  alias Bookk.Operation

  @typedoc """
  The struct representing an account.

  ## Properties

  - `head` - The head of the account, which is a struct that contains
    all the information we need to either find or create an account
    within a ledger.
  - `balance` - An integer representing the amount of money that the
    account holds. This number should be in the smallest fraction of
    the currency you're using, for example cents in the case of USD.
    The amount may be a negative number, but it's not recommended
    because it's often a sign that you're missing some accounts in
    your design. See `Bookk.Account` for more information.
  """
  @type t :: %Bookk.Account{
          head: Bookk.AccountHead.t(),
          balance: integer
        }

  defstruct head: nil,
            balance: 0

  @doc """
  Changes an account's balance by posting an operation against it.

  If both the account class' naturable balance
  (`account.head.class.natural_balance`) and the operation's
  direction (`operation.direction`) are the same (either `:credit` or
  `:debit`), then the operation increases the account's balance;
  othersie, the operation decreases it.

  ## Examples

  When the directions are the same, balance increases:

        iex> account = %Bookk.Account{
        iex>   head: %Bookk.AccountHead{
        iex>     class: %Bookk.AccountClass{natural_balance: :credit}
        iex>     #                 natural balance is :credit ↑
        iex>   },
        iex>   balance: 0
        iex>   #        ↑ current balance is $0.00
        iex> }
        iex>
        iex> operation = Bookk.Operation.credit(account.head, 100_00)
        iex> #                           ↑ the operation's direction
        iex> #                             is also :credit
        iex>
        iex> Bookk.Account.post(account, operation)
        %Bookk.Account{
          head: %Bookk.AccountHead{class: %Bookk.AccountClass{natural_balance: :credit}},
          balance: 100_00
          #        ↑ balance increased by $100.00
        }

  When the directions are different, balance decreases:

        iex> account = %Bookk.Account{
        iex>   head: %Bookk.AccountHead{
        iex>     class: %Bookk.AccountClass{natural_balance: :credit}
        iex>     #                 natural balance is :credit ↑
        iex>   },
        iex>   balance: 0
        iex> }
        iex>
        iex> operation = Bookk.Operation.debit(account.head, 100_00)
        iex> #                           ↑ but the operation's
        iex> #                             direction is :debit
        iex>
        iex> Bookk.Account.post(account, operation)
        %Bookk.Account{
          head: %Bookk.AccountHead{class: %Bookk.AccountClass{natural_balance: :credit}},
          balance: -100_00
          #         ↑ balance decreased by $100.00
        }

  """
  @spec post(account, operation) :: account
        when account: Bookk.Account.t(),
             operation: Bookk.Operation.t()

  def post(%Account{} = account, %Operation{} = operation) do
    case {account.head.class.natural_balance, operation.direction} do
      {same, same} -> %{account | balance: account.balance + operation.amount}
      {_, _} -> %{account | balance: account.balance - operation.amount}
    end
  end
end
