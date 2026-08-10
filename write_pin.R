# about -------------------------------------------------------------------

# This file bundles data for the HIP registration dashboard
# Data are summarized and pushed as a pin to Posit Connect 

# By Abby Walter
# August 2026

# library -----------------------------------------------------------------

`%within%` <- lubridate::`%within%`

# source pin specs --------------------------------------------------------

source(here::here("R", "pin_spec.R"))

# create ------------------------------------------------------------------

# Define data path
data_path <- paste0(here::here(), "/data/2025-2026/")
data_path_past <- paste0(here::here(), "/data/2024-2025/")

# List data files
data_files <- list.files(data_path, full.names = TRUE)

# Get all sum files
sum_files <- data_files[stringr::str_detect(data_files, "sums")]

# Fail if there's no data
stopifnot("No data files found." = length(sum_files) > 0)

# Define a state name/state abbreviation lookup table
state_lookup <-
  tibble::tibble(
    state_name = state.name[state.name != "Hawaii"],
    state_abbr = state.abb[state.abb != "HI"])

# HIP download schedule/dates for 2024
sched_last_year <-
  tibble::tibble(
    Download = c(
      "0800",
      "0901",
      "0902",
      "1001",
      "1002",
      "1003",
      "1101",
      "1201",
      "1202",
      "1301",
      "1302",
      "1303",
      "1401",
      "1402",
      "1501",
      "1502"
    ), Date = c(
      "August 22, 2024",
      "September 5, 2024",
      "September 19, 2024",
      "October 3, 2024",
      "October 17, 2024",
      "October 31, 2024",
      "November 14, 2024",
      "December 2, 2024",
      "December 12, 2024",
      "January 9, 2025",
      "January 16, 2025",
      "January 23, 2025",
      "February 6, 2025",
      "February 20, 2025",
      "March 6, 2025",
      "March 20, 2025"
    ),     
    # Subtract a day because the dates above are Thursdays (sample date) and we 
    # need to plot Wednesdays (due dates)
    cyc = 
      (lubridate::mdy(Date) - lubridate::days(1)) |> 
      format("%b %d")
  )

# HIP download schedule/dates for this season
sched <-
  tibble::tribble(
    ~`Download Cycle`,                ~Date,
    "0800",    "August 13, 2025",
    "0802",    "August 27, 2025",
    "0901", "September 10, 2025",
    "0902", "September 24, 2025",
    # Furlough
    #"1001",    "October 9, 2025",
    #"1002",   "October 23, 2025",
    "1101",  "November 13, 2025",
    "1102",  "November 20, 2025",
    "1201",   "December 4, 2025",
    "1202",  "December 18, 2025",
    "1301",   "January 14, 2026",
    "1302",   "January 28, 2026",
    "1401",  "February 11, 2026",
    "1402",  "February 25, 2026",
    "1501",     "March 11, 2026",
    "1502",     "March 25, 2026"
  ) |> 
  dplyr::mutate(cyc = lubridate::mdy(Date) |> format("%b %d"))

# Last season's database totals by download
db_totals_last_szn <-
  readr::read_csv(
    data_files[stringr::str_detect(data_files, "db_tots_2024-2025")]) |> 
  dplyr::mutate(dl_cycle = as.character(DL)) |> 
  dplyr::select(-"DL") |> 
  dplyr::left_join(
    sched_last_year |> dplyr::rename(dl_cycle = Download),
    by = "dl_cycle") |> 
  dplyr::mutate(name = "Last season") |> 
  dplyr::rename(value = "cumulative_total") |> 
  dplyr::filter(!dl_cycle %in% c("1601", "1701"))

# Last season's database totals by download and state
db_st_totals_last_szn <-
  readr::read_csv(
    data_files[stringr::str_detect(data_files, "db_state_tots_2024-2025")]) |> 
  dplyr::mutate(dl_cycle = as.character(DL)) |> 
  dplyr::select(-"DL") |> 
  dplyr::left_join(
    sched_last_year |> dplyr::rename(dl_cycle = Download),
    by = "dl_cycle") |> 
  dplyr::mutate(name = "Last season") |> 
  dplyr::filter(!dl_cycle %in% c("1601", "1701"))

# Database totals by download
db_totals <-
  readr::read_csv(data_files[stringr::str_detect(data_files, "db_tots.csv")]) |> 
  dplyr::mutate(dl_cycle = as.character(DL)) |> 
  dplyr::select(-"DL") |> 
  dplyr::left_join(
    sched |> dplyr::rename(dl_cycle = `Download Cycle`),
    by = "dl_cycle") |> 
  dplyr::mutate(name = "Current season") |> 
  dplyr::rename(value = "cumulative_total")

# Database totals by download and state
db_state_totals <-
  readr::read_csv(
    data_files[stringr::str_detect(data_files, "db_state_tots.csv")]) |> 
  dplyr::left_join(
    sched |> dplyr::rename(dl_cycle = `Download Cycle`),
    by = "dl_cycle") |> 
  dplyr::mutate(
    Date = ifelse(is.na(Date), "August 1, 2025", Date),
    cyc = ifelse(is.na(cyc), "Aug 1", cyc),
  ) |> 
  dplyr::mutate(name = "Current season") |> 
  dplyr::rename(value = "cumulative_registrations")

# Database totals by download and state - NEXT SEASON
db_state_totals_future <-
  readr::read_csv(
    data_files[stringr::str_detect(data_files, "db_state_totals_future.csv")]
  ) |> 
  dplyr::mutate(dl_cycle = as.character(dl_cycle)) |> 
  dplyr::left_join(
    sched |> dplyr::rename(dl_cycle = `Download Cycle`),
    by = "dl_cycle") |> 
  dplyr::mutate(name = "Accepted 2026") |> 
  dplyr::rename(value = "cumulative_registrations")

# Registrations submitted this season
season_sums <-
  tidyr::expand_grid(
    sched |> dplyr::select(dl_cycle = `Download Cycle`),
    tibble::tibble(dl_state = migbirdHIP:::REF_ABBR_49_STATES)) |> 
  dplyr::left_join(
    purrr::map(
      seq_along(sum_files), 
      \(x) readr::read_csv(sum_files[x], col_types = "ccdddcc")) |> 
      purrr::list_rbind(),
    by = c("dl_state", "dl_cycle")) |> 
  dplyr::mutate(
    retained = round(retained, 1),
    dl_cycle = as.character(.data$dl_cycle)) |> 
  migbirdHIP:::assignFlyway("dl_state", "fl")

# Acceptance rate table
state_summary_table <-
  db_state_totals |> 
  dplyr::filter(dl_cycle != "carryover") |> 
  dplyr::select(-"value") |> 
  dplyr::rename(n_db = n_registrations) |> 
  dplyr::left_join(
    season_sums |> 
      dplyr::select(c("dl_cycle", "dl_state", "raw_n")), 
    by = c("dl_cycle", "dl_state")) |> 
  dplyr::left_join(
    db_state_totals_future |> 
      dplyr::select(
        dl_cycle, dl_state,
        n_future = n_registrations),
    by = c("dl_cycle", "dl_state")
  )  |> 
  dplyr::mutate(
    n_future = ifelse(is.na(n_future), 0, n_future)
  ) |> 
  dplyr::left_join(
    state_lookup |> 
      dplyr::rename(dl_state = "state_abbr"), 
    by = "dl_state") |> 
  dplyr::mutate(
    rate = paste0(round((n_db + n_future) / raw_n, 3) * 100, "%"),
    raw_n = format.default(.data$raw_n, big.mark = ","),
    n_db = format.default(.data$n_db, big.mark = ","),
    n_future = format.default(.data$n_future, big.mark = ",")
  ) |> 
  dplyr::select(
    state_name,
    `Upload date` = "cyc",
    `Submitted registrations` = "raw_n",
    `Accepted registrations (current)` = "n_db",
    `Accepted registrations (future)` = "n_future",
    `Acceptance rate` = "rate"
  )

# Define the most recent download
todays_dl <- dplyr::slice_tail(db_totals, n = 1)$dl_cycle

# Define the most recent git commit
latest_commit_date <- 
  tryCatch({
    resp <- httr::GET("https://api.github.com/repos/USFWS/hip-viz/commits")
    
    # Return an error if the request fails
    httr::stop_for_status(resp)
    
    commits <- jsonlite::fromJSON(rawToChar(resp$content))
    latest_commit <- commits$commit$author$date[1]
    
    as.Date(latest_commit)
  }, 
  error = 
    function(e) stop("GitHub commit lookup failed: ", conditionMessage(e))
  )

# Number of submissions
n_submissions <- 
  db_state_totals |> 
  dplyr::select(dl_cycle, dl_state) |> 
  dplyr::bind_rows(
    db_state_totals_future |> 
      dplyr::select(dl_cycle, dl_state)) |> 
  dplyr::filter(dl_cycle != "carryover") |> 
  dplyr::distinct() |> 
  dplyr::count(dl_state)

# Sum total registrations by state
big_data_by_state2 <-
  db_state_totals |> 
  dplyr::filter(dl_cycle != "carryover") |> 
  dplyr::summarize(
    sum_db = sum(n_registrations),
    .by = "dl_state") |> 
  dplyr::left_join(n_submissions, by = "dl_state") |> 
  dplyr::left_join(
    season_sums |> 
      dplyr::summarize(
        sum_raw = sum(raw_n, na.rm = T), 
        .by = c("dl_state", "fl")),
    by = "dl_state"
  ) |> 
  dplyr::relocate(sum_raw, .before = "sum_db") |> 
  dplyr::left_join(
    db_state_totals_future |> 
      dplyr::summarize(
        sum_future = sum(n_registrations),
        .by = "dl_state"
      ),
    by = "dl_state"
  ) |> 
  dplyr::relocate(sum_future, .before = "sum_db") |> 
  dplyr::mutate(
    sum_db_all = sum(sum_db, sum_future, na.rm = T),
    .by = "dl_state",
    .after = "sum_db") |> 
  dplyr::mutate(
    # Acceptance
    acceptance = 
      round((.data$sum_db_all / .data$sum_raw) * 100, 1), 
    # Submission (participation)
    participation = 
      round(.data$n/which(sched$`Download Cycle` == todays_dl) * 100, 0),
    acceptance_text = 
      ifelse(sum_db_all < sum_raw & acceptance == 100, "~ 100", acceptance)
  ) |> 
  dplyr::left_join(
    state_lookup |> 
      dplyr::rename(dl_state = "state_abbr"), 
    by = "dl_state")

# Sum total registrations by state WITH CARRYOVER IN THE SUM
big_data_by_state3 <-
  db_state_totals |> 
  dplyr::summarize(
    sum_db = sum(n_registrations),
    n = dplyr::n(),
    .by = "dl_state") |> 
  dplyr::left_join(
    state_lookup |> 
      dplyr::rename(dl_state = "state_abbr"), 
    by = "dl_state")

# Calculate registration statistics by download and flyway
mean_big_data_by_flyway <-
  big_data_by_state2 |> 
  dplyr::select(-c("sum_raw", "sum_future", "sum_db", "sum_db_all")) |> 
  # Get the sum_db from another tibble because we want to include carryover in
  # the totals
  dplyr::left_join(
    big_data_by_state3 |> 
      dplyr::select("dl_state", "sum_db"),
    by = "dl_state") |> 
  dplyr::summarize(
    sum_total = sum(sum_db, na.rm = T),
    mean_acceptance = round(mean(acceptance, na.rm = T), 1),
    mean_participation = round(mean(participation, na.rm = T), 1),
    .by = "fl"
  )

# Summary of last season's issue dates for each state
issue_date_summary_past <- 
  readr::read_csv(paste0(data_path_past, "issue_date_summary_2024.csv"))

# Current season issue dates for each download and state
issue_date_summary <- 
  readr::read_csv(paste0(data_path, "issue_date_summary.csv"))

# Calculate the lag between the download date and issue date
lag <- 
  issue_date_summary |> 
  dplyr::left_join(
    sched |> dplyr::rename(dl_cycle = `Download Cycle`),
    by = "dl_cycle") |> 
  dplyr::mutate(dl_date = lubridate::mdy(Date)) |> 
  dplyr::select(dl_state, issue_date, dl_date) |> 
  # Set all lag for first download to 0
  # dplyr::mutate(
  #   lag = 
  #     ifelse(
  #       dl_date == lubridate::mdy(sched$Date[2]), 
  #       0, 
  #       dl_date - issue_date)
  # ) |> 
  # For 2025-2026 only...
  # Set all lag for first download to 0
  # Set all lag for first AND second download after furlough to 0
  dplyr::mutate(
    lag = 
      dplyr::case_when(
        dl_date == lubridate::mdy(sched$Date[2]) ~ 0,
        dl_date %in% 
          c(lubridate::mdy(sched$Date[5]), lubridate::mdy(sched$Date[6])) &
          issue_date %within% 
          lubridate::interval(
            lubridate::mdy("9/22/2025"), lubridate::mdy("11/20/2025")) ~ 0, 
        .default = as.double(dl_date - issue_date)
      )
  ) |>
  # Don't include some wacky data
  dplyr::filter(lag > -5) |> 
  # If the issue date is the day before the download date, change the lag to 0
  dplyr::mutate(
    lag =
      dplyr::case_when(
        lag == lubridate::days(-1) ~ 0, 
        lag == lubridate::days(-2) ~ 0,
        lag == lubridate::days(-3) ~ 0,
        lag == lubridate::days(-4) ~ 0,
        TRUE ~ as.numeric(lag)))

# Summarize the lag between the download date and issue date by state
lag_summary <- 
  lag |> 
  dplyr::mutate(greater_than_30 = ifelse(lag > 30, 1, 0)) |> 
  dplyr::summarize(
    mean_lag = as.numeric(mean(lag)),
    max_lag = as.numeric(max(lag)),
    median_lag = as.numeric(median(lag)),
    prop_over_30 = sum(greater_than_30)/dplyr::n(),
    p30_text = paste0(round(prop_over_30 * 100, 1), "%"),
    .by = "dl_state"
  ) |> 
  dplyr::left_join(
    state_lookup |> 
      dplyr::rename(dl_state = "state_abbr"), 
    by = "dl_state"
  )

lag_summary_fl <- 
  lag |> 
  migbirdHIP:::assignFlyway("dl_state", "fl") |> 
  dplyr::mutate(greater_than_30 = ifelse(lag > 30, 1, 0)) |> 
  dplyr::summarize(
    mean_lag = as.numeric(mean(lag)),
    max_lag = as.numeric(max(lag)),
    median_lag = as.numeric(median(lag)),
    prop_over_30 = sum(greater_than_30)/dplyr::n(),
    p30_text = paste0(round(prop_over_30 * 100, 1), "%"),
    .by = "fl"
  ) 

# By state comparison of current season cumulative HIP total vs previous season
# cumulative HIP total
overunder <-
  # Get past season cum total as of THIS TIME LAST YEAR
  db_st_totals_last_szn |> 
  dplyr::select(dl_state, Date, past_cumulative = cumulative_registrations) |> 
  dplyr::mutate(Date = lubridate::mdy(Date)) |> 
  dplyr::filter(Date < lubridate::today() - 365) |> 
  dplyr::filter(Date == max(Date), .by = "dl_state") |> 
  # This is the cumulative sum per state as of NOW, total hip for current
  # hunting season; including carryover registrations
  dplyr::left_join(
    big_data_by_state3 |> 
      dplyr::select(-"n") |> 
      dplyr::rename(current_cumulative = sum_db), 
    by = "dl_state"
  ) |> 
  dplyr::mutate(
    overunder_pct = 
      round(
        ((current_cumulative - past_cumulative) / past_cumulative) * 100, 
        1),
    .before = "state_name"
  ) |> 
  dplyr::mutate(
    emoji = 
      ifelse(
        overunder_pct > 0,
        "caret-up",
        "caret-down"),
    emoji_color = 
      ifelse(
        overunder_pct > 0,
        "icon-positive-color",
        "icon-negative-color")
  )

# By flyway comparison of current season cumulative HIP total vs previous season
# cumulative HIP total
overunder_fl <-
  overunder |> 
  dplyr::select(dl_state, past_cumulative, current_cumulative) |> 
  migbirdHIP:::assignFlyway("dl_state", "fl") |> 
  dplyr::summarize(
    fl_past_cumulative = sum(past_cumulative),
    fl_current_cumulative = sum(current_cumulative),
    .by = "fl") |> 
  dplyr::mutate(
    overunder_pct = 
      round(
        ((fl_current_cumulative - fl_past_cumulative) / fl_past_cumulative) * 100, 
        1),
    emoji = 
      ifelse(
        overunder_pct > 0,
        "caret-up",
        "caret-down"),
    emoji_color = 
      ifelse(
        overunder_pct > 0,
        "icon-positive-color",
        "icon-negative-color")
  )

# Calculate how many days are left in the season
days_left_actual <- lubridate::mdy("03/11/2026") - lubridate::today()
days_left <- ifelse(days_left_actual < 0, 0, days_left_actual)

# pin ---------------------------------------------------------------------

# Bundle all used data objects into one named list
bundle <- list(
  latest_commit_date = latest_commit_date,
  todays_dl = todays_dl,
  days_left = days_left,
  sched = sched,
  state_lookup = state_lookup,
  db_totals = db_totals,
  db_state_totals = db_state_totals,
  db_state_totals_future = db_state_totals_future,
  db_totals_last_szn = db_totals_last_szn,
  big_data_by_state2 = big_data_by_state2,
  big_data_by_state3 = big_data_by_state3,
  state_summary_table = state_summary_table,
  season_sums = season_sums,
  overunder = overunder,
  overunder_fl = overunder_fl,
  issue_date_summary = issue_date_summary,
  issue_date_summary_past = issue_date_summary_past,
  lag = lag,
  lag_summary = lag_summary,
  lag_summary_fl = lag_summary_fl,
  mean_big_data_by_flyway = mean_big_data_by_flyway
)

# Uses CONNECT_SERVER + CONNECT_API_KEY from .Renviron
board <- pins::board_connect()   

# Double check
validate_bundle(bundle)

board |>
  pins::pin_write(
    bundle,
    name = "hip-viz-data_2025",
    type = "rds",
    versioned = TRUE
  )
