# hip-viz (dev)

## Major updates

- Switch from `bslib::page_navbar()` to `bslib::page_fillable()`, moving the `About` page link to the left menu and combining the `about.md` and `contact.md` contents into one markdown file.
- Create state `Overview` tab with line plot of registrations by issue date, showing data for current season and last season.

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

# hip-viz 0.1.0

Launched with 2025-2026 Harvest Information Program registration summary data.
