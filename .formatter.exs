locals_without_parens = [
  credit: 2,
  debit: 2,
  journalize!: 2
]

[
  inputs: ["{config,lib,test}/**/*.{ex,exs}"],
  line_length: 100,
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
]
