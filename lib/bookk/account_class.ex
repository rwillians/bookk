defmodule Bookk.AccountClass do
  @moduledoc """
  Account classes provide a way to group account with commom
  properties and purpose. The properties of an account class are
  inherited by its accounts.

  There can be subclasses. Subclasses will have their `parent_sigil`
  filled with their parent class' `sigil`, while "root" classes have
  their `parent_sigil` set to `nil`.

  Subclasses inherite the properties of their parent class, their only
  purpose is to further group accounts based on a more specific
  purpose.

  For example, take `Asset` ("root" class) and `Current Asset`
  (subclass). Both their natural balance is `:debit` and both
  indicate "money" you own. But some of that money might have beeen
  invested in real state properties, for example. That kind of money
  should be represented differently from actual cash you have because
  it's way harder to sell a property to get its value in cash than it
  is to go to the bank and withdraw some money. That's why we usually
  group cash that can be liquidated fast into accounts of class
  `Current Asset`, so that we know which amounts we can use right away.

  ## Common Account Classes

  Some of the most commonly used account classes:
  - `Asset` - Represents the value of things you own, like cash and
    real state properties. It has natural balance `:debit`, meaning
    accounts from this class grows their balance with `:debit`
    operations.
    - `Current Asset` - it's a subclass of `Assets` that represents
      the value of things you own that can be withdrawn or sold
      quickly, like cash and stocks.
    - `Accounts Receivable` - it represents money that you're owed to.
      You already earned that money, you just didn't get paid yet.
      Some times it can be considered a subclass of `Current Asset`,
      but that depends on the accounting specifically done to you or
      your company.
  - `Expense` - Holds the amount spent on things like bills, takes,
    services, products, etc. It has natural balance `:debit`.
  - `Owner's Equity` - Represents the value of the owner's investment
    in the company. It has natural balance `:credit`, meaning accounts
    from this class grows their balance with `:credit` operations.
  - `Liability` - Represents the value of things you owe to others,
    like loans, bills or money that you're holding but belongs to
    others (a common case for banks). It has natural balance `:credit`.
    Ask your accountant how to properly group subclasses of Liability.
    - `Accounts Payable` - it represents money that you owe to others
      and its due really soon or past due.
  - `Gain` - Accounts for values you earned. Ask your accountant how
    to properly group subclasses of Gain.
    - `Income` - Usually accounts for money you earned from salary.
    - `Revenue` - Tracks money you received from selling products or
      services.

  **Contra classes**: classes may have a counterpart for equially
  opposite purpose, with oposite natural balance. For example, `Asset`,
  which has natural balance `:debit`, can track the value of your car;
  while `Contra Asset`, which has natural balance `:credit`, can track
  the deprecation of that car.

  > #### Warning {: .warning}
  > I'm not an accountant, I'm a software engineer. Please consult
  > a professional accountant to learn more and help design the
  > accounts & classes that better fit your needs.
  """
  @moduledoc since: "0.2.0"

  @typedoc """
  A struct that describes an account class.

  ## Fields

  - `sigil` - A 2-to-3 letter sigil that identifies the class. For
    example, `"A"` for the Asset class and `"E"` for the Expense
    class.
  - `parent_sigil` - If a subclass, then it's set to the parent class'
    sigil; otherwise, it's set to `nil`.
  - `name` - The name of the class.
  - `natural_balance` - Either `:credit` or `:debit`, it specifies
    the direction with which its accounts grows their balance.
  """
  @typedoc since: "0.2.0"
  @type t :: %Bookk.AccountClass{
          sigil: String.t(),
          parent_sigil: String.t() | nil,
          name: String.t(),
          natural_balance: :credit | :debit
        }

  defstruct [:sigil, :parent_sigil, :name, :natural_balance]
end
