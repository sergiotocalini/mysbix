#!/usr/bin/env ksh
PATH=/usr/local/bin:${PATH}
IFS_DEFAULT="${IFS}"
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

zabbix_not_support() {
    echo "ZBX_NOTSUPPORTED"
    exit 1
}

vert2json() {
    sql="${1}"
    attrs="${2:-.[]}"

    json_raw=""
    idx="${#rows[@]}"
    while read line; do
	if [[ "${line}" =~ ^\* ]]; then
	    pos=${idx}
	    let "idx=idx+1"
	else
	    key=`echo ${line}|awk -F: '{print $1}'|awk '{$1=$1};1'`
	    val=`echo ${line}|awk -F: '{print $2}'|awk '{$1=$1};1'`

	    rows[${pos}]+="\"${key}\":\"${val}\","
	fi
    done <<< "${sql}"

    json_raw="[ "
    for idx in ${!rows[@]}; do
	json_raw+="{${rows[${idx}]%?}},"
    done
    echo "${json_raw%?} ]" | jq -r "${attrs}" 2>/dev/null
}

sql_exec() {
    sql=${1}
    sql_args=( ${2} )
    sql_opts=${3}
    
    if [[ -f "${sql%.sql}.sql" ]]; then
	count=1
	for arg in ${sql_args[@]}; do
	    params+="SET @p${count}=\"${arg}\";"
	    let "count=count+1"
	done

	rval=`mysql --defaults-file=${APP_DIR}/.my.conf \
                    -s${sql_opts:-N}e "${params}source ${SQL%.sql}.sql;" 2>/dev/null`
	echo "${rval}"
	return 0
    fi

    return 1
}

join() {
    delimiter=${1}
    shift
    array=( ${@} )

    length=$(( ${#array[@]} - 1 ))
    for idx in ${!array[@]}; do
	if [[ ${array[${idx}]} != '' && ${array[${idx}]} != ${delimiter} ]]; then
	    str+="${array[${idx}]}"
	    if [[ ${idx} < ${length} ]]; then
		str+="${delimiter}"
	    fi
	fi
    done
    echo "${str}"
}
#
#################################################################################

#################################################################################
while getopts "s::a:q:s:uphvj:" OPTION; do
    case ${OPTION} in
	h)
	    usage
	    ;;
	s)
	    SQL="${APP_DIR}/sql/${OPTARG}"
	    ;;	    
	o)
	    OUTPUT="${OPTARG}"
	    ;;
        j)
	    JSON=1
            IFS=":" JSON_ATTR=( ${OPTARG-:0} )
	    IFS="${IFS_DEFAULT}"
            ;;
	a)
	    ARGS[${#ARGS[*]}]=${OPTARG//p=}
	    ;;
	v)
	    version
	    ;;
        \?)
            exit 1
            ;;
    esac
done

if [[ `basename ${SQL%.sql}` =~ replication_(masters|slaves) ]]; then
    rval=$( sql_exec "${SQL}" "" "E" )
    [ ${?} != 0 ] && zabbix_not_support

    if [[ -n ${rval} ]]; then
	if [[ ${#ARGS[*]} > 0 ]]; then
	    for arg in ${ARGS[@]}; do
		key=`echo ${arg}|awk -F: '{print $1}'|awk '{$1=$1};1'`
		val=`echo ${arg}|awk -F: '{print $2}'|awk '{$1=$1};1'`
		if [[ -n ${key} && -n ${val} ]]; then
		    selec[${#selec[@]}]=".${key}==\"${val}\""
		else
		    attrs[${#attrs[@]}]="\(.${arg})"
		fi
	    done
	    filters[${#filters[@]}]=".[]"
	    [[ ${#selec[*]} > 0 ]] && filters[${#filters[@]}]="select($( join " and" ${selec[@]} ))"
	    [[ ${#attrs[*]} > 0 ]] && filters[${#filters[@]}]="\"$( join " | " ${attrs[@]:-'\(.)'} )\""
	    filters=$( join "|" ${filters[@]} )
	elif [[ `basename ${SQL%.sql}` == 'replication_masters' ]]; then
	    if [[ ${JSON} -eq 1 ]]; then
		filters=".[] | \"\(.Master_Host)|\(.Master_UUID)|\(.Master_Server_Id)\""
	    else
		filters=".[] | {Master_Host, Master_UUID, Master_Server_Id}"
	    fi
	elif [[ `basename ${SQL%.sql}` == 'replication_slaves' ]]; then
	    if [[ ${JSON} -eq 1 ]]; then
		filters=".[] | \"\(.Host)|\(.Server_id)|\(.Slave_UUID)|\(.Master_id)\""
	    else
		filters=".[] | {Host, Server_id, Slave_UUID, Master_id}"
	    fi
	fi
	rval=$( vert2json "${rval}" "${filters}" )
    fi
else
    rval=$( sql_exec "${SQL}" "${ARGS[*]}" )
    [ ${?} != 0 ] && zabbix_not_support
    if [[ `basename ${SQL%.sql}.sql` =~ (global_status|global_variables) ]]; then
	rval=`echo ${rval} | sed -s "s:^${ARGS[0]} ::"`
    fi
fi


if [[ ${JSON} -eq 1 ]]; then
    echo '{'
    echo '   "data":['
    count=1
    while read line; do
	if [[ ${line} != '' ]]; then
            IFS="|" values=(${line})
            output='{ '
            for val_index in ${!values[*]}; do
		output+='"'{#${JSON_ATTR[${val_index}]:-${val_index}}}'":"'${values[${val_index}]}'"'
		if (( ${val_index}+1 < ${#values[*]} )); then
                    output="${output}, "
		fi
            done 
            output+=' }'
            if (( ${count} < `echo ${rval}|wc -l` )); then
		output="${output},"
            fi
            echo "      ${output}"
	fi
        let "count=count+1"
    done <<< ${rval}
    echo '   ]'
    echo '}'
else
    echo "${rval:-0}"
fi

exit ${rcode}
