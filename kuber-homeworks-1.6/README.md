# Домашнее задание к занятию «Хранение в K8s. Часть 1»

<details>
  <summary><b>Задание 1. Создать Deployment приложения, состоящего из двух контейнеров и обменивающихся данными.</b></summary>

1. Создать Deployment приложения, состоящего из контейнеров busybox и multitool.
2. Сделать так, чтобы busybox писал каждые пять секунд в некий файл в общей директории.
3. Обеспечить возможность чтения файла контейнером multitool.
4. Продемонстрировать, что multitool может читать файл, который периодоически обновляется.
5. Предоставить манифесты Deployment в решении, а также скриншоты или вывод команды из п. 4.

</details>

## Ответ

### deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: multi-busy
  labels:
    app: multi-busy
spec:
  replicas: 1
  selector:
    matchLabels:
      app: multi-busy
  template:
    metadata:
      labels:
        app: multi-busy
    spec:
      containers:
      - name: multitool
        image: wbitt/network-multitool
        ports:
        - containerPort: 80
        volumeMounts:
          - mountPath: "/read"
            name: empty-volume
      - name: busybox
        image: busybox
        command:
          - "sh"
          - "-c"
          - "touch /write/busy.txt; while true; do echo somethine >> /write/busy.txt; sleep 5;  done"
        volumeMounts:
          - mountPath: "/write"
            name: empty-volume
      volumes:
        - name: empty-volume
          emptyDir: {}
```

### bash

```bash
PS D:\VM_RDP\Vagrant_learn\for_ansible\kubes> .\kubectl apply -f .\dp_volumes_empty.yml
deployment.apps/multi-busy created
PS D:\VM_RDP\Vagrant_learn\for_ansible\kubes> .\kubectl exec --stdin --tty multi-busy-6cdd894d76-sqzm7 -- sh
Defaulted container "multitool" out of: multitool, busybox
/ # cat /read/busy.txt
somethine
somethine
somethine
somethine
somethine
somethine
somethine
/ # cat /read/busy.txt
somethine
somethine
somethine
somethine
somethine
somethine
somethine
somethine
somethine
somethine
somethine
somethine
/ # exit
```

<details>
  <summary><b>Задание 2. Создать DaemonSet приложения, которое может прочитать логи ноды.</b></summary>

1. Создать DaemonSet приложения, состоящего из multitool.
2. Обеспечить возможность чтения файла `/var/log/syslog` кластера MicroK8S.
3. Продемонстрировать возможность чтения файла изнутри пода.
4. Предоставить манифесты Deployment, а также скриншоты или вывод команды из п. 2.

</details>

## Ответ

### deployment

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: multitool-daemonset
  labels:
    app: multitool-daemonset
spec:
  selector:
    matchLabels:
      app: multitool-daemonset
  template:
    metadata:
      labels:
        app: multitool-daemonset
    spec:
      containers:
      - name: multitool
        image: wbitt/network-multitool
        ports:
        - containerPort: 80
        volumeMounts:
        - mountPath: /logs
          name: syslog-host
          readOnly: true
      volumes:
      - name: syslog-host
        hostPath:
          path: /var/log/syslog
          type: File
```

### bash

```bash
PS D:\VM_RDP\Vagrant_learn\for_ansible\kubes> .\kubectl get pods
NAME                        READY   STATUS    RESTARTS   AGE
multitool-daemonset-mtnxq   1/1     Running   0          2m11s
PS D:\VM_RDP\Vagrant_learn\for_ansible\kubes> .\kubectl exec --stdin --tty multitool-daemonset-mtnxq -- sh
/ # tail -n 10 /logs
Feb 22 19:46:18 server1 microk8s.daemon-containerd[23267]: time="2024-02-22T19:46:18.351486042Z" level=info msg="Container exec \"a20936a04b2deff8a3862a34e0e281f5d0906112d21296b7171501b6466a193c\" 
stdin closed"
Feb 22 19:46:20 server1 systemd[1]: run-containerd-runc-k8s.io-bf6d56456d15ab206e944b8168647d8ee710e34ead118c16b6194906fce596e2-runc.8ABT9v.mount: Succeeded.
Feb 22 19:46:20 server1 systemd[1]: run-containerd-runc-k8s.io-bf6d56456d15ab206e944b8168647d8ee710e34ead118c16b6194906fce596e2-runc.MTduws.mount: Succeeded.
Feb 22 19:46:21 server1 systemd[1]: run-containerd-runc-k8s.io-487949e85daae5ef9438212d9bb4b5007b2e545e4b763fe4b9a261fd26eaedd7-runc.iv96nF.mount: Succeeded.
Feb 22 19:46:21 server1 systemd[1]: run-containerd-runc-k8s.io-487949e85daae5ef9438212d9bb4b5007b2e545e4b763fe4b9a261fd26eaedd7-runc.ovoGtL.mount: Succeeded.
Feb 22 19:46:24 server1 systemd[1]: run-containerd-runc-k8s.io-d2055a2e5aded9dd82ea9b39ac89f7c97893a25eb35aea746acd409c34c60747-runc.F2kcLz.mount: Succeeded.
Feb 22 19:46:30 server1 systemd[1]: run-containerd-runc-k8s.io-bf6d56456d15ab206e944b8168647d8ee710e34ead118c16b6194906fce596e2-runc.comPGO.mount: Succeeded.
Feb 22 19:46:30 server1 systemd[1]: run-containerd-runc-k8s.io-bf6d56456d15ab206e944b8168647d8ee710e34ead118c16b6194906fce596e2-runc.mQZlaR.mount: Succeeded.
Feb 22 19:46:31 server1 systemd[1]: run-containerd-runc-k8s.io-487949e85daae5ef9438212d9bb4b5007b2e545e4b763fe4b9a261fd26eaedd7-runc.T4OYor.mount: Succeeded.
Feb 22 19:46:31 server1 systemd[1]: run-containerd-runc-k8s.io-487949e85daae5ef9438212d9bb4b5007b2e545e4b763fe4b9a261fd26eaedd7-runc.jGMnGt.mount: Succeeded.
```