# Домашнее задание к занятию «Сетевое взаимодействие в K8S. Часть 1»

<details>
  <summary><b>Задание 1. Создать Deployment и обеспечить доступ к контейнерам приложения по разным портам из другого Pod внутри кластера</b></summary>

1. Создать Deployment приложения, состоящего из двух контейнеров (nginx и multitool), с количеством реплик 3 шт.
2. Создать Service, который обеспечит доступ внутри кластера до контейнеров приложения из п.1 по порту 9001 — nginx 80, по 9002 — multitool 8080.
3. Создать отдельный Pod с приложением multitool и убедиться с помощью `curl`, что из пода есть доступ до приложения из п.1 по разным портам в разные контейнеры.
4. Продемонстрировать доступ с помощью `curl` по доменному имени сервиса.
5. Предоставить манифесты Deployment и Service в решении, а также скриншоты или вывод команды п.4.
</details>

## Ответ

### 1. Создать Deployment приложения, состоящего из двух контейнеров (nginx и multitool), с количеством реплик 3 шт.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
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
        - containerPort: 8080
        env:
        - name: HTTP_PORT
          value: "8080"
        - name: HTTPS_PORT
          value: "11443"
```

#### 2. Создать Service, который обеспечит доступ внутри кластера до контейнеров приложения из п.1 по порту 9001 — nginx 80, по 9002 — multitool 8080.

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
      port: 8080
      targetPort: 8080
```

### 3. Создать отдельный Pod с приложением multitool и убедиться с помощью `curl`, что из пода есть доступ до приложения из п.1 по разным портам в разные контейнеры.

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
PS D:\VM_RDP\Vagrant_learn\for_ansible\kubes> .\kubectl exec --stdin --tty pd-multic -- sh
/ # curl -v sr-nginx-deployment:80
* processing: sr-nginx-deployment:80
*   Trying 10.152.183.239:80...
* Connected to sr-nginx-deployment (10.152.183.239) port 80
> GET / HTTP/1.1
> Host: sr-nginx-deployment
> User-Agent: curl/8.2.1
> Accept: */*
>
< HTTP/1.1 200 OK
< Server: nginx/1.14.2
< Date: Thu, 15 Feb 2024 19:56:40 GMT
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
/ # curl -v sr-nginx-deployment:8080
* processing: sr-nginx-deployment:8080
*   Trying 10.152.183.239:8080...
* Connected to sr-nginx-deployment (10.152.183.239) port 8080
> GET / HTTP/1.1
> Host: sr-nginx-deployment:8080
> User-Agent: curl/8.2.1
> Accept: */*
>
< HTTP/1.1 200 OK
< Server: nginx/1.24.0
< Date: Thu, 15 Feb 2024 19:56:43 GMT
< Content-Type: text/html
< Content-Length: 154
< Last-Modified: Thu, 15 Feb 2024 19:51:04 GMT
< Connection: keep-alive
< ETag: "65ce6b28-9a"
< Accept-Ranges: bytes
<
WBITT Network MultiTool (with NGINX) - nginx-deployment-56cb7689d9-8n9hf - 10.1.116.163 - HTTP: 8080 , HTTPS: 11443 . (Formerly praqma/network-multitool)
* Connection #0 to host sr-nginx-deployment left intact
```

#### 4. Продемонстрировать доступ с помощью `curl` по доменному имени сервиса.

```bash
/ # nslookup 10.152.183.239
239.183.152.10.in-addr.arpa     name = sr-nginx-deployment.default.svc.cluster.local.

/ # curl -v sr-nginx-deployment.default.svc.cluster.local:80
* processing: sr-nginx-deployment.default.svc.cluster.local:80
*   Trying 10.152.183.239:80...
* Connected to sr-nginx-deployment.default.svc.cluster.local (10.152.183.239) port 80
> GET / HTTP/1.1
> Host: sr-nginx-deployment.default.svc.cluster.local
> User-Agent: curl/8.2.1
> Accept: */*
>
< HTTP/1.1 200 OK
< Server: nginx/1.14.2
< Date: Thu, 15 Feb 2024 19:58:05 GMT
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
* Connection #0 to host sr-nginx-deployment.default.svc.cluster.local left intact
/ # curl -v sr-nginx-deployment.default.svc.cluster.local:8080
* processing: sr-nginx-deployment.default.svc.cluster.local:8080
*   Trying 10.152.183.239:8080...
* Connected to sr-nginx-deployment.default.svc.cluster.local (10.152.183.239) port 8080
> GET / HTTP/1.1
> Host: sr-nginx-deployment.default.svc.cluster.local:8080
> User-Agent: curl/8.2.1
> Accept: */*
>
< HTTP/1.1 200 OK
< Server: nginx/1.24.0
< Date: Thu, 15 Feb 2024 19:58:13 GMT
< Content-Type: text/html
< Content-Length: 154
< Last-Modified: Thu, 15 Feb 2024 19:51:04 GMT
< Connection: keep-alive
< ETag: "65ce6b28-9a"
< Accept-Ranges: bytes
<
WBITT Network MultiTool (with NGINX) - nginx-deployment-56cb7689d9-8n9hf - 10.1.116.163 - HTTP: 8080 , HTTPS: 11443 . (Formerly praqma/network-multitool)
* Connection #0 to host sr-nginx-deployment.default.svc.cluster.local left intact
```

<details>
  <summary><b>Задание 2. Создать Service и обеспечить доступ к приложениям снаружи кластера</b></summary>

1. Создать отдельный Service приложения из Задания 1 с возможностью доступа снаружи кластера к nginx, используя тип NodePort.
2. Продемонстрировать доступ с помощью браузера или `curl` с локального компьютера.
3. Предоставить манифест и Service в решении, а также скриншоты или вывод команды п.2.
</details>

## Ответ

### 1. Создать отдельный Service приложения из Задания 1 с возможностью доступа снаружи кластера к nginx, используя тип NodePort.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: sr-ndprt-nginx-deployment
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - protocol: TCP
      name: nginx-tcp
      port: 80
      targetPort: 80
      nodePort: 30007
```

### 2. Продемонстрировать доступ с помощью браузера или `curl` с локального компьютера.

```bash
vagrant@server1:~$ curl -v 127.0.0.1:30007
*   Trying 127.0.0.1:30007...
* TCP_NODELAY set
* Connected to 127.0.0.1 (127.0.0.1) port 30007 (#0)
> GET / HTTP/1.1
> Host: 127.0.0.1:30007
> User-Agent: curl/7.68.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Server: nginx/1.14.2
< Date: Thu, 15 Feb 2024 20:07:35 GMT
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
* Connection #0 to host 127.0.0.1 left intact
```