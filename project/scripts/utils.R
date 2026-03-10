# Utility helpers for reproducible academic data pipelines.

suppressPackageStartupMessages({
  library(fs)
  library(readr)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(lubridate)
  library(janitor)
  library(purrr)
  library(ggplot2)
  library(scales)
  library(jsonlite)
  library(httr2)
  library(rbcb)
  library(sidrar)
})

log_info <- function(message) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), message))
}

safe_run <- function(step_name, fn) {
  log_info(sprintf("Starting step: %s", step_name))
  result <- tryCatch(
    fn(),
    error = function(err) {
      log_info(sprintf("ERROR in %s: %s", step_name, err$message))
      stop(err)
    }
  )
  log_info(sprintf("Completed step: %s", step_name))
  result
}

ensure_directories <- function(base_dir = "project") {
  dirs <- c(
    path(base_dir, "data", "raw"),
    path(base_dir, "data", "interim"),
    path(base_dir, "data", "manual"),
    path(base_dir, "data", "processed"),
    path(base_dir, "scripts"),
    path(base_dir, "figures"),
    path(base_dir, "tables"),
    path(base_dir, "logs")
  )
  walk(dirs, dir_create)
}

clean_numeric <- function(x) {
  if (is.numeric(x)) return(x)
  x %>%
    str_replace_all("\\.", "") %>%
    str_replace_all(",", ".") %>%
    parse_number(locale = locale(decimal_mark = "."))
}

save_dual_plot <- function(plot_obj, output_stub, width = 9, height = 5, dpi = 300) {
  png_file <- paste0(output_stub, ".png")
  pdf_file <- paste0(output_stub, ".pdf")

  ggsave(filename = png_file, plot = plot_obj, width = width, height = height, dpi = dpi)
  ggsave(filename = pdf_file, plot = plot_obj, width = width, height = height, device = cairo_pdf)

  invisible(list(png = png_file, pdf = pdf_file))
}

read_csv_safe <- function(path_file, ...) {
  if (!file_exists(path_file)) {
    stop(sprintf("File not found: %s", path_file))
  }
  readr::read_csv(path_file, show_col_types = FALSE, ...)
}

`%||%` <- function(x, y) if (is.null(x) || length(x) == 0 || is.na(x)) y else x
