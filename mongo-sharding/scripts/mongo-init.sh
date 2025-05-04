#!/bin/bash

# Функция ожидания подключения к сервису
# Поскольку инициализация и применение конфигураций занимает время,
# необходимо дождаться, пока к сервису можно будет подключиться
wait_for_service() {
  local service=$1
  local port=$2
  local max_retries=10
  local wait_seconds=5
  local count=1

  echo "Подключиться к $service..."

  until docker exec $service mongosh --port $port --eval "db.adminCommand('ping')" > /dev/null 2>&1
  do
    echo "Попытка $count не удалась. Ждём $wait_seconds сек..."
    if [ "$count" -ge "$max_retries" ]; then
      echo "Не удалось подключиться к $service после $max_retries попыток."
      exit 1
    fi
    count=$((count + 1))
    sleep $wait_seconds
  done

  echo "Успешно подключились к $service"
}

echo "Инициализируем конфигурацию"

wait_for_service configSrv 27017

docker exec configSrv mongosh --port 27017 --eval '
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);'

wait_for_service shard1 27018
echo "Инициализируем первый шард"
docker exec shard1 mongosh --port 27018 --eval '
rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1:27018" },
      ]
    }
)'

wait_for_service shard2 27019
echo "Инициализируем воторой шард"
docker exec shard2 mongosh --port 27019 --eval '
rs.initiate(
    {
      _id : "shard2",
      members: [
        { _id : 1, host : "shard2:27019" }
      ]
    }
  );'

wait_for_service mongos_router 27020
echo "Настройка роутера и заполнение БД.."
docker exec mongos_router mongosh --port 27020 --eval '
sh.addShard( "shard1/shard1:27018");
sh.addShard( "shard2/shard2:27019");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );
let db = db.getSiblingDB("somedb");
for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i});
db.helloDoc.countDocuments();'
echo "Уфф, вроде все, проверим количество документов в шардах"

echo "В первом"
docker exec shard1 mongosh --port 27018 --eval '
let db = db.getSiblingDB("somedb");
db.helloDoc.countDocuments();'

echo "Во втором"
docker exec shard2 mongosh --port 27019 --eval '
let db = db.getSiblingDB("somedb");
db.helloDoc.countDocuments();'
echo "..."
sleep 10