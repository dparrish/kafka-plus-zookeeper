# Zookeeper & Kafka on GKE Demonstration

This is a demonstration of running Zookeeper and Kafka on Google Kubernnetes
Engine. The GKE cluster is created with Terraform, which creates a Kubernetes
client configuration file ready for `kubectl`.

Zookeeper configuration is based on
https://github.com/kubernetes/contrib/tree/master/statefulsets/zookeeper.

Kafka configuration is based on
https://github.com/kubernetes/contrib/tree/master/statefulsets/kafka.

## Steps

First of all, make sure `terraform` and `kubectl` are installed. You will need
to create a service account with permission to create GKE clusters, or remove
the `credentials` line from `main.tf`. 


```
$ git clone https://github.com/dparrish/kafka-plus-zookeeper.git
remote: Enumerating objects: 12, done.
remote: Counting objects: 100% (12/12), done.
remote: Compressing objects: 100% (12/12), done.
remote: Total 12 (delta 0), reused 12 (delta 0), pack-reused 0
Unpacking objects: 100% (12/12), done.
Checking connectivity... done.

$ cd kafka-plus-zookeeper
```

If you created a service account for Terraform, be sure to download the key.

```
$ gcloud --project project iam service-accounts keys create credentials.json --iam-account=terraform@project.iam.gserviceaccount.com
created key [1488f0daecdf0ae8757eb276c956b5ab90e3a571] of type [json] as [credentials.json] for [terraform@project.iam.gserviceaccount.com]
```

```
$ terraform init
Initializing provider plugins...
- Checking for available provider plugins on https://releases.hashicorp.com...
- Downloading plugin for provider "local" (1.1.0)...
- Downloading plugin for provider "google" (1.18.0)...
- Downloading plugin for provider "template" (1.0.0)...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.google: version = "~> 1.18"
* provider.local: version = "~> 1.1"
* provider.template: version = "~> 1.0"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.

$ terraform apply
var.project
  Enter a value: project

var.region
  Enter a value: us-west1


An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create
 <= read (data resources)

Terraform will perform the following actions:

 <= data.template_file.kubeconfig
      id:                                                                 <computed>
      rendered:                                                           <computed>
      template:                                                           "apiVersion: v1\nclusters:\n- cluster:\n ..."
      vars.%:                                                             <computed>

  + google_container_cluster.primary
      id:                                                                 <computed>
...
      zone:                                                               <computed>

  + local_file.kubeconfig
      id:                                                                 <computed>
      content:                                                            "${data.template_file.kubeconfig.rendered}"
      filename:                                                           "kubeconfig.yaml"


Plan: 2 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

google_container_cluster.primary: Creating...
  additional_zones.#:                                                 "" => "<computed>"
...
  zone:                                                               "" => "<computed>"
google_container_cluster.primary: Still creating... (10s elapsed)
...
google_container_cluster.primary: Creation complete after 2m32s (ID: cluster-1)
data.template_file.kubeconfig: Refreshing state...
local_file.kubeconfig: Creating...
  content:  "" => "apiVersion: v1\nclusters:\n- cluster:\n..."
  filename: "" => "kubeconfig.yaml"
local_file.kubeconfig: Creation complete after 0s (ID: 52f59068ebc0a0b7e1b586be6846bd55245ac8e0)

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

$ kubectl --kubeconfig kubeconfig.yaml apply -f zookeeper.yaml
service "zk-svc" created
configmap "zk-cm" created
poddisruptionbudget "zk-pdb" created
statefulset "zk" created

$ sleep 60
NAME      READY     STATUS              RESTARTS   AGE
zk-0      1/1       Running             0          1m
zk-1      1/1       Running             0          36s
zk-2      0/1       ContainerCreating   0          4s

$ kubectl --kubeconfig kubeconfig.yaml get pod
```

Watch the output of `get pod` until there are at least two `zk-*` pods
available, which is the minimum availability for the test Zookeeper cluster.

```
$ kubectl --kubeconfig kubeconfig.yaml apply -f kafka.yaml
service "kafka-svc" created
poddisruptionbudget "kafka-pdb" created
statefulset "kafka" created

$ sleep 60

$ kubectl --kubeconfig kubeconfig.yaml get pod
NAME      READY     STATUS    RESTARTS   AGE
kafka-0   1/1       Running   0          5m
kafka-1   1/1       Running   0          4m
kafka-2   1/1       Running   0          4m
zk-0      1/1       Running   0          6m
zk-1      1/1       Running   0          6m
zk-2      1/1       Running   0          5m
```

You should see 3 kafka pods in `Running` state.

Follow the testing instructions at
https://github.com/kubernetes/contrib/tree/master/statefulsets/kafka#testing to
send some test messages.


## Clean-up

To avoid incurring cost, destroy the Kubernetes cluster.

```
$ terraform destroy
var.project
  Enter a value: project

var.region
  Enter a value: us-west1

google_container_cluster.primary: Refreshing state... (ID: cluster-1)
data.template_file.kubeconfig: Refreshing state...
local_file.kubeconfig: Refreshing state... (ID: 52f59068ebc0a0b7e1b586be6846bd55245ac8e0)

An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  - destroy

Terraform will perform the following actions:

  - google_container_cluster.primary


Plan: 0 to add, 0 to change, 1 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

google_container_cluster.primary: Destroying... (ID: cluster-1)
...
google_container_cluster.primary: Destruction complete after 3m9s

Destroy complete! Resources: 1 destroyed.

```
