# This file was generated with AI assistance using Claude Opus 4.8 on August 10,
# 2026.

# Runs against the live pin. Needs CONNECT_SERVER + CONNECT_API_KEY.

source(paste0(here::here(), "/pin-spec.R"))

testthat::test_that("published pin satisfies the app contract", {
  skip_if(Sys.getenv("CONNECT_API_KEY") == "", "no Connect credentials")
  board <- pins::board_connect()
  bundle <- pins::pin_read(board, "abby_walter@fws.gov/hip-viz-data_2025")
  testthat::expect_true(validate_bundle(bundle))
})

testthat::test_that("published pin is fresh during the active season", {
  testthat::skip_if(Sys.getenv("CONNECT_API_KEY") == "", "no Connect credentials")
  today <- Sys.Date()
  md <- format(today, "%m-%d")
  in_season <- md >= "08-20" || md <= "03-15"
  testthat::skip_if_not(in_season, "off-season: pin intentionally not updating")
  
  board <- pins::board_connect()
  meta <- pins::pin_meta(board, "abby_walter@fws.gov/hip-viz-data_2025")
  testthat::expect_gt(as.Date(meta$created), today - 21)
})
