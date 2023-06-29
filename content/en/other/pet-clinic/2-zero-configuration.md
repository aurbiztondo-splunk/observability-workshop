---
title: Zero Configuration Auto Instrumentation for Java
linkTitle: 2. Zero Configuration
weight: 2
---

## 1. Spring PetClinic Application

First thing we need to setup APM is... well, an application. For this exercise, we will use the Spring PetClinic application. This is a very popular sample java application built with Spring framework (Springboot).

First clone the PetClinic GitHub repository, then we will compile, build, package and test the application:

```bash
git clone https://github.com/spring-projects/spring-petclinic
```

Change into the `spring-petclinic` directory (and checkout a specific commit):

```bash
cd spring-petclinic && git checkout 276880e
```

Start a MySQL database for PetClinic to use:

```bash
docker run -d -e MYSQL_USER=petclinic -e MYSQL_PASSWORD=petclinic -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=petclinic -p 3306:3306 docker.io/mysql:5.7.8
```

Next we will start a Docker container running Locust that will generate some simple traffic to the PetClinic application. Locust is a simple load testing tool that can be used to generate traffic to a web application.

```bash
docker run --network="host" -d -p 8090:8090 -v /home/ubuntu/workshop/petclinic:/mnt/locust docker.io/locustio/locust -f /mnt/locust/locustfile.py --headless -u 10 -r 3 -H http://127.0.0.1:8080
```

Next, run the `maven` command to compile/build/package PetClinic:

```bash
./mvnw package -Dmaven.test.skip=true
```

{{% notice style="info" %}}
This will take a few minutes the first time you run, `maven` will download a lot of dependencies before it actually compiles the application. Future executions will be a lot quicker.
{{% /notice %}}

Once the compilation is complete, you can run the application with the following command. Notice that we are passing the `mysql` profile to the application, this will tell the application to use the MySQL database we started earlier. We are also setting the `otel.service.name` to a logical service name that will also be used in the UI for filtering:

```bash
java \
-Dotel.service.name=$(hostname)-petclinic-service \
-jar target/spring-petclinic-*.jar --spring.profiles.active=mysql
```

You can validate if the application is running by visiting `http://<VM_IP_ADDRESS>:8080`.

## 2. AlwaysOn Profiling and Metrics

When we installed the collector we configured it to enable AlwaysOn Profiling and Metrics. This means that the collector will automatically generate CPU and Memory profiles for the application and send them to Splunk Observability Cloud.

When you start the PetClinic application you will see the collector automatically detect the application and instrument it for traces and profiling.

{{% tab title="Example output" %}}

``` text {wrap="false"}
Picked up JAVA_TOOL_OPTIONS: -javaagent:/usr/lib/splunk-instrumentation/splunk-otel-javaagent.jar -Dsplunk.profiler.enabled=true -Dsplunk.profiler.memory.enabled=true
OpenJDK 64-Bit Server VM warning: Sharing is only supported for boot loader classes because bootstrap classpath has been appended
[otel.javaagent 2023-06-26 13:32:04:661 +0100] [main] INFO io.opentelemetry.javaagent.tooling.VersionLogger - opentelemetry-javaagent - version: splunk-1.25.0-otel-1.27.0
[otel.javaagent 2023-06-26 13:32:05:294 +0100] [main] INFO com.splunk.javaagent.shaded.io.micrometer.core.instrument.push.PushMeterRegistry - publishing metrics for SignalFxMeterRegistry every 30s
[otel.javaagent 2023-06-26 13:32:07:043 +0100] [main] INFO com.splunk.opentelemetry.profiler.ConfigurationLogger - -----------------------
[otel.javaagent 2023-06-26 13:32:07:044 +0100] [main] INFO com.splunk.opentelemetry.profiler.ConfigurationLogger - Profiler configuration:
[otel.javaagent 2023-06-26 13:32:07:047 +0100] [main] INFO com.splunk.opentelemetry.profiler.ConfigurationLogger -                  splunk.profiler.enabled : true
[otel.javaagent 2023-06-26 13:32:07:048 +0100] [main] INFO com.splunk.opentelemetry.profiler.ConfigurationLogger -                splunk.profiler.directory : /tmp
[otel.javaagent 2023-06-26 13:32:07:049 +0100] [main] INFO com.splunk.opentelemetry.profiler.ConfigurationLogger -       splunk.profiler.recording.duration : 20s
[otel.javaagent 2023-06-26 13:32:07:050 +0100] [main] INFO com.splunk.opentelemetry.profiler.ConfigurationLogger -               splunk.profiler.keep-files : false
[otel.javaagent 2023-06-26 13:32:07:051 +0100] [main] INFO com.splunk.opentelemetry.profiler.ConfigurationLogger -            splunk.profiler.logs-endpoint : null
[otel.javaagent 2023-06-26 13:32:07:053 +0100] [main] INFO com.splunk.opentelemetry.profiler.ConfigurationLogger -              otel.exporter.otlp.endpoint : null
[otel.javaagent 2023-06-26 13:32:07:054 +0100] [main] INFO com.splunk.opentelemetry.profiler.ConfigurationLogger -           splunk.profiler.memory.enabled : true
[otel.javaagent 2023-06-26 13:32:07:055 +0100] [main] INFO com.splunk.opentelemetry.profiler.ConfigurationLogger -             splunk.profiler.tlab.enabled : true
[otel.javaagent 2023-06-26 13:32:07:056 +0100] [main] INFO com.splunk.opentelemetry.profiler.ConfigurationLogger -        splunk.profiler.memory.event.rate : 150/s
[otel.javaagent 2023-06-26 13:32:07:057 +0100] [main] INFO com.splunk.opentelemetry.profiler.ConfigurationLogger -      splunk.profiler.call.stack.interval : PT10S
[otel.javaagent 2023-06-26 13:32:07:058 +0100] [main] INFO com.splunk.opentelemetry.profiler.ConfigurationLogger -  splunk.profiler.include.internal.stacks : false
[otel.javaagent 2023-06-26 13:32:07:059 +0100] [main] INFO com.splunk.opentelemetry.profiler.ConfigurationLogger -      splunk.profiler.tracing.stacks.only : false
[otel.javaagent 2023-06-26 13:32:07:059 +0100] [main] INFO com.splunk.opentelemetry.profiler.ConfigurationLogger - -----------------------
[otel.javaagent 2023-06-26 13:32:07:060 +0100] [main] INFO com.splunk.opentelemetry.profiler.JfrActivator - Profiler is active.
```

{{% /tab %}}

## 3. Configure Profiling Data Collection

We need to edit the collector configuration file `/etc/otel/collector/agent_config.yaml` and add a new exporter to send the profiling data to Splunk Observability Cloud:

``` yaml {hl_lines="1-3"}
  splunk_hec/profiling:
    token: "${SPLUNK_ACCESS_TOKEN}"
    endpoint: "${SPLUNK_INGEST_URL}/v1/log"
```

We, also, then need to create a new pipeline called `logs/profiling` under the `service:` section:

``` yaml {hl_lines="1-7"}
    logs/profiling:
      receivers: [otlp]
      processors:
      - memory_limiter
      - batch
      - resourcedetection
      exporters: [splunk_hec/profiling]
```

Save the changes and exit the editor, then restart the collector:

``` bash
sudo systemctl restart splunk-otel-collector
```

You can now visit the Splunk APM UI and examine the application components, traces, profiling, DB Query performance and metrics. From the left hand menu **APM → Explore**, click the environment dropdown and select your own environment (which is prefixed with your hostname of your instance).

![APM Environment](../images/apm-environment.png)

Once your validation is complete you can stop the application by pressing `Ctrl-c`.

## 4. Adding Resource Attributes to Spans

Resource attributes can be added to every reported span. For example `version=0.314`. A comma separated list of resource attributes can also be defined e.g. `key1=val1,key2=val2`.

Let's launch the PetClinic again using a new resource attribute. Note, that adding resource attributes to the run command will override what was defined when we installed the collector. Let's add a new resource attribute `version=0.314`:

```bash
java \
-Dotel.service.name=$(hostname)-petclinic-service \
-Dotel.resource.attributes=version=0.314 \
-jar target/spring-petclinic-*.jar --spring.profiles.active=mysql
```

Back in the Splunk APM UI we can drill down on a recent trace and see the new `version` attribute in a span.
