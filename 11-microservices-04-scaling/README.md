# Домашнее задание к занятию «Микросервисы: масштабирование»

<details>
  <summary><b>Задача 1: Кластеризация</b></summary>

Предложите решение для обеспечения развёртывания, запуска и управления приложениями.
Решение может состоять из одного или нескольких программных продуктов и должно описывать способы и принципы их взаимодействия.

Решение должно соответствовать следующим требованиям:

- поддержка контейнеров;
- обеспечивать обнаружение сервисов и маршрутизацию запросов;
- обеспечивать возможность горизонтального масштабирования;
- обеспечивать возможность автоматического масштабирования;
- обеспечивать явное разделение ресурсов, доступных извне и внутри системы;
- обеспечивать возможность конфигурировать приложения с помощью переменных среды, в том числе с возможностью безопасного хранения чувствительных данных таких как пароли, ключи доступа, ключи шифрования и т. п.

Обоснуйте свой выбор.
</details>

## Ответ

Для обеспечения развёртывания, запуска и управления приложениями отлично подойдет Kubernetes.

Kubernetes - это открытая система управления контейнерами, которая позволяет автоматизировать и упростить процесс развертывания, масштабирования и управления приложениями в контейнерах.

Он так же удовлетворяет требованиям:

- <b>Для обнаружения сервисов и маршрутизации запросов</b> внутри кластера Kubernetes, можно использовать встроенную функциональность Kubernetes Service Discovery и Ingress Controller. Service Discovery позволяет автоматически обнаруживать и прослушивать услуги в кластере, а Ingress Controller управляет входящим трафиком, маршрутизацией и балансировкой нагрузки.
- <b>Горизонтальное масштабирование</b> приложений можно реализовать с помощью функции автомасштабирования ReplicaSet или Deployment в Kubernetes. Это позволит динамически изменять количество экземпляров приложений в зависимости от нагрузки.
- <b>Автоматическое масштабирование</b> в Kubernetes можно достичь с помощью подсчета метрик, таких как использование CPU или памяти, и настройки правил масштабирования для каждого приложения. Kubernetes автоматически масштабирует приложения в соответствии с определенными правилами.
- <b>Для разделения ресурсов</b> доступных извне и внутри системы, можно использовать Kubernetes Service тип LoadBalancer или Ingress для предоставления доступа к приложениям извне, а для внутренних ресурсов можно использовать сервисы типа ClusterIP или NodePort.
- <b>Конфигурирование приложений</b> с помощью переменных среды и безопасного хранения чувствительных данных, в Kubernetes можно использовать Secrets для хранения паролей, ключей доступа и других конфиденциальных данных. Secrets могут быть безопасно переданы в приложение или монтированы в виде файлов в контейнере.