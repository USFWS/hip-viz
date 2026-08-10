# Harvest Information Program registration dashboard
# libraries ---------------------------------------------------------------

library(markdown)

# source data -------------------------------------------------------------

# Get pinned data
board  <- pins::board_connect()
bundle <- board |> pins::pin_read("abby_walter@fws.gov/hip-viz-data_2025")
list2env(bundle, envir = environment())

# Sketch an HTML table format
sketch <- 
  htmltools::withTags(
    table(
      class = 'display',
      thead(
        tr(
          th(rowspan = 2, 'Upload date'),
          th(rowspan = 2, 'Submitted'),
          th(class = 'dt-center', colspan = 2, 'Accepted'),
          th(rowspan = 2, 'Acceptance rate')
        ),
        tr(
          lapply(c('Current season', 'Next season'), th)
        )
      )
    ))

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

# ui ----------------------------------------------------------------------

# Define UI
ui <- 
  bslib::page_fillable(
    # Browser window title
    title = "USFWS Harvest Information Program Dashboard",
    fillable_mobile = TRUE,
    # Theme
    theme = 
      bslib::bs_theme(version = 5, preset = "flatly") |> 
        bslib::bs_add_rules(sass::sass_file("style.scss")),
    # Header
    div(
      class = "app-header d-flex align-items-center p-2 border-bottom",
      img(src = "fws.svg", style = "height: 80px;", class = "me-3"),
      div(
        div(
          class = "d-flex flex-column",
          div(class = "app_title", "Harvest Information Program Registrations 2025–2026"),
          div(class = "app_subtitle", "U.S. Fish & Wildlife Service • Migratory Bird Program")
        )
      )
         
    ),
    # Body
    bslib::layout_column_wrap(
      style = bslib::css(grid_template_columns = "1fr 4fr"),
      # Menu
      bslib::layout_column_wrap(
        width = 1,
        fill = FALSE,
        bslib::card(
          bslib::card_header("View"),
          bslib::card_body(
            class = "special_nav",
            radioButtons(
              "panel_selection", NULL,
              choices = c("About", "Total", "State", "Flyway"),
              selected = "Total"
            ),
            uiOutput("dynamic_dropdown")
          )
        ),
        # Last updated
        div(
          paste0(
            "Last updated: ",
            lubridate::month(latest_commit_date, label = TRUE), " ",
            lubridate::day(latest_commit_date), ", ",
            lubridate::year(latest_commit_date)
          ),
          style = "position: absolute; bottom: 15px;"
        )
      ),
      # Main panel
      uiOutput("dynamic_panel")
    )
  )

# server ------------------------------------------------------------------

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  shiny::observe({ 
    shiny::showModal( 
      shiny::modalDialog( 
        title = "Legend definitions", 
        easy_close = TRUE, 
        size = "l",
        div(
          style = "max-height: 400px; overflow-y: auto; padding-right: 10px;",
          p(strong("Submitted"),  "- Number of registrations uploaded."),
          p(strong("Accepted 2025"), 
            "- Registrations accepted and sample eligible for the current",
            "2025-2026 hunting season. The number of registrations accepted",
            "may be less than the number of registrations submitted, because",
            "registrations are dropped if they are missing hunter contact",
            "information, have bad bag values, or posess other major errors."),
          p(strong("Accepted 2026"), 
            "- Registrations accepted for the upcoming 2026-2027 hunting",
            "season. These registrations will be sample eligible next season."),
          p(strong("Carryover"), 
            "- Registrations accepted the previous season for the current",
            "season; e.g., the", em("Accepted 2026"), "registrations will show",
            "as ", em("Carryover"), "in the 2026-2027 season. This category",
            "only applies to states with overlapping issue start and end dates."
            )
          )
      ) 
    ) 
  }) |> 
    shiny::bindEvent(input$show) 
  
  output$dynamic_panel <- renderUI({
    if (input$panel_selection == "About") {
      bslib::page_fillable(
        fillable_mobile = TRUE,
        bslib::card(
          bslib::card_header("About"),
          bslib::card_body(
            class = "special_nav",
            shiny::includeMarkdown("about.md")),
          height = "100%"
        )
      )
      
    } else if (input$panel_selection == "Total") {
      
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
            title = "Latest upload",
            showcase = bsicons::bs_icon("calendar-week"),
            theme = "fws-yel",
            value = sched$cyc[sched$`Download Cycle` == as.character(todays_dl)]
          ),
          bslib::value_box(
            title = "New registrations",
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
          bslib::card_body(plotly::plotlyOutput("cumulative_plot")),
          height = "100%"
        )
      )
    } else if (input$panel_selection == "State") {

      # State UI
      bslib::page_fillable(
        fillable_mobile = TRUE,
        bslib::layout_column_wrap(
          height = "100%",
          style = bslib::css(grid_template_columns = "3fr 1fr"),
          bslib::navset_card_tab(
            title = input$stateChosen,
            bslib::nav_spacer(),
            bslib::nav_panel(
              "Overview",
              plotly::plotlyOutput("state_overview_plot")
            ),
            bslib::nav_panel(
              "Submission",
              plotly::plotlyOutput("state_plot"),
              shiny::actionButton(
                "show", 
                label = "Legend definitions",
                icon = bsicons::bs_icon("info-circle"),
                width = "33%"),
              class = "submission_tab"
              ),
            bslib::nav_panel(
              "Acceptance",
              DT::dataTableOutput("file_table"),
              p(".", class = "spacer")
            ),
            bslib::nav_panel(
              "Tardiness",
              plotly::plotlyOutput("lag_plot")
            )
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
                  "Submission rate",
                  bslib::tooltip(
                    bsicons::bs_icon("info-circle"),
                    htmltools::HTML(
                    "Proportion of data upload deadlines met.<br><br>For states with seasons that end before March, it may not be possible for this number to reach 100%."
                    )
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
          height = "100%",
          style = bslib::css(grid_template_columns = "3fr 1fr"),
          bslib::card(
            bslib::card_header(input$flyw),
            bslib::card_body(
              class = "special_nav",
              p(
                paste("The radar chart below displays performance metrics for",
                      "every state in the flyway.",# Every state is a spoke.",
                      "The closer the blue area (acceptance rate) and orange",
                      "area (submission rate) are to the outside edge, the",
                      "better. Hover over points for details.", 
                      sep = " "),
                class = "text_description"),
              plotly::plotlyOutput("fly_web"))
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
                  "Submission rate",
                  bslib::tooltip(
                    bsicons::bs_icon("info-circle"),
                    htmltools::HTML(
                      "Average proportion of data upload deadlines met.<br><br>For flyways with seasons that end before March, it may not be possible for this number to reach 100%."
                    )
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
          paging = FALSE,
          ordering = FALSE,
          columnDefs = 
            list(
              list(className = 'dt-head-right', targets = c(1, 2, 3, 4)),
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
  
  dataByStateIssuance <- 
    shiny::reactive({
      
      # Get the state abbreviation for the chosen state name input
      stateChosen_abbr <- 
        state_lookup$state_abbr[state_lookup$state_name == input$stateChosen]
      
      # Issue dates (with gaps)
      raw_dates <- 
        issue_date_summary |> 
        dplyr::filter(dl_state == stateChosen_abbr) |> 
        dplyr::count(issue_date) |> 
        dplyr::mutate(name = "Current season")
      
      # All issue dates
      dplyr::tibble(
        issue_date = 
          seq(min(raw_dates$issue_date),
              max(raw_dates$issue_date), 
              by = "days")) |> 
        dplyr::left_join(raw_dates, by = "issue_date") |> 
        dplyr::mutate(
          n = tidyr::replace_na(n, 0),
          name = tidyr::replace_na(name, "Current season")
        )
      
    })
  
  dataByStateIssuancePast <- 
    shiny::reactive({
      
      # Get the state abbreviation for the chosen state name input
      stateChosen_abbr <- 
        state_lookup$state_abbr[state_lookup$state_name == input$stateChosen]
      
      # Find the earliest issue date allowed and use it to filter the data to
      # reduce x-axis stretching
      min_issue <-
        migbirdHIP:::REF_DATES |>
        dplyr::filter(state == stateChosen_abbr) |> 
        dplyr::pull(issue_start)
      
      issue_date_summary_past |> 
        dplyr::filter(dl_state == stateChosen_abbr) |> 
        dplyr::filter(issue_date >= min_issue - lubridate::days(365)*2) |> 
        dplyr::mutate(name = "Last season")
      
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
                        "<b>Upload date:</b> ", .data$Date, "<br>",
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
                        "<b>Upload date:</b> ", .data$Date, "<br>",
                        "<b>Cumulative registrations:</b> ", 
                        format.default(.data$value, big.mark = ",")
                        
          )),
        linewidth = 2,
        alpha = 0.8) +
      ggplot2::labs(
        x = "Upload date", 
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
  
  output$state_overview_plot <- plotly::renderPlotly({
    
    state_overview_plot <- 
      ggplot2::ggplot() +
      ggplot2::geom_line(
        data = dataByStateIssuancePast(),
        ggplot2::aes(
          x = .data$issue_date + lubridate::days(365),
          y = .data$n,
          color = .data$name,
          group = .data$name,
          text = paste0("<b>Category:</b> ", .data$name, "<br>",
                        "<b>Upload date:</b> ", 
                        format(.data$issue_date, "%B %d, %Y"), "<br>",
                        "<b>Registrations issued:</b> ",
                        format.default(.data$n, big.mark = ",")
          )
        )) +
      ggplot2::geom_line(
        data = dataByStateIssuance(),
        ggplot2::aes(
          x = .data$issue_date, 
          y = .data$n, 
          color = .data$name,
          group = .data$name,
          text = paste0("<b>Category:</b> ", .data$name, "<br>",
                        "<b>Upload date:</b> ", 
                        format(.data$issue_date, "%B %d, %Y"), "<br>",
                        "<b>Registrations issued:</b> ",
                        format.default(.data$n, big.mark = ",")
          )
        )) +
      ggplot2::labs(
        x = "Issue date", 
        y = "Number of registrations",
        color = "",
        linewidth = "") +
      ggplot2::scale_y_continuous(label = scales::comma) +
      ggplot2::scale_x_date(date_breaks = "2 months", date_labels = "%b") +
      ggplot2::scale_color_manual(
        values = c("Last season" = "#F2B028",
                   "Current season" = colors[1])) +
      ggplot2::theme_bw() +
      ggplot2::theme(
        axis.text.x = 
          ggplot2::element_text(angle = 45, vjust = 1, hjust = 1))
    
    o_state <- plotly::ggplotly(state_overview_plot, tooltip = "text")
  
    o_state |> 
      plotly::layout(
        legend = list(orientation = "h", xanchor = "center", x = 0.5, y = -0.5)) 
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
                        "<b>Upload date:</b> ", .data$Date, "<br>",
                        "<b>Registrations:</b> ", 
                        format.default(.data$value, big.mark = ","))
          ),
        stat = "identity",
        position = ggplot2::position_dodge2(preserve = "single"),
        width = 6
      ) +
      ggplot2::labs(
        x = "Upload date", 
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
