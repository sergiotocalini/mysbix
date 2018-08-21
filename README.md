# mysbix
Zabbix Agent - MySQL

* Replication: Masters and Slaves

# Dependencies
## Packages
* ksh
* jq

### Debian/Ubuntu

    #~ apt install ksh jq
    #~

## MySQL configuration

    #~ cat /etc/zabbix/scripts/agent/mysbix/.my.cnf
    [client]
    user = "monitor"
    password = "xxxxx"
    #~
   
# Deployment
## Zabbix

    #~ git clone https://github.com/sergiotocalini/mysbix.git
    #~ ./mysbix/deploy_zabbix.sh 'monitor' 'xxxxxx' 'localhost'
    #~
   
   
