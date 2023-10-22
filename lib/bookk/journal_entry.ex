defmodule Bookk.JournalEntry do
  @moduledoc false

  @typedoc false
  @type t ::
          Bookk.JournalEntry.Compound.t()
          | Bookk.JournalEntry.Complex.t()
end
