#!/bin/bash

prevent_startup() {
    echo "ERROR: You must run `dirname ${0}`/../bin/setup.sh for this instance to function"
    exit 1
}

CATALINA_BASE="__CATALINA_BASE__"
CATALINA_HOME="__TOMCAT_INSTALL_DIR__"

# Verify setup.sh has been run & a proper CATALINA_BASE/_HOME has been set
if [ -d ${CATALINA_BASE} ] && [ -d ${CATALINA_HOME} ]; then
    STUBS=`grep "__" ${CATALINA_HOME}/conf/server.xml | wc -l`
    
    if [ 0 -ne ${STUBS} ]; then
        prevent_startup
    fi
else
    prevent_startup
fi

JAVA_OPTS="${JAVA_OPTS}"

