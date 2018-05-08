#!/bin/bash

if [ "${PWD##*/}" == "create" ]; then
    KUBECONFIG_FOLDER=${PWD}/../../kube-configs
elif [ "${PWD##*/}" == "scripts" ]; then
    KUBECONFIG_FOLDER=${PWD}/../kube-configs
else
    echo "Please run the script from 'scripts' or 'scripts/create' folder"
fi

PAID=false

Parse_Arguments() {
	while [ $# -gt 0 ]; do
		case $1 in
			--paid)
				echo "Configured to setup a paid storage on ibm-cs"
				PAID=true
				;;
			--business-network-card)
				shift
				COMPOSER_CARD=$1
				;;
			--port)
				shift
				PORT_NUMBER=$1
				;;
		esac
		shift
	done
}

Parse_Arguments $@

if [ "${PAID}" == "true" ]; then
	OFFERING="paid"
else
	OFFERING="free"
fi

if [ -z ${COMPOSER_CARD} ]; then
	echo "Usage: $0 --business-network-card <business-network-card> --port <port_number> [--paid]"
    exit 1
fi

if [ -z ${PORT_NUMBER} ]; then
	echo "Usage: $0 --business-network-card <business-network-card> --port <port_number> [--paid]"
    exit 1
fi

echo "Preparing yaml file for create composer-rest-server"
rm ${KUBECONFIG_FOLDER}/composer-rest-server.yaml
cat ${KUBECONFIG_FOLDER}/composer-rest-server.yaml.base | \
sed 's/%COMPOSER_CARD%/'${COMPOSER_CARD}'/g;' | \
sed 's/%PORT_NUMBER%/'${PORT_NUMBER}'/g;' \
> ${KUBECONFIG_FOLDER}/composer-rest-server.yaml



echo "Preparing yaml file for create composer-rest-server-services"
sed -e "s/%PORT_NUMBER%/${PORT_NUMBER}/g" ${KUBECONFIG_FOLDER}/composer-rest-server-services-${OFFERING}.yaml.base > ${KUBECONFIG_FOLDER}/composer-rest-server-services-${OFFERING}.yaml

echo "Creating composer-rest-server pod"
echo "Running: kubectl create -f ${KUBECONFIG_FOLDER}/composer-rest-server.yaml"
kubectl create -f ${KUBECONFIG_FOLDER}/composer-rest-server.yaml

if [ "$(kubectl get svc | grep composer-rest-server-${PORT_NUMBER} | wc -l | awk '{print $1}')" == "0" ]; then
    echo "Creating composer-rest-server service"
    echo "Running: kubectl create -f ${KUBECONFIG_FOLDER}/composer-rest-server-services-${OFFERING}.yaml"
    kubectl create -f ${KUBECONFIG_FOLDER}/composer-rest-server-services-${OFFERING}.yaml
fi

echo "Composer rest server created successfully"
