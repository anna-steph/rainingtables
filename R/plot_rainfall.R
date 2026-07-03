#' Plot rainfall
#'
#' Dependencies:  ggplot2
#'
#' Plot precipitation data pulled from the NOAA API
plot_rainfall <- function(data) {
  ggplot(data, aes(x = as.Date(date), y = value, fill = station)) +
    geom_col() +
    facet_wrap(~station, ncol = 1) +
    scale_x_date(date_breaks = "1 month", date_labels = "%b") +
    theme_bw() +
    theme(legend.position = "bottom") +
    labs(title = "Daily Precipitation", x = "Date", y = "Precipitation")
}
