defmodule Bookk.UnbalancedError do
  @moduledoc """
  An error representing that something (a journal entry, a ledger, a
  state...) isn't balanced.
  """

  @type t :: %Bookk.UnbalancedError{
          message: String.t()
        }

  defexception [:message]
end
