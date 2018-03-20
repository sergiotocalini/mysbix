#!/usr/bin/env ksh
rcode=0
PATH=/usr/local/bin:${PATH}

#################################################################################

#################################################################################
#
#  Variable Definition
# ---------------------
#
APP_NAME=$(basename $0)
APP_DIR=$(dirname $0)
APP_VER="1.0.0"
APP_WEB="http://www.sergiotocalini.com.ar/"
#
#################################################################################

#################################################################################
#
#  Load Oracle Environment
# -------------------------
#
[ -f ${APP_DIR}/${APP_NAME%.*}.conf ] && . ${APP_DIR}/${APP_NAME%.*}.conf

#
#################################################################################

#################################################################################
#
#  Function Definition
# ---------------------
#
usage() {
    echo "Usage: ${APP_NAME%.*} [Options]"
    echo ""
    echo "Options:"
    echo "  -a            Query arguments."
    echo "  -h            Displays this help message."
    echo "  -j            Jsonify output."
    echo "  -s ARG(str)   Query to MySQL."
    echo "  -v            Show the script version."
    echo ""
    echo "Please send any bug reports to sergiotocalini@gmail.com"
    exit 1
}

version() {
    echo "${APP_NAME%.*} ${APP_VER}"
    exit 1
}
#
#################################################################################

#################################################################################
while getopts "s::a:s:uphvj:" OPTION; do
    case ${OPTION} in
	h)
	    usage
	    ;;
	s)
	    SQL="${APP_DIR}/sql/${OPTARG}"
	    ;;
        j)
            JSON=1
	    #JSON_ATTR=${OPTARG}
            IFS=":" JSON_ATTR=(${OPTARG})
            ;;
	a)
	    SQL_ARGS[${#SQL_ARGS[*]}]=${OPTARG}
	    ;;
	v)
	    version
	    ;;
         \?)
            exit 1
            ;;
    esac
done

count=1
for arg in ${SQL_ARGS[@]}; do
    ARGS+="SET @p${count}=\"${arg//p=}\"; "
    let "count=count+1"
done

if [[ -f "${SQL%.sql}.sql" ]]; then
    rval=`mysql --defaults-file=${APP_DIR}/.my.conf -sNe "${ARGS} source ${SQL%.sql}.sql;" 2>/dev/null`
    rval=`echo ${rval} | sed -s "s:^${SQL_ARGS[1]} ::"`
    rcode="${?}"
    if [[ ${JSON} -eq 1 ]]; then
       echo '{'
       echo '   "data":['
       count=1
       while read line; do
          IFS="|" values=(${line})
          output='{ '
          for val_index in ${!values[*]}; do
             output+='"'{#${JSON_ATTR[${val_index}]}}'":"'${values[${val_index}]}'"'
             if (( ${val_index}+1 < ${#values[*]} )); then
                output="${output}, "
             fi
          done 
          output+=' }'
          if (( ${count} < `echo ${rval}|wc -l` )); then
             output="${output},"
          fi
          echo "      ${output}"
          let "count=count+1"
       done <<< ${rval}
       echo '   ]'
       echo '}'
    else
       echo ${rval:-0}
    fi
else
    echo "ZBX_NOTSUPPORTED"
    rcode="1"
fi

exit ${rcode}
