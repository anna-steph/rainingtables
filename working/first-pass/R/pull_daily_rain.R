#' Pull daily rain
#'
#' Pull daily precipitation data from the NOAA CDO Web Services API, either
#' for a zip code (using NOAA's own zip-to-station aggregation) or for one
#' or more specific stations (e.g. the output of \code{find_nearby_stations()}).
#'
#' Dependencies: httr, dplyr
#'
#' Request a NOAA CDO Web Services token here:
#' https://www.ncdc.noaa.gov/cdo-web/token
#'
#' NOAA's API documentation can be found here:
#' https://www.ncdc.noaa.gov/cdo-web/webservices/v2
#'
#' You can search NOAA's data resources using their Climate Data Online Search here:
#' https://www.ncei.noaa.gov/cdo-web/search
#'
#' A good explainer of how to search NOAA weather data:
#' https://www.youtube.com/watch?v=YY8JYbEO3Ow
#'
#' @param api_key Character. Your NOAA CDO API token.
#' @param zipcode Character. 5-digit US zip code (keep as character to
#'   preserve leading zeros, e.g. "02138"). Ignored if \code{stationid} is
#'   supplied.
#' @param stationid Character vector, optional. One or more NOAA station IDs
#'   (e.g. "GHCND:US1WAKG0072"), such as the \code{id} column returned by
#'   \code{find_nearby_stations()}. When supplied, data is pulled for these
#'   specific stations instead of the zip code's default station pool.
#' @param date_start Character. Start date, format "YYYY-MM-DD".
#' @param date_end Character. End date, format "YYYY-MM-DD". NOAA CDO API
#'   requires date ranges of one year or less per request for GHCND.
#' @param units Character. "standard" or "metric". Defaults to "standard".
#' @param limit Integer. Max records per request (NOAA's ceiling is 1000).
#'   Defaults to 1000.
#'
#' @return A data frame of daily precipitation (PRCP) records, or an empty
#'   data frame with a warning if no data is returned.
#'
#' @importFrom httr RETRY add_headers stop_for_status content timeout
#' @importFrom dplyr bind_rows
#'
#' @export
pull_daily_rain <- function(
    api_key,
    zipcode = NULL,
    stationid = NULL,
    date_start,
    date_end,
    units = "standard",
    limit = 1000,
    timeout_sec = 10,
    retry_times = 3
) {
    if (is.null(zipcode) && is.null(stationid)) {
        stop("Supply either zipcode or stationid.")
    }

    if (!is.null(stationid)) {
        # one or more stations: repeat stationid= for each, per NOAA's API
        location_params <- paste0("&stationid=", stationid, collapse = "")
    } else {
        zipcode <- as.character(zipcode) # guard against leading-zero loss
        location_params <- paste0("&locationid=ZIP:", zipcode)
    }

    url_string <- paste0(
        "https://www.ncei.noaa.gov/cdo-web/api/v2/data?",
        "datasetid=GHCND",
        "&datatypeid=PRCP",
        location_params,
        "&startdate=",
        date_start,
        "&enddate=",
        date_end,
        "&units=",
        units,
        "&limit=",
        limit
    )

    response <- tryCatch(
        httr::RETRY(
            verb = "GET",
            url = url_string,
            httr::add_headers(token = api_key),
            httr::timeout(timeout_sec),
            times = retry_times,
            pause_base = 1,
            pause_cap = 10,
            quiet = TRUE
        ),
        error = function(e) {
            stop(
                "Failed to reach NOAA CDO API after ",
                retry_times,
                " attempts -- ",
                "check your internet connection or try increasing timeout_sec. ",
                "Original error: ",
                conditionMessage(e),
                call. = FALSE
            )
        }
    )

    httr::stop_for_status(response, task = "pull data from NOAA CDO API")

    parsed <- httr::content(response, as = "parsed", type = "application/json")

    if (length(parsed$results) == 0) {
        warning("No precipitation data returned for this request.")
        return(data.frame())
    }

    dplyr::bind_rows(lapply(parsed$results, as.data.frame))
}
