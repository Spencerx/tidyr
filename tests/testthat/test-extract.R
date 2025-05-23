test_that("default returns first alpha group", {
  df <- data.frame(x = c("a.b", "a.d", "b.c"))
  out <- df %>% extract(x, "A")
  expect_equal(out$A, c("a", "a", "b"))
})

test_that("can match multiple groups", {
  df <- data.frame(x = c("a.b", "a.d", "b.c"))
  out <- df %>% extract(x, c("A", "B"), "([[:alnum:]]+)\\.([[:alnum:]]+)")
  expect_equal(out$A, c("a", "a", "b"))
  expect_equal(out$B, c("b", "d", "c"))
})

test_that("can drop groups", {
  df <- data.frame(x = c("a.b.e", "a.d.f", "b.c.g"))
  out <- df %>% extract(x, c("x", NA, "y"), "([a-z])\\.([a-z])\\.([a-z])")
  expect_named(out, c("x", "y"))
  expect_equal(out$y, c("e", "f", "g"))
})

test_that("match failures give NAs", {
  df <- data.frame(x = c("a.b", "a"))
  out <- df %>% extract(x, "a", "(b)")
  expect_equal(out$a, c("b", NA))
})

test_that("extract keeps characters as character", {
  df <- tibble(x = "X-1")
  out <- extract(df, x, c("x", "y"), "(.)-(.)", convert = TRUE)
  expect_equal(out$x, "X")
  expect_equal(out$y, 1L)
})

test_that("can combine into multiple columns", {
  df <- tibble(x = "abcd")
  out <- extract(df, x, c("a", "b", "a", "b"), "(.)(.)(.)(.)", convert = TRUE)
  expect_equal(out, tibble(a = "ac", b = "bd"))
})

test_that("groups are preserved", {
  df <- tibble(g = 1, x = "X1") %>% dplyr::group_by(g)
  rs <- df %>% extract(x, c("x", "y"), "(.)(.)")
  expect_equal(class(df), class(rs))
  expect_equal(dplyr::group_vars(df), dplyr::group_vars(rs))
})

test_that("informative error message if wrong number of groups", {
  df <- tibble(x = "a")
  expect_snapshot(error = TRUE, {
    extract(df, x, "y", ".")
  })
  expect_snapshot(error = TRUE, {
    extract(df, x, c("y", "z"), ".")
  })
})

test_that("informative error if using stringr modifier functions (#693)", {
  df <- tibble(x = "a")
  regex <- structure("a", class = "pattern")

  expect_snapshot(error = TRUE, {
    extract(df, x, "x", regex = regex)
  })
})

test_that("str_match_first handles edge cases", {
  expect_identical(
    str_match_first(c("r-2", "d-2-3-4"), "(.)-(.)"),
    list(c("r", "d"), c("2", "2"))
  )
  expect_identical(
    str_match_first(NA, "test"),
    list()
  )
  expect_equal(
    str_match_first(c("", " "), "^(.*)$"),
    list(c("", " "))
  )
  expect_equal(
    str_match_first("", "(.)-(.)"),
    list(NA_character_, NA_character_)
  )
  expect_equal(
    str_match_first(character(), "(.)-(.)"),
    list(character(), character())
  )
})

test_that("validates its inputs", {
  df <- data.frame(x = letters)

  expect_snapshot(error = TRUE, {
    df %>% extract()
  })
  expect_snapshot(error = TRUE, {
    df %>% extract(x, regex = 1)
  })
  expect_snapshot(error = TRUE, {
    df %>% extract(x, into = 1:3)
  })
  expect_snapshot(error = TRUE, {
    df %>% extract(x, into = "x", convert = 1)
  })
})
