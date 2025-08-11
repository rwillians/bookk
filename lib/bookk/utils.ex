defmodule Bookk.Utils do
  @moduledoc ~S"""
  Utility functions.
  """

  @doc ~S"""
  Casts the given value into a `Decimal`. It raises `ArgumentError` if
  the given value is of an unsupported type.
  """
  @spec to_decimal(value) :: Decimal.t()
        when value: Decimal.t() | integer() | float()

  def to_decimal(%Decimal{} = value), do: value
  def to_decimal(value) when is_integer(value), do: Decimal.new(value)
  def to_decimal(value) when is_float(value), do: Decimal.from_float(value)
  def to_decimal(value), do: raise(ArgumentError, "amounts must be either a Decimal, an integer or a float, got #{inspect(value)}")
end
