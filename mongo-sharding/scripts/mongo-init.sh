#!/bin/bash
echo "Инициализируем конфигурацию"
sleep 20
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
echo "Подождём 10 секунд, чтобы конфигурация успела примениться..."
sleep 20
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
echo "Подождём 10 секунд, чтобы конфигурация успела примениться..."
sleep 20
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
echo "Подождём 10 секунд, чтобы конфигурация успела примениться..."
sleep 20
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