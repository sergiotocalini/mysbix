#!/usr/bin/env ksh
SOURCE_DIR=$(dirname $0)
ZABBIX_DIR=/etc/zabbix

mkdir -p ${ZABBIX_DIR}/scripts/agentd/mysbix
cp -r ${SOURCE_DIR}/mysbix/sql ${ZABBIX_DIR}/scripts/agentd/mysbix/
cp ${SOURCE_DIR}/mysbix/mysbix.sh ${ZABBIX_DIR}/scripts/agentd/mysbix/
cp ${SOURCE_DIR}/mysbix/zabbix_agentd.conf ${ZABBIX_DIR}/zabbix_agentd.d/mysbix.conf
