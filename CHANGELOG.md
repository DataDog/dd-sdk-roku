# Next release: 1.5.0

# 1.4.0 / 2026-03-16
* [FEATURE] Add RUM Operations tracking (start, stop, update, cancel operations with custom attributes). See [#133](https://github.com/DataDog/dd-sdk-roku/pull/133)
* [FEATURE] Add `ignoredExitEvents` in configuration. See [#126](https://github.com/DataDog/dd-sdk-roku/pull/126)
* [BUGFIX] Fix crash in `RumViewScope`. See [#116](https://github.com/DataDog/dd-sdk-roku/pull/116)
* [IMPROVEMENT] Reduce rendezvous events in `RumAgent`. See [#121](https://github.com/DataDog/dd-sdk-roku/pull/121)
* [IMPROVEMENT] Refactor `RumAgent` to avoid race condition. See [#115](https://github.com/DataDog/dd-sdk-roku/pull/115)
* [MAINTENANCE] Add GitHub publish action. See [#110](https://github.com/DataDog/dd-sdk-roku/pull/110)
* [MAINTENANCE] Migrate off legacy CI runners. See [#111](https://github.com/DataDog/dd-sdk-roku/pull/111)
* [MAINTENANCE] Centralize versions for devDependencies in `package.json`. See [#134](https://github.com/DataDog/dd-sdk-roku/pull/134)
* [MAINTENANCE] Improve contributing guide and dev environment setup. See [#124](https://github.com/DataDog/dd-sdk-roku/pull/124)

# 1.3.1 / 2025-09-08
* [BUGFIX] Add missing BrighterScript `Callfunc` Operator to fix crash. See [#106](https://github.com/DataDog/dd-sdk-roku/pull/106)

# 1.3.0 / 2025-08-18
* [BUGFIX] Fix `RumAgent` crash when initialising uploader. See [#102](https://github.com/DataDog/dd-sdk-roku/pull/102)

# 1.2.0 / 2025-06-30
* [FEATURE] Add `baggage` with Session ID in trace headers. See [#90](https://github.com/DataDog/dd-sdk-roku/pull/90)
* [FEATURE] Add `TraceContextInjection` in trace configuration. See [#91](https://github.com/DataDog/dd-sdk-roku/pull/91)
* [FEATURE] Add `AP2` support in SDK. See [#93](https://github.com/DataDog/dd-sdk-roku/pull/93)
* [MAINTENANCE] Add workflow: Changelog update to Confluence . See [#94](https://github.com/DataDog/dd-sdk-roku/pull/94)
* [MAINTENANCE] Update `.gitignore` and `CONTRIBUTING.md`. See [#89](https://github.com/DataDog/dd-sdk-roku/pull/89)


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