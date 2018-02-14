#!/bin/bash

function _main_ip() {
    echo 192.168.231.2
}

function up() {
    export USING_KUBE_SCRIPTS=true
    # Make sure that the vagrant environment is up and running
    vagrant up --provider=libvirt
    # Synchronize kubectl config
    vagrant ssh-config master 2>&1 | grep "not yet ready for SSH" >/dev/null &&
        {
            echo "Master node is not up"
            exit 1
        }

    OPTIONS=$(vagrant ssh-config master | grep -v '^Host ' | awk -v ORS=' ' 'NF{print "-o " $1 "=" $2}')

    scp $OPTIONS master:/usr/bin/kubectl ${KUBEVIRT_PATH}cluster/.kubectl
    chmod u+x cluster/.kubectl

    vagrant ssh master -c "sudo cat /etc/kubernetes/admin.conf" >${KUBEVIRT_PATH}cluster/.kubeconfig

    # Make sure that local config is correct
    prepare_config
}

function prepare_config() {
    BASE_PATH=${KUBEVIRT_PATH:-$PWD}
    cat >hack/config-provider-vagrant-kubernetes.sh <<EOF
master_ip=$(_main_ip)
docker_tag=devel
kubeconfig=${BASE_PATH}/cluster/vagrant-kubernetes/.kubeconfig
EOF
}

function build() {
    make build manifests
    for VM in $(vagrant status | grep -v "^The Libvirt domain is running." | grep running | cut -d " " -f1); do
        vagrant rsync $VM # if you do not use NFS
        vagrant ssh $VM -c "cd /vagrant && export DOCKER_TAG=${docker_tag} && sudo -E hack/build-docker.sh build"
    done
}

function _kubectl() {
    export KUBECONFIG=${KUBEVIRT_PATH}cluster/.kubeconfig
    ${KUBEVIRT_PATH}cluster/.kubectl "$@"
}

function down() {
    vagrant halt
}