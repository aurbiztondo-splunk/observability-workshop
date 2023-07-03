---
title: OpenTelemetry Collector Development
linkTitle: 8.3 Component Review
weight: 11
---

## Component Review

To recap the type of component we will need to in order to capture metrics from Jenkins:

{{% tabs %}}
{{% tab title="Extension" %}}
The business usecase an extension helps solves for are:

1. Having shared functionality that requires runtime configuration
1. Indirectly helps with observing the runtime of the collector

See [Extensions Overview](/en/conf/opentelemetry-collector/2-extensions) for more details.
{{% /tab %}}
{{% tab title="Receiver" %}}
The business usecase a receiver solves for:

- Fetching data from a remote source
- Receiving data from remote source(s)

This are commonly referred to _pull_ vs _push_ based data collection, and you read more about the details in the [Receiver Overview](/en/conf/opentelemetry-collector/3-receivers).
{{% /tab %}}
{{% tab title="Processor" %}}
The business usecase a processor solves for is:

- Adding or removing data, fields, or values
- Observing and making decisions on the data
- Buffering, queueing, and reorodering

The thing to keep in mind that the data type flowing through a processor needs to use the forward
the same data type to its downstream components.
Read through [Processor Overview](/en/conf/opentelemetry-collector/4-processors) for the details.
{{% /tab %}}
{{% tab title="Exporter" %}}
The business usecase an exporter solves for:

- Send the data to a tool, service, or storage

The OpenTelemetry collector does not want to be "backend", an all in one observability suite, but rather
keep to the principles that founded OpenTelemetry to begin with; A vendor agnostic Observability for all.
To help revist the details, please read through [Exporter Overview](/en/conf/opentelemetry-collector/5-exporters).

{{% /tab %}}
{{% tab title="{{% badge style=primary icon=user-ninja %}}**Ninja:** Connectors{{% /badge %}}"  %}}

This is a component type that was missed in the workshop since it is a relatively new addition to the collector,
but the best way to think about a connector is that it is like a processor that allows to be used across different
telemetry types, and pipelines. Meaning that a connector can accept data as logs, and output metrics, or accept
metrics from one pipeline and provide metrics on the data it has observed.

The business case that a connector solves for:

- Converting from different telemetry types
  - logs to metrics
  - traces to metrics
  - metrics to logs
- Observing incoming data and producing its own data
  - Accepting metrics and generating analytical metrics of the data.

There was a brief overview within the **Ninja** section as part of the [Processor Overview](/en/conf/opentelemetry-collector/4-processors),
and be sure what the project for updates for new connector components.
{{% /tab %}}
{{% /tabs %}}

From the component overviews, it is clear that developing a pull based receiver for Jenkins.
