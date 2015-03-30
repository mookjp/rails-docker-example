#!/bin/sh -x

echo "Start to create backup for DB..."
docker run --volumes-from railsdockerexample_data_1 -v /backup/db:/backup busybox tar cvf /backup/db_$(date +%Y%m%d%H%M).tar /var/lib/postgresql/data

echo "Start to create backup for /tmp ..."
docker run --volumes-from railsdockerexample_data_1 -v /backup/tmp:/backup busybox tar cvf /backup/tmp_$(date +%Y%m%d%H%M).tar /tmp
