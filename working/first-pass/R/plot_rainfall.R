#' Plot rainfall
#'
#' Plot daily precipitation as a bar chart, faceted by station.
#'
#' Expects the caller to have already cleaned column names to lowercase
#' snake_case (e.g. via \code{janitor::clean_names()}) and to have a
#' \code{prcp} column (rename from whatever the source uses, e.g. NOAA's
#' \code{PRCP}) -- this function does no cleaning itself.
#'
#' @param data Data frame with columns \code{date} (Date or
#'   date-coercible), \code{prcp} (numeric, precipitation), and
#'   \code{station} (character, station id or name).
#'
#' @return A ggplot object.
#'
#' @importFrom ggplot2 ggplot aes geom_col facet_wrap scale_x_date theme_bw theme labs
#'
#' @export
plot_rainfall <- function(data) {
  ggplot2::ggplot(
    data,
    ggplot2::aes(x = as.Date(date), y = prcp, fill = station)
  ) +
    ggplot2::geom_col() +
    ggplot2::facet_wrap(~station, ncol = 1) +
    ggplot2::scale_x_date(date_breaks = "1 month", date_labels = "%b") +
    ggplot2::theme_bw() +
    ggplot2::theme(legend.position = "bottom") +
    ggplot2::labs(title = "Daily Precipitation", x = "Date", y = "Precipitation")
}
