# This file was generated with AI assistance using Claude Opus 4.8 on August 10,
# 2026.

source(paste0(here::here(), "/R/magic_number.R"))

testthat::test_that("sub-1000 values return a character string", {
  testthat::expect_type(magic_number(500), "character")
  testthat::expect_equal(magic_number(500), "500")
})

testthat::test_that("zero is not an error", {
  testthat::expect_equal(magic_number(0), "0")
})

testthat::test_that("NA input returns error", {
  testthat::expect_error(magic_number(NA_real_))
})

testthat::test_that("thousands and millions format consistently as character", {
  testthat::expect_type(magic_number(1500), "character")
  testthat::expect_type(magic_number(1500000), "character")
})