#!/bin/sh

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

delete_stack () {
    STACK_NAME=$1
    aws cloudformation delete-stack \
    --stack-name ${SYSTEM_NAME}-${ENV_TYPE}-${STACK_NAME} \
    --profile ${SYSTEM_NAME}-${ENV_TYPE}

    aws cloudformation wait stack-delete-complete \
    --stack-name ${SYSTEM_NAME}-${ENV_TYPE}-${STACK_NAME} \
    --profile ${SYSTEM_NAME}-${ENV_TYPE}
}

# delete_stack ec2
# delete_stack ami-build
# delete_stack sg
# delete_stack network
# delete_stack iam

exit 0