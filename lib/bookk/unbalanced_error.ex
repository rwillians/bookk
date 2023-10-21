defmodule Bookk.UnbalancedError do
  @moduledoc false

  @typedoc false
  @type t :: %Bookk.UnbalancedError{
          message: String.t()
        }

  defexception [:message]
end
