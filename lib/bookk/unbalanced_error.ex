defmodule Bookk.UnbalancedError do
  @moduledoc """
  TODO
  """

  @typedoc false
  @type t :: %Bookk.UnbalancedError{
          message: String.t()
        }

  defexception [:message]
end
