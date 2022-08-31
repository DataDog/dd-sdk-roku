# Contributing

First of all, thanks for contributing!

This document provides some basic guidelines for contributing to this repository.
To propose improvements, feel free to submit a PR or open an Issue.

## Setup your developer Environment

To setup your enviroment, first make sure you followed the official [Roku Developer environment setup](https://developer.roku.com/en-gb/docs/developer-program/getting-started/developer-setup.md).

You also need to have the [BrighterScript](https://npmjs.org/package/brighterscript), [BSLint](https://www.npmjs.com/package/@rokucommunity/bslint) and [ROPM](https://www.npmjs.com/package/ropm) `npm` packages installed: 

```shell script
npm install -g brighterscript
npm install -g ropm
npm install -g @rokucommunity/bslint
```

### Running the static analysis

The whole project is covered by a set of static analysis tools, which can be launched via a shell script.

```shell script
./tools/lint/lint.sh sample test library
```

### Running the tests

The whole project is covered by a set of tests using Roku's official [Unit Testing Framework](https://github.com/rokudev/unit-testing-framework), which can be launched via `npm`.

**Note** in order to run the test app, you need to have a Roku device set up in development mode. You also must set the `ROKU_DEV_TARGET` environment variable to your device's IP address, and the `ROKU_DEV_PASSWORD` environment variable to your device's dev password.

```shell script
npm test
```

### Running the sample app

A sample app is available to showcase the basic features of the SDK. Before using the sample application, you **must** create a `sample/source/credentials.brs` file with the following lines: 

```brightscript
' Returns a valid Datadog RUM Client Token
function getDatadogClientToken() as string
    return "pub0123456789abcdef0123456789abcdef"
end function
```
**Note** in order to run the sample app, you need to have a Roku device set up in development mode. You also must set the `ROKU_DEV_TARGET` environment variable to your device's IP address, and the `ROKU_DEV_PASSWORD` environment variable to your device's dev password.

```shell script
npm run sample
```

## Submitting Issues

Many great ideas for new features come from the community, and we'd be happy to
consider yours!

To share your request, you can open an [issue](https://github.com/DataDog/dd-sdk-roku/issues/new?labels=enhancement&template=feature_request.md) 
with the details about what you'd like to see. At a minimum, please provide:

 - The goal of the new feature;
 - A description of how it might be used or behave;
 - Links to any important resources (e.g. Github repos, websites, screenshots,
     specifications, diagrams).

## Found a bug?

For any urgent matters (such as outages) or issues concerning the Datadog service
or UI, contact our support team via https://docs.datadoghq.com/help/ for direct,
faster assistance.

You may submit bug reports concerning the Datadog SDK for Roku by 
[opening a Github issue](https://github.com/DataDog/dd-sdk-roku/issues/new?labels=bug&template=bug_report.md).
At a minimum, please provide:

 - A description of the problem;
 - Steps to reproduce;
 - Expected behavior;
 - Actual behavior;
 - Errors (with stack traces) or warnings received;
 - Any details you can share about your configuration including:
    - Datadog SDK version;
    - Name and versions of any other relevant dependencies ;
    - Which Roku device(s) the issue appears on;

If at all possible, also provide:

 - Logs (from the telnet log on port 8085) or other diagnostics;
 - Screenshots, links, or other visual aids that are publicly accessible;
 - Code sample or test that reproduces the problem;
 - An explanation of what causes the bug and/or how it can be fixed.

Reports that include rich detail are better, and ones with code that reproduce
the bug are best.

## Have a patch?

We welcome code contributions to the library, which you can 
[submit as a pull request](https://github.com/DataDog/dd-sdk-roku/pull/new/develop).
Before you submit a PR, make sure that you first create an Issue to explain the
bug or the feature your patch covers, and make sure another Issue or PR doesn't
already exist.

To create a pull request:

1. **Fork the repository** from https://github.com/DataDog/dd-sdk-roku ;
2. **Create a new branch** based on `develop`;
3. **Make any changes** for your patch;
4. **Write tests** that demonstrate how the feature works or how the bug is fixed;
5. **Update any documentation**, especially for new features;
6. **Submit the pull request** from your fork back to this 
    [repository](https://github.com/DataDog/dd-sdk-roku) .


The pull request will be run through our CI pipeline, and a project member will
review the changes with you. At a minimum, to be accepted and merged, pull
requests must:

 - Have a stated goal and detailed description of the changes made;
 - Include thorough test coverage and documentation, where applicable;
 - Pass all tests and code quality checks (linting/coverage/benchmarks) on CI;
 - Receive at least one approval from a project member with push permissions.

Make sure that your code is clean and readable, that your commits are small and
atomic, with a proper commit message. 
