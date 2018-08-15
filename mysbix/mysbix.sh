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

vert2csv() {
    sql_raw="${1}"

    IFS="${IFS_DEFAULT}"
    json_raw=""
    idx="${#rows[@]}"
    while read line; do
	if [[ "${line}" =~ ^\* ]]; then
	    pos=${idx}
	    let "idx=idx+1"
	else
	    rows[${pos}]+="${line}|"
	fi
    done <<< "${sql_raw}"
    
    for idx in ${!rows[@]}; do
    	echo "${rows[${idx}]%?}"
    done
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

#
#################################################################################

#################################################################################
while getopts "s::a:q:s:uphvj:" OPTION; do
    case ${OPTION} in
	h)
	    usage
	    ;;
	q)
	    SQL="${APP_DIR}/sql/${OPTARG}"
	    ;;	    
	s)
	    SECTION="${OPTARG}"
	    ;;
        j)
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

sql_exec() {
    sql=${1}
    sql_args=( ${2} )
    sql_opts=${3}
    
    if [[ -f "${sql%.sql}.sql" ]]; then
	count=1
	for arg in ${sql_args[@]}; do
	    params+="SET @p${count}=\"${arg}\"; "
	    let "count=count+1"
	done

	rval=`mysql --defaults-file=${APP_DIR}/.my.conf \
                    -${sql_opts:-N} -se "${params} source ${SQL%.sql}.sql; " 2>/dev/null`
	echo "${rval}"
	return 0
    fi

    return 1
}

discovery() {
    sql=${1}
    sql_args=( ${2} )

    if [[ `basename ${sql%.sql}` =~ replication ]]; then
	rval=$( sql_exec "${sql}" "${sql_args[*]}" "E" )
	rval=$( vert2json "${rval}" ".[] | \"\(.Host)|\(.Server_id)|\(.Slave_UUID)\"" )
    else
	rval=$( sql_exec "${sql}" "${sql_args[*]}" )
    fi

    echo "${rval}"
}

if [[ ${SECTION} == 'discovery' ]]; then
    rval=$(discovery "${SQL}" "${ARGS[*]}" )
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
fi

# count=1
# for arg in ${SQL_ARGS[@]}; do
#     ARGS+="SET @p${count}=\"${arg//p=}\"; "
#     let "count=count+1"
# done

# if [[ -f "${SQL%.sql}.sql" ]]; then
#     rval=`mysql --defaults-file=${APP_DIR}/.my.conf -sNe "${ARGS} source ${SQL%.sql}.sql;" 2>/dev/null`
#     if [[ `basename ${SQL%.sql}.sql` =~ (global_status|global_variables) ]]; then
# 	rval=`echo ${rval} | sed -s "s:^${SQL_ARGS[0]//p=} ::"`
#     elif [[ `basename ${SQL%.sql}.sql` =~ replication_(masters|slaves).* ]]; then
# 	rval=$( vert2json "${rval}" "${SQL_ARGS[@]}" )
#     fi
#     rcode="${?}"
#     if [[ ${JSON} -eq 1 ]]; then
#        echo '{'
#        echo '   "data":['
#        count=1
#        while read line; do
# 	   if [[ ${line} != '' ]]; then
#                IFS="|" values=(${line})
#                output='{ '
#                for val_index in ${!values[*]}; do
# 		   output+='"'{#${JSON_ATTR[${val_index}]:-${val_index}}}'":"'${values[${val_index}]}'"'
# 		   if (( ${val_index}+1 < ${#values[*]} )); then
#                        output="${output}, "
# 		   fi
#                done 
#                output+=' }'
#                if (( ${count} < `echo ${rval}|wc -l` )); then
# 		   output="${output},"
#                fi
#                echo "      ${output}"
# 	   fi
#            let "count=count+1"
#        done <<< ${rval}
#        echo '   ]'
#        echo '}'
#     else
#        echo "${rval:-0}"
#     fi
# else
#     echo "ZBX_NOTSUPPORTED"
#     rcode="1"
# fi

exit ${rcode}
