#' Export data to CSV
#'
#' Thin wrapper around \code{readr::write_csv()} that messages the path
#' written to, for use as a visible pipeline step.
#'
#' @param data Data frame to write.
#' @param path Character. File path to write the CSV to.
#'
#' @return The path written to, invisibly.
#'
#' @importFrom readr write_csv
#'
#' @export
export_csv <- function(data, path) {
  readr::write_csv(data, path)
  message("Wrote CSV to: ", path)
  invisible(path)
}

#' Export data to XLSX
#'
#' Thin wrapper around \code{openxlsx::write.xlsx()} that messages the path
#' written to, for use as a visible pipeline step.
#'
#' @param data Data frame to write.
#' @param path Character. File path to write the XLSX to.
#' @param sheet_name Character. Name of the worksheet. Defaults to "data".
#'
#' @return The path written to, invisibly.
#'
#' @importFrom openxlsx write.xlsx
#'
#' @export
export_xlsx <- function(data, path, sheet_name = "data") {
  openxlsx::write.xlsx(data, path, sheetName = sheet_name)
  message("Wrote XLSX to: ", path)
  invisible(path)
}

#' Export a gt table as PDF
#'
#' Renders \code{data} as a \code{gt} table and saves it as a PDF.
#'
#' @details
#' PDF export is facilitated by the \code{webshot2} package, which drives a
#' real, installed Chrome/Chromium browser headlessly via \code{chromote} to
#' rasterize the HTML table. This means it will \strong{not} work in an
#' environment without a Chrome/Chromium binary available (e.g. a bare
#' GitHub Actions runner) unless that environment installs one first (e.g.
#' via \code{browser-actions/setup-chrome} or similar in CI, or
#' \code{chromote::find_chrome()} locally to confirm one is discoverable).
#' Later stages that automate this (e.g. stage (j), GitHub Actions) will
#' need to add a Chrome-install step to their workflow.
#'
#' @param data Data frame to render as a table.
#' @param path Character. File path to write the PDF to (must end in
#'   \code{.pdf}; \code{gt::gtsave()} infers the output format from this
#'   extension).
#' @param title Character. Optional table title. Defaults to \code{NULL}
#'   (no title).
#'
#' @return The path written to, invisibly.
#'
#' @importFrom gt gt tab_header gtsave
#'
#' @export
export_gt_pdf <- function(data, path, title = NULL) {
  if (!requireNamespace("webshot2", quietly = TRUE)) {
    stop(
      "Package 'webshot2' is required to export gt tables as PDF.\n",
      "Install it with: install.packages('webshot2')\n",
      "You'll also need a Chrome/Chromium browser installed -- see ",
      "?webshot2::install_chromote or run chromote::find_chrome().",
      call. = FALSE
    )
  }

  tbl <- gt::gt(data)
  if (!is.null(title)) {
    tbl <- gt::tab_header(tbl, title = title)
  }

  gt::gtsave(tbl, filename = path)
  message("Wrote gt PDF table to: ", path)
  invisible(path)
}
