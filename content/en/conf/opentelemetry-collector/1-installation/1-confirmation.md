---
title: Installing OpenTelemetry Collector Contrib
linkTitle: 1.1 Confirm Installation
weight: 1
---

## Confirm the Collector is running

The collector should now be running. We will verify this as root using `systemctl` command. To exit the status just press `q`.

{{< tabs >}}
{{% tab title="Command" %}}

``` bash
sudo systemctl status otelcol-contrib
```

{{% /tab %}}
{{% tab title="Status Output" %}}

``` text
● otelcol-contrib.service - OpenTelemetry Collector Contrib
     Loaded: loaded (/lib/systemd/system/otelcol-contrib.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2023-05-16 08:23:23 UTC; 25s ago
   Main PID: 1415 (otelcol-contrib)
      Tasks: 5 (limit: 1141)
     Memory: 22.2M
        CPU: 125ms
     CGroup: /system.slice/otelcol-contrib.service
             └─1415 /usr/bin/otelcol-contrib --config=/etc/otelcol-contrib/config.yaml

May 16 08:23:39 ip-10-0-9-125 otelcol-contrib[1415]: NumberDataPoints #0
May 16 08:23:39 ip-10-0-9-125 otelcol-contrib[1415]: Data point attributes:
May 16 08:23:39 ip-10-0-9-125 otelcol-contrib[1415]:      -> exporter: Str(logging)
May 16 08:23:39 ip-10-0-9-125 otelcol-contrib[1415]:      -> service_instance_id: Str(df8a57f4-abdc-46b9-a847-acd62db1001f)
May 16 08:23:39 ip-10-0-9-125 otelcol-contrib[1415]:      -> service_name: Str(otelcol-contrib)
May 16 08:23:39 ip-10-0-9-125 otelcol-contrib[1415]:      -> service_version: Str(0.75.0)
May 16 08:23:39 ip-10-0-9-125 otelcol-contrib[1415]: StartTimestamp: 2023-05-16 08:23:39.006 +0000 UTC
May 16 08:23:39 ip-10-0-9-125 otelcol-contrib[1415]: Timestamp: 2023-05-16 08:23:39.006 +0000 UTC
May 16 08:23:39 ip-10-0-9-125 otelcol-contrib[1415]: Value: 0.000000
May 16 08:23:39 ip-10-0-9-125 otelcol-contrib[1415]:         {"kind": "exporter", "data_type": "metrics", "name": "logging"}
```

{{% /tab %}}
{{< /tabs >}}

As will be running the rest of the workshop using the `otelcol-contrib` standalone binary, we will stop the service and then disable it from starting on boot:

{{< tabs >}}
{{% tab title="Command" %}}

``` bash
sudo systemctl stop otelcol-contrib
```

{{% /tab %}}
{{< /tabs >}}

{{< tabs >}}
{{% tab title="Command" %}}

``` bash
sudo systemctl disable otelcol-contrib
```

{{% /tab %}}
{{< /tabs >}}

---

{{% expand title="{{% badge style=primary icon=user-ninja %}}**Ninja:** Build your own collector using Open Telemetry Collector Builder (ocb){{% /badge %}}" %}}
For this part we will require the following installed on your system:

- Golang (latest version)

  ``` bash
  cd /tmp
  wget https://golang.org/dl/go1.20.linux-amd64.tar.gz
  sudo tar -C /usr/local -xzf go1.20.linux-amd64.tar.gz
  ```

  Edit `.profile` and add the following environment variables:

  ``` bash
  export GOROOT=/usr/local/go
  export GOPATH=$HOME/go
  export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
  ```

  Renew your shell session:
  
  ``` bash
  source ~/.profile
  ```

  Check Go version:

  ``` bash
  go version
  ```
  
- ocb installed
  - Most recent from the [project releases](https://github.com/open-telemetry/opentelemetry-collector/releases)
  - Install using go by `go install go.opentelemetry.io/collector/cmd/builder@v0.75.0`
- (Optional) Docker

## Why build your own collector?

The default distribution of the collector (core and contrib) either contain too much or too little in what they have to offer.

It is also not advised to run the contrib collector in your production environments due to the amount of components installed which more than likely are not needed by your deployment.

## Benefits of building your own collector?

When creating your own collector binaries, (commonly referred to as distribution), means you build what you need.

The benefits of this are:

1. Smaller sized binaries
2. Can use existing go scanners for vulnerabilities
3. Include internal components that can tie in with your organisation

## Considerations for building your own collector?

Now, this would not be a 🥷 Ninja zone if it didn't come with some draw backs:

1. Go experience is recommended if not required
1. **No** Splunk support
1. Responsibility of distribution and lifecycle management

It is important to note that project is working towards stability but it does not mean changes made will not break your workflow. The team at Splunk provide increased support and a higher level of stability so they can provide a curated experience helping you with your deployment needs.

## The Ninja Zone

Once you have all the required tools installed to get started, you will need to create a new file named `otelcol-builder.yaml` and we will follow this directory structure:

``` bash
.
└── otelcol-builder.yaml
```

Once we have the file created, we need to add a list of components for it to install with some additional metadata.

For this example, we are going to create a builder manifest that will install only the components we need for the introduction config:

```yaml
dist:
  name: otelcol-ninja
  description: A custom build of the Open Telemetry Collector
  output_path: ./dist

extensions:
- gomod: go.opentelemetry.io/collector/extension/ballastextension v0.80.0
- gomod: go.opentelemetry.io/collector/extension/zpagesextension  v0.80.0
- gomod: github.com/open-telemetry/opentelemetry-collector-contrib/extension/httpforwarder v0.80.0
- gomod: github.com/open-telemetry/opentelemetry-collector-contrib/extension/healthcheckextension v0.80.0

exporters:
- gomod: go.opentelemetry.io/collector/exporter/loggingexporter v0.80.0
- gomod: go.opentelemetry.io/collector/exporter/otlpexporter v0.80.0
- gomod: github.com/open-telemetry/opentelemetry-collector-contrib/exporter/splunkhecexporter v0.80.0
- gomod: github.com/open-telemetry/opentelemetry-collector-contrib/exporter/signalfxexporter v0.80.0
- gomod: github.com/open-telemetry/opentelemetry-collector-contrib/exporter/sapmexporter v0.80.0

processors:
- gomod: go.opentelemetry.io/collector/processor/batchprocessor v0.80.0
- gomod: go.opentelemetry.io/collector/processor/memorylimiterprocessor v0.80.0

receivers:
- gomod: go.opentelemetry.io/collector/receiver/otlpreceiver v0.80.0
- gomod: github.com/open-telemetry/opentelemetry-collector-contrib/receiver/hostmetricsreceiver v0.80.0
- gomod: github.com/open-telemetry/opentelemetry-collector-contrib/receiver/jaegerreceiver v0.80.0
- gomod: github.com/open-telemetry/opentelemetry-collector-contrib/receiver/prometheusreceiver v0.80.0
- gomod: github.com/open-telemetry/opentelemetry-collector-contrib/receiver/zipkinreceiver v0.80.0
```

Once the yaml file has been updated for the _ocb_, then run the following command:

```shell
ocb --config=otelcol-builder.yaml
```

Which leave you with the following directory structure:

``` text
├── dist
│   ├── components.go
│   ├── components_test.go
│   ├── go.mod
│   ├── go.sum
│   ├── main.go
│   ├── main_others.go
│   ├── main_windows.go
│   └── otelcol-ninja
└── otelcol-builder.yaml
```

### References

1. [https://opentelemetry.io/docs/collector/custom-collector/](https://opentelemetry.io/docs/collector/custom-collector/)

{{% /expand %}}

---

## Default configuration

OpenTelemetry is configured through YAML files. These files have default configurations that we can modify to meet our needs. Let's look at the default configuration that is supplied:

{{< tabs >}}
{{% tab title="Command" %}}

```bash
cat /etc/otelcol-contrib/config.yaml
```

{{% /tab %}}
{{% tab title="config.yaml" %}}

```yaml { lineNos="table" wrap="true"}
extensions:
  health_check:
  pprof:
    endpoint: 0.0.0.0:1777
  zpages:
    endpoint: 0.0.0.0:55679

receivers:
  otlp:
    protocols:
      grpc:
      http:

  opencensus:

  # Collect own metrics
  prometheus:
    config:
      scrape_configs:
      - job_name: 'otel-collector'
        scrape_interval: 10s
        static_configs:
        - targets: ['0.0.0.0:8888']

  jaeger:
    protocols:
      grpc:
      thrift_binary:
      thrift_compact:
      thrift_http:

  zipkin:

processors:
  batch:

exporters:
  logging:
    verbosity: detailed

service:

  pipelines:

    traces:
      receivers: [otlp, opencensus, jaeger, zipkin]
      processors: [batch]
      exporters: [logging]

    metrics:
      receivers: [otlp, opencensus, prometheus]
      processors: [batch]
      exporters: [logging]

  extensions: [health_check, pprof, zpages]
```

{{% /tab %}}
{{< /tabs >}}

Congratulations! You have successfully downloaded and installed the OpenTelemetry Collector. You are well on your way to becoming an OTel Ninja. But first lets walk through configuration files and different distributions of the OpenTelemetry Collector.

{{% notice style="note" %}}

Splunk does provide its own, fully supported, distribution of the OpenTelemetry Collector. This distribution is available to install from the [Splunk GitHub Repository](https://github.com/signalfx/splunk-otel-collector) or via a wizard in Splunk Observability Cloud that will build out a simple installation script to copy and paste. This distribution includes a number of additional features and enhancements that are not available in the OpenTelemetry Collector Contrib distribution.

- The Splunk Distribution of the OpenTelemetry Collector is production tested; it is in use by the majority of customers in their production environments.
- Customers that use our distribution can receive direct help from official Splunk support within SLA's.
- Customers can use or migrate to the Splunk Distribution of the OpenTelemetry Collector without worrying about future breaking changes to its core configuration experience for metrics and traces collection (OpenTelemetry logs collection configuration is in beta). There may be breaking changes to the Collector's own metrics.

{{% /notice %}}

We will now walk through each section of the configuration file and modify it to send host metrics to Splunk Observability Cloud.
