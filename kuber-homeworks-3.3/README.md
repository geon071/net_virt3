# Домашнее задание к занятию «Как работает сеть в K8s»

<details>
  <summary><b>Задание 1. Создать сетевую политику или несколько политик для обеспечения доступа</b></summary>

1. Создать deployment'ы приложений frontend, backend и cache и соответсвующие сервисы.
2. В качестве образа использовать network-multitool.
3. Разместить поды в namespace App.
4. Создать политики, чтобы обеспечить доступ frontend -> backend -> cache. Другие виды подключений должны быть запрещены.
5. Продемонстрировать, что трафик разрешён и запрещён.

</details>

## Ответ

### Создание NS

```bash
ubuntu@node4:~$ sudo kubectl get nodes
NAME    STATUS   ROLES           AGE     VERSION
node1   Ready    <none>          4d20h   v1.29.2
node2   Ready    <none>          4d20h   v1.29.2
node3   Ready    <none>          4d20h   v1.29.2
node4   Ready    control-plane   4d20h   v1.29.2
node5   Ready    <none>          4d20h   v1.29.2
ubuntu@node4:~$ kubectl create namespace app
namespace/app created
ubuntu@node4:~$ kubectl get namespace
NAME              STATUS   AGE
app               Active   118s
default           Active   4d20h
kube-node-lease   Active   4d20h
kube-public       Active   4d20h
kube-system       Active   4d20h
```

### Манифесты приложений

#### frontend

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
      - name: multitool
        image: wbitt/network-multitool
        ports:
        - containerPort: 80

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

#### backend

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deploy
  labels:
    app: backend
spec:
  replicas: 2
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

#### cache

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cache-deploy
  labels:
    app: cache
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cache
  template:
    metadata:
      labels:
        app: cache
    spec:
      containers:
      - name: multitool
        image: wbitt/network-multitool
        ports:
        - containerPort: 80

apiVersion: v1
kind: Service
metadata:
  name: sr-cache
spec:
  selector:
    app: cache
  ports:
    - protocol: TCP
      name: cache-tcp
      port: 80
      targetPort: 80

```

```bash
ubuntu@node4:~$ kubectl get pods -n app
NAME                               READY   STATUS    RESTARTS   AGE
backend-deploy-59c6d755b6-m2z9k    1/1     Running   0          6s
backend-deploy-59c6d755b6-mzh97    1/1     Running   0          6s
cache-deploy-675db85444-4bgjb      1/1     Running   0          2m22s
cache-deploy-675db85444-l4mln      1/1     Running   0          2m22s
frontend-deploy-67bf59bdc4-bz6fc   1/1     Running   0          5m22s
frontend-deploy-67bf59bdc4-pgc5r   1/1     Running   0          5m22s
frontend-deploy-67bf59bdc4-zjvpl   1/1     Running   0          5m22s
```

### Манифесты NetworkPolicy

#### frontend -> backend

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: alow-to-backend
  namespace: app
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
      - podSelector:
          matchLabels:
            app: frontend
      ports:
        - protocol: TCP
          port: 80
```

#### backend -> cache

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: alow-to-cache
  namespace: app
spec:
  podSelector:
    matchLabels:
      app: cache
  policyTypes:
    - Ingress
  ingress:
    - from:
      - podSelector:
          matchLabels:
            app: backend
      ports:
        - protocol: TCP
          port: 80
```

#### default

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-ingress-all
  namespace: app
spec:
  podSelector: {}
  policyTypes:
    - Ingress
```

```bash
ubuntu@node4:~$ kubectl get networkpolicy -n app
NAME               POD-SELECTOR   AGE
alow-to-backend    app=backend    27s
alow-to-cache      app=cache      19s
deny-ingress-all   <none>         14s
```

### Проверка

#### frontend -> backend

```bash
ubuntu@node4:~$ kubectl exec -n app frontend-deploy-67bf59bdc4-bz6fc -- curl sr-backend:80 -I
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0   147    0     0    0     0     HTTP/1.1 200 OK:-- --:--:-- --:--:--     0
 0      0 --:--:-- --:--:-- --:--:--     0
Server: nginx/1.24.0
Date: Thu, 21 Mar 2024 19:26:56 GMT
Content-Type: text/html
Content-Length: 147
Last-Modified: Thu, 21 Mar 2024 19:14:05 GMT
Connection: keep-alive
ETag: "65fc86fd-93"
Accept-Ranges: bytes
```

#### backend -> cache

```bash
ubuntu@node4:~$ kubectl exec -n app backend-deploy-59c6d755b6-mzh97 -- curl sr-cache:80 -I
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0   147    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
HTTP/1.1 200 OK
Server: nginx/1.24.0
Date: Thu, 21 Mar 2024 19:27:42 GMT
Content-Type: text/html
Content-Length: 147
Last-Modified: Thu, 21 Mar 2024 19:11:49 GMT
Connection: keep-alive
ETag: "65fc8675-93"
Accept-Ranges: bytes
```

#### Default

```bash
ubuntu@node4:~$ kubectl exec -n app backend-deploy-59c6d755b6-mzh97 -- curl sr-frontend:80 -I --connect-timeout 5
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:--  0:00:05 --:--:--     0
curl: (28) Failed to connect to sr-frontend port 80 after 5000 ms: Timeout was reached
command terminated with exit code 28
```
