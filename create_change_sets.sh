#!/bin/sh

. ./.env_vars

if [ $# -ne 1 ]; then
    echo "      $0 <ENV_TYPE(dev|stg|prod)>"
    exit 1
elif [ "$1" != "dev" -a "$1" != "stg" -a "$1" != "prod" ]; then
    echo "      $0 <ENV_TYPE(dev|stg|prod)>"
    exit 1
fi

cd `dirname $0`

SYSTEM_NAME=RockyLinux8
ENV_TYPE=$1

create_change_set () {
    STACK_NAME=$1
    aws cloudformation create-change-set \
    --stack-name ${SYSTEM_NAME}-${ENV_TYPE}-${STACK_NAME} \
    --change-set-name ${SYSTEM_NAME}-${ENV_TYPE}-${STACK_NAME}-change-set \
    --template-body file://./${SYSTEM_NAME}/${STACK_NAME}/${STACK_NAME}.yml \
    --cli-input-json file://./${SYSTEM_NAME}/${STACK_NAME}/${ENV_TYPE}-parameters.json \
    --profile ${SYSTEM_NAME}-${ENV_TYPE}


    aws cloudformation wait change-set-create-complete \
    --stack-name ${SYSTEM_NAME}-${ENV_TYPE}-${STACK_NAME} \
    --change-set-name ${SYSTEM_NAME}-${ENV_TYPE}-${STACK_NAME}-change-set \
    --profile ${SYSTEM_NAME}-${ENV_TYPE}
}

#####################################
# 最初に実行する
#####################################
# create_change_set iam
# create_change_set network
# create_change_set sg
# create_change_set ami-build

#####################################
# /RockyLinux8/ec2/{EnvType}-parameters.json
# "AMIID" へ作成されたAMI IDを入力後実行する
#####################################
# create_change_set ec2

exit 0