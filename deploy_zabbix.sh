#!/usr/bin/env ksh
SOURCE_DIR=$(dirname $0)
ZABBIX_DIR=/etc/zabbix

MYSQL_USER=${1:-monitor}
MYSQL_PASS=${2}
MYSQL_HOST=${3:-localhost}

mkdir -p ${ZABBIX_DIR}/scripts/agentd/mysbix

SCRIPT_AUTH="${ZABBIX_DIR}/scripts/agentd/mysbix/.my.conf"
[[ -f ${SCRIPT_AUTH} ]] && SCRIPT_AUTH="${SCRIPT_AUTH}.new"
SCRIPT_CONFIG="${ZABBIX_DIR}/scripts/agentd/mysbix/mysbix.conf"
[[ -f ${SCRIPT_CONFIG} ]] && SCRIPT_CONFIG="${SCRIPT_CONFIG}.new"

cp -rv ${SOURCE_DIR}/mysbix/mysbix.sh            ${ZABBIX_DIR}/scripts/agentd/mysbix/
cp -rv ${SOURCE_DIR}/mysbix/sql                  ${ZABBIX_DIR}/scripts/agentd/mysbix/
cp -rv ${SOURCE_DIR}/mysbix/zabbix_agentd.conf   ${ZABBIX_DIR}/zabbix_agentd.d/mysbix.conf
cp -rv ${SOURCE_DIR}/mysbix/.my.conf             ${SCRIPT_AUTH}
cp -rv ${SOURCE_DIR}/mysbix/mysbix.conf.example  ${SCRIPT_CONFIG}

regex_array[0]="s|host = .*|host = \"${MYSQL_HOST}\"|g"
regex_array[1]="s|user = .*|user = \"${MYSQL_USER}\"|g"
regex_array[2]="s|password = .*|password = \"${MYSQL_PASS}\"|g"
for index in ${!regex_array[*]}; do
    sed -i "${regex_array[${index}]}" ${SCRIPT_AUTH}
done

mysql -sNe "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'${MYSQL_HOST}' IDENTIFIED BY '${MYSQL_PASS}';"
mysql -sNe "GRANT SELECT, REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO '${MYSQL_USER}'@'${MYSQL_HOST}';"
