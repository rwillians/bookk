defmodule Bookk.AccountClass do
  @moduledoc false

  @typedoc """
  ## Fields

  - **`id`**: it's recomended that, instead of using it with an arbitrary value,
    you should assign it to the abbreviation of the account class. In the
    section below you will find some of the most common classes.
  - **`parent_id`**: If the class is a subclass, then `parent_id` should be set
    to the parent class' abbreviation. For example, Current Assets is a subclass
    of Assets, therefore its `parent_id` should be set to `"A"`.
  - **`name`**: The human readable name of the account class.
  - **`balance_increases_with`** (either `:debit` or `:credit`): specifies the
    direction in which accounts of this class grows their balance. For example,
    Assets accounts grows their balances with `:debit`.

  ## Common classes

  These are some of the most common classes used, they are organized as a tree
  to represent the relationship of parent classes & children subclasses:

  > **Note**: this is how classes will be represented:
  >
  > (**A**) [debit] Assets
  >    ^     ^      ^
  >    ^     ^      ^ The name of the class or subclass.
  >    ^     ^
  >    ^     ^ The direction in which the classes' accounts grows their balance.
  >    ^
  >    ^ The class' or subclass' name abbreviation.
  >
  > Subclasses inherits all properties from their parents.

  - (A) [debit] **Assets**
    - (CA) Current Assets
    - (AR) Accounts Receivable
  - (Ac) [credit] **Contra Assets**
  - (E) [debit] **Expenses**
  - (OE) [credit] **Owner's Equity**
  - (OEc) [debit] **Contra Owner's Equity**
  - (L) [credit] **Liabilities**
  - (I) [credit] **Income**
    - (G) Gains
    - (R) Revenue
    - (AP) Accounts Payable

  """
  @type t :: %Bookk.AccountClass{
          id: String.t(),
          parent_id: String.t() | nil,
          name: String.t(),
          balance_increases_with: :credit | :debit
        }

  defstruct [:id, :parent_id, :name, :balance_increases_with]
end
