# Домашнее задание к занятию 11 «Teamcity»

## Основная часть

1. Создайте новый проект в teamcity на основе fork.
2. Сделайте autodetect конфигурации.

![alt text](img/team1.png "team1")

3. Сохраните необходимые шаги, запустите первую сборку master.

![alt text](img/team2.png "team2")

4. Поменяйте условия сборки: если сборка по ветке `master`, то должен происходит `mvn clean deploy`, иначе `mvn clean test`.

![alt text](img/team3.png "team3")

5. Для deploy будет необходимо загрузить [settings.xml](./teamcity/settings.xml) в набор конфигураций maven у teamcity, предварительно записав туда креды для подключения к nexus.

![alt text](img/team4.png "team4")

6. В pom.xml необходимо поменять ссылки на репозиторий и nexus.
7. Запустите сборку по master, убедитесь, что всё прошло успешно и артефакт появился в nexus.

![alt text](img/nexus1.png "nexus1")

8. Мигрируйте `build configuration` в репозиторий.

![alt text](img/team5.png "team5")

9. Создайте отдельную ветку `feature/add_reply` в репозитории.
10. Напишите новый метод для класса Welcomer: метод должен возвращать произвольную реплику, содержащую слово `hunter`.

```java
 public String welcomerSaysNewHunter(){
  return "How you doing, hunter?";
 }
```

11. Дополните тест для нового метода на поиск слова `hunter` в новой реплике.

```java
 @Test
 public void welcomerSaysHunter(){
  assertThat(welcomer.sayHunter(), containsString("hunter"));
 }
```

12. Сделайте push всех изменений в новую ветку репозитория.
13. Убедитесь, что сборка самостоятельно запустилась, тесты прошли успешно.

Запустилось, по событию commit, но упал с ошибкой выкладки в nexus, потому что версия 0.0.2 там уже есть. Поднял версию через еще один коммит

![alt text](img/team6.png "team6")

14. Внесите изменения из произвольной ветки `feature/add_reply` в `master` через `Merge`.

![alt text](img/merge1.png "merge1")

15. Убедитесь, что нет собранного артефакта в сборке по ветке `master`.
16. Настройте конфигурацию так, чтобы она собирала `.jar` в артефакты сборки.

![alt text](img/team7.png "team7")

17. Проведите повторную сборку мастера, убедитесь, что сбора прошла успешно и артефакты собраны.

![alt text](img/team8.png "team8")

18. Проверьте, что конфигурация в репозитории содержит все настройки конфигурации из teamcity.

![alt text](img/git1.png "git1")

19. В ответе пришлите ссылку на репозиторий.

[Fork репозиторий с конфигурацией Teamcity](https://github.com/geon071/example-teamcity)