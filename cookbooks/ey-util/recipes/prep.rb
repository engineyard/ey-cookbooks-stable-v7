include_recipe "ey-deploy-keys"
include_recipe "ey-cron"

include_recipe "ey-app::remove"
include_recipe "ey-app::create"
include_recipe "ey-app-logs"
#include_recipe "ey-db-libs"
