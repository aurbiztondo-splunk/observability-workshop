---
title: OpenTelemetry Collector Service
linkTitle: 6. Service
weight: 6
---

The **Service** section is used to configure what components are enabled in the Collector based on the configuration found in the receivers, processors, exporters, and extensions sections. If a component is configured, but not defined within the service section then it is not enabled. The service section consists of three sub-sections:

- extensions
- pipelines
- telemetry

In the default configuration the extension section has been configured to enable `health_check`, `pprof` and `zpages` which we configured in the Extensions module earlier.

``` yaml
service:
  extensions: [health_check, pprof, zpages]
```

## Configure Metric Pipeline

### Hostmetrics Receiver

Earlier in the workshop we defined the [Host Metrics Receiver](../3-receivers/#host-metrics-receiver) to generate metrics about the host system scraped from various sources. We now need to enabled this under the metrics pipeline. Update the `receivers` section to include `hostmetrics` under the `metrics` pipeline.

```yaml {hl_lines=[11]}
service:

  pipelines:

    traces:
      receivers: [otlp, opencensus, jaeger, zipkin]
      processors: [batch]
      exporters: [logging]

    metrics:
      receivers: [hostmetrics, otlp, opencensus, prometheus]
      processors: [batch]
      exporters: [logging]
```

### Prometheus Internal Receiver

We renamed the `prometheus` receiver to reflect that is was collecting metrics internal to the collector. We now need to enable this under the metrics pipeline. Update the `receivers` section to include `prometheus/internal` under the `metrics` pipeline.

```yaml {hl_lines=[11]}
service:

  pipelines:

    traces:
      receivers: [otlp, opencensus, jaeger, zipkin]
      processors: [batch]
      exporters: [logging]

    metrics:
      receivers: [hostmetrics, otlp, opencensus, prometheus/internal]
      processors: [batch]
      exporters: [logging]
```

### Resource Detection Processor

The `resourcedetection` processor was added so that the collector could capture the hostname of the instance upon which it is installed and running. We now need to enable this under the metrics pipeline. Update the `processors` section to include `resourcedetection` under the `metrics` pipeline.

```yaml {hl_lines=[12]}
service:

  pipelines:

    traces:
      receivers: [otlp, opencensus, jaeger, zipkin]
      processors: [batch]
      exporters: [logging]

    metrics:
      receivers: [hostmetrics, otlp, opencensus, prometheus/internal]
      processors: [batch, resourcedetection]
      exporters: [logging]
```

### OTLPHTTP Exporter

We configured the `otlphttp` exporter to send metrics to Splunk Observability Cloud. We now need to enable this under the metrics pipeline. Update the `exporters` section to include `otlphttp/splunk` under the `metrics` pipeline.

```yaml {hl_lines=[13]}
service:

  pipelines:

    traces:
      receivers: [otlp, opencensus, jaeger, zipkin]
      processors: [batch]
      exporters: [logging]

    metrics:
      receivers: [hostmetrics, otlp, opencensus, prometheus/internal]
      processors: [batch, resourcedetection]
      exporters: [logging, otlphttp/splunk]
```

## Final configuration

The final configuration should look like this:

``` yaml
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
  resourcedetection:
    detectors: [system]
    system:
      hostname_sources: [os]

exporters:
  logging:
    verbosity: normal
  otlphttp/splunk:
    metrics_endpoint: https://ingest.us1.signalfx.com/v2/datapoint/otlp
    headers:
      X-SF-TOKEN: <TOKEN REDACTED>

service:

  pipelines:

    traces:
      receivers: [otlp, opencensus, jaeger, zipkin]
      processors: [batch]
      exporters: [logging]

    metrics:
      receivers: [hostmetrics, otlp, opencensus, prometheus/internal]
      processors: [batch, resourcedetection]
      exporters: [logging, otlphttp/splunk]

  extensions: [health_check, pprof, zpages]
```

Now that we have a working configuration, let's restart the collector and then check to see what [zPages](../2-extensions/#zpages) is reporting.

``` bash
sudo systemctl restart otelcol-contrib
```

![pipelinez-full-config](../images/pipelinez-full-config.png)
