defmodule Bookk.AccountHead do
  @moduledoc false

  @typedoc false
  @type t :: %Bookk.AccountHead{
          name: String.t(),
          class: Bookk.AccountClass.t()
        }

  defstruct [:name, :class]
end
