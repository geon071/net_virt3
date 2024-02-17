# Домашнее задание к занятию «Сетевое взаимодействие в K8S. Часть 2»

<details>
  <summary><b>Задание 1. Создать Deployment приложений backend и frontend</b></summary>

1. Создать Deployment приложения _frontend_ из образа nginx с количеством реплик 3 шт.
2. Создать Deployment приложения _backend_ из образа multitool. 
3. Добавить Service, которые обеспечат доступ к обоим приложениям внутри кластера. 
4. Продемонстрировать, что приложения видят друг друга с помощью Service.
5. Предоставить манифесты Deployment и Service в решении, а также скриншоты или вывод команды п.4.

</details>

## Ответ

### 1. Создать Deployment приложения _frontend_ из образа nginx с количеством реплик 3 шт.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-deploy
  labels:
    app: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

### 2. Создать Deployment приложения _backend_ из образа multitool.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deploy
  labels:
    app: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: multitool
        image: wbitt/network-multitool
        ports:
        - containerPort: 80
```

### 3. Добавить Service, которые обеспечат доступ к обоим приложениям внутри кластера. 

```yaml
apiVersion: v1
kind: Service
metadata:
  name: sr-backend
spec:
  selector:
    app: backend
  ports:
    - protocol: TCP
      name: backend-tcp
      port: 80
      targetPort: 80
```

```yaml
apiVersion: v1
kind: Service
metadata:
  name: sr-frontend
spec:
  selector:
    app: frontend
  ports:
    - protocol: TCP
      name: frontend-tcp
      port: 80
      targetPort: 80
```

### 4. Продемонстрировать, что приложения видят друг друга с помощью Service.

```bash
PS D:\VM_RDP\Vagrant_learn\for_ansible\kubes> .\kubectl run curl-test --image=radial/busyboxplus:curl -i --tty --rm       
If you don't see a command prompt, try pressing enter.
[ root@curl-test:/ ]$ curl -v sr-backend
> GET / HTTP/1.1
> User-Agent: curl/7.35.0
> Host: sr-backend
> Accept: */*
>
< HTTP/1.1 200 OK
< Server: nginx/1.24.0
< Date: Sat, 17 Feb 2024 15:49:44 GMT
< Content-Type: text/html
< Content-Length: 148
< Last-Modified: Sat, 17 Feb 2024 15:35:51 GMT
< Connection: keep-alive
< ETag: "65d0d257-94"
< Accept-Ranges: bytes
<
WBITT Network MultiTool (with NGINX) - backend-deploy-59c6d755b6-c2r9s - 10.1.116.179 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
[ root@curl-test:/ ]$ curl -v sr-frontend
> GET / HTTP/1.1
> User-Agent: curl/7.35.0
> Host: sr-frontend
> Accept: */*
> 
< HTTP/1.1 200 OK
< Server: nginx/1.14.2
< Date: Sat, 17 Feb 2024 15:49:54 GMT
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
```

<details>
  <summary><b>Задание 2. Создать Ingress и обеспечить доступ к приложениям снаружи кластера</b></summary>

1. Включить Ingress-controller в MicroK8S.
2. Создать Ingress, обеспечивающий доступ снаружи по IP-адресу кластера MicroK8S так, чтобы при запросе только по адресу открывался _frontend_ а при добавлении /api - _backend_.
3. Продемонстрировать доступ с помощью браузера или `curl` с локального компьютера.
4. Предоставить манифесты и скриншоты или вывод команды п.2.

</details>

## Ответ

### 1. Включить Ingress-controller в MicroK8S.

```bash
vagrant@server1:~$ microk8s enable ingress
Infer repository core for addon ingress
Enabling Ingress
ingressclass.networking.k8s.io/public created
ingressclass.networking.k8s.io/nginx created
namespace/ingress created
serviceaccount/nginx-ingress-microk8s-serviceaccount created
clusterrole.rbac.authorization.k8s.io/nginx-ingress-microk8s-clusterrole created
role.rbac.authorization.k8s.io/nginx-ingress-microk8s-role created
clusterrolebinding.rbac.authorization.k8s.io/nginx-ingress-microk8s created
rolebinding.rbac.authorization.k8s.io/nginx-ingress-microk8s created
configmap/nginx-load-balancer-microk8s-conf created
configmap/nginx-ingress-tcp-microk8s-conf created
configmap/nginx-ingress-udp-microk8s-conf created
daemonset.apps/nginx-ingress-microk8s-controller created
Ingress is enabled
```

### 2. Создать Ingress, обеспечивающий доступ снаружи по IP-адресу кластера MicroK8S так, чтобы при запросе только по адресу открывался _frontend_ а при добавлении /api - _backend_.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: http-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: example.info
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: sr-frontend
            port:
              number: 80
      - path: /backend
        pathType: Prefix
        backend:
          service:
            name: sr-backend
            port:
              number: 80
```

### 3. Продемонстрировать доступ с помощью браузера или `curl` с локального компьютера.

```bash
vagrant@server1:~$ curl -v example.info:80/
*   Trying 127.0.0.1:80...
* TCP_NODELAY set
* Connected to example.info (127.0.0.1) port 80 (#0)
> GET / HTTP/1.1
> Host: example.info
> User-Agent: curl/7.68.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Date: Sat, 17 Feb 2024 16:08:55 GMT
< Content-Type: text/html
< Content-Length: 612
< Connection: keep-alive
< Last-Modified: Tue, 04 Dec 2018 14:44:49 GMT
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
* Connection #0 to host example.info left intact
vagrant@server1:~$ curl -v example.info:80/backend
*   Trying 127.0.0.1:80...
* TCP_NODELAY set
* Connected to example.info (127.0.0.1) port 80 (#0)
> GET /backend HTTP/1.1
> Host: example.info
> User-Agent: curl/7.68.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Date: Sat, 17 Feb 2024 16:09:01 GMT
< Content-Type: text/html
< Content-Length: 148
< Connection: keep-alive
< Last-Modified: Sat, 17 Feb 2024 15:35:51 GMT
< ETag: "65d0d257-94"
< Accept-Ranges: bytes
<
WBITT Network MultiTool (with NGINX) - backend-deploy-59c6d755b6-c2r9s - 10.1.116.179 - HTTP: 80 , HTTPS: 443 . (Formerly praqma/network-multitool)
* Connection #0 to host example.info left intact
```