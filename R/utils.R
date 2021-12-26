germanNumberFormat <- function(x, accuracy = 1, scale = 1, prefix = "", suffix = "") {
  s <- number(
    x,
    accuracy = accuracy,
    scale = scale,
    prefix = prefix,
    suffix = suffix,
    decimal.mark = ",",
    big.mark = "."
  )
  s
}
