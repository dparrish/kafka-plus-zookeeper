# Zookeeper & Kafka on GKE Demonstration

This is a demonstration of running Zookeeper and Kafka on Google Kubernnetes
Engine. The GKE cluster is created with Terraform, which creates a Kubernetes
client configuration file ready for `kubectl`.

Zookeeper configuration is based on https://github.com/kubernetes/contrib/tree/master/statefulsets/zookeeper.

Kafka configuration is based on https://github.com/kubernetes/contrib/tree/master/statefulsets/kafka.

## Steps

First of all, make sure `terraform` and `kubectl` are installed.

```sh
git clone https://github.com/dparrish/kafka-plus-zookeeper.git
cd kafka-plus-zookeeper
terraform init
terraform apply
kubectl --kubeconfig kubeconfig.yaml apply -f zookeeper.yaml
sleep 30
kubectl --kubeconfig kubeconfig.yaml get pod
```

Watch the output of `get pod` until there are at least two `zk-*` pods available, which is the minimum availability for the test Zookeeper cluster.

```sh
kubectl --kubeconfig kubeconfig.yaml apply -f kafka.yaml
sleep 30
kubectl --kubeconfig kubeconfig.yaml get pod
```

You should see 3 kafka pods in `Running` state.

Follow the testing instructions at
https://github.com/kubernetes/contrib/tree/master/statefulsets/kafka#testing to
send some test messages.


## Clean-up

To avoid incurring cost, destroy the Kubernetes cluster.

```sh
$ terraform destroy
```
