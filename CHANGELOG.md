# Next release: 1.2.0

# 1.1.0 / 2025-02-10

* [IMPROVEMENT] Improve performance regarding internal logging (#78)
* [IMPROVEMENT] Take into account all intake HTTP errors
* [IMPROVEMENT] Read console log for crash report on Roku 13+ 
* [IMPROVEMENT] Update trace to use 128 bit id instead of 64
* [IMPROVEMENT] Allow sending custom error with type

# 1.0.0 / 2023-12-18

### Changes

* [FEATURE] Allow custom context attribute for individual events
* [FEATURE] Add support for OTel header when tracing synchronous requests
* [FEATURE] Add automatic metadata to Logs


# 1.0.0-beta2 / 2023-07-06

### Changes

* [BUGFIX] Ensure events keep being sent after 10 minutes

# 1.0.0-beta1 / 2023-06-26

### Changes

* [FEATURE] Add control over distributed tracing sampling and supported hosts

# 1.0.0-alpha2 / 2023-03-31

### Changes

* [BUGFIX] Send the `env` tag with RUM Events

# 1.0.0-alpha1 / 2023-02-23

### Changes

* [FEATURE] Manual RUM tracking (Views, Actions, Resources, Errors)
* [FEATURE] Manual Logs
* [FEATURE] Track channel crashes