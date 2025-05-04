# pymongo-api

## Как запустить

Перейти в каталог sharding-repl-cache

```shell
cd .\sharding-repl-cache\
```

Запустить mongodb в режиме шардирования и репликации, reddis и приложение

```shell
docker compose up -d
```

Инициализировать mongodb с шардированием и репликацией и заполнить данными

```shell
./scripts/mongo-init.sh
```
Скрипт выполняет следующие операции:
1. инициализирует сервис конфигурации configSrv, инициализирует 3 реплики
2. инициализирует шарды shard1-1 и shard2-1 и их реплики
3. инициализирует роутер mongos_router и создает тестовые данные
4. демонстрирует количество документов в шардах

> Скрипт написан для выполнения в Windows

## Как проверить

Откройте в браузере http://localhost:8080

## Доступные эндпоинты

Список доступных эндпоинтов, swagger http://localhost:8080/docs

## Схемы по заданию

[Здесь](https://drive.google.com/file/d/10aabCoBvxNod4RT49UngOWWJgXRTZv_i/view?usp=sharing)