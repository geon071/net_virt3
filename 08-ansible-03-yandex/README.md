# Домашнее задание к занятию 3 «Использование Ansible»

<details>
  <summary>Описание ДЗ</summary>
1. Допишите playbook: нужно сделать ещё один play, который устанавливает и настраивает LightHouse.
2. При создании tasks рекомендую использовать модули: `get_url`, `template`, `yum`, `apt`.
3. Tasks должны: скачать статику LightHouse, установить Nginx или любой другой веб-сервер, настроить его конфиг для открытия LightHouse, запустить веб-сервер.
4. Подготовьте свой inventory-файл `prod.yml`.
5. Запустите `ansible-lint site.yml` и исправьте ошибки, если они есть.
6. Попробуйте запустить playbook на этом окружении с флагом `--check`.
7. Запустите playbook на `prod.yml` окружении с флагом `--diff`. Убедитесь, что изменения на системе произведены.
8. Повторно запустите playbook с флагом `--diff` и убедитесь, что playbook идемпотентен.
9. Подготовьте README.md-файл по своему playbook. В нём должно быть описано: что делает playbook, какие у него есть параметры и теги.
10. Готовый playbook выложите в свой репозиторий, поставьте тег `08-ansible-03-yandex` на фиксирующий коммит, в ответ предоставьте ссылку на него.

</details>

### Ответ

#### 1. Допишите playbook: нужно сделать ещё один play, который устанавливает и настраивает LightHouse.

#### 2. При создании tasks рекомендую использовать модули: `get_url`, `template`, `yum`, `apt`.

#### 3. Tasks должны: скачать статику LightHouse, установить Nginx или любой другой веб-сервер, настроить его конфиг для открытия LightHouse, запустить веб-сервер.

```yml
- name: Install Nginx
  hosts: lighthouse
  handlers:
    - name: start-nginx
      become: true
      command: nginx
    - name: reload-nginx
      become: true
      command: nginx -s reload
  pre_tasks:
    - name: Nginx | Install epel-release
      become: true
      ansible.builtin.yum:
        name: epel-release
        state: present
  tasks:
    - name: Nginx | Install nginx
      become: true
      ansible.builtin.yum:
        name: nginx
        state: present
      notify: start-nginx
    - name: Nginx | Load nginx config
      become: true
      ansible.builtin.template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        mode: 0644
      notify: reload-nginx

- name: Install Lighthouse
  hosts: lighthouse
  handlers:
    - name: reload-nginx
      become: true
      command: nginx -s reload
  pre_tasks:
    - name: Lighthouse | Install git
      become: true
      ansible.builtin.yum:
        name: git
        state: present
  tasks:
    - name: Lighthouse | Clone repo
      ansible.builtin.git:
        repo: "{{ lighthouse_repo }}"
        dest: "{{ lighthouse_dest }}"
        version: master
    - name: Lighthouse | Apply config
      become: true
      ansible.builtin.template:
        src: lighthouse_nginx.conf.j2
        dest: /etc/nginx/conf.d/lighthouse.conf
        mode: 0644
      notify: reload-nginx
```

#### 4. Подготовьте свой inventory-файл `prod.yml`.

```yml
---
clickhouse:
  hosts:
    clickhouse-01:
      ansible_user: centos
      ansible_host: 158.160.124.43
vector:
  hosts:
    vector-01:
      ansible_user: centos
      ansible_host: 158.160.114.110
lighthouse:
  hosts:
    lighthouse-01:
      ansible_user: centos
      ansible_host: 158.160.36.59
```

#### 5. Запустите `ansible-lint site.yml` и исправьте ошибки, если они есть.

```bash
vagrant@server1:/vagrant$ ansible-lint -v ./playbook/site.yml
Examining playbook/site.yml of type playbook
```

#### 6. Попробуйте запустить playbook на этом окружении с флагом `--check`.

Упал, потому что при флаге --check Ансибл фактически не устанавливает необходимые пакеты через менеджер yum

```bash
vagrant@server1:/vagrant$ ansible-playbook -i ./playbook/inventory/prod.yml ./playbook/site.yml --key-file ya.key --check

PLAY [Install Nginx] **********************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************
ok: [lighthouse-01]

TASK [Nginx | Install epel-release] *******************************************************************************************************************
changed: [lighthouse-01]

TASK [Nginx | Install nginx] **************************************************************************************************************************
fatal: [lighthouse-01]: FAILED! => {"changed": false, "msg": "No package matching 'nginx' found available, installed or updated", "rc": 126, "results": ["No package matching 'nginx' found available, installed or updated"]}

PLAY RECAP ********************************************************************************************************************************************
lighthouse-01              : ok=2    changed=1    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0
```

#### 7. Запустите playbook на `prod.yml` окружении с флагом `--diff`. Убедитесь, что изменения на системе произведены.

```bash
vagrant@server1:/vagrant$ ansible-playbook -i ./playbook/inventory/prod.yml ./playbook/site.yml --key-file ya.key --diff

PLAY [Install Nginx] **********************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************
ok: [lighthouse-01]

TASK [Nginx | Install epel-release] *******************************************************************************************************************
changed: [lighthouse-01]

TASK [Nginx | Install nginx] **************************************************************************************************************************
changed: [lighthouse-01]

TASK [Nginx | Load nginx config] **********************************************************************************************************************
--- before: /etc/nginx/nginx.conf
+++ after: /home/vagrant/.ansible/tmp/ansible-local-3676z9guk4fw/tmpn8ykggjz/nginx.conf.j2
@@ -1,13 +1,8 @@
-# For more information on configuration, see:
-#   * Official English Documentation: http://nginx.org/en/docs/
-#   * Official Russian Documentation: http://nginx.org/ru/docs/
-
-user nginx;
+user centos;
 worker_processes auto;
 error_log /var/log/nginx/error.log;
 pid /run/nginx.pid;

-# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
 include /usr/share/nginx/modules/*.conf;

 events {
@@ -25,7 +20,7 @@
     tcp_nopush          on;
     tcp_nodelay         on;
     keepalive_timeout   65;
-    types_hash_max_size 4096;
+    types_hash_max_size 2048;

     include             /etc/nginx/mime.types;
     default_type        application/octet-stream;
@@ -34,51 +29,4 @@
     # See http://nginx.org/en/docs/ngx_core_module.html#include
     # for more information.
     include /etc/nginx/conf.d/*.conf;
-
-    server {
-        listen       80;
-        listen       [::]:80;
-        server_name  _;
-        root         /usr/share/nginx/html;
-
-        # Load configuration files for the default server block.
-        include /etc/nginx/default.d/*.conf;
-
-        error_page 404 /404.html;
-        location = /404.html {
-        }
-
-        error_page 500 502 503 504 /50x.html;
-        location = /50x.html {
-        }
-    }
-
-# Settings for a TLS enabled server.
-#
-#    server {
-#        listen       443 ssl http2;
-#        listen       [::]:443 ssl http2;
-#        server_name  _;
-#        root         /usr/share/nginx/html;
-#
-#        ssl_certificate "/etc/pki/nginx/server.crt";
-#        ssl_certificate_key "/etc/pki/nginx/private/server.key";
-#        ssl_session_cache shared:SSL:1m;
-#        ssl_session_timeout  10m;
-#        ssl_ciphers HIGH:!aNULL:!MD5;
-#        ssl_prefer_server_ciphers on;
-#
-#        # Load configuration files for the default server block.
-#        include /etc/nginx/default.d/*.conf;
-#
-#        error_page 404 /404.html;
-#            location = /40x.html {
-#        }
-#
-#        error_page 500 502 503 504 /50x.html;
-#            location = /50x.html {
-#        }
-#    }
-
-}
-
+}
\ No newline at end of file

changed: [lighthouse-01]

RUNNING HANDLER [start-nginx] *************************************************************************************************************************
changed: [lighthouse-01]

RUNNING HANDLER [reload-nginx] ************************************************************************************************************************
changed: [lighthouse-01]

PLAY [Install Lighthouse] *****************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************
ok: [lighthouse-01]

TASK [Lighthouse | Install git] ***********************************************************************************************************************
changed: [lighthouse-01]

TASK [Lighthouse | Clone repo] ************************************************************************************************************************
>> Newly checked out d701335c25cd1bb9b5155711190bad8ab852c2ce
changed: [lighthouse-01]

TASK [Lighthouse | Apply config] **********************************************************************************************************************
--- before
+++ after: /home/vagrant/.ansible/tmp/ansible-local-3676z9guk4fw/tmp0xssywxh/lighthouse_nginx.conf.j2
@@ -0,0 +1,10 @@
+server {
+    listen    8080;
+       server_name localhost;
+       location / {
+
+           root /opt/nginx/www;
+               index index.html;
+
+       }
+}
\ No newline at end of file

changed: [lighthouse-01]

RUNNING HANDLER [reload-nginx] ************************************************************************************************************************
changed: [lighthouse-01]

PLAY [Install Clickhouse] *****************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************
The authenticity of host '158.160.124.43 (158.160.124.43)' can't be established.
ECDSA key fingerprint is SHA256:0yTYQ81Uxn5Exr8hgnxvoJOC7iuzHfX8b1L/aeNvU/A.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
ok: [clickhouse-01]

TASK [Get clickhouse distrib] *************************************************************************************************************************
changed: [clickhouse-01] => (item=clickhouse-client)
changed: [clickhouse-01] => (item=clickhouse-server)
failed: [clickhouse-01] (item=clickhouse-common-static) => {"ansible_loop_var": "item", "changed": false, "dest": "./clickhouse-common-static-22.3.3.44.rpm", "elapsed": 0, "item": "clickhouse-common-static", "msg": "Request failed", "response": "HTTP Error 404: Not Found", "status_code": 404, "url": "https://packages.clickhouse.com/rpm/stable/clickhouse-common-static-22.3.3.44.noarch.rpm"}

TASK [Get clickhouse distrib] *************************************************************************************************************************
changed: [clickhouse-01]

TASK [Install clickhouse packages] ********************************************************************************************************************
changed: [clickhouse-01]

TASK [Flush handlers] *********************************************************************************************************************************

RUNNING HANDLER [Start clickhouse service] ************************************************************************************************************
changed: [clickhouse-01]

TASK [Pause for 30 sec to start service] **************************************************************************************************************
Pausing for 30 seconds
(ctrl+C then 'C' = continue early, ctrl+C then 'A' = abort)
ok: [clickhouse-01]

TASK [Create database] ********************************************************************************************************************************
changed: [clickhouse-01]

PLAY [Install Vector] *********************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************
The authenticity of host '158.160.114.110 (158.160.114.110)' can't be established.
ECDSA key fingerprint is SHA256:RIT7tULtVS/jwgTJjJ84134NEA4w0YATG2yYPsPcnN0.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
ok: [vector-01]

TASK [Download packages] ******************************************************************************************************************************
changed: [vector-01]

TASK [Install packages] *******************************************************************************************************************************
changed: [vector-01]

TASK [Apply template] *********************************************************************************************************************************
--- before
+++ after: /home/vagrant/.ansible/tmp/ansible-local-3676z9guk4fw/tmpdenzis0v/vector_conf.yml.j2
@@ -0,0 +1,12 @@
+sinks:
+    to_clickhouse:
+        database: logs
+        endpoint: http://158.160.124.43:8123
+        inputs:
+        - example_logs
+        table: table1
+        type: clickhouse
+sources:
+    example_logs:
+        format: syslog
+        type: demo_logs

changed: [vector-01]

PLAY RECAP ********************************************************************************************************************************************
clickhouse-01              : ok=6    changed=4    unreachable=0    failed=0    skipped=0    rescued=1    ignored=0
lighthouse-01              : ok=11   changed=9    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
vector-01                  : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

#### 8. Повторно запустите playbook с флагом `--diff` и убедитесь, что playbook идемпотентен.

```bash
vagrant@server1:/vagrant$ ansible-playbook -i ./playbook/inventory/prod.yml ./playbook/site.yml --key-file ya.key --diff

PLAY [Install Nginx] **********************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************
ok: [lighthouse-01]

TASK [Nginx | Install epel-release] *******************************************************************************************************************
ok: [lighthouse-01]

TASK [Nginx | Install nginx] **************************************************************************************************************************
ok: [lighthouse-01]

TASK [Nginx | Load nginx config] **********************************************************************************************************************
ok: [lighthouse-01]

PLAY [Install Lighthouse] *****************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************
ok: [lighthouse-01]

TASK [Lighthouse | Install git] ***********************************************************************************************************************
ok: [lighthouse-01]

TASK [Lighthouse | Clone repo] ************************************************************************************************************************
ok: [lighthouse-01]

TASK [Lighthouse | Apply config] **********************************************************************************************************************
ok: [lighthouse-01]

PLAY [Install Clickhouse] *****************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************
ok: [clickhouse-01]

TASK [Get clickhouse distrib] *************************************************************************************************************************
ok: [clickhouse-01] => (item=clickhouse-client)
ok: [clickhouse-01] => (item=clickhouse-server)
failed: [clickhouse-01] (item=clickhouse-common-static) => {"ansible_loop_var": "item", "changed": false, "dest": "./clickhouse-common-static-22.3.3.44.rpm", "elapsed": 0, "gid": 1000, "group": "centos", "item": "clickhouse-common-static", "mode": "0664", "msg": "Request failed", "owner": "centos", "response": "HTTP Error 404: Not Found", "secontext": "unconfined_u:object_r:user_home_t:s0", "size": 246310036, "state": "file", "status_code": 404, "uid": 1000, "url": "https://packages.clickhouse.com/rpm/stable/clickhouse-common-static-22.3.3.44.noarch.rpm"}

TASK [Get clickhouse distrib] *************************************************************************************************************************
ok: [clickhouse-01]

TASK [Install clickhouse packages] ********************************************************************************************************************
ok: [clickhouse-01]

TASK [Flush handlers] *********************************************************************************************************************************

TASK [Pause for 30 sec to start service] **************************************************************************************************************
Pausing for 30 seconds
(ctrl+C then 'C' = continue early, ctrl+C then 'A' = abort)
ok: [clickhouse-01]

TASK [Create database] ********************************************************************************************************************************
ok: [clickhouse-01]

PLAY [Install Vector] *********************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************
ok: [vector-01]

TASK [Download packages] ******************************************************************************************************************************
ok: [vector-01]

TASK [Install packages] *******************************************************************************************************************************
ok: [vector-01]

TASK [Apply template] *********************************************************************************************************************************
ok: [vector-01]

PLAY RECAP ********************************************************************************************************************************************
clickhouse-01              : ok=5    changed=0    unreachable=0    failed=0    skipped=0    rescued=1    ignored=0
lighthouse-01              : ok=8    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
vector-01                  : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

#### 9. Подготовьте README.md-файл по своему playbook. В нём должно быть описано: что делает playbook, какие у него есть параметры и теги.

#### 10. Готовый playbook выложите в свой репозиторий, поставьте тег `08-ansible-03-yandex` на фиксирующий коммит, в ответ предоставьте ссылку на него.