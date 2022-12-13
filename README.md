# Testing HAProxy

Prerequisites:

1. Docker 1.12.3+
1. Docker Compose

Start containers:

```bash
docker-compose up -d
```

Add one more backend server:

```bash
docker-compose up -d --scale backend=2 --no-recreate
```

Check output of balancer:

```bash
curl -s http://localhost
```

Output of balancer should look like:

```html
<!DOCTYPE html>
<html>
<head>
<title>Backend</title>
</head>
<body>
hostname
</body>
</html>
```

where `hostname` is the name of backend host which actually served request.

Ensure that if output is requested multiple times then different `hostname` is returned.

Invoke Prometheus Blackbox exporter probes by running

```bash
curl -s 'http://localhost:9115/probe?target=backend%3A8080&module=http'
```

multiple times.

Ensure that Blackbox exporter tries all IPs it was able to resolve:

1. Check address resolving log records of Blackbox exporter

    ```bash
    docker-compose logs blackbox | grep -F 'Resolved target address'
    ```

    expected output looks like (contains different values in `ip=` part of the log records)

    ```text
    blackbox_1  | ts=2022-08-18T06:03:23.846Z caller=main.go:212 module=http target=backend:8080 level=debug msg="Resolved target address" target=backend ip=172.19.0.2
    blackbox_1  | ts=2022-08-18T06:03:53.863Z caller=main.go:212 module=http target=backend:8080 level=debug msg="Resolved target address" target=backend ip=172.19.0.4
    ```

1. Check access log of backend and ensure that all backends are hit by Blackbox exporter

    ```bash
    docker-compose logs backend | grep blackbox
    ```

    expected output looks like (includes all backends)

    ```text
    backend_1   | [access] 172.19.0.3 - - [18/Aug/2022:06:03:06 +0000] "GET / HTTP/1.1" 200 97 "-" "blackbox" "-"
    backend_2   | [access] 172.19.0.3 - - [18/Aug/2022:06:04:23 +0000] "GET / HTTP/1.1" 200 97 "-" "blackbox" "-"
    ```

Stop containers:

```bash
docker-compose stop
```

Cleanup:

```bash
docker-compose down -v -t 0 && \
docker rmi -f abrarov/haproxy-test-backend && \
docker rmi -f abrarov/haproxy-test-balancer && \
docker rmi -f abrarov/haproxy-test-blackbox
```

Testing with K8s

Build images

```bash
docker build -t abrarov/haproxy-test-backend backend && \
docker build -t abrarov/haproxy-test-blackbox blackbox
```

Install kubectl, Helm and Minikube

```bash
k8s_version='1.24.4' && \
curl -Ls "https://storage.googleapis.com/kubernetes-release/release/v${k8s_version}/bin/linux/amd64/kubectl" \
  | sudo tee /usr/local/bin/kubectl > /dev/null && \
sudo chmod +x /usr/local/bin/kubectl && \
helm_version='3.9.3' && \
curl -Ls "https://get.helm.sh/helm-v${helm_version}-linux-amd64.tar.gz" \
  | sudo tar -xz --strip-components=1 -C /usr/local/bin "linux-amd64/helm" && \
minikube_version='1.26.1' && \
curl -Ls "https://github.com/kubernetes/minikube/releases/download/v${minikube_version}/minikube-linux-amd64.tar.gz" \
  | tar -xzO --strip-components=1 "out/minikube-linux-amd64" \
  | sudo tee /usr/local/bin/minikube > /dev/null && \
sudo chmod +x /usr/local/bin/minikube
```

Start K8s

```bash
minikube start --driver=docker --addons=ingress,registry,dashboard
```

Push built images into K8s internal image registry

```bash
minikube_registry="$(minikube ip):5000" && \
docker tag abrarov/haproxy-test-backend "${minikube_registry}/backend" && \
docker tag abrarov/haproxy-test-blackbox "${minikube_registry}/blackbox" && \
docker push "${minikube_registry}/backend" && \
docker push "${minikube_registry}/blackbox"
```

Run containers with Helm chart

```bash
k8s_namespace='default' && \
k8s_app='blackbox-test' && \
helm_release='blackbox-test' && \
backend_hostname='backend.local' && \
blackbox_hostname='blackbox.local' && \
helm upgrade "${helm_release}" helm/blackbox-test \
  -n "${k8s_namespace}" \
  --set nameOverride="${k8s_app}" \
  --set backend.image.registry='localhost:5000' \
  --set backend.image.repository='backend' \
  --set backend.ingress.host="${backend_hostname}" \
  --set blackbox.image.registry='localhost:5000' \
  --set blackbox.image.repository='blackbox' \
  --set blackbox.image.tag='latest' \
  --set blackbox.ingress.host="${blackbox_hostname}" \
  --install --wait
```

Access application (multiple times)

```bash
curl -s --resolve "${backend_hostname}:80:$(minikube ip)" "http://${backend_hostname}"
```

Access Blackbox exporter

```bash
curl -s --resolve "${blackbox_hostname}:80:$(minikube ip)" "http://${blackbox_hostname}"
```

Run Blackbox exporter probe (multiple times)

```bash
curl -s --resolve "${blackbox_hostname}:80:$(minikube ip)" "http://${blackbox_hostname}/probe?target=${helm_release}-backend.${k8s_namespace}.svc%3A8080&module=http"
```

Check the logs of Blackbox exporter

```bash
pod_name="$(kubectl -n "${k8s_namespace}" get pods \
  -l "app.kubernetes.io/name=${k8s_app}" \
  -l "app.kubernetes.io/component=blackbox" \
  -o jsonpath={..metadata.name})" && \
kubectl -n "${k8s_namespace}" logs "${pod_name}" | grep -F 'Resolved target address'
```

Check the logs of application

```bash
for pod_name in $(kubectl -n "${k8s_namespace}" get pods \
  -l "app.kubernetes.io/name=${k8s_app}" \
  -l "app.kubernetes.io/component=backend" \
  -o jsonpath={..metadata.name}); do \
  echo "Pod: ${pod_name}" && \
  kubectl -n "${k8s_namespace}" logs "${pod_name}" | grep -F blackbox ; \
done
```

Remove containers and images from K8s

```bash
helm uninstall "${helm_release}" -n "${k8s_namespace}" && \
minikube_registry="$(minikube ip):5000" && \
docker rmi "${minikube_registry}/backend" && \
docker rmi "${minikube_registry}/blackbox"
```

Stop and delete K8s

```bash
minikube delete --purge=true && \
rm -rf ~/.kube
```

Testing with OpenShift Origin 3.11

Install oc command line tool

```bash
openshift_version='3.11.0' && openshift_build='0cbc58b' && \
curl -Ls "https://github.com/openshift/origin/releases/download/v${openshift_version}/openshift-origin-client-tools-v${openshift_version}-${openshift_build}-linux-64bit.tar.gz" \
  | sudo tar -xz --strip-components=1 -C /usr/bin "openshift-origin-client-tools-v${openshift_version}-${openshift_build}-linux-64bit/oc"
```

Configure Docker insecure registry for 172.30.0.0/16 subnet, e.g. add into /etc/docker/daemon.json file:

```json
{
  "insecure-registries": ["172.30.0.0/16"]
}
```

Restart Docker daemon. e.g.

```bash
sudo systemctl restart docker
```

Setup local OpenShift Origin single node cluster

```bash
openshift_address="$(ip address show \
  | sed -r 's/^[[:space:]]*inet (192(\.[0-9]{1,3}){3})\/[0-9]+ brd (([0-9]{1,3}\.){3}[0-9]{1,3}) scope global .*$/\1/;t;d' \
  | head -n 1)" && \
oc cluster up \
  --base-dir="${HOME}/openshift.local.clusterup" \
  --public-hostname="${openshift_address}" \
  --enable="router,web-console"
```

Run containers with Helm chart

```bash
openshift_user='developer' && \
openshift_password='developer' && \
k8s_namespace='myproject' && \
k8s_app='blackbox-test' && \
helm_release='blackbox-test' && \
backend_hostname='backend.local' && \
blackbox_hostname='blackbox.local' && \
oc login -u "${openshift_user}" -p "${openshift_password}" \
  --insecure-skip-tls-verify=true "${openshift_address}:8443" && \
helm upgrade "${helm_release}" helm/blackbox-test \
  -n "${k8s_namespace}" \
  --set nameOverride="${k8s_app}" \
  --set backend.ingress.host="${backend_hostname}" \
  --set blackbox.image.repository="abrarov/haproxy-test-blackbox" \
  --set blackbox.image.tag='latest' \
  --set blackbox.ingress.host="${blackbox_hostname}" \
  --install --wait
```

Access application (multiple times)

```bash
curl -s --resolve "${backend_hostname}:80:${openshift_address}" "http://${backend_hostname}"
```

Access Blackbox exporter

```bash
curl -s --resolve "${blackbox_hostname}:80:${openshift_address}" "http://${blackbox_hostname}"
```

Run Blackbox exporter probe (multiple times)

```bash
curl -s --resolve "${blackbox_hostname}:80:${openshift_address}" "http://${blackbox_hostname}/probe?target=${helm_release}-backend.${k8s_namespace}.svc%3A8080&module=http"
```

Check the logs of Blackbox exporter

```bash
pod_name="$(kubectl -n "${k8s_namespace}" get pods \
  -l "app.kubernetes.io/name=${k8s_app}" \
  -l "app.kubernetes.io/component=blackbox" \
  -o jsonpath={..metadata.name})" && \
kubectl -n "${k8s_namespace}" logs "${pod_name}" | grep -F 'Resolved target address'
```

Check the logs of application

```bash
for pod_name in $(kubectl -n "${k8s_namespace}" get pods \
  -l "app.kubernetes.io/name=${k8s_app}" \
  -l "app.kubernetes.io/component=backend" \
  -o jsonpath={..metadata.name}); do \
  echo "Pod: ${pod_name}" && \
  kubectl -n "${k8s_namespace}" logs "${pod_name}" | grep -F blackbox ; \
done
```

Run Blackbox exporter probe (multiple times)

```bash
curl -s --resolve "${blackbox_hostname}:80:${openshift_address}" "http://${blackbox_hostname}/probe?target=${helm_release}-backend.${k8s_namespace}.svc%3A8080&module=http_random_ip"
```

Check the logs of Blackbox exporter

```bash
pod_name="$(kubectl -n "${k8s_namespace}" get pods \
  -l "app.kubernetes.io/name=${k8s_app}" \
  -l "app.kubernetes.io/component=blackbox" \
  -o jsonpath={..metadata.name})" && \
kubectl -n "${k8s_namespace}" logs "${pod_name}" | grep -F 'Resolved target address'
```

Check the logs of application

```bash
for pod_name in $(kubectl -n "${k8s_namespace}" get pods \
  -l "app.kubernetes.io/name=${k8s_app}" \
  -l "app.kubernetes.io/component=backend" \
  -o jsonpath={..metadata.name}); do \
  echo "Pod: ${pod_name}" && \
  kubectl -n "${k8s_namespace}" logs "${pod_name}" | grep -F blackbox ; \
done
```

Remove containers from OpenShift

```bash
oc login -u "${openshift_user}" -p "${openshift_password}" \
  --insecure-skip-tls-verify=true "${openshift_address}:8443" && \
helm uninstall "${helm_release}" -n "${k8s_namespace}"
```

Stop and delete OpenShift

```bash
oc cluster down && \
for openshift_mount in $(mount | grep openshift | awk '{ print $3 }'); do \
  echo "Unmounting ${openshift_mount}" && sudo umount "${openshift_mount}"; \
done && \
sudo rm -rf "${HOME}/openshift.local.clusterup"
```
