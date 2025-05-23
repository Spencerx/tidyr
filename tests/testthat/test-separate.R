test_that("missing values in input are missing in output", {
  df <- tibble(x = c(NA, "a b"))
  out <- separate(df, x, c("x", "y"))
  expect_equal(out$x, c(NA, "a"))
  expect_equal(out$y, c(NA, "b"))
})

test_that("positive integer values specific position between characters", {
  df <- tibble(x = c(NA, "ab", "cd"))
  out <- separate(df, x, c("x", "y"), 1)
  expect_equal(out$x, c(NA, "a", "c"))
  expect_equal(out$y, c(NA, "b", "d"))
})

test_that("negative integer values specific position between characters", {
  df <- tibble(x = c(NA, "ab", "cd"))
  out <- separate(df, x, c("x", "y"), -1)
  expect_equal(out$x, c(NA, "a", "c"))
  expect_equal(out$y, c(NA, "b", "d"))
})

test_that("extreme integer values handled sensibly", {
  df <- tibble(x = c(NA, "a", "bc", "def"))

  out <- separate(df, x, c("x", "y"), 3)
  expect_equal(out$x, c(NA, "a", "bc", "def"))
  expect_equal(out$y, c(NA, "", "", ""))

  out <- separate(df, x, c("x", "y"), -3)
  expect_equal(out$x, c(NA, "", "", ""))
  expect_equal(out$y, c(NA, "a", "bc", "def"))
})

test_that("convert produces integers etc", {
  df <- tibble(x = "1-1.5-FALSE")
  out <- separate(df, x, c("x", "y", "z"), "-", convert = TRUE)
  expect_equal(out$x, 1L)
  expect_equal(out$y, 1.5)
  expect_equal(out$z, FALSE)
})

test_that("convert keeps characters as character", {
  df <- tibble(x = "X-1")
  out <- separate(df, x, c("x", "y"), "-", convert = TRUE)
  expect_equal(out$x, "X")
  expect_equal(out$y, 1L)
})

test_that("too many pieces dealt with as requested", {
  df <- tibble(x = c("a b", "a b c"))

  expect_snapshot(separate(df, x, c("x", "y")))

  merge <- separate(df, x, c("x", "y"), extra = "merge")
  expect_equal(merge[[1]], c("a", "a"))
  expect_equal(merge[[2]], c("b", "b c"))

  drop <- separate(df, x, c("x", "y"), extra = "drop")
  expect_equal(drop[[1]], c("a", "a"))
  expect_equal(drop[[2]], c("b", "b"))

  expect_snapshot(separate(df, x, c("x", "y"), extra = "error"))
})

test_that("too few pieces dealt with as requested", {
  df <- tibble(x = c("a b", "a b c"))

  expect_snapshot(separate(df, x, c("x", "y", "z")))

  left <- separate(df, x, c("x", "y", "z"), fill = "left")
  expect_equal(left$x, c(NA, "a"))
  expect_equal(left$y, c("a", "b"))
  expect_equal(left$z, c("b", "c"))

  right <- separate(df, x, c("x", "y", "z"), fill = "right")
  expect_equal(right$z, c(NA, "c"))
})

test_that("preserves grouping", {
  df <- tibble(g = 1, x = "a:b") %>% dplyr::group_by(g)
  rs <- df %>% separate(x, c("a", "b"))
  expect_equal(class(df), class(rs))
  expect_equal(dplyr::group_vars(df), dplyr::group_vars(rs))
})

test_that("drops grouping when needed", {
  df <- tibble(x = "a:b") %>% dplyr::group_by(x)
  rs <- df %>% separate(x, c("a", "b"))
  expect_equal(rs$a, "a")
  expect_equal(dplyr::group_vars(rs), character())
})

test_that("overwrites existing columns", {
  df <- tibble(x = "a:b")
  rs <- df %>% separate(x, c("x", "y"))

  expect_named(rs, c("x", "y"))
  expect_equal(rs$x, "a")
})

test_that("drops NA columns", {
  df <- tibble(x = c(NA, "ab", "cd"))
  out <- separate(df, x, c(NA, "y"), 1)
  expect_equal(names(out), "y")
  expect_equal(out$y, c(NA, "b", "d"))
})

test_that("validates inputs", {
  df <- tibble(x = "a:b")

  expect_snapshot(error = TRUE, {
    separate(df)
  })
  expect_snapshot(error = TRUE, {
    separate(df, x, into = 1)
  })
  expect_snapshot(error = TRUE, {
    separate(df, x, into = "x", sep = c("a", "b"))
  })
  expect_snapshot(error = TRUE, {
    separate(df, x, into = "x", remove = 1)
  })
  expect_snapshot(error = TRUE, {
    separate(df, x, into = "x", convert = 1)
  })
})

test_that("informative error if using stringr modifier functions (#693)", {
  df <- tibble(x = "a")
  sep <- structure("a", class = "pattern")

  expect_snapshot(separate(df, x, "x", sep = sep), error = TRUE)
})

# helpers -----------------------------------------------------------------

test_that("str_split_n can cap number of splits", {
  expect_equal(str_split_n(c("x,x"), ",", 1), list("x,x"))
  expect_equal(str_split_n(c("x,x"), ",", 2), list(c("x", "x")))
  expect_equal(str_split_n(c("x,x"), ",", 3), list(c("x", "x")))
})

test_that("str_split_n handles edge cases", {
  expect_equal(str_split_n(character(), ",", 1), list())
  expect_equal(str_split_n(NA, ",", 1), list(NA_character_))
})

test_that("str_split_n handles factors", {
  expect_equal(str_split_n(factor(), ",", 1), list())
  expect_equal(str_split_n(factor("x,x"), ",", 2), list(c("x", "x")))
})

test_that("list_indices truncates long warnings", {
  expect_equal(list_indices(letters, max = 3), "a, b, c, ...")
})
