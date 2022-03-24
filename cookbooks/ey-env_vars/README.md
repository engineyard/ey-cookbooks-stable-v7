# env_vars

This recipe is used to upload  `/data/app_name/shared/config/env.custom` and  `/data/app_name/shared/config/env.cloud` files on the stable-v7 stacks. These files are used to load environment variables for the web application; the V7 scripts for Passenger, Unicorn, Puma, as long as Sidekiq were written to source these files on startup.

Environment Variables added [via dashboard](https://support.cloud.engineyard.com/hc/en-us/articles/360007661794-Environment-Variables-and-How-to-Use-Them) are included into `env.cloud` file. 

The `ey-env_vars` recipe is managed by Engine Yard.

We accept contributions for changes that can be used by all customers.
