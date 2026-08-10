# This file was generated with AI assistance using Claude Opus 4.8 on August 10,
# 2026.

# Double checks the pin contents. Lives in R/ so it is auto-loaded by the app,
# and sourced by the writer and tests. Defines only objects/functions; no side
# effects.

pin_spec <- list(
  sched                   = c("Download Cycle", "Date", "cyc"),
  state_lookup            = c("state_name", "state_abbr"),
  db_totals               = c("dl_cycle", "n_registrations", "value", "Date", "name"),
  db_state_totals         = c("dl_cycle", "dl_state", "n_registrations", "value", "Date", "cyc", "name"),
  db_state_totals_future  = c("dl_cycle", "dl_state", "n_registrations", "value", "name"),
  db_totals_last_szn      = c("dl_cycle", "Date", "value", "name"),
  big_data_by_state2      = c("dl_state", "state_name", "fl", "acceptance",
                              "acceptance_text", "participation"),
  big_data_by_state3      = c("dl_state", "state_name", "sum_db", "n"),
  state_summary_table     = c("state_name", "Upload date", "Submitted registrations",
                              "Accepted registrations (current)",
                              "Accepted registrations (future)", "Acceptance rate"),
  season_sums             = c("dl_cycle", "dl_state", "raw_n", "final_n", "retained", "fl"),
  overunder               = c("dl_state", "state_name", "overunder_pct", "emoji", "emoji_color"),
  overunder_fl            = c("fl", "overunder_pct", "emoji", "emoji_color"),
  issue_date_summary      = c("dl_state", "issue_date"),
  issue_date_summary_past = c("dl_state", "issue_date"),
  lag                     = c("dl_state", "issue_date", "lag"),
  lag_summary             = c("dl_state", "state_name", "p30_text"),
  lag_summary_fl          = c("fl", "p30_text"),
  mean_big_data_by_flyway = c("fl", "mean_participation", "mean_acceptance", "sum_total")
)

pin_scalars <- c("latest_commit_date", "todays_dl", "days_left")

# Fails loudly. Call in write_pin.R before pin_write(); assert in tests.
validate_bundle <- function(bundle, spec = pin_spec, scalars = pin_scalars) {
  missing_obj <- setdiff(c(names(spec), scalars), names(bundle))
  if (length(missing_obj))
    stop("Bundle missing objects: ", paste(missing_obj, collapse = ", "))
  
  for (nm in names(spec)) {
    gone <- setdiff(spec[[nm]], names(bundle[[nm]]))
    if (length(gone))
      stop(sprintf("`%s` missing columns: %s", nm, paste(gone, collapse = ", ")))
    if (nrow(bundle[[nm]]) == 0)
      stop(sprintf("`%s` has 0 rows -- refusing to publish an empty pin.", nm))
  }
  
  for (nm in scalars) {
    v <- bundle[[nm]]
    if (length(v) != 1 || is.na(v))
      stop(sprintf("Scalar `%s` must be length-1 non-NA (got length %d).", nm, length(v)))
  }
  invisible(TRUE)
}