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

Stop containers:

```bash
docker-compose stop
```

Cleanup:

```bash
docker-compose down -v -t 0 && \
docker rmi -f abrarov/haproxy-test-backend && \
docker rmi -f abrarov/haproxy-test-balancer
```
