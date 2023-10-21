defmodule Bookk.JournalEntry.Compound do
  @moduledoc false

  @typedoc false
  @type t :: %Bookk.JournalEntry.Compound{
          ledger_name: String.t(),
          entries: [Bookk.JournalEntry.Simple.t()]
        }

  defstruct [:ledger_name, entries: []]
end
