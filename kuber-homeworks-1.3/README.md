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
/ # 
```