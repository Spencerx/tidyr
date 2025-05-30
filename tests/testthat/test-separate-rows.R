test_that("can handle collapsed rows", {
  df <- tibble(x = 1:3, y = c("a", "d,e,f", "g,h"))
  expect_equal(separate_rows(df, y)$y, unlist(strsplit(df$y, "\\,")))
})

test_that("can handle empty data frames (#308)", {
  df <- tibble(a = character(), b = character())
  rs <- separate_rows(df, b)
  expect_equal(rs, tibble(a = character(), b = unspecified()))
})

test_that("default pattern does not split decimals in nested strings", {
  df <- dplyr::tibble(x = 1:3, y = c("1", "1.0,1.1", "2.1"))
  expect_equal(separate_rows(df, y)$y, unlist(strsplit(df$y, ",")))
})

test_that("preserves grouping", {
  df <- tibble(g = 1, x = "a:b") %>% dplyr::group_by(g)
  rs <- df %>% separate_rows(x)

  expect_equal(class(df), class(rs))
  expect_equal(dplyr::group_vars(df), dplyr::group_vars(rs))
})

test_that("drops grouping when needed", {
  df <- tibble(x = 1, y = "a:b") %>% dplyr::group_by(x, y)

  out <- df %>% separate_rows(y)
  expect_equal(out$y, c("a", "b"))
  expect_equal(dplyr::group_vars(out), "x")

  out <- df %>%
    dplyr::group_by(y) %>%
    separate_rows(y)
  expect_equal(dplyr::group_vars(out), character())
})

test_that("drops grouping on zero row data frames when needed (#886)", {
  df <- tibble(x = numeric(), y = character()) %>% dplyr::group_by(y)
  out <- df %>% separate_rows(y)
  expect_equal(dplyr::group_vars(out), character())
})

test_that("convert produces integers etc", {
  df <- tibble(x = "1,2,3", y = "T,F,T", z = "a,b,c")

  out <- separate_rows(df, x, y, z, convert = TRUE)
  expect_equal(class(out$x), "integer")
  expect_equal(class(out$y), "logical")
  expect_equal(class(out$z), "character")
})

test_that("leaves list columns intact (#300)", {
  df <- tibble(x = "1,2,3", y = list(1))

  out <- separate_rows(df, x)
  # Can't compare tibbles with list columns directly
  expect_equal(names(out), c("x", "y"))
  expect_equal(out$x, as.character(1:3))
  expect_equal(out$y, rep(list(1), 3))
})

test_that("does not silently drop blank values (#1014)", {
  df <- tibble(x = 1:3, y = c("a", "d,e,f", ""))

  out <- separate_rows(df, y)
  expect_equal(
    out,
    tibble(x = c(1, 2, 2, 2, 3), y = c("a", "d", "e", "f", ""))
  )
})

test_that("it validates its inputs", {
  df <- tibble(x = 1:3, y = c("a", "d,e,f", ""))

  expect_snapshot(error = TRUE, {
    separate_rows(df, x, sep = 1)
  })
  expect_snapshot(error = TRUE, {
    separate_rows(df, x, convert = 1)
  })
})
