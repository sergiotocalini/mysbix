# mysbix
Zabbix Agent - MySQL

# Dependencies
## Packages
* ksh

### Debian/Ubuntu

    #~ apt install ksh
    #~

## MySQL configuration

    #~ cat /root/.my.cnf
    [client]
    user = "root"
    password = "xxxxx"
    #~
   
# Deployment
## Zabbix

    #~ git clone https://github.com/sergiotocalini/mysbix.git
    #~ ./mysbix/deploy_zabbix.sh 'monitor' 'xxxxxx' 'localhost'
    #~
   
   
