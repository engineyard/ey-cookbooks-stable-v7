# Contributing to Engine Yard v7 Cookbooks repository

We're glad you want to contribute to a Engine Yard v7 Cookbooks repository ! This document will help answer common questions you may have during your first contribution.

## Instructions for creating a cookbook

1. Clone the repository or pull the latest changes! `git clone` or `git fetch`.
2. Install cookstyle this can be done with `gem install cookstyle`. This is required for the linting process. (Make sure cookstyle is version **1.25.1 or higher**
3. If you're creating or migrating a base recipe that is used by the default chef process, make sure the recipe starts with `ey-` for example `ey-core`. 
4. Create your cookbook
5. The metadata must have a version number in it
6. To test first run it through the linter by running `cookstyle`. If there are any errors amend them or leave a comment why they should be left / exist


## Steps required for Pull Request submitting

1. Ensure you are working in a branch in <b>ey-cookbooks-stable-v7</b>
 * If you are contributing from outside EngineYard, please create a fork and create a pull request we will suggest any code changes in the comments.
 * The branch should be named after the feature being worked on. Ticket id (For example: CC-1123 ) should be used instead of feature name if you are Engine Yard employee.
2. Please use cookstyle to make sure your recipe passes the linting process, we will make any changes to rubocop.yml as needed
3. Rebase your branch against the most recent version of the master branch:
  * `git fetch --all && git rebase -i origin/master`
  * Squash all the commits down to a single commit, with a summary commit
    message with the ticket as a prefix
    (e.g.: [CC-199] Enables users to ..."
4. Use the following Pull Request template in the description field

```
Description of your patch
-------------

Recommended Release Notes
-------------

Estimated risk
-------------

Components involved
-------------

Dependencies
-------------

Description of testing done
-------------

QA Instructions
-------------
```

_Notes:_
For "Estimated risk", specify low, medium or high, and justify your selection.
"Components involved" should list not the files changed, but the area of work (i.e.: a region specific change, customers on ruby 1.8.7, all node customers, etc).
"Dependencies" should state if this PR depends on another one, which must be merged first.
If for example, the PR was created by branching off of another feature branch (not master), 
then the PR depends on that branch and needs to state that clearly.
PRs that depend on others will only be considered if the parent PR is ready for review and testing.

## Steps after submitting your Pull Request

1. Update the ticket to 'Pull Request' status, and add a link to the pull
   request
2. Do not continue to do work in the branch used for the pull request -- PRs
   are automatically updated with any changes
3. Monitor your pull request for updates.  Your pull request will be reviewed
   on or before each Thursday at 8:30 am Pacific.  Any deficiencies found must
   be rectified by 12:pm Pacific to make it into that week's release.
4. Feel free to contact us in ZenDesk or IRC if a pull request is overlooked.
