#!/bin/bash

print_help() {
    echo "Usage: ${0} [OPTION....]"
    echo ""
    echo "  -h                                  this help screen"
    echo ""
    echo "  Required parameters:"
    echo ""
    echo "    -c <catalina base>                  path to the Tomcat base install"
    echo ""
    echo "  Option Parameters:"
    echo ""
    echo "    -o <offset>                         the port offset, defaults to 0"
    echo "    -f <truststore file>                the truststore file to use for HTTPS, defaults to HTTPS off"
    echo "    -p <truststore password>            the truststore password to use for HTTPS, defaults to HTTPS off, required if -f specified"
    echo "    -d <fully qualified domain name>    the fully qualified domain name to use for HTTPS, defaults to `hostname -f`"
    echo "    -j <jvm route>                      the jvm route, defaults to jvmroute"
    echo ""
    exit 0
}

# Set variable defaults
INIT_ROOT=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)
INIT_ROOT=${INIT_ROOT%/bin}
OFFSET=0
TRUSTSTORE_FILE=""
TRUSTSTORE_PASS=""
FQDN=`hostname -f`
JVMROUTE="jvmroute"
CATALINA_BASE=""

# Parameter handling
while getopts "ho:f:p:d:j:c:" ARG; do
    case ${ARG} in
        h)
            print_help
            ;;
        o)
            OFFSET=${OPTARG}
            ;;
        f)
            TRUSTSTORE_FILE=${OPTARG}
            ;;
        p)
            TRUSTSTORE_PASS=${OPTARG}
            ;;
        d)
            FQDN=${OPTARG}
            ;; 
        j)
            JVMROUTE=${OPTARG}
            ;;
        c)
            CATALINA_BASE=${OPTARG}
            ;;
    esac
done

# Verify parameters
VALID_OFFSET='^[0-9]+$'
if [[ -n ${TRUSTSTORE_FILE} ]] && [[ ! -f ${TRUSTSTORE_FILE} ]]; then
    echo "ERROR: Invalid TRUSTSTORE_FILE specified."
    echo ""
    print_help
elif [[ -f ${TRUSTSTORE_FILE} ]] && [[ -z ${TRUSTSTORE_PASS} ]]; then
    echo "ERROR: TRUSTSTORE_FILE specified but no password specified."
    echo ""
    print_help
elif [[ ! ${OFFSET} =~ ${VALID_OFFSET} ]]; then
    echo "ERROR: Specified offset is not a number."
    echo ""
    print_help
elif [[ ! -d ${CATALINA_BASE} ]]; then
    echo "ERROR: Specified CATALINA_BASE does not exist."
    echo ""
    print_help
fi

# Set ports from default port + provided offset
SHUTDOWN_PORT=$((7005 + ${OFFSET}))
HTTP_PORT=$((8080 + ${OFFSET}))
HTTPS_PORT=$((8443 + ${OFFSET}))
AJP_PORT=$((8009 + ${OFFSET}))

# Create required base directories
mkdir -p ${INIT_ROOT}/conf ${INIT_ROOT}/bin ${INIT_ROOT}/work ${INIT_ROOT}/lib ${INIT_ROOT}/webapps ${INIT_ROOT}/logs ${INIT_ROOT}/temp

# Replace template stubs with real values
perl -pi -e "s/__SHUTDOWN_PORT__/${SHUTDOWN_PORT}/g" ${INIT_ROOT}/conf/server.xml
perl -pi -e "s/__HTTP_PORT__/${HTTP_PORT}/g" ${INIT_ROOT}/conf/server.xml
perl -pi -e "s/__HTTPS_PORT__/${HTTPS_PORT}/g" ${INIT_ROOT}/conf/server.xml
perl -pi -e "s/__AJP_PORT__/${AJP_PORT}/g" ${INIT_ROOT}/conf/server.xml
perl -pi -e "s/__TOMCAT_INSTALL_DIR__/${INIT_ROOT//\//\\/}/g" ${INIT_ROOT}/bin/setenv.sh
perl -pi -e "s/__CATALINA_BASE__/${CATALINA_BASE//\//\\/}/g" ${INIT_ROOT}/bin/setenv.sh
perl -pi -e "s/__JVM_ROUTE__/${JVMROUTE}/g" ${INIT_ROOT}/conf/server.xml
perl -pi -e "s/__FQDN__/${FQDN}/g" ${INIT_ROOT}/conf/server.xml
perl -pi -e "s/__TRUSTSTORE_FILE__/${TRUSTSTORE_FILE//\//\\/}/g" ${INIT_ROOT}/conf/server.xml
perl -pi -e "s/__TRUSTSTORE_PASS__/${TRUSTSTORE_PASS}/g" ${INIT_ROOT}/conf/server.xml

# Enable HTTPS if TRUSTSTORE_* provided
if [[ -f ${TRUSTSTORE_FILE} ]]; then
    perl -pi -e "s/<!-- REMOVE TO ENABLE HTTPS//g" ${INIT_ROOT}/conf/server.xml
    perl -pi -e "s/REMOVE TO ENABLE HTTPS -->//g" ${INIT_ROOT}/conf/server.xml
fi

# Create symlinks to install root
ln -sf ${CATALINA_BASE}/bin/tomcat-juli.jar ${INIT_ROOT}/bin/tomcat-juli.jar
ln -sf ${CATALINA_BASE}/bin/catalina.sh ${INIT_ROOT}/bin/catalina.sh
ln -sf ${CATALINA_BASE}/bin/daemon.sh ${INIT_ROOT}/bin/daemon.sh
ln -sf ${CATALINA_BASE}/bin/digest.sh ${INIT_ROOT}/bin/digest.sh
ln -sf ${CATALINA_BASE}/bin/setclasspath.sh ${INIT_ROOT}/bin/setclasspath.sh
ln -sf ${CATALINA_BASE}/bin/shutdown.sh ${INIT_ROOT}/bin/shutdown.sh
ln -sf ${CATALINA_BASE}/bin/startup.sh ${INIT_ROOT}/bin/startup.sh
ln -sf ${CATALINA_BASE}/bin/tool-wrapper.sh ${INIT_ROOT}/bin/tool-wrapper.sh
ln -sf ${CATALINA_BASE}/bin/version.sh ${INIT_ROOT}/bin/version.sh
ln -sf ${CATALINA_BASE}/conf/catalina.properties ${INIT_ROOT}/conf/catalina.properties
ln -sf ${CATALINA_BASE}/conf/logging.properties ${INIT_ROOT}/conf/logging.properties
ln -sf ${CATALINA_BASE}/conf/web.xml ${INIT_ROOT}/conf/web.xml

unset CATALINA_BASE INIT_ROOT OFFSET SHUTDOWN_PORT HTTP_PORT HTTPS_PORT AJP_PORT FQDN JVMROUTE

