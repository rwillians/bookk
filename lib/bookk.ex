defmodule Bookk do
  @moduledoc false

  alias Bookk.InterledgerEntry
  alias Bookk.JournalEntry
  alias Bookk.Ledger
  alias Bookk.NaiveState

  @doc ~S"""
  Checks whether the given object is balanced (the sum of debits is
  equal the sum of credits).
  """
  @spec balanced?(Bookk.InterledgerEntry.t()) :: boolean()
  @spec balanced?(Bookk.JournalEntry.t()) :: boolean()
  @spec balanced?(Bookk.Ledger.t()) :: boolean()
  @spec balanced?(Bookk.NaiveState.t()) :: boolean()

  def balanced?(%InterledgerEntry{} = entry), do: InterledgerEntry.balanced?(entry)
  def balanced?(%JournalEntry{} = entry), do: JournalEntry.balanced?(entry)
  def balanced?(%Ledger{} = ledger), do: Ledger.balanced?(ledger)
  def balanced?(%NaiveState{} = state), do: NaiveState.balanced?(state)

  @doc ~S"""
  Calculates the diff two object, expressed in the form of either a
  `Bookk.JournalEntry` or a `Bookk.InterledgerEntry`.
  """
  @spec diff(a :: Bookk.InterledgerEntry.t(), b :: Bookk.InterledgerEntry.t()) :: Bookk.InterledgerEntry.t()
  @spec diff(a :: Bookk.JournalEntry.t(), b :: Bookk.JournalEntry.t()) :: Bookk.JournalEntry.t()
  @spec diff(a :: Bookk.Ledger.t(), b :: Bookk.Ledger.t()) :: Bookk.JournalEntry.t()
  @spec diff(a :: Bookk.NaiveState.t(), b :: Bookk.NaiveState.t()) :: Bookk.InterledgerEntry.t()

  def diff(%InterledgerEntry{} = a, %InterledgerEntry{} = b), do: InterledgerEntry.diff(a, b)
  def diff(%JournalEntry{} = a, %JournalEntry{} = b), do: JournalEntry.diff(a, b)
  def diff(%Ledger{id: same} = a, %Ledger{id: same} = b), do: Ledger.diff(a, b)
  def diff(%NaiveState{} = a, %NaiveState{} = b), do: NaiveState.diff(a, b)

  @doc ~S"""
  Merges two of the same object together.
  """
  @spec merge(a :: Bookk.InterledgerEntry.t(), b :: Bookk.InterledgerEntry.t()) :: boolean()
  @spec merge(a :: Bookk.JournalEntry.t(), b :: Bookk.JournalEntry.t()) :: boolean()
  @spec merge(a :: Bookk.Ledger.t(), b :: Bookk.Ledger.t()) :: boolean()
  @spec merge(a :: Bookk.NaiveState.t(), b :: Bookk.NaiveState.t()) :: boolean()

  def merge(%InterledgerEntry{} = a, %InterledgerEntry{} = b), do: InterledgerEntry.merge(a, b)
  def merge(%JournalEntry{} = a, %JournalEntry{} = b), do: JournalEntry.merge(a, b)
  def merge(%Ledger{id: same} = a, %Ledger{id: same} = b), do: Ledger.merge(a, b)
  def merge(%NaiveState{} = a, %NaiveState{} = b), do: NaiveState.merge(a, b)
end
