<!-- README.md is generated from README.Rmd. Please edit that file -->



# RescueTime R Wrapper

<!-- badges: start -->
<!-- badges: end -->

The goal of RescueTime Wrapper is to provide access to Rescue Time Data through R. Also it is possible to get anonymized data from here.

## Installation

You can install the version via the remotes package.

``` r
remotes.install_github(repo = "tud-ise/rescuetime-r-wrapper")
```

## Example

After loading the library you have two ways to access the RescueTime API. The Parameters are the same for both functions. 
First, you need to supply your RescueTimeAPI Key, second and third the start and enddate provided as string in ISO Format (YYYY-mm-DDTHH:MM:SSZ).
The fourth parameter varies between the function and defines the scope of the data returned. There is an optional fifth parameter that is discussed in the next paragraph.


```r
library(rescuetimewrapper)
# complete
data <- get_rescue_time_data("XYZ","2021-04-11T00:00:00Z","2021-04-12T23:59:59Z", 'Activity')
# anonymized
data <- get_rescue_time_data_anonymized("XYZ","2021-04-11T00:00:00Z","2021-04-12T23:59:59Z","Category")
```

The data returned is a table looking like this


```r
data <- get_rescue_time_data("XYZ","2021-04-11T00:00:00Z","2021-04-12T23:59:59Z", 'activity')
#> Date                `Time Spent (seconds)` `Number of People` Activity             Category                           Productivity
#> 1 2021-04-11 00:00:00                   1451                  1 idea64               Editing & IDEs                                2
#> 2 2021-04-11 00:00:00                    924                  1 Windows Explorer     General Utilities                             1
#> 3 2021-04-11 00:00:00                    892                  1 discord              General Communication & Scheduling            0
#> 4 2021-04-11 00:00:00                    620                  1 brave                Browsers                                      0
#> 5 2021-04-11 00:00:00                    574                  1 iTunes               Music                                        -2
#> 6 2021-04-11 00:00:00                    495                  1 youtube.com          Video                                        -2

data <- get_rescue_time_data_anonymized("XYZ","2021-04-12T00:00:00Z","2021-04-12T23:59:59Z", 'Category')
#>                      Category       Date Time Number of Applications
#> 1                    Business 2021-04-12  961                      4
#> 2  Communication & Scheduling 2021-04-12  406                      2
#> 3           Social Networking 2021-04-12   53                      1
#> 4        Design & Composition 2021-04-12   NA                      0
#> 5               Entertainment 2021-04-12 3157                      6
#> 6              News & Opinion 2021-04-12   29                      2
#> 7        Reference & Learning 2021-04-12  301                      5
#> 8        Software Development 2021-04-12 7208                      8
#> 9                    Shopping 2021-04-12   60                      2
#> 10                  Utilities 2021-04-12 1489                      9
#> 11              Uncategorized 2021-04-12  344                      8
```

### Transformed Data
You can also query the data in a transformed way, with an optional Parameter. The transformed data will also contain the productivity index described below. The output will look like this:
```r
data <- get_rescue_time_data("XYZ","2021-04-11T00:00:00Z","2021-04-12T23:59:59Z", 'activity', TRUE)
#> Date                   `idea64_Time`     `Windows Explorer_Time` ...
#> 1 2021-04-11 00:00:00                   1451                  924

data <- get_rescue_time_data_anonymized("XYZ","2021-04-12T00:00:00Z","2021-04-12T23:59:59Z", 'Category', TRUE)
#> Date                   `Business_Time`     `Business_Number of Applications`   'Communication & Scheduling_Time' ...
#> 1 2021-04-11 00:00:00                   961                  4                   406
```

### Productivity Index
You can also calculate a productivity index (weighted mean) for a given time period. The value varies from -2 (very unproductive) to 2 (very productive)
```r
productivity_index <- get_productivity_index("XYZ","2021-04-11T00:00:00Z","2021-04-12T23:59:59Z")
#> Date           Productivity Index
#> 2021-04-11   1.75
#> 2021-04-12   0.98
```
