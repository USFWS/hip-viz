# Create a function to put a progress bar in the state and flyway value boxes

progress_bar <- 
  function(prop, last_season) {
    if (length(prop) == 0 || is.na(prop)) prop <- 0
    if (length(last_season) == 0 || is.na(last_season)) last_season <- "0"
    pct <- round(prop * 100)
    fill <- min(pct, 100)
    over <- pct > 100
    
    htmltools::div(
      style = htmltools::css(width = "100%"),
      title = paste0(last_season, " registrations last season"),
      htmltools::div(
        style = htmltools::css(
          display = "flex",
          `justify-content` = "space-between",
          `align-items` = "baseline",
          `margin-bottom` = "0.15rem"
        ),
        htmltools::span(paste0(pct, "%")),
        htmltools::span(
          paste0("of ", last_season, " "),
          style = htmltools::css(`font-size` = "0.5em", color = "#6c757d")
        )
      ),
      htmltools::div(
        style = htmltools::css(
          width = "100%",
          height = "0.5rem",
          `background-color` = "#e9ecef",
          `border-radius` = "0.25rem",
          overflow = "hidden"
        ),
        htmltools::div(
          style = htmltools::css(
            width = paste0(fill, "%"),
            height = "100%",
            `background-color` = if (over) "#009E73" else "#007AC3"
          )
        )
      )
    )
  }
