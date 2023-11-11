defmodule Bookk.AccountClass do
  @moduledoc """
  An account class has properties that are inherited by accounts and
  serves as a way of grouping account's balances.

  ## Common classes

  Here are some of the most common used classes for reference:

  | id       | parent id | natural balance | name                     |
  | ---      | ---       | ---             | ---                      |
  | **`A`**  |           | `:debit`        | Assets                   |
  | **`CA`** | **`A`**   | `:debit`        | Current Assets           |
  | **`AR`** | **`A`**   | `:debit`        | Accounts Receivables     |
  | **`Ac`** |           | `:credit`       | Contra Assets            |
  | **`AD`** | **`Ac`**  | `:credit`       | Accumulated Depreciation |
  | **`E`**  |           | `:debit`        | Expenses                 |
  | **`OE`** |           | `:credit`       | Owner's Equity           |
  | **`L`**  |           | `:credit`       | Liabilities              |
  | **`AP`** | **`L`**   | `:credit`       | Accounts Payables        |
  | **`I`**  |           | `:credit`       | Income                   |
  | **`G`**  | **`I`**   | `:credit`       | Gains                    |
  | **`R`**  | **`I`**   | `:credit`       | Revenue                  |

  ## Related

  - `Bookk.AccountHead`;
  - `Bookk.Account`.
  """

  @typedoc """
  The struct that describes an account class.

  ## Fields

  An account class in composed of:
  - **`id`**: it's recomended that, instead of using it with an
    arbitrary value, you assign it to the class' name abbreviation;
  - **`parent_id`**: If the class is a subclass, then `parent_id`
    should be set to the parent class' abbreviation. For example,
    Current Assets is a subclass of Assets, therefore its `parent_id`
    should be set to `"A"` (where `"A"` is the abbreviation of
    Assets);
  - **`name`**: The human readable name of the account class;
  - **`natural_balance`** (either `:debit` or `:credit`): specifies
    the direction in which accounts of this class grows their balance.
    For example, Assets accounts grows their balances with `:debit`
    operations.

  See section [Common classes](#module-common-classes) for examples of
  classes.
  """
  @type t :: %Bookk.AccountClass{
          id: String.t(),
          parent_id: String.t() | nil,
          name: String.t(),
          natural_balance: :credit | :debit
        }

  defstruct [:id, :parent_id, :name, :natural_balance]
end
