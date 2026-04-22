defmodule Bookk.AccountHead do
  @moduledoc ~S"""
  An Account head is a struct contained all the values necessary to
  either fetch or create an account in a ledger.

  ## Related

  - `Bookk.AccountClass`;
  - `Bookk.Account`;
  - `Bookk.Ledger`;
  - `Bookk.Operations`.
  """

  @typedoc ~S"""
  The struct that describes an account head.

  ## Fields

  An account head is composed of:
  - `name`: the account's name (unique within a ledger);
  - `class`: a `Bookk.AccountClass` struct that describes the class to
    which the account belongs;
  - `meta`: a map of metadata for whatever information you find useful
    to hold.
  """
  @type t :: %Bookk.AccountHead{
          name: String.t(),
          class: Bookk.AccountClass.t(),
          meta: map
        }

  defstruct [:name, :class, meta: %{}]
end
