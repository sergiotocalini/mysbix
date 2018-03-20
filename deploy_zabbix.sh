#!/usr/bin/env ksh
SOURCE_DIR=$(dirname $0)
ZABBIX_DIR=/etc/zabbix

MYSQL_USER=${1:-monitor}
MYSQL_PASS=${2}
MYSQL_HOST=${3:-localhost}

mkdir -p ${ZABBIX_DIR}/scripts/agentd/mysbix
cp -rv ${SOURCE_DIR}/mysbix/mysbix.sh            ${ZABBIX_DIR}/scripts/agentd/mysbix/
cp -rv ${SOURCE_DIR}/mysbix/.my.conf             ${ZABBIX_DIR}/scripts/agentd/mysbix/
cp -rv ${SOURCE_DIR}/mysbix/mysbix.conf.example  ${ZABBIX_DIR}/scripts/agentd/mysbix/mysbix.conf
cp -rv ${SOURCE_DIR}/mysbix/sql                  ${ZABBIX_DIR}/scripts/agentd/mysbix/
cp -rv ${SOURCE_DIR}/mysbix/zabbix_agentd.conf   ${ZABBIX_DIR}/zabbix_agentd.d/mysbix.conf

sed -i "s|host = .*|host = \"${MYSQL_HOST}\"|g" ${ZABBIX_DIR}/scripts/agentd/mysbix/.my.conf
sed -i "s|user = .*|user = \"${MYSQL_USER}\"|g" ${ZABBIX_DIR}/scripts/agentd/mysbix/.my.conf
sed -i "s|password = .*|password = \"${MYSQL_PASS}\"|g" ${ZABBIX_DIR}/scripts/agentd/mysbix/.my.conf

mysql -sNe "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'${MYSQL_HOST}' IDENTIFIED BY '${MYSQL_PASS}';"
mysql -sNe "GRANT SELECT ON *.* TO '${MYSQL_USER}'@'${MYSQL_HOST}';"
