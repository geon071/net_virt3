# Домашнее задание к занятию 2 «Работа с Playbook»

<details>
  <summary>Описание ДЗ</summary>
1. Подготовьте свой inventory-файл `prod.yml`.
2. Допишите playbook: нужно сделать ещё один play, который устанавливает и настраивает [vector](https://vector.dev). Конфигурация vector должна деплоиться через template файл jinja2.
3. При создании tasks рекомендую использовать модули: `get_url`, `template`, `unarchive`, `file`.
4. Tasks должны: скачать дистрибутив нужной версии, выполнить распаковку в выбранную директорию, установить vector.
5. Запустите `ansible-lint site.yml` и исправьте ошибки, если они есть.
6. Попробуйте запустить playbook на этом окружении с флагом `--check`.
7. Запустите playbook на `prod.yml` окружении с флагом `--diff`. Убедитесь, что изменения на системе произведены.
8. Повторно запустите playbook с флагом `--diff` и убедитесь, что playbook идемпотентен.
9. Подготовьте README.md-файл по своему playbook. В нём должно быть описано: что делает playbook, какие у него есть параметры и теги. Пример качественной документации ansible playbook по [ссылке](https://github.com/opensearch-project/ansible-playbook).
10. Готовый playbook выложите в свой репозиторий, поставьте тег `08-ansible-02-playbook` на фиксирующий коммит, в ответ предоставьте ссылку на него.

</details>

### Ответ

#### 1. Подготовьте свой inventory-файл `prod.yml`

Для тестирования установки плуйбука решил исопльзовать контейнеры докер

```yml
clickhouse:
  hosts:
    clickhouse-01:
      ansible_user: centos
      ansible_host: 51.250.76.93
vector:
  hosts:
    vector-01:
      ansible_user: centos
      ansible_host: 158.160.63.18
```

#### 2. Допишите playbook: нужно сделать ещё один play, который устанавливает и настраивает [vector](https://vector.dev). Конфигурация vector должна деплоиться через template файл jinja2.

```yml
- name: Install Vector
  hosts: vector
  handlers:
    - name: Start Vector service
      become: true
      ansible.builtin.service:
        name: vector
        state: restarted
  tasks:
    - name: Download packages
      ansible.builtin.get_url:
        url: "{{ vector_url }}"
        dest: "./vector-{{ vector_version }}-1.x86_64.rpm"
    - name: Install packages
      become: true
      ansible.builtin.yum:
        name: "./vector-{{ vector_version }}-1.x86_64.rpm"
        disable_gpg_check: true
    - name: Apply template
      become: true
      ansible.builtin.template:
        src: vector_conf.yml.j2
        dest: "{{ vector_config_dir }}/vector.yml"
        mode: "0644"
        owner: "{{ ansible_user_id }}"
        group: "{{ ansible_user_gid }}"
        validate: vector validate --no-environment --config-yaml %s
```

#### 5. Запустите `ansible-lint site.yml` и исправьте ошибки, если они есть.

```bash
vagrant@server1:/vagrant/playbook$ ansible-lint -v site.yml
Examining site.yml of type playbook
```

#### 6. Попробуйте запустить playbook на этом окружении с флагом `--check`.

```bash
vagrant@server1:/vagrant/playbook$ ansible-playbook -i ./inventory/prod.yml site.yml --key-file ya --check

PLAY [Install Clickhouse] *****************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************
ok: [clickhouse-01]

TASK [Get clickhouse distrib] *************************************************************************************************************
changed: [clickhouse-01] => (item=clickhouse-client)
changed: [clickhouse-01] => (item=clickhouse-server)
failed: [clickhouse-01] (item=clickhouse-common-static) => {"ansible_loop_var": "item", "changed": false, "dest": "./clickhouse-common-static-22.3.3.44.rpm", "elapsed": 0, "item": "clickhouse-common-static", "msg": "Request failed", "response": "HTTP Error 404: Not Found", "status_code": 404, "url": "https://packages.clickhouse.com/rpm/stable/clickhouse-common-static-22.3.3.44.noarch.rpm"}

TASK [Get clickhouse distrib] *************************************************************************************************************
changed: [clickhouse-01]

TASK [Install clickhouse packages] ********************************************************************************************************
fatal: [clickhouse-01]: FAILED! => {"changed": false, "msg": "No RPM file matching 'clickhouse-common-static-22.3.3.44.rpm' found on system", "rc": 127, "results": ["No RPM file matching 'clickhouse-common-static-22.3.3.44.rpm' found on system"]}

PLAY RECAP ********************************************************************************************************************************
clickhouse-01              : ok=2    changed=1    unreachable=0    failed=1    skipped=0    rescued=1    ignored=0
```

#### 7. Запустите playbook на `prod.yml` окружении с флагом `--diff`. Убедитесь, что изменения на системе произведены.

```bash
vagrant@server1:/vagrant/playbook$ ansible-playbook -i ./inventory/prod.yml site.yml --key-file ya --diff

PLAY [Install Clickhouse] *****************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************
ok: [clickhouse-01]

TASK [Get clickhouse distrib] *************************************************************************************************************
changed: [clickhouse-01] => (item=clickhouse-client)
changed: [clickhouse-01] => (item=clickhouse-server)
failed: [clickhouse-01] (item=clickhouse-common-static) => {"ansible_loop_var": "item", "changed": false, "dest": "./clickhouse-common-static-22.3.3.44.rpm", "elapsed": 0, "item": "clickhouse-common-static", "msg": "Request failed", "response": "HTTP Error 404: Not Found", "status_code": 404, "url": "https://packages.clickhouse.com/rpm/stable/clickhouse-common-static-22.3.3.44.noarch.rpm"}

TASK [Get clickhouse distrib] *************************************************************************************************************
changed: [clickhouse-01]

TASK [Install clickhouse packages] ********************************************************************************************************
changed: [clickhouse-01]

TASK [Flush handlers] *********************************************************************************************************************

RUNNING HANDLER [Start clickhouse service] ************************************************************************************************
changed: [clickhouse-01]

TASK [Pause for 30 sec to start service] **************************************************************************************************
Pausing for 30 seconds
(ctrl+C then 'C' = continue early, ctrl+C then 'A' = abort)
ok: [clickhouse-01]

TASK [Create database] ********************************************************************************************************************
changed: [clickhouse-01]

PLAY [Install Vector] *********************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************
The authenticity of host '51.250.66.37 (51.250.66.37)' can't be established.
ECDSA key fingerprint is SHA256:YeGw5UmAr94Wet8GluH47SHl2bJDB36tBHk79Gq5tnA.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
ok: [vector-01]

TASK [Download packages] ******************************************************************************************************************
changed: [vector-01]

TASK [Install packages] *******************************************************************************************************************
changed: [vector-01]

TASK [Apply template] *********************************************************************************************************************
--- before
+++ after: /home/vagrant/.ansible/tmp/ansible-local-9334m99brfs7/tmpatfjxwgd/vector_conf.yml.j2
@@ -0,0 +1,12 @@
+sinks:
+    to_clickhouse:
+        database: test123
+        endpoint: http://84.201.129.38:8123
+        inputs:
+        - example_logs
+        table: table1
+        type: clickhouse
+sources:
+    example_logs:
+        format: syslog
+        type: demo_logs

changed: [vector-01]

PLAY RECAP ********************************************************************************************************************************
clickhouse-01              : ok=6    changed=4    unreachable=0    failed=0    skipped=0    rescued=1    ignored=0
vector-01                  : ok=4    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

#### 8. Повторно запустите playbook с флагом `--diff` и убедитесь, что playbook идемпотентен.

```bash
vagrant@server1:/vagrant/playbook$ ansible-playbook -i ./inventory/prod.yml site.yml --key-file ya --diff

PLAY [Install Clickhouse] *****************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************
ok: [clickhouse-01]

TASK [Get clickhouse distrib] *************************************************************************************************************
ok: [clickhouse-01] => (item=clickhouse-client)
ok: [clickhouse-01] => (item=clickhouse-server)
failed: [clickhouse-01] (item=clickhouse-common-static) => {"ansible_loop_var": "item", "changed": false, "dest": "./clickhouse-common-static-22.3.3.44.rpm", "elapsed": 0, "gid": 1000, "group": "centos", "item": "clickhouse-common-static", "mode": "0664", "msg": "Request failed", "owner": "centos", "response": "HTTP Error 404: Not Found", "secontext": "unconfined_u:object_r:user_home_t:s0", "size": 246310036, "state": "file", "status_code": 404, "uid": 1000, "url": "https://packages.clickhouse.com/rpm/stable/clickhouse-common-static-22.3.3.44.noarch.rpm"}

TASK [Get clickhouse distrib] *************************************************************************************************************
ok: [clickhouse-01]

TASK [Install clickhouse packages] ********************************************************************************************************
ok: [clickhouse-01]

TASK [Flush handlers] *********************************************************************************************************************

TASK [Pause for 30 sec to start service] **************************************************************************************************
Pausing for 30 seconds
(ctrl+C then 'C' = continue early, ctrl+C then 'A' = abort)
Press 'C' to continue the play or 'A' to abort
ok: [clickhouse-01]

TASK [Create database] ********************************************************************************************************************
ok: [clickhouse-01]

PLAY [Install Vector] *********************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************
ok: [vector-01]

TASK [Download packages] ******************************************************************************************************************
ok: [vector-01]

TASK [Install packages] *******************************************************************************************************************
ok: [vector-01]

TASK [Apply template] *********************************************************************************************************************
ok: [vector-01]

PLAY RECAP ********************************************************************************************************************************
clickhouse-01              : ok=5    changed=0    unreachable=0    failed=0    skipped=0    rescued=1    ignored=0
vector-01                  : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

#### 9. Подготовьте README.md-файл по своему playbook. В нём должно быть описано: что делает playbook, какие у него есть параметры и теги. Пример качественной документации ansible playbook по [ссылке](https://github.com/opensearch-project/ansible-playbook).

<https://github.com/geon071/net_virt3/releases/tag/08-ansible-02-playbook>
