defmodule Bookk.UnbalancedError do
  @moduledoc """
  An error representing that something (a journal entry, a ledger, a
  state...) isn't balanced.
  """
  @moduledoc since: "0.1.0"

  @typedoc """
  The struct representing an unbalanced error.

  ## Fields

  - `message` - the error message.
  """
  @typedoc since: "0.1.0"
  @type t :: %Bookk.UnbalancedError{
          message: String.t()
        }

  defexception [:message]
end
