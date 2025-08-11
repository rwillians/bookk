defmodule Bookk.UnbalancedError do
  @moduledoc ~S"""
  An error representing that something (a journal entry, a ledger, a
  state...) isn't balanced.
  """

  @typedoc false
  @type t :: %Bookk.UnbalancedError{
          message: String.t()
        }

  defexception [:message]
end
