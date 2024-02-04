defmodule Bookk.AccountHead do
  @moduledoc """
  An account head is a struct with information that identifies an
  account. It contains all the properties necessary to either find or
  create an account in a ledger.

  - See `Bookk.Ledger` to learn more about ledgers;
  - See `Bookk.AccountClass` to learn more about account classes;
  """

  @typedoc """
  A struct that represents an identifier of an account. It contains
  all the information necessary to either find or create an account in
  a ledger.

  ## Properties

  - `name` - A string of the name of the account. It must be unique
    within the ledger.
  - `class` - An account class struct, which contains properties that
    are inherited by the account, such as its natural balance.
  """
  @type t :: %Bookk.AccountHead{
          name: String.t(),
          class: Bookk.AccountClass.t()
        }

  defstruct [:name, :class]
end
