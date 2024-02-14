defmodule Bookk.AccountHead do
  @moduledoc """
  An account head is a struct with information that identifies an
  account. It contains all the properties necessary to either find or
  create an account in a ledger.

  - See `Bookk.Ledger` to learn more about ledgers;
  - See `Bookk.AccountClass` to learn more about account classes;
  """
  @moduledoc since: "0.1.0"

  @typedoc """
  A struct that describes the identifier of an account. It contains
  all the information necessary to either find or create an account in
  a ledger.

  ## Fields

  - `name` - A string of the name of the account. It must be unique
    within the ledger.
  - `class` - A `Bookk.AccountClass` struct, which contains properties
    that are inherited by the account, such as its natural balance.
  """
  @typedoc since: "0.1.0"
  @type t :: %Bookk.AccountHead{
          name: String.t(),
          class: Bookk.AccountClass.t()
        }

  defstruct [:name, :class]
end
