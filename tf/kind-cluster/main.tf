resource "kind_cluster" "default" {
    name           = "test-cluster"
    wait_for_ready = true

  kind_config {
      kind        = "Cluster"
      api_version = "kind.x-k8s.io/v1alpha4"

      node {
          role = "control-plane"

          extra_port_mappings {
              container_port = 8080
              host_port      = 2045
          }
          extra_port_mappings {
              container_port = 8443
              host_port      = 2046
          }
      }

      node {
          role = "worker"
      }
  }

}
