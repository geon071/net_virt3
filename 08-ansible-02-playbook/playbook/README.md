## Плейбук установки Clickhouse, Vector

Данный плейбук позволяет установить следующие программные продукты

- Clickhouse (<https://clickhouse.com/>)
- Vector (<https://vector.dev/>)

### Пререквизиты

- **Ansible 2.12+**
- Операционная система: **CentOS**

### Конфигурация

Основные файлы c параметрами:

- `group_vars\clickhouse\vars.yml` файл конфигурации для Vector, содержит следующие параметры:

  - clickhouse_version: версия для установки (Пример: "22.3.3.44")
  - clickhouse_packages: список пакетов для установки

- `group_vars\vector\vars.yml` файл конфигурации для ClickHouse 

  - vector_url: ссылка для скачивания дистрибутива Vector (Пример: "https://packages.timber.io/vector/{{ vector_version }}/vector-{{ vector_version }}-1.x86_64.rpm")
  - vector_version: версия для установки (Пример: "0.31.0")
  - vector_config_dir: директория расположения файлов конфигурации Vector (Пример: "/etc/vector")
  - vector_config: описание конфигурации Vector в формате yaml

В файле `inventory\prod.yml` можно сконфигурировать на какие узлы производить установку продуктов. Приведен пример подключения через SSH.

### Запуск установки

    # Deploy with ansible playbook - run the playbook as root
    ansible-playbook -i ./inventory/prod.yml site.yml --key-file your_key.pem

your_key.pem - приватный SSH ключ для подключения к узлам указанным в файле `inventory\prod.yml`

По окончании будет произведена установка программных продуктов Clickhouse и Vector, конфигурация их, согласно параметрам.  
