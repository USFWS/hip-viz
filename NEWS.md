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
