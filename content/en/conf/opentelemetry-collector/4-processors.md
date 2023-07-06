---
title: OpenTelemetry Collector Processors
linkTitle: 4. Processors
weight: 4
---

[**Processors**](https://github.com/open-telemetry/opentelemetry-collector/blob/main/processor/README.md) are run on data between being received and being exported. Processors are optional though some are recommended. There are [a large number of processors](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor) included in the OpenTelemetry contrib Collector.

{{< mermaid >}}
%%{
  init:{
    "theme":"base",
    "themeVariables": {
      "primaryColor": "#ffffff",
      "clusterBkg": "#eff2fb",
      "defaultLinkColor": "#333333"
    }
  }
}%%

flowchart LR;
    style Processors fill:#e20082,stroke:#333,stroke-width:4px,color:#fff
    subgraph Collector
    A[OTLP] --> M(Receivers)
    B[JAEGER] --> M(Receivers)
    C[Prometheus] --> M(Receivers)
    end
    subgraph Processors
    M(Receivers) --> H(Filters, Attributes, etc)
    E(Extensions)
    end
    subgraph Exporters
    H(Filters, Attributes, etc) --> S(OTLP)
    H(Filters, Attributes, etc) --> T(JAEGER)
    H(Filters, Attributes, etc) --> U(Prometheus)
    end
{{< /mermaid >}}

## Batch Processor

By default, only the **batch** processor is enabled. This processor is used to batch up data before it is exported. This is useful for reducing the number of network calls made to exporters. For this workshop we will accept the defaults:

- `send_batch_size` (default = 8192): Number of spans, metric data points, or log records after which a batch will be sent regardless of the timeout. send_batch_size acts as a trigger and does not affect the size of the batch. If you need to enforce batch size limits sent to the next component in the pipeline see send_batch_max_size.
- `timeout` (default = 200ms): Time duration after which a batch will be sent regardless of size. If set to zero, send_batch_size is ignored as data will be sent immediately, subject to only send_batch_max_size.
- `send_batch_max_size` (default = 0): The upper limit of the batch size. 0 means no upper limit of the batch size. This property ensures that larger batches are split into smaller units. It must be greater than or equal to send_batch_size.

## Resource Detection Processor

The **resourcedetection** processor can be used to detect resource information from the host and append or override the resource value in telemetry data with this information.

By default, the hostname is set to the FQDN if possible, otherwise the hostname provided by the OS is used as a fallback. This logic can be changed from using using the `hostname_sources` configuration option. To avoid getting the FQDN and use the hostname provided by the OS, we will set the `hostname_sources` to `os`.

{{% tab title="System Resource Detection Processor Configuration" %}}

``` yaml {hl_lines="3-7"}
processors:
  batch:
  resourcedetection/system:
    detectors: [system]
    system:
      hostname_sources: [os]
```

{{% /tab %}}

If the workshop instance is running on an AWS/EC2 instance we can gather the following tags from the EC2 metadata API (this is not available on other platforms).

- `cloud.provider ("aws")`
- `cloud.platform ("aws_ec2")`
- `cloud.account.id`
- `cloud.region`
- `cloud.availability_zone`
- `host.id`
- `host.image.id`
- `host.name`
- `host.type`

We will create another processor to append these tags to our metrics.

{{% tab title="EC2 Resource Detection Processor Configuration" %}}

``` yaml {hl_lines="7-8"}
processors:
  batch:
  resourcedetection/system:
    detectors: [system]
    system:
      hostname_sources: [os]
  resourcedetection/ec2:
    detectors: [ec2]
```

{{% /tab %}}

## Attributes Processor

The attributes processor modifies attributes of a span, log, or metric. This processor also supports the ability to filter and match input data to determine if they should be included or excluded for specified actions.

It takes a list of actions which are performed in order specified in the config. The supported actions are:

- `insert`: Inserts a new attribute in input data where the key does not already exist.
- `update`: Updates an attribute in input data where the key does exist.
- `upsert`: Performs insert or update. Inserts a new attribute in input data where the key does not already exist and updates an attribute in input data where the key does exist.
- `delete`: Deletes an attribute from the input data.
- `hash`: Hashes (SHA1) an existing attribute value.
- `extract`: Extracts values using a regular expression rule from the input key to target keys specified in the rule. If a target key already exists, it will be overridden.

We are going to create an attributes processor to `insert` a new attribute to all our host metrics called `conf.attendee.name` with a value of your own name e.g. `homer_simpson`.

{{% notice style="warning" %}}

Ensure you replace `INSERT_YOUR_NAME_HERE` with your own name and also ensure you **do not** use spaces in your name.

{{% /notice %}}

Later on in the workshop we will use this attribute to filter our metrics in Splunk Observability Cloud.

{{% tab title="Attributes Processor Configuration" %}}

``` yaml {hl_lines="9-13"}
processors:
  batch:
  resourcedetection/system:
    detectors: [system]
    system:
      hostname_sources: [os]
  resourcedetection/ec2:
    detectors: [ec2]
  attributes/conf:
    actions:
      - key: conf.attendee.name
        action: insert
        value: "INSERT_YOUR_NAME_HERE"
```

{{%/ tab %}}

---

{{% expand title="{{% badge style=primary icon=user-ninja %}}**Ninja:** Using connectors to gain internal insights{{% /badge %}}" %}}

One of the most recent additions to the collector was the notion of a [connector](https://opentelemetry.io/docs/collector/configuration/#connectors), which allows you to join output of one pipeline to input of another pipeline.

An example of how this is beneficial is that some services emit metrics based on the amount of datapoints being exported, number of logs containing an error status,
or the amount of data being sent from one deployment environment. The count connector helps address this for you out of the box.

## Why a connector instead of a processor?

A processor is limited in what additional data it can produce considering it has to pass on the data it has processed making it hard to expose additional information. Connectors do not have to emit the data they received which means they provide an opportunity to create those insights we are after.

For example, a connector could be made to count the number of logs, metrics, and traces that do not have the deployment environment attribute.

A very simple example with the output of being able to break down data usage by deployment environment.

## Considerations with connectors

A connector only accepts data exported from one pipeline and receiver by another pipeline, this means you may have to consider how you construct your collector config to take advantage of it.

## References

1. [https://opentelemetry.io/docs/collector/configuration/#connectors](https://opentelemetry.io/docs/collector/configuration/#connectors)
2. [https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/connector/countconnector](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/connector/countconnector)

{{% /expand %}}

---

## Configuration Check-in

That's processors covered, let's check our configuration changes.

---

{{% expand title="{{% badge icon=check color=green title=**Check-in** %}}Review your configuration{{% /badge %}}" %}}
{{< tabs >}}
{{% tab title="config.yaml" %}}

```yaml {lineNos="table" wrap="true" hl_lines="58-68"}
extensions:
  health_check:
    endpoint: 0.0.0.0:13133
  pprof:
    endpoint: 0.0.0.0:1777
  zpages:
    endpoint: 0.0.0.0:55679

receivers:
  hostmetrics:
    collection_interval: 10s
    scrapers:
      # CPU utilization metrics
      cpu:
      # Disk I/O metrics
      disk:
      # File System utilization metrics
      filesystem:
      # Memory utilization metrics
      memory:
      # Network interface I/O metrics & TCP connection metrics
      network:
      # CPU load metrics
      load:
      # Paging/Swap space utilization and I/O metrics
      paging:
      # Process count metrics
      processes:
      # Per process CPU, Memory and Disk I/O metrics. Disabled by default.
      # process:
  otlp:
    protocols:
      grpc:
      http:

  opencensus:

  # Collect own metrics
  prometheus/internal:
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
  resourcedetection/system:
    detectors: [system]
    system:
      hostname_sources: [os]
  resourcedetection/ec2:
    detectors: [ec2]
  attributes/conf:
    actions:
      - key: conf.attendee.name
        action: insert
        value: "INSERT_YOUR_NAME_HERE"

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
{{% /expand %}}

---
