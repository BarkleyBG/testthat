#' @include reporter.R
NULL

#' Test reporter: Teamcity format.
#'
#' This reporter will output results in the Teamcity message format.
#' For more information about Teamcity messages, see
#' http://confluence.jetbrains.com/display/TCD7/Build+Script+Interaction+with+TeamCity
#'
#' @export
#' @export TeamcityReporter
#' @aliases TeamcityReporter
#' @keywords debugging
#' @param ... Arguments used to initialise class
TeamcityReporter <- setRefClass("TeamcityReporter", contains = "Reporter",
  fields = list(
    "i" = "integer"
  ),

  methods = list(

    start_context = function(context) {
      teamcity("testSuiteStarted", context)
    },
    end_context = function(context) {
      teamcity("testSuiteFinished", context)
      cat("\n\n")
    },

    start_test = function(context, test) {
      teamcity("testSuiteStarted", test)
      i <<- 1L
    },
    end_test = function(context, test) {
      teamcity("testSuiteFinished", test)
      cat("\n")
    },

    add_result = function(context, test, result) {
      testName <- paste0("expectation ", i)
      i <<- i + 1L

      if (expectation_skip(result)) {
        teamcity("testIgnored", testName, message = result$message)
        return()
      }

      teamcity("testStarted", testName)

      if (!expectation_success(result)) {
        lines <- strsplit(result$message, "\n")[[1]]

        teamcity("testFailed", testName, message = lines[1],
          details = paste(lines[-1], collapse = "\n")
        )
      }
      teamcity("testFinished", testName)
    }

  )
)

teamcity <- function(event, name, ...) {
  values <- list(name = name, ...)

  values <- vapply(values, teamcity_escape, character(1))
  if (length(values) == 0) {
    value_string <- ""
  } else {
    value_string <- paste0(names(values), "='", values, "'", collapse = " ")
  }

  cat("##teamcity[", event, " ", value_string, "]\n", sep = "")
}

# teamcity escape character is |
teamcity_escape <- function(s) {
  s <- gsub("(['|]|\\[|\\])", "|\\1", s)
  gsub("\n", "|n", s)
}