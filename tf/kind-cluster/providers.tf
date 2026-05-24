terraform {
  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.11.0"   # pin to a version
    }
  }
}

# Configure the Kind Provider
provider "kind" {}
