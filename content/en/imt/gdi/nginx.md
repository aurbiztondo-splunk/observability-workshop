---
title: Deploying NGINX in K3s
linkTitle: 2.1 Deploy NGINX
menuPost: " <i class='fa fa-user-ninja'></i>"
weight: 3
---

* Deploy a NGINX ReplicaSet into your K3s cluster and confirm the discovery of your NGINX deployment.
* Run a load test to create metrics and confirm them streaming into Splunk Observability Cloud!

---

## 1. Start your NGINX

Verify the number of pods running in the Splunk UI by selecting the **WORKLOADS** tab. This should give you an overview of the workloads on your cluster.

![Workload Agent](../../images/k8s-workloads.png)

Note the single agent container running per node among the default Kubernetes pods. This single container will monitor all the pods and services being deployed on this node!

Now switch back to the default cluster node view by selecting the **MAP** tab and select your cluster again.

In your AWS/EC2 or Multipass shell session change into the `nginx` directory:

{{< tabs >}}
{{% tab title="Change Directory" %}}

```bash
cd ~/workshop/k3s/nginx
```

{{% /tab %}}
{{< /tabs >}}
  
---

## 2. Create NGINX deployment

Create the NGINX ConfigMap[^1] using the `nginx.conf` file:

{{< tabs >}}
{{% tab title="Kubectl Configmap Create" %}}

```bash
kubectl create configmap nginxconfig --from-file=nginx.conf
```

{{% /tab %}}
{{% tab title="Kubectl Create Configmap Output" %}}
configmap/nginxconfig created
{{% /tab %}}
{{< /tabs >}}

Then create the deployment:

{{< tabs >}}
{{% tab title="Kubectl Create Deployment" %}}

```bash
kubectl create -f nginx-deployment.yaml
```

{{% /tab %}}
{{% tab title="Kubectl Create Deployment Output" %}}
deployment.apps/nginx created
service/nginx created
{{% /tab %}}
{{< /tabs >}}

Next we will deploy Locust[^2] which is an open source tool used for creating a load test against NGINX:

{{< tabs >}}
{{% tab title="Kubectl Create Deployment" %}}

```bash
kubectl create -f locust-deployment.yaml
```

{{% /tab %}}
{{% tab title="Kubectl Create Deployment Output" %}}
deployment.apps/nginx-loadgenerator created
service/nginx-loadgenerator created
{{% /tab %}}
{{< /tabs >}}

Validate the deployment has been successful and that the Locust and NGINX pods are running.

If you have the Splunk UI open you should see new Pods being started and containers being deployed.

It should only take around 20 seconds for the pods to transition into a Running state. In the Splunk UI you will have a cluster that looks like below:

![back to Cluster](../../images/cluster.png)

If you select the **WORKLOADS** tab again you will now see that there is a new ReplicaSet and a deployment added for NGINX:

![NGINX loaded](../../images/k8s-workloads-nginx.png)

---

Let's validate this in your shell as well:

{{< tabs >}}
{{% tab title="Kubectl Get Pods" %}}

```bash
kubectl get pods
```

{{% /tab %}}
{{% tab title="Kubectl Get Pods Output" %}}
NAME                                                          READY   STATUS    RESTARTS   AGE
splunk-otel-collector-k8s-cluster-receiver-77784c659c-ttmpk   1/1     Running   0          9m19s
splunk-otel-collector-agent-249rd                             1/1     Running   0          9m19s
svclb-nginx-vtnzg                                             1/1     Running   0          5m57s
nginx-7b95fb6b6b-7sb9x                                        1/1     Running   0          5m57s
nginx-7b95fb6b6b-lnzsq                                        1/1     Running   0          5m57s
nginx-7b95fb6b6b-hlx27                                        1/1     Running   0          5m57s
nginx-7b95fb6b6b-zwns9                                        1/1     Running   0          5m57s
svclb-nginx-loadgenerator-nscx4                               1/1     Running   0          2m20s
nginx-loadgenerator-755c8f7ff6-x957q                          1/1     Running   0          2m20s
{{% /tab %}}
{{< /tabs >}}

---

## 3. Run Locust load test

Locust, an open source load generator, is available on port 8080 of the EC2 instance's IP address. Open a new tab in your web browser and go to `http://{==EC2-IP==}:8080/`, you will then be able to see the Locust running.

![Locust](../../images/nginx-locust.png)

Set the **Spawn rate** to be 2 and click **Start Swarming**.

![Locust Spawn Rate](../../images/nginx-locust-spawn-rate.png)

This will start a gentle continuous load on the application.

![Locust Statistics](../../images/nginx-locust-statistics.png)

As you can see from the above screenshot, most of the calls will report a fail, this is expected, as we have not yet deployed the application behind it, however NGINX is reporting on your attempts and you should be able to see those metrics.  

Validate you are seeing those metrics in the UI by selecting **Dashboards → Built-in Dashboard Groups  → NGINX → NGINX Servers**. Using the **Overrides** filter on `k8s.cluster.name:`, find the name of your cluster as returned by `echo $(hostname)-k3s-cluster` in the terminal.

![NGINX Dashboard](../../images/nginx-dashboard.png)

[^1]: A ConfigMap is an API object used to store non-confidential data in key-value pairs. Pods can consume ConfigMaps as environment variables, command-line arguments, or as configuration files in a volume. A ConfigMap allows you to decouple environment-specific configuration from your container images, so that your applications are easily portable.

[^2]: [What is Locust?](https://locust.io/)
