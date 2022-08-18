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
curl -s 'http://localhost:9115/probe?target=backend:8080&module=http_2xx'
```

multiple times.

Ensure that Blackbox exporter tries all IPs it was able to resolve:

1. Check address resolving log records of Blackbox exporter

    ```bash
    docker-compose logs blackbox | grep -F 'Resolved target address'
    ```

    expected output looks like (contains different values in `ip=` part of the log records)

    ```text
    blackbox_1  | ts=2022-08-18T06:03:23.846Z caller=main.go:212 module=http_2xx target=backend:8080 level=debug msg="Resolved target address" target=backend ip=172.19.0.2
    blackbox_1  | ts=2022-08-18T06:03:53.863Z caller=main.go:212 module=http_2xx target=backend:8080 level=debug msg="Resolved target address" target=backend ip=172.19.0.4
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
