#' Fill in missing values with previous or next value
#'
#' Fills missing values in selected columns using the next or previous entry.
#' This is useful in the common output format where values are not repeated,
#' and are only recorded when they change.
#'
#' Missing values are replaced in atomic vectors; `NULL`s are replaced in lists.
#'
#' @section Grouped data frames:
#' With grouped data frames created by [dplyr::group_by()], `fill()` will be
#' applied _within_ each group, meaning that it won't fill across group
#' boundaries. This can also be accomplished using the `.by` argument to
#' `fill()`, which creates a temporary grouping for just this operation.
#'
#' @inheritParams dplyr::mutate
#'
#' @param data A data frame.
#' @param ... <[`tidy-select`][tidyr_tidy_select]> Columns to fill.
#' @param .direction Direction in which to fill missing values. Currently
#'   either "down" (the default), "up", "downup" (i.e. first down and then up)
#'   or "updown" (first up and then down).
#'
#' @export
#' @examples
#' # direction = "down" --------------------------------------------------------
#' # Value (year) is recorded only when it changes
#' sales <- tibble::tribble(
#'   ~quarter, ~year, ~sales,
#'   "Q1",    2000,    66013,
#'   "Q2",      NA,    69182,
#'   "Q3",      NA,    53175,
#'   "Q4",      NA,    21001,
#'   "Q1",    2001,    46036,
#'   "Q2",      NA,    58842,
#'   "Q3",      NA,    44568,
#'   "Q4",      NA,    50197,
#'   "Q1",    2002,    39113,
#'   "Q2",      NA,    41668,
#'   "Q3",      NA,    30144,
#'   "Q4",      NA,    52897,
#'   "Q1",    2004,    32129,
#'   "Q2",      NA,    67686,
#'   "Q3",      NA,    31768,
#'   "Q4",      NA,    49094
#' )
#' # `fill()` defaults to replacing missing data from top to bottom
#' sales %>% fill(year)
#'
#' # direction = "up" ----------------------------------------------------------
#' # Value (pet_type) is missing above
#' tidy_pets <- tibble::tribble(
#'   ~rank, ~pet_type, ~breed,
#'   1L,        NA,    "Boston Terrier",
#'   2L,        NA,    "Retrievers (Labrador)",
#'   3L,        NA,    "Retrievers (Golden)",
#'   4L,        NA,    "French Bulldogs",
#'   5L,        NA,    "Bulldogs",
#'   6L,     "Dog",    "Beagles",
#'   1L,        NA,    "Persian",
#'   2L,        NA,    "Maine Coon",
#'   3L,        NA,    "Ragdoll",
#'   4L,        NA,    "Exotic",
#'   5L,        NA,    "Siamese",
#'   6L,     "Cat",    "American Short"
#' )
#'
#' # For values that are missing above you can use `.direction = "up"`
#' tidy_pets %>%
#'   fill(pet_type, .direction = "up")
#'
#' # direction = "downup" ------------------------------------------------------
#' # Value (n_squirrels) is missing above and below within a group
#' squirrels <- tibble::tribble(
#'   ~group,    ~name,     ~role,     ~n_squirrels,
#'   1,      "Sam",    "Observer",   NA,
#'   1,     "Mara", "Scorekeeper",    8,
#'   1,    "Jesse",    "Observer",   NA,
#'   1,      "Tom",    "Observer",   NA,
#'   2,     "Mike",    "Observer",   NA,
#'   2,  "Rachael",    "Observer",   NA,
#'   2,  "Sydekea", "Scorekeeper",   14,
#'   2, "Gabriela",    "Observer",   NA,
#'   3,  "Derrick",    "Observer",   NA,
#'   3,     "Kara", "Scorekeeper",    9,
#'   3,    "Emily",    "Observer",   NA,
#'   3, "Danielle",    "Observer",   NA
#' )
#'
#' # The values are inconsistently missing by position within the `group`.
#' # Use `.direction = "downup"` to fill missing values in both directions
#' # and `.by = group` to apply the fill per group.
#' squirrels %>%
#'   fill(n_squirrels, .direction = "downup", .by = group)
#'
#' # If you want, you can also supply a data frame grouped with `group_by()`,
#' # but don't forget to `ungroup()`!
#' squirrels %>%
#'   dplyr::group_by(group) %>%
#'   fill(n_squirrels, .direction = "downup") %>%
#'   dplyr::ungroup()
fill <- function(
  data,
  ...,
  .by = NULL,
  .direction = c("down", "up", "downup", "updown")
) {
  check_dots_unnamed()
  UseMethod("fill")
}

#' @export
fill.data.frame <- function(
  data,
  ...,
  .by = NULL,
  .direction = c("down", "up", "downup", "updown")
) {
  vars <- names(tidyselect::eval_select(
    expr = expr(c(...)),
    data = data,
    allow_rename = FALSE
  ))

  .direction <- arg_match0(
    arg = .direction,
    values = c("down", "up", "downup", "updown"),
  )

  fn <- function(col) {
    vec_fill_missing(col, direction = .direction)
  }

  dplyr::mutate(
    data,
    dplyr::across(any_of(vars), .fns = fn),
    .by = {{ .by }}
  )
}
