# Домашнее задание к занятию «Запуск приложений в K8S»

<details>
  <summary><b>Задание 1. Создать Deployment и обеспечить доступ к репликам приложения из другого Pod</b></summary>

1. Создать Deployment приложения, состоящего из двух контейнеров — nginx и multitool. Решить возникшую ошибку.
2. После запуска увеличить количество реплик работающего приложения до 2.
3. Продемонстрировать количество подов до и после масштабирования.
4. Создать Service, который обеспечит доступ до реплик приложений из п.1.
5. Создать отдельный Pod с приложением multitool и убедиться с помощью `curl`, что из пода есть доступ до приложений из п.1.

</details>

## Ответ

### 1. Создать Deployment приложения, состоящего из двух контейнеров — nginx и multitool. Решить возникшую ошибку.

Ошибка возникает из-за того, что в состав образа multitool так же входит веб-сервер nginx и по умолчанию он поднимается на таких же портах - 80, 443. Согласно документации для поднятия на кастомных портах нужно задать переменные HTTP_PORT, HTTPS_PORT.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
      - name: multitool
        image: wbitt/network-multitool
        ports:
        - containerPort: 1180
        env:
        - name: HTTP_PORT
          value: "1180"
        - name: HTTPS_PORT
          value: "11443"
```

### 2. После запуска увеличить количество реплик работающего приложения до 2.

### 3. Продемонстрировать количество подов до и после масштабирования.

```bash
D:\VM\Netology_vagrant\k8s_yamls> .\kubectl get pods
NAME                               READY   STATUS    RESTARTS   AGE
nginx-deployment-67b6fff8f-vz5zk   2/2     Running   0          8m4s
D:\VM\Netology_vagrant\k8s_yamls> .\kubectl scale --replicas=2 deployment nginx-deployment
deployment.apps/nginx-deployment scaled
D:\VM\Netology_vagrant\k8s_yamls> .\kubectl get pods
NAME                               READY   STATUS    RESTARTS   AGE 
nginx-deployment-67b6fff8f-vz5zk   2/2     Running   0          21m 
nginx-deployment-67b6fff8f-6zljb   2/2     Running   0          114s
```

### 4. Создать Service, который обеспечит доступ до реплик приложений из п.1.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: sr-nginx-deployment
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      name: nginx-tcp
      port: 80
      targetPort: 80
    - protocol: TCP
      name: multitool-tcp
      port: 1180
      targetPort: 1180
```

### 5. Создать отдельный Pod с приложением multitool и убедиться с помощью `curl`, что из пода есть доступ до приложений из п.1.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pd-multic
spec:
  containers:
  - name: multic
    image: wbitt/network-multitool
    ports:
    - containerPort: 80
```

```bash
PS D:\VM\Netology_vagrant\k8s_yamls> .\kubectl exec --stdin --tty pd-multic -- /bin/sh
/ # curl -v http://sr-nginx-deployment:80
* processing: http://sr-nginx-deployment:80
*   Trying 10.152.183.244:80...
* Connected to sr-nginx-deployment (10.152.183.244) port 80
> GET / HTTP/1.1
> Host: sr-nginx-deployment
> User-Agent: curl/8.2.1
> Accept: */*
>
< HTTP/1.1 200 OK
< Server: nginx/1.14.2
< Date: Sat, 10 Feb 2024 15:04:32 GMT
< Content-Type: text/html
< Content-Length: 612
< Last-Modified: Tue, 04 Dec 2018 14:44:49 GMT
< Connection: keep-alive
< ETag: "5c0692e1-264"
< Accept-Ranges: bytes
<
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
* Connection #0 to host sr-nginx-deployment left intact
```

<details>
  <summary><b>Задание 2. Создать Deployment и обеспечить старт основного контейнера при выполнении условий</b></summary>

1. Создать Deployment приложения nginx и обеспечить старт контейнера только после того, как будет запущен сервис этого приложения.
2. Убедиться, что nginx не стартует. В качестве Init-контейнера взять busybox.
3. Создать и запустить Service. Убедиться, что Init запустился.
4. Продемонстрировать состояние пода до и после запуска сервиса.

</details>

## Ответ

### 1. Создать Deployment приложения nginx и обеспечить старт контейнера только после того, как будет запущен сервис этого приложения.

### 2. Убедиться, что nginx не стартует. В качестве Init-контейнера взять busybox.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: read-nginx
  labels:
    app: r_nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: r_nginx
  template:
    metadata:
      labels:
        app: r_nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
      initContainers:
      - name: init-web
        image: busybox:1.28
        command: ['sh', '-c', "until nslookup webservice.$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace).svc.cluster.local; do echo waiting for myservice; sleep 2; done"]
```

```bash
PS D:\VM\Netology_vagrant\k8s_yamls> .\kubectl get pod
NAME                               READY   STATUS     RESTARTS      AGE
nginx-deployment-67b6fff8f-vz5zk   2/2     Running    2 (21m ago)   18h
nginx-deployment-67b6fff8f-6zljb   2/2     Running    2 (21m ago)   18h
pd-multic                          1/1     Running    1 (21m ago)   18h
read-nginx-d9999b84-c55ng          0/1     Init:0/1   0             99s
```

```bash
PS D:\VM\Netology_vagrant\k8s_yamls> .\kubectl describe pod read-nginx-d9999b84-c55ng
Name:             read-nginx-d9999b84-c55ng
Namespace:        default
...
Init Containers:
  init-web:
    Container ID:  containerd://e7d9dab5e28d9b757d7e7dd00ca1c5d9def5c8b64c78070fb7ef5ac792300942
    Image:         busybox:1.28
    Image ID:      docker.io/library/busybox@sha256:141c253bc4c3fd0a201d32dc1f493bcf3fff003b6df416dea4f41046e0f37d47
    Port:          <none>
    Host Port:     <none>
    Command:
      sh
      -c
      until nslookup webservice.$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace).svc.cluster.local; do echo waiting for myservice; sleep 2; done
    State:          Running
      Started:      Sun, 11 Feb 2024 12:15:19 +0300
...
Containers:
  nginx:
    Container ID:
    Image:          nginx:1.14.2
    Image ID:
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Waiting
      Reason:       PodInitializing
    Ready:          False
    Restart Count:  0
    Readiness:      http-get http://:80/ delay=0s timeout=1s period=10s #success=1 #failure=3
...
```

### 3. Создать и запустить Service. Убедиться, что Init запустился.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: webservice
spec:
  selector:
    app: r_nginx
  ports:
    - protocol: TCP
      name: tcp
      port: 80
      targetPort: 80
```

```bash
PS D:\VM\Netology_vagrant\k8s_yamls> .\kubectl get pod
NAME                               READY   STATUS    RESTARTS      AGE
nginx-deployment-67b6fff8f-vz5zk   2/2     Running   2 (25m ago)   19h
nginx-deployment-67b6fff8f-6zljb   2/2     Running   2 (25m ago)   18h
pd-multic                          1/1     Running   1 (25m ago)   18h
read-nginx-d9999b84-c55ng          1/1     Running   0             5m28s
```

### 4. Продемонстрировать состояние пода до и после запуска сервиса.

```bash
PS D:\VM\Netology_vagrant\k8s_yamls> .\kubectl describe pod read-nginx-d9999b84-c55ng
Name:             read-nginx-d9999b84-c55ng
Namespace:        default
Priority:         0
Service Account:  default
Node:             first/10.0.2.15
Start Time:       Sun, 11 Feb 2024 12:14:57 +0300
Labels:           app=r_nginx
...
Init Containers:
  init-web:
    Container ID:  containerd://e7d9dab5e28d9b757d7e7dd00ca1c5d9def5c8b64c78070fb7ef5ac792300942
    Image:         busybox:1.28
    Image ID:      docker.io/library/busybox@sha256:141c253bc4c3fd0a201d32dc1f493bcf3fff003b6df416dea4f41046e0f37d47
    Port:          <none>
    Host Port:     <none>
    Command:
      sh
      -c
      until nslookup webservice.$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace).svc.cluster.local; do echo waiting for myservice; sleep 2; done
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Sun, 11 Feb 2024 12:15:19 +0300
      Finished:     Sun, 11 Feb 2024 12:20:03 +0300
...
Containers:
  nginx:
    Container ID:   containerd://d1295dba2da440a1ef97a7c91cfd7c690c41f78ae48890d13bfd9909d87d646d
    Image:          nginx:1.14.2
    Image ID:       docker.io/library/nginx@sha256:f7988fb6c02e0ce69257d9bd9cf37ae20a60f1df7563c3a2a6abe24160306b8d
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Sun, 11 Feb 2024 12:20:12 +0300
    Ready:          True
    Restart Count:  0
    Readiness:      http-get http://:80/ delay=0s timeout=1s period=10s #success=1 #failure=3
    Environment:    <none>
...
```