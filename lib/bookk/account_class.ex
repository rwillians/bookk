defmodule Bookk.AccountClass do
  @moduledoc false

  @typedoc false
  @type t :: %Bookk.AccountClass{
          sigil: String.t(),
          parent_sigil: String.t() | nil,
          name: String.t(),
          balance_increases_with: :credit | :debit
        }

  defstruct [:sigil, :parent_sigil, :name, :balance_increases_with]
end
