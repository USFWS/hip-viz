# Harvest Information Program registration dashboard

# libraries ---------------------------------------------------------------

library(markdown)

# setup -------------------------------------------------------------------

# Define data path
data_path <- paste0(here::here(), "/data/2025-2026/")

# List data files
data_files <- list.files(data_path, full.names = TRUE)

# Get all sum files
sum_files <- data_files[stringr::str_detect(data_files, "sums")]

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
    `Cycle date` = "cyc",
    `Submitted registrations` = "raw_n",
    `Accepted registrations (current)` = "n_db",
    `Accepted registrations (future)` = "n_future",
    `Acceptance rate` = "rate"
  )

# Sketch an HTML table format
sketch <- 
  htmltools::withTags(
    table(
      class = 'display',
      thead(
        tr(
          th(rowspan = 2, 'Cycle date'),
          th(rowspan = 2, 'Submitted'),
          th(class = 'dt-center', colspan = 2, 'Accepted'),
          th(rowspan = 2, 'Acceptance rate')
        ),
        tr(
          lapply(c('Current season', 'Next season'), th)
        )
      )
    ))

# Define the most recent download
todays_dl <- dplyr::slice_tail(db_totals, n = 1)$dl_cycle

# Define the most recent git commit
resp <- httr::GET("https://api.github.com/repos/USFWS/hip-viz/commits")
commits <- jsonlite::fromJSON(rawToChar(resp$content))
latest_commit <- commits$commit$author$date[1]
latest_commit_date <- as.Date(latest_commit)

# Sum total registrations by state
big_data_by_state2 <-
  db_state_totals |> 
  dplyr::filter(dl_cycle != "carryover") |> 
  dplyr::summarize(
    sum_db = sum(n_registrations),
    n = dplyr::n(),
    .by = "dl_state") |> 
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
    acceptance = 
      round((.data$sum_db_all / .data$sum_raw) * 100, 1), 
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

# Select all of the issue dates for each download and state
issue_date_summary <- 
  readr::read_csv(paste0(data_path, "issue_date_summary.csv"))

# Calculate the lag between the download date and issue date
lag <- 
  issue_date_summary |> 
  dplyr::left_join(
    sched |> dplyr::rename(dl_cycle = `Download Cycle`),
    by = "dl_cycle") |> 
  dplyr::mutate(
    dl_date = lubridate::mdy(Date)
  ) |> 
  dplyr::select(dl_state, issue_date, dl_date) |> 
  dplyr::mutate(
    lag = dl_date - issue_date) |> 
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
  
# Set colors for figures 
colors <-
  c(ggthemes::colorblind_pal()(7)[6], #"#0072B2", blue
    ggthemes::colorblind_pal()(7)[3], #"#56B4E9", light blue
    ggthemes::colorblind_pal()(7)[4], #"#009E73", green
    ggthemes::colorblind_pal()(7)[5], #"#F0E442", yellow
    ggthemes::colorblind_pal()(7)[2], #"#E69F00", orange
    ggthemes::colorblind_pal()(8)[8], #"#CC79A7", pink
    ggthemes::colorblind_pal()(7)[7]  #"#D55E00", red
  )

# Create a link to the github repository
link_github <- 
  tags$a(shiny::icon("github"), 
         "", 
         href = "https://github.com/USFWS/hip-viz/", 
         target = "_blank")

# Create a function to magically format numbers
magic_number <-
  function(x) {
    
    a_thousand <- 1000
    ten_thousand <- 10000
    thousands <- 999999
    a_million <- 1000000
    a_billion <- 1000000000
    
    if (x > thousands & x < a_billion) {
      # Millions labeler
      scales::label_number(
        accuracy = 0.01, 
        scale_cut = scales::cut_short_scale())(x)
    } else if (x >= 999500 & x < a_million) {
      "999K"
    } else if (x >= ten_thousand & x < a_million) {
      # Thousands labeler
      scales::label_number(
        accuracy = 1, 
        scale_cut = scales::cut_short_scale())(x)
    } else if (x >= a_thousand & x < ten_thousand) {
      scales::label_number(
        accuracy = 0.1, 
        scale_cut = scales::cut_short_scale())(x)
    } else if (x > 0 & x < a_thousand) {
      x
    } else {
      "ERROR"
    }
  }

# Test magic_number() function
# purrr::map(
#   c(1, 10, 100, 999, 1000, 1200, 1900, 9900, 9999,
#     10000, 10100, 15321, 43256, 99999, 100000, 
#     101000, 145234, 456789, 499999, 500000, 501000,
#     678923, 789456, 899000, 989000, 999000, 999499,
#     999500, 999999, 1000000, 1000100, 1010000,
#     1234567, 1567890, 1700300, 9234100, 9999999,
#     10000000, 15000000, 99123456),
#   \(x) magic_number(x)
# )

# ui ----------------------------------------------------------------------

# Define UI for application that draws a histogram
ui <- 
  bslib::page_navbar(
    fillable = TRUE,
    fillable_mobile = TRUE,
    theme = 
      bslib::bs_theme(version = 5, preset = "flatly") |> 
        bslib::bs_add_rules(sass::sass_file("style.scss")),
    navbar_options = bslib::navbar_options(underline = TRUE),
    title = tags$span(
      tags$img(
        src = "fws.svg", 
        style = "height: 40px;", 
        class = "me-2 align-middle"),
      tags$span(
        class = "align-middle", 
        "Harvest Information Program Registrations 2025–2026")
    ),
    bslib::nav_panel(
      title = "HIP", 
      bslib::layout_column_wrap(
        style = bslib::css(grid_template_columns = "1fr 4fr"),
        bslib::layout_column_wrap(
          width = 1,
          fill = FALSE,
          bslib::card(
            bslib::card_header("View"),
            bslib::card_body(
              class = "special_nav",
              shiny::radioButtons(
                "panel_selection",
                label = NULL,
                choices = c("Total", "State", "Flyway"),
                selected = "Total"),
              shiny::uiOutput("dynamic_dropdown")
            )
          )
          ,
          div(
            paste0(
              "Last updated: ",
              lubridate::month(latest_commit_date, label = TRUE), " ", 
              lubridate::day(latest_commit_date), ", ", 
              lubridate::year(latest_commit_date)),
            style = "position: absolute; bottom: 15px;"
            )
          ),
        # Use as_fill_carrier to magically make all of the panels expand to fit
        # a large browser window; did not find another way to achieve this
        bslib::as_fill_carrier(
          shiny::uiOutput("dynamic_panel")
          )
      )
      ),
    bslib::nav_panel(
      title = "About",
      fillable = TRUE,
      fillable_mobile = TRUE,
      bslib::layout_column_wrap(
        bslib::card(
          bslib::card_header("About"),
          bslib::card_body(
            class = "special_nav",
            shiny::includeMarkdown("about.md")
          )
        ),
        bslib::card(
          bslib::card_header("Contact"),
          bslib::card_body(
            class = "special_nav",
            shiny::includeMarkdown("contact.md")
            )
        )
        )
      ),
    bslib::nav_spacer(),
    bslib::nav_item(link_github)
    )

# server ------------------------------------------------------------------

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  output$dynamic_panel <- renderUI({
    if (input$panel_selection == "Total") {
      
      # Totals UI
      
      bslib::page_fillable(
        fillable_mobile = TRUE,
        bslib::layout_columns(
          bslib::value_box(
            title = "Days left",
            showcase = bsicons::bs_icon("clock-history"),
            theme = "fws-tan",
            value = days_left
          ),
          bslib::value_box(
            title = "Current cycle",
            showcase = bsicons::bs_icon("calendar-week"),
            theme = "fws-yel",
            value = sched$cyc[sched$`Download Cycle` == as.character(todays_dl)]
          ),
          bslib::value_box(
            title = "Registrations added",
            showcase = bsicons::bs_icon("person-plus"),
            theme = "fws-ora",
            value = 
              format.default(
                dplyr::slice_tail(db_totals, n = 1)$n_registrations, 
                big.mark = ",")
          ),
          bslib::value_box(
            title = "Total registrations",
            showcase = bsicons::bs_icon("database-add"),
            theme = "fws-blu",
            value = 
              format.default(
                dplyr::slice_tail(db_totals, n = 1)$value, 
                big.mark = ",")
          )
        ),
        bslib::card(
          bslib::card_header("Cumulative HIP Registrations 2025-2026"),
          bslib::card_body(plotly::plotlyOutput("cumulative_plot"))
        )
      )
    } else if (input$panel_selection == "State") {

      # State UI
      bslib::page_fillable(
        fillable_mobile = TRUE,
        bslib::layout_column_wrap(
          style = bslib::css(grid_template_columns = "3fr 1fr"),
          bslib::navset_card_tab(
            title = input$stateChosen,
            bslib::nav_panel(
              "Submission",
              plotly::plotlyOutput("state_plot")
              ),
            bslib::nav_panel(
              "Acceptance",
              DT::dataTableOutput("file_table"),
              p(".", class = "spacer")
            ),
            bslib::nav_panel(
              "Tardiness",
              plotly::plotlyOutput("lag_plot")
            ),
            ),
          bslib::layout_column_wrap(
            width = 1,
            heights_equal = "row",
            bslib::value_box(
              title = 
                shiny::span(
                  "Total registrations",
                  bslib::tooltip(
                    bsicons::bs_icon("info-circle"),
                    "Total registrations accepted for the current season. Year-over-year comparison to last season is in parentheses."
                  )
                ),
              showcase = bsicons::bs_icon("person-plus"),
              value = 
                shiny::p(
                  format.default(
                    big_data_by_state3$sum_db[big_data_by_state3$state_name == input$stateChosen],
                    big.mark = ","),
                  " (",
                  shiny::uiOutput("st_icon", inline = TRUE),
                  " ",
                  paste0(
                    overunder$overunder_pct[overunder$state_name == input$stateChosen],
                    "%"),
                  ")")
            ),
            bslib::value_box(
              title = 
                shiny::span(
                  "Acceptance rate",
                  bslib::tooltip(
                    bsicons::bs_icon("info-circle"),
                    "Proportion of registrations accepted."
                    )
                ),
              showcase = bsicons::bs_icon("clipboard-check"),
              value = 
                paste0(big_data_by_state2$acceptance_text[big_data_by_state2$state_name == input$stateChosen],
                       "%")
            ),
            bslib::value_box(
              title = 
                shiny::span(
                  "Submission rate",
                  bslib::tooltip(
                    bsicons::bs_icon("info-circle"),
                    "Proportion of download cycle deadlines met."
                  )
                ),
              showcase = bsicons::bs_icon("download"),
              value = 
                paste0(big_data_by_state2$participation[big_data_by_state2$state_name == input$stateChosen],
                       "%")
            ),
            bslib::value_box(
              title = 
                shiny::span(
                  "Tardiness rate",
                  bslib::tooltip(
                    bsicons::bs_icon("info-circle"),
                    "Proportion of registrations issued more than 30 days before we received them."
                  )
                ),
              showcase = bsicons::bs_icon("hourglass-split"),
              value = 
                lag_summary$p30_text[lag_summary$state_name == input$stateChosen]
            )
          )
        )
      )
    } else if (input$panel_selection == "Flyway") {
      
      # Flyway UI
      bslib::page_fillable(
        fillable_mobile = TRUE,
        bslib::layout_column_wrap(
          style = bslib::css(grid_template_columns = "3fr 1fr"),
          bslib::card(
            bslib::card_header(input$flyw),
            bslib::card_body(plotly::plotlyOutput("fly_web"))
          ),
          bslib::layout_column_wrap(
            width = 1,
            heights_equal = "row",
            bslib::value_box(
              title = 
                shiny::span(
                  "Total registrations",
                  bslib::tooltip(
                    bsicons::bs_icon("info-circle"),
                    "Total registrations accepted for the current season. Year-over-year comparison to last season is in parentheses."
                  )
                ),
              showcase = bsicons::bs_icon("person-plus"),
              value = 
                shiny::p(
                  shiny::uiOutput("fl_total", inline = TRUE),
                  " (",
                  shiny::uiOutput("fl_icon", inline = TRUE),
                  " ",
                  paste0(
                    overunder_fl$overunder_pct[overunder_fl$fl == input$flyw],
                    "%"),
                  ")"
                )
            ),
            bslib::value_box(
              title = 
                shiny::span(
                  "Acceptance rate",
                  bslib::tooltip(
                    bsicons::bs_icon("info-circle"),
                    "Average proportion of registrations accepted."
                  )
                ),
              showcase = bsicons::bs_icon("clipboard-check"),
              value = 
                paste0(
                  mean_big_data_by_flyway$mean_acceptance[mean_big_data_by_flyway$fl == input$flyw], 
                  "%")
            ),
            bslib::value_box(
              title = 
                shiny::span(
                  "Submission rate",
                  bslib::tooltip(
                    bsicons::bs_icon("info-circle"),
                    "Average proportion of download cycle deadlines met."
                  )
                ),
              showcase = bsicons::bs_icon("download"),
              value = 
                paste0(
                  mean_big_data_by_flyway$mean_participation[mean_big_data_by_flyway$fl == input$flyw], 
                  "%")
            ),
            bslib::value_box(
              title = 
                shiny::span(
                  "Tardiness rate",
                  bslib::tooltip(
                    bsicons::bs_icon("info-circle"),
                    "Proportion of registrations issued more than 30 days before we received them."
                  )
                ),
              showcase = bsicons::bs_icon("hourglass-split"),
              value = 
                lag_summary_fl$p30_text[lag_summary_fl$fl == input$flyw]
            )
          )
        )
      )
      
    } 
  })
  
  output$dynamic_dropdown <- shiny::renderUI({
    if (input$panel_selection == "Flyway") {
      
      shiny::selectInput(
        "flyw",
        "Select a flyway:",
        c("Atlantic Flyway", 
          "Mississippi Flyway", 
          "Central Flyway", 
          "Pacific Flyway"),
        selected = "Atlantic Flyway")
      
    } else if (input$panel_selection == "State") {
      
      shiny::selectInput(
        "stateChosen",
        "Select a state:",
        state.name[state.name != "Hawaii"],
        selected = sample(state.name[state.name != "Hawaii"], 1)
      )
    }
  })
  
  output$st_icon <- shiny::renderUI({
    # Check if input$stateChosen is available and not empty
    req(input$stateChosen) 
    
    shiny::icon(
      name = overunder$emoji[overunder$state_name == input$stateChosen],
      class = overunder$emoji_color[overunder$state_name == input$stateChosen])
  })
  
  output$fl_icon <- shiny::renderUI({
    # Check if input$flyw is available and not empty
    req(input$flyw) 
    
    shiny::icon(
      name = overunder_fl$emoji[overunder_fl$fl == input$flyw],
      class = overunder_fl$emoji_color[overunder_fl$fl == input$flyw])
  })
  
  output$fl_total <- shiny::renderUI({
    # Check if input$flyw is available and not empty
    req(input$flyw) 
    
    magic_number(mean_big_data_by_flyway$sum_total[mean_big_data_by_flyway$fl == input$flyw])
  })
  
  output$file_table <- DT::renderDataTable(
    DT::datatable(
      state_summary_table |> 
        dplyr::filter(state_name == input$stateChosen) |> 
        dplyr::select(-"state_name"), 
      container = sketch, 
      fillContainer = TRUE,
      rownames = FALSE,
      extensions = 'Buttons',
      style = "bootstrap",
      options =
        list(
          dom = "tBr",
          ordering = FALSE,
          columnDefs = 
            list(
              list(className = 'dt-body-right', targets = c(1, 2, 3, 4))
            ),
          buttons =
            list(
              list(
                text = "<i class='fa fa-download'></i> CSV",
                extend = "csv", 
                filename = paste0(input$stateChosen, "_HIP summary 2025-2026"), 
                titleAttr = "Download as CSV"
              ),
              list(
                extend = "excel", 
                filename = paste0(input$stateChosen, "_HIP summary 2025-2026"), 
                titleAttr = "Download as Excel"
              ),
              list(
                extend = "pdf", 
                filename = paste0(input$stateChosen, "_HIP summary 2025-2026"), 
                titleAttr = "Download as PDF"
              )
            )
          )
      )
  )
  
  dataByFlyway <- shiny::reactive({
    
    season_sums |> 
      dplyr::select(c("dl_cycle", "dl_state", "final_n", "fl")) |> 
      dplyr::filter(fl == input$flyw) |> 
      dplyr::left_join(
        sched |> 
          dplyr::rename(dl_cycle = `Download Cycle`),
        by = "dl_cycle") |> 
      dplyr::mutate(
        fct_dl_cycle = 
          factor(
            dl_cycle,
            levels = sched$`Download Cycle`),
        current = 
          ifelse(
            as.integer(.data$fct_dl_cycle) <= 
              as.integer(factor(todays_dl, levels = sched$`Download Cycle`)),
            "current",
            "future")) 
    
      })
  
  dataByState <- 
    shiny::reactive({
      
      # Get the state abbreviation for the chosen state name input
      stateChosen_abbr <- 
        state_lookup$state_abbr[state_lookup$state_name == input$stateChosen]
      
      db_state_totals |> 
        dplyr::select(
          dl_cycle,
          dl_state,
          db_registrations = n_registrations) |> 
        dplyr::full_join(
          season_sums |> 
            dplyr::select(-c("retained", "fl")) |> 
            dplyr::filter(!is.na(raw_n)),
          by = c("dl_cycle", "dl_state")
        ) |> 
        dplyr::left_join(
          sched |> dplyr::rename(dl_cycle = `Download Cycle`),
          by = "dl_cycle") |> 
        dplyr::mutate(
          Date = ifelse(is.na(Date), "August 1, 2025", Date),
          cyc = ifelse(is.na(cyc), "Aug 1", cyc),
        ) |> 
        dplyr::arrange(lubridate::mdy(Date)) |> 
        dplyr::full_join(
          tidyr::expand_grid(
            sched, 
            dl_state = migbirdHIP:::REF_ABBR_49_STATES) |> 
            dplyr::rename(dl_cycle = `Download Cycle`)
          ) |> 
        dplyr::mutate(
          db_registrations = 
            ifelse(is.na(db_registrations), 0, db_registrations),
          raw_n = ifelse(is.na(raw_n), 0, raw_n),
          final_n = ifelse(is.na(final_n), 0, final_n)
        ) |> 
        dplyr::filter(dl_state == stateChosen_abbr) |> 
        tidyr::pivot_longer(cols = c("db_registrations", "raw_n")) |> 
        dplyr::mutate(
          name = 
            dplyr::case_when(
              dl_cycle == "carryover" & name == "db_registrations" ~ 
                "Carryover",
              dl_cycle != "carryover" & name == "db_registrations" ~ 
                "Accepted 2025",
              name == "raw_n" ~ "Submitted",
              TRUE ~ NA_character_
            ),
          name = 
            factor(
              name, 
              levels = 
                c("Submitted", 
                  "Accepted 2025", 
                  "Carryover"))
        ) |> 
        dplyr::filter(!(dl_cycle == "carryover" & name == "Submitted")) |> 
        dplyr::bind_rows(
          db_state_totals_future |> 
            dplyr::filter(dl_state == stateChosen_abbr) |> 
            dplyr::rename(
              final_n = value,
              value = n_registrations
            ) |> 
            dplyr::mutate(issue_date = NA, .after = "final_n") |> 
            dplyr::relocate(value, .after = "name") |> 
            dplyr::mutate(
              name = 
                factor(
                  name, 
                  levels = 
                    c("Submitted", 
                      "Accepted 2025", 
                      "Accepted 2026",
                      "Carryover"))
            )
        )
      
    })
  
  output$cumulative_plot <- plotly::renderPlotly({
    
    cumulative_plot <- 
      ggplot2::ggplot() +
      ggplot2::geom_line(
        data = db_totals_last_szn,
        ggplot2::aes(
          x = lubridate::mdy(.data$Date) + lubridate::days(365), 
          y = .data$value, 
          group = .data$name, 
          color = .data$name,
          text = paste0("<b>Category: </b> Last season <br>",
                        "<b>Cycle date:</b> ", .data$Date, "<br>",
                        "<b>Cumulative registrations:</b> ", 
                        format.default(.data$value, big.mark = ",")
          )),
        linetype = "dotted",
        linewidth = 2) +
      ggplot2::geom_line(
        data = db_totals,
        ggplot2::aes(
          x = lubridate::mdy(.data$Date), 
          y = .data$value, 
          group = .data$name, 
          color = .data$name,
          text = paste0("<b>Category: </b> Current season <br>",
                        "<b>Cycle date:</b> ", .data$Date, "<br>",
                        "<b>Cumulative registrations:</b> ", 
                        format.default(.data$value, big.mark = ",")
                        
          )),
        linewidth = 2,
        alpha = 0.8) +
      ggplot2::labs(
        x = "Cycle date", 
        y = "Number of registrations",
        color = "",
        linewidth = "") +
      ggplot2::scale_y_continuous(label = scales::comma) +
      ggplot2::scale_x_date(
        breaks = lubridate::mdy(sched$Date),
        labels = sched$cyc) +
      ggplot2::scale_color_manual(
        values = c("Last season" = "darkgray",
                   "Current season" = colors[1])) +
      ggplot2::theme_bw() +
      ggplot2::theme(
        axis.text.x = 
          ggplot2::element_text(angle = 45, vjust = 1, hjust = 1))
    
    plotly::ggplotly(cumulative_plot, tooltip = "text")
  })
  
  output$fly_web <- plotly::renderPlotly({
    
    web_data <-
      big_data_by_state2 |> 
      dplyr::filter(fl == input$flyw) |> 
      dplyr::select(dl_state, acceptance, participation) |> 
      dplyr::left_join(
        state_lookup |> 
          dplyr::rename(dl_state = state_abbr),
        by = "dl_state"
      )
    
    fig <- 
      plotly::plot_ly(
        type = "scatterpolar",
        fill = "toself",
        mode = "markers"
      ) 
    
    fig <- fig |>
      plotly::add_trace(
        mode = "markers+lines",
        r = c(web_data$acceptance, web_data$acceptance[1]),
        theta = c(web_data$dl_state, web_data$dl_state[1]),
        customdata = c(web_data$state_name, web_data$state_name[1]), 
        name = "Acceptance rate",
        fillcolor = "rgba(0, 122, 195, 0.2)",
        marker = list(color = "rgba(0, 122, 195, 0.7)"),
        line = list(color = "rgba(0, 122, 195, 0.7)"),
        hovertemplate = paste0("<b>State:</b> %{customdata}<br>",
                               "<b>Acceptance rate</b>: %{r}<br>",
                               "<extra></extra>")
      ) 
    
    fig <- fig |>
      plotly::add_trace(
        mode = "markers+lines",
        r = c(web_data$participation, web_data$participation[1]),
        theta =  c(web_data$dl_state, web_data$dl_state[1]),
        customdata = c(web_data$state_name, web_data$state_name[1]), 
        name = "Submission rate",
        fillcolor = "rgba(242, 176, 40, 0.4)",
        marker = list(color = "rgba(242, 176, 40, 0.9)"),
        line = list(color = "rgba(242, 176, 40, 0.9)"),
        hovertemplate = paste0("<b>State:</b> %{customdata}<br>",
                               "<b>Submission rate</b>: %{r}<br>",
                               "<extra></extra>")
      ) 
    
    fig <- 
      fig |>
      plotly::layout(
        polar = list(
          radialaxis = list(
            visible = T,
            range = c(0, 100),
            ticksuffix = "%",
            tickangle = 0,
            tickfont = list(size = 10),
            tickvals = c(0, 25, 50, 75, 100)
          )
        )
      )
    
    fig 
  })
  
  
  output$lag_plot <- plotly::renderPlotly({
    
    stateChosen_abbr <- 
      state_lookup$state_abbr[state_lookup$state_name == input$stateChosen]
    
    p <- 
      lag |> 
      dplyr::filter(dl_state == stateChosen_abbr) |> 
      dplyr::count(dl_state, issue_date, lag) |> 
      dplyr::mutate(
        value_color = 
          ifelse(
            lag > 30, 
            "Tardy (> 30 days to receipt)", 
            "On time (30 days or less)")) |> 
      ggplot2::ggplot() +
      ggplot2::geom_point(
        ggplot2::aes(x = issue_date,
            y = n, 
            color = value_color,
            shape = value_color,
            text = 
              paste0("<b>Data:</b> ", 
                     stringr::str_extract(.data$value_color, "^.+(?=\\()"), 
                     "<br>",
                     "<b>Issue date:</b> ", .data$issue_date, "<br>",
                     "<b>Number of registrations:</b> ", .data$n)
              )) +
      ggplot2::labs(
        x = "Issue date", 
        y = "Number of registrations",
        color = "",
        shape = "") +
      ggplot2::theme_bw() + 
      ggplot2::scale_color_manual(
        values = c(`On time (30 days or less)` = "black", 
                   `Tardy (> 30 days to receipt)` = colors[7])) + 
      ggplot2::scale_shape_manual(
        values = c(`On time (30 days or less)` = 16, 
                   `Tardy (> 30 days to receipt)` = 17))
    
    pplot <- plotly::ggplotly(p, tooltip = "text")
    
    pplot |> 
      plotly::layout(
        legend = list(orientation = "h", xanchor = "center", x = 0.5, y = -0.5)) 
  })
  
  output$state_plot <- plotly::renderPlotly({
    
    state_plot <- 
      dataByState() |> 
      ggplot2::ggplot() +
      ggplot2::geom_bar(
        ggplot2::aes(
          x = lubridate::mdy(.data$Date), 
          y = .data$value,  
          fill = .data$name,
          text = paste0("<b>Category: </b> ", .data$name, "<br>",
                        "<b>Cycle date:</b> ", .data$Date, "<br>",
                        "<b>Registrations:</b> ", 
                        format.default(.data$value, big.mark = ","))
          ),
        stat = "identity",
        position = ggplot2::position_dodge2(preserve = "single"),
        width = 6
      ) +
      ggplot2::labs(
        x = "Cycle date", 
        y = "Number of registrations",
        fill = "") +
      ggplot2::scale_y_continuous(label = scales::comma) +
      ggplot2::scale_x_date(
        breaks = 
          c(lubridate::mdy("August 1, 2025"), lubridate::mdy(sched$Date)),
        labels = c("Carryover", sched$cyc)) +
      ggplot2::theme_bw() +
      ggplot2::theme(
        axis.text.x = 
          ggplot2::element_text(angle = 45, vjust = 1, hjust = 1)) + 
      ggplot2::scale_fill_manual(
        labels = c("Submitted", 
                   "Accepted 2025", 
                   "Accepted 2026", 
                   "Carryover"),
        values = c(colors[1], colors[2], colors[3], colors[5]))
    
    p_state <- plotly::ggplotly(state_plot, tooltip = "text")

    p_state |> 
      plotly::layout(
        legend = list(orientation = "h", xanchor = "center", x = 0.5, y = -0.5)) 
  })
}

# run ---------------------------------------------------------------------

# Run the application 
shiny::shinyApp(ui = ui, server = server)
