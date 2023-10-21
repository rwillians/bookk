defmodule Bookk.JournalEntry.Complex do
  @moduledoc false

  @typedoc false
  @type t :: %Bookk.JournalEntry.Complex{
          entries: [Bookk.JournalEntry.Compound.t()]
        }

  defstruct [:entries]
end
