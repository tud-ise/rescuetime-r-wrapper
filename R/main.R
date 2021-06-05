#' Get RescueTime Data based on an API Key.
#' The Data is returned unfiltered
#'
#' @param key string provided by RescueTime
#' @param dateFrom string in iso date format "YYYY-mm-DDTHH:MM:ssZ"
#' @param dateTo string in iso date format "YYYY-mm-DDTHH:MM:ssZ"
#' @param scope string either "Overview", "Category", "Activity", "Productivity", "Document"
#' @param transform boolean transform data to different structure

#'
#' @return table with complete data
#' @export
#'
#' @examples
#' data <- get_rescue_time_data("XYZ","2021-04-11T00:00:00Z","2021-04-12T23:59:59Z","Category")
get_rescue_time_data <- function (key, dateFrom, dateTo, scope = "Activity", transform = FALSE) {
  library(httr)
  params <- list("key" = key,
                 "format" = "csv",
                 "restrict_begin" = dateFrom,
                 "restrict_end" = dateTo ,
                 "resolution_time" = "day",
                 "perspective" = "interval",
                 "restrict_kind" = tolower(scope))

  res <- POST("https://www.rescuetime.com/anapi/data",
              body = params,
              encode = "form",
              verbose()
  )

  # parse data
  if (status_code(res) == 200) {
    activity_data <- content(res, "parsed")

    if (transform) {
      colnames(activity_data)[colnames(activity_data) == "Time Spent (seconds)"] <- "Time"
      colnames(activity_data) <- stringr::str_replace_all(colnames(activity_data),"[:punct:]|[:space:]|[/+]","")
      activity_data <- transform(activity_data, Date = strftime(Date, "%Y-%m-%d"))
      return(transform_data(activity_data, "Date", scope,  c("Time")))
    } else {
      return(activity_data)
    }
  } else {
    print(paste("Keine Daten von Server erhalten (Error Code ", status_code(res), ")"))
    return(NULL)
  }

}

#' Get RescueTime Data based on an API Key.
#' The Data is return anonymized according to the category definitions on package level
#'
#'
#' @param key string provided by RescueTime
#' @param dateFrom string in iso date format "YYYY-mm-DDTHH:MM:ssZ"
#' @param dateTo string in iso date format "YYYY-mm-DDTHH:MM:ssZ"
#' @param scope string either "Category" or "SubCategory"
#' @param transform boolean transform data to different structure
#'
#' @return table with an entry for each category for each day
#' @export
#'
#' @examples
#' data <- get_rescue_time_data_anonymized("XYZ","2021-04-11T00:00:00Z","2021-04-12T23:59:59Z","Category")
get_rescue_time_data_anonymized <- function (key, dateFrom, dateTo, scope = "Category", transform = FALSE) {
  library(dplyr)
  activity_data <- get_rescue_time_data(key, dateFrom, dateTo, "Activity", FALSE)

  if(!is.null(activity_data) && ncol(activity_data) > 0 && nrow(activity_data) > 0) {
    csv_path <- system.file("categories.csv", package="rescuetimewrapper")
    categories <- read.csv(csv_path)

    # join with categories
    joined_data <- merge(
      categories,
      activity_data,
      by.x = "SubCategory",
      by.y = "Category",
      all = TRUE,
    )

    # productivity index
    productivity_index <- activity_data %>%
      group_by(Date) %>%
      summarise(weighted.mean(Productivity, `Time Spent (seconds)`))
    names(productivity_index)<-c("Date","Productivity Index")
    productivity_index <- transform(productivity_index, Date = strftime(Date, "%Y-%m-%d"))

    # anonymize data by aggreagting over categories
    anomymized_data <- aggregate(x = joined_data$`Time Spent (seconds)`,
                                 by = list(joined_data[,scope], joined_data$Date),
                                 FUN = sum)
    colnames(anomymized_data) <- c("Category", "Date","Time Spent (seconds)")

    all_data <- expand.grid(unique(na.omit(categories[,scope])),
                            unique(na.omit(joined_data$Date)),
                            "Time Spent (seconds)"=NA)
    colnames(all_data) <- c("Category", "Date","Time Spent (seconds)")
    result <- select(merge(all_data, anomymized_data, by = c("Category", "Date"), all=TRUE),-"Time Spent (seconds).x")
    colnames(result) <- c("Category", "Date","Time")

    # add number of Applications for each row
    for (row in 1:nrow(result)) {
      current_category <- toString(result[row, "Category"])
      current_date <- result[row, "Date"]
      result[row, "Number of Applications"] <- length(which(joined_data[,scope] == current_category & joined_data$Date == current_date))
    }

    if (transform) {
      colnames(result)[colnames(result) == "Time Spent (seconds)"] <- "Time"
      colnames(result) <- stringr::str_replace_all(colnames(result),"[:punct:]|[:space:]|[+]","")
      result <- transform(result, Date = strftime(Date, "%Y-%m-%d"))
      transformed_result <- transform_data(result, "Date", scope, c("Time", "NumberofApplications"))
      data_with_productivity <- merge(transformed_result, productivity_index, by = "Date", all = TRUE)
      return(data_with_productivity)
    } else {
      return(result)
    }
  } else {
    return(NULL)
  }
}

#' Transform data frame based on row and column definitions
#'
#' @param data data.frame with rows and columns
#' @param row_column string the column that contains the values for the transformed row
#' @param col_column string the column that contains the values for the transformed columns
#' @param ignored_columns array list of columns to ignore as value columns
#'
#' @return a data frame that has a row for each entry of the values in the row_column
#' and columns for each value of the col_column
#'
#' @examples new_data <- transform_data(data, "Date", "Category")
transform_data <- function(data, row_column, col_column, value_columns = c("Time")) {
  library(lubridate)
  # create table with unique values for row_column as rows
  transformed_data <- data.frame(unique(na.omit(data[, row_column])))
  colnames(transformed_data) <- c(row_column)


  # for each column that values are converted to columns themselves
  unique_items <- data.frame(unique(na.omit(data[,col_column])))
  colnames(unique_items) <- c(col_column)

  for(i in 1:nrow(transformed_data)) {
    for (j in 1:nrow(unique_items)) {
      col_value <- unique_items[j, col_column]
      current_row <- data[which(grepl(pattern = toString(transformed_data[i, row_column]), x=data[,row_column], fixed=TRUE)
                                & grepl(pattern = toString(col_value), x = data[, col_column], fixed=TRUE)),]
      for (col in value_columns) {
        transformed_data[i, paste(col_value, col, sep = "_")] <- current_row[1, col]
      }
    }
  }
  return(transformed_data)
}

#' Function that calculates a productivity index (weighted mean) for a given time period
#'
#' @param key string provided by RescueTime
#' @param dateFrom string in iso date format "YYYY-mm-DDTHH:MM:ssZ"
#' @param dateTo string in iso date format "YYYY-mm-DDTHH:MM:ssZ"
#'
#' @return data.frame with a productivity for each date
#' @export
#'
#' @examples productivity_index <- get_productivity_index("XYZ","2021-04-11T00:00:00Z","2021-04-12T23:59:59Z")

get_productivity_index <- function(key, dateFrom, dateTo) {
  library(dplyr)
  activity_data <- get_rescue_time_data(key, dateFrom, dateTo, "Activity", FALSE)

  if(!is.null(activity_data) && ncol(activity_data) > 0 && nrow(activity_data) > 0) {
    # productivity index
    productivity_index <- activity_data %>%
      group_by(Date) %>%
      summarise(weighted.mean(Productivity, `Time Spent (seconds)`))
    names(productivity_index)<-c("Date","Productivity Index")
    productivity_index <- transform(productivity_index, Date = strftime(Date, "%Y-%m-%d"))

    return(productivity_index)
  } else {
      return(NULL)
  }
}
