variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "enable_cluster_autoscaler" {
  description = "Whether to enable cluster autoscaler IAM policy"
  type        = bool
  default = false    
}