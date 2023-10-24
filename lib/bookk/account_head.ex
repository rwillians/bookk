defmodule Bookk.AccountHead do
  @moduledoc """
  Account head is a struct contained all the values necessary to either fetch
  or create a `Bookk.Account` from/into a `Bookk.Ledger`.

  ## Related

  - `Bookk.AccountClass`;
  - `Bookk.Account`;
  - `Bookk.Ledger`;
  - `Bookk.Operations`.
  """

  @typedoc """
  The struct that describes an account head.

  ## Fields

  An account head is composed of:
  - `name`: the accounts name (unique within a ledger);
  - `class`: a `Bookk.AccountClass` struct that describes the class to which the
    account belongs.
  """
  @type t :: %Bookk.AccountHead{
          name: String.t(),
          class: Bookk.AccountClass.t()
        }

  defstruct [:name, :class]
end
