resource "google_container_cluster" "primary" {
  project     = "${var.project}"
  name        = "${var.cluster_name}"
  region      = "${var.region}"
  network     = "projects/${var.project}/global/networks/default"

  enable_legacy_abac = false
  logging_service = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
  min_master_version = "1.10.6"

  // Private cluster
  private_cluster = false

  master_auth {
    // Disable basic authentication.
    username = ""
    password = ""
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  lifecycle {
    ignore_changes = ["node_pool"]
  }

  node_pool {
    name       = "node-pool-1"
    node_count = "1"

    autoscaling {
      min_node_count = "1"
      max_node_count = "3"
    }

    management {
      auto_repair = true
      auto_upgrade = true
    }

    node_config {
      preemptible  = true
      machine_type = "n1-standard-2"
      labels {
        environment = "prod"
      }

      oauth_scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
      ]
    }
  }
}

// Write the local kubernetes configuration file.
data "template_file" "kubeconfig" {
  template = "${file("kubeconfig.tpl")}"
  vars {
    "endpoint" = "${join("", google_container_cluster.primary.*.endpoint)}"
    "cluster_certificate" = "${google_container_cluster.primary.0.master_auth.0.cluster_ca_certificate}"
    "cluster_name" = "${google_container_cluster.primary.name}"
  }
}

resource "local_file" "kubeconfig" {
  content  = "${data.template_file.kubeconfig.rendered}"
  filename = "kubeconfig.yaml"
  lifecycle {
    ignore_changes = ["content"]
  }
}

