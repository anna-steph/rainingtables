#' Get zip centroids
#'
#' Look up ZCTA (zip code) centroid coordinates
#'
#' Reads the U.S. Census Bureau's Gazetteer file for ZIP Code Tabulation
#' Areas (ZCTAs) and returns a lookup table of zip codes with their centroid
#' latitude/longitude. This is a static file lookup, not a live geocoding API
#' call -- read it once per session and reuse the result, rather than calling
#' this function repeatedly.
#'
#' Download the ZCTA Gazetteer file here (choose the most recent year):
#' https://www.census.gov/geographies/reference-files/time-series/geo/gazetteer-files.html
#'
#' @param gaz_path Character. File path to a downloaded ZCTA Gazetteer file
#'   (tab-delimited .txt), e.g. "2024_Gaz_zcta_national.txt".
#'
#' @return A data frame with columns `zipcode` (character), `lat` (numeric),
#'   and `lon` (numeric).
#'
#' @importFrom readr read_delim cols col_character
#' @importFrom dplyr select
#'
#' @export
get_zip_centroids <- function(gaz_path) {
  readr::read_delim(
    gaz_path,
    delim = "|",
    col_types = readr::cols(GEOID = readr::col_character())
  ) |>
    dplyr::select(zipcode = GEOID, lat = INTPTLAT, lon = INTPTLONG)
}

#' Find nearby stations
#'
#' Find nearby NOAA weather stations for a zip code, sorted by data coverage
#'
#' Looks up the centroid coordinates for a given zip code (via a pre-loaded
#' Gazetteer table from \code{get_zip_centroids()}) and queries the NOAA CDO
#' API for weather stations within a bounding box around that point. Results
#' are sorted with the most data-complete stations first, since a nearby
#' station with sparse historical coverage (e.g. an inconsistently-reporting
#' volunteer station) may be less useful than a slightly farther one with a
#' more complete record.
#'
#' Request a NOAA CDO Web Services token here:
#' https://www.ncdc.noaa.gov/cdo-web/token
#'
#' NOAA's API documentation can be found here:
#' https://www.ncdc.noaa.gov/cdo-web/webservices/v2
#'
#' @param zipcode Character. 5-digit US zip code (keep as character to
#'   preserve leading zeros).
#' @param zip_centroids Data frame. Output of \code{get_zip_centroids()}.
#' @param api_key Character. Your NOAA CDO API token.
#' @param radius_deg Numeric. Search radius in decimal degrees of
#'   latitude/longitude (NOT miles). 1 degree of latitude is a consistent
#'   ~69 miles everywhere, but 1 degree of longitude shrinks as you move away
#'   from the equator (e.g. ~47 miles at 47 degrees N), so the resulting
#'   bounding box is a rectangle, not a true-mile circle. Defaults to 0.5
#'   (~35 miles north-south).
#' @param datasetid Character. NOAA dataset to filter stations by.
#'   Defaults to "GHCND" (Daily Summaries).
#' @param retry_times Integer. Number of retry attempts for the API request.
#'   Defaults to 3.
#'
#' @return A data frame of nearby stations, sorted by \code{datacoverage}
#'   (descending), with columns including station id, name, coordinates,
#'   and data coverage fraction (0-1).
#'
#' @importFrom httr RETRY add_headers stop_for_status content
#'
#' @export
find_nearby_stations <- function(
  zipcode,
  zip_centroids,
  api_key,
  radius_deg = 0.2,
  datasetid = "GHCND",
  retry_times = 3
) {
  zipcode <- as.character(zipcode) # guard against leading-zero loss

  centroid <- zip_centroids[zip_centroids$zipcode == zipcode, ]
  if (nrow(centroid) == 0) {
    stop("Zip code '", zipcode, "' not found in gazetteer file.")
  }

  extent <- paste(
    centroid$lat - radius_deg,
    centroid$lon - radius_deg,
    centroid$lat + radius_deg,
    centroid$lon + radius_deg,
    sep = ","
  )

  response <- tryCatch(
    httr::RETRY(
      verb = "GET",
      url = paste0(
        "https://www.ncei.noaa.gov/cdo-web/api/v2/stations?",
        "extent=",
        extent,
        "&datasetid=",
        datasetid,
        "&sortfield=datacoverage",
        "&sortorder=desc"
      ),
      httr::add_headers(token = api_key),
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
        "check your internet connection. Original error: ",
        conditionMessage(e),
        call. = FALSE
      )
    }
  )

  httr::stop_for_status(response, task = "find nearby NOAA stations")

  parsed <- httr::content(response, as = "parsed", type = "application/json")

  if (length(parsed$results) == 0) {
    warning(
      "No stations found within ",
      radius_deg,
      " degrees of zip code '",
      zipcode,
      "'."
    )
    return(data.frame())
  }

  stations <- dplyr::bind_rows(lapply(parsed$results, as.data.frame))
  stations[order(-stations$datacoverage), ] # safety-net sort, in case the API's own sort is ever ignored
}
