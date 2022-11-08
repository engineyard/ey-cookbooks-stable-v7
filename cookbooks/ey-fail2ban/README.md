# fail2ban

This recipe is used to run fail2ban on the stable-v7 stack.

We accept contributions for changes that can be used by all customers.

In order to enable the recipe, consider setting `EY_FAIL2BAN_ENABLED` to `true`

In order to specify on which instances it should run.

```
EY_FAIL2BAN_ENABLED_INSTANCES
```

set the role values as comma separated values.

i.e: solo,util
db_master,app,util