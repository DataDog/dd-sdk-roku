# Datadog SDK for Roku

> A client-side Roku library to interact with Datadog.

**NOTE** This library is still in early Developer Preview.

## Getting Started

### Setup with ROPM (recommended)

`ROPM` is a package manager for the Roku platform (based on NPM). If you're not already using `ROPM` in your Roku project, read their [Getting started guide][1]. Once your project is set up to use `ROPM`, you can use the following command to install the Datadog dependency:

```shell
ropm install datadog-roku
```

### Setup manually

If your project does not use `ROPM`, install the library manually by downloading the [Roku SDK][5] zip archive, 
and unzipping it in your project's root folder.

Make sure you have a `roku_modules/datadogroku` subfolder in both the `components` and ` source` folders of your projet.

### Configure Datadog

To configure the Datadog SDK, copy the following code snippet into the `RunUserInterface()` method of your `main.brs` file. Make sure that you call `datadogroku_initialize` after the `show` method of your screen.

```brightscript
sub RunUserInterface(args as dynamic)

    screen = CreateObject("roSGScreen")
    scene = screen.CreateScene("MyScene")
    screen.show()

    ' Setup Datadog
    datadogroku_initialize({
        clientToken: "pub00000000000000000000000000000000, ' replace with your client token
        applicationId: ""00000000-0000-0000-0000-000000000000", ' replace with your RUM application Id
        site: "us1", ' replace with the site you're targeting: "us1", "us3", "us5", or "eu1" 
        env: "prod" ' replace with the environment you're targeting, e.g.: prod, staging, …
        sessionSampleRate: 100, ' the percentage (integer) of sessions to track
        launchArgs: args
    }, globalNode)

    ' complete your channel setup here
end sub
```

### Track RUM events manually

#### Track RUM Views

To split [user sessions][4] into logical steps, manually start a View using the following code. Every navigation to a new screen within your channel should correspond to a new RUM View.

```brightscript
    viewName = "VideoDetails"
    viewUrl = "components/screens/VideoDetails.xml"
    m.global.datadogRumAgent.callfunc("startView", viewName, viewUrl)
```

#### Track RUM Actions

RUM Actions represent the interactions your users have with your channel. You can forward actions to Datadog as follows:

```brightscript
    target = "playButton" ' the name of the SG Node the user interacted with
    type = "click" ' the type of interaction, should be one of "click", "back", or "custom" 
    m.global.datadogRumAgent.callfunc("addAction", { target: targetName, type: type})
```

#### Track RUM Errors

Whenever you perform an operation that might throw an exception, you can forward the error to Datadog as follows:

```brightscript
    try
        doSomethingThatMightThrowAnException()
    catch error
        m.global.datadogRumAgent.callfunc("addError", error)
    end try
```

#### Track RUM Resources

##### `roUrlTransfer`

Network requests made directly with a `roUrlTransfer` node must be tracked. 

For **synchronous requests**, you can use our wrapper to track the resource automatically, by using our `datadogroku_DdUrlTransfer` wrapper, 
which supports most features of the `roUrlTransfer` component (except anything related to async network calls).

For example, here's how to do a `GetToString` call:

```brightscript
    ddUrlTransfer = datadogroku_DdUrlTransfer(m.global.datadogRumAgent)
    ddUrlTransfer.SetUrl(url)
    ddUrlTransfer.EnablePeerVerification(false)
    ddUrlTransfer.EnableHostVerification(false)
    result = ddUrlTransfer.GetToString()
```

For **asynchronous request**, there's no automatic instrumentation yet, meaning you need to track the resource manually. The following code snippet shows how to report the request as a RUM Resource:

```brightscript
sub performRequest()

    m.port = CreateObject("roMessagePort")
    request = CreateObject("roUrlTransfer")
    ' setup the node url, headers, …

    timer = CreateObject("roTimespan")
    timer.Mark()
    request.AsyncGetToString()
    
    while (true)
        msg = wait(1000, m.port)
        if (msg <> invalid)
            msgType = type(msg)
            if (msgType = "roUrlEvent")
                if (msg.GetInt() = 1) ' transfer complete
                    durationMs& = timer.TotalMilliseconds()
                    transferTime# = datadogroku_millisToSec(durationMs&)
                    httpCode = msg.GetResponseCode()
                    status = "ok"
                    if (httpCode < 0)
                        status = msg.GetFailureReason()
                    end if
                    resource = {
                        url: requestUrl
                        method: "GET"
                        transferTime: transferTime#
                        httpCode: httpCode
                        status: status
                    }
                    m.global.datadogRumAgent.callfunc("addResource", resource)
                end if
            end if
        end if
    end while
end sub
```

##### Streaming resources

Whenever you use a `Video` or an `Audio` node to stream media, you can forward all `roSystemLogEvent` you receive to Datadog as follows: 

```brightscript 
    sysLog = CreateObject("roSystemLog")
    sysLog.setMessagePort(m.port)
    sysLog.enableType("http.error")
    sysLog.enableType("http.complete")

    while(true)
        msg = wait(0, m.port)
        if (type(msg) = "roSystemLogEvent")
            m.global.datadogRumAgent.callfunc("addResource", msg.getInfo())
        end if
    end while
```

### Identifying your users

Adding user information to your RUM sessions makes it easy to:
* Follow the journey of a given user.
* Know which users are the most impacted by errors.
* Monitor performance for your most important users.

The following attributes are **optional**, but you should provide **at least one** of them:

| Attribute | Type   | Description                                                                                              |
| --------- | ------ | -------------------------------------------------------------------------------------------------------- |
| id        | String | Unique user identifier.                                                                                  |
| name      | String | User friendly name, displayed by default in the RUM UI.                                                  |
| email     | String | User email, displayed in the RUM UI if the user name is not present. It is also used to fetch Gravatars. |

To identify user sessions, use the `datadogUserInfo` global field, after initializing the SDK, for example:

```brightscript
    m.global.setField("datadogUserInfo", { id: 42, name: "Abcd Efg", email: "abcd.efg@example.com"})
```

### Track custom global attributes

In addition to the default attributes captured by the SDK automatically, you can choose to add additional contextual information, such as custom attributes, to your Logs and RUM events to enrich your observability within Datadog. Custom attributes allow you to filter and group information about observed user behavior (for example by cart value, merchant tier, or ad campaign) with code-level information (such as backend services, session timeline, error logs, and network health).

```brightscript
    m.global.setField("datadogContext", { foo: "Some value", bar: 123})
```

### Send logs

In addition to standard RUM events, you can send individual logs to track any event or state of your channel, with a log message, and optionally additional custom attributes. 

- `logOk`: Sends a log with status "ok".
- `logDebug`: Sends a log with status "debug", for messages that contain information that is useful for debugging a program.
- `logInfo`: Sends a log with status "info", for confirmation that the program is working as expected.
- `logNotice`: Sends a log with status "notice", for conditions that are not error conditions, but that may require special handling.
- `logWarn`: Sends a log with status "warning", for warning situations.
- `logError`: Sends a log with status "error", for errors.
- `logCritical`: Sends a log with status "critical", for situations when the application is in a critical state.
- `logAlert`: Sends a log with status "alert", for conditions that should be corrected immediately, such as a corrupted system database.
- `logEmergency`: Sends a log with status "emergency", for a panic condition.

The following code snippet illustrates the `logInfo` function, but all functions on the LogsAgent use the same signature:
```brightscript
    msg = "Switching screen to video details"
    attributes = { video_id : 42 }
    m.global.datadogLogsAgent.callfunc("logInfo", msg, attributes)
```

### Troubleshooting

To see internal messages and warnings about how the SDK is behaving,  enable the SDK verbosity to see debug information when you connect to your device with telnet on port `8085`.

```brightscript
    m.global.setField("datadogVerbosity", 3) ' 0 = none; 1 = error; 2 = warning; 3 = info; 4 = verbose;
```

## Looking up your RUM events

Navigate to the [RUM Explorer][2]. In the side bar, select your application and explore Sessions, Views, Actions, Errors, Resources, and Long Tasks.

## Looking up your Logs

Navigate to the [Log Explorer][3]. In the side bar, select your application and explore Sessions, Views, Actions, Errors, Resources, and Long Tasks.

## Contributing

Pull requests are welcome. First, open an issue to discuss what you would like to change. For more information, read the [Contributing Guide](CONTRIBUTING.md).

## License

[Apache License, v2.0](LICENSE)

[1]: https://github.com/rokucommunity/ropm
[2]: https://app.datadoghq.com/rum/explorer?query=%40type%3Asession%20source%3Aroku
[3]: https://app.datadoghq.com/logs?query=source%3Aroku
[4]: https://docs.datadoghq.com/real_user_monitoring/
[5]: https://github.com/DataDog/dd-sdk-roku/releases/latest