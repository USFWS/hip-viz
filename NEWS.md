# hip-viz (dev)

## General updates and improvements
- Use `today()` for the last data update date.
- Move days left in season countdown calculation to `app.R` so that it changes every day, not just when the pin is updated.
- Delete days left from `pin_spec.R`.
- Add late submitted registrations to the "last season" State overview plot data.
- Exclude MO lifetime licenses from State overview plot data.
- Replaced the USGS default favicon with USFWS logo.

## Mobile layout improvements
- Title and subtitle font smaller.
- Reposition "last updated" date reliably on desktop and mobile.
- Shift KPI boxes into a 2x2 grid.
- About page text surrounded by card box, scrolls with screen.
- Adjusted state view tabs so they don't wrap.
- No horizontal scroll on state acceptance table.
- Reactively move the legend on the cumulative totals plot so that it isn't vertically squished on desktop or horizontally squished on mobile.
- Reactively move the legend on the flyway plot so that it doesn't render too small; adjusted to be centered.

## Minor changes
- Fixed typo in `shiny::modalDialog` from `easy_close` to `easyClose`.
- Fixed typo in legend definitions ("possess").
- Commented out `dataByFlyway()` since it isn't used.
- Added `req()` tags to reactive chunks.
- Changed "Totals" tab y-axis labels to `3M` format instead of `3,000,000`.
- Fixed typo in `state_overview_plot`... changed "upload date" to "issue date".
- Fixed typos in `scale_y_continuous()` functions from `label` to `labels`.

# hip-viz 2026.0.1

- Fix the brief error/warning red text when switching to the State page; introduced by conditionally excluding YoY percent in KPI box, which was introduced in `v2026.0.0`.
- Fix the YoY percent calculation on the flyway page (was summarizing as `NA`). This bug was also introduced in `v2026.0.0` by excluding states who haven't submitted HIP data yet.

# hip-viz 2026.0.0

- Release for beginning of 2026-2027, including first 3 data cycles.

# hip-viz 2025.1.0

## Minor updates

- Add unit tests.
- Add github actions.

# hip-viz 2025.0.0

## Major updates

- Pin data to Posit Connect using R `{pins}` package.
- Switch from `bslib::page_navbar()` to `bslib::page_fillable()`, moving the `About` page link to the left menu and combining the `about.md` and `contact.md` contents into one markdown file.
- Create state `Overview` tab with line plot of registrations by issue date, showing data for current season and last season.
- Added a modal dialog window to the state `Submission` tab to define legend categories in more detail.

## Minor updates

- Use `migbirdHIP:::assignFlyway()` for flyway assignments.
- Use `{httr}` and `{jsonlite}` to get the most recent commit from the `hip-viz` repo to return "last updated" date to users, rather that previous method which is uninformative on live release (`lubridate::now()`).
- Data are not tardy unless received after the first download date.
- Edit About page text and link URLs.
- Move `magic_number()` helper function to its own script file.
- Increase size of title and FWS logo, add subtitle.
- Reduce padding on state navigation tabs, and push them to the right side to accommodate a new overview tab.
- Label clarity
    - Replace `Cycle Date` labels with `Upload Date`
    - `Current cycle` KPI box label switched to `Latest upload`
    - `Registrations added` KPI box label switched to `New registrations`
- Added description to flyway radar chart.
- Registrations issued during furlough and received in subsequent two upload cycles are not considered tardy.

# hip-viz 0.1.0

Launched with 2025-2026 Harvest Information Program registration summary data.
