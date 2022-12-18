# ey-clamav cookbook

In order to implement clamav on your environment. 

1. Enabled clamav to be run on the environment using `EY_CLAMAV_ENABLED` to `true` via environment variables.
2. Then if you are in need of running `clamav` on selected instance roles, make use of the following environment variables.

* `EY_CLAMAV_APP_PATHS` 
* `EY_CLAMAV_DB_PATHS`
* `EY_CLAMAV_UTIL_PATHS`
* `EY_CLAMAV_SOLO_PATHS`

default value for each of the roles would be `[]` , In order add paths to run under the scanner, set the value to an Array like `["/data", "/tmp"]` which would create 2 cronjobs to run.