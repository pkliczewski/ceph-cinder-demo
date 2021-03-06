
all: cluster-up cluster-openshift cluster-storage cluster-kubevirt cluster-miq

cluster-up:
	vagrant up --no-provision

cluster-openshift:
	vagrant provision node --provision-with=node
	vagrant provision master --provision-with=master

cluster-storage:
	vagrant provision --provision-with=storage

cluster-kubevirt:
	vagrant provision --provision-with=kubevirt

cluster-miq:
	vagrant provision --provision-with=miq

cluster-clean:
	rm .oc.sh -rf
	rm oc.sh -rf
	rm .kubeconfig -rf
	rm .kubectl -rf
	vagrant destroy
