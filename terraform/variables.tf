variable "rg_name" {
  type        = string
  default     = "rg-crc-test-westeur-001"
  description = "Resource group for the static website"
}

variable "location" {
  type        = string
  default     = "westeurope"
  description = "Default location for the Azure resources"
}

variable "tags" {
  description = "Common tags for all resources"

  type = object({
    environment = string
    provisioned = string
  })

  default = {
    environment = "test"
    provisioned = "terraform"
  }
}

variable "storage-account" {
  description = "All properties for the storage account"

  type = object({
    name                  = string
    container             = string
    kind                  = string
    tier                  = string
    replication           = string
    blob-type             = string
    access-tier           = string
    container-access-type = string
    content-type          = string
    min-tls-version       = string
  })

  default = {
    name                  = "stcrctestwesteur001"
    container             = "$web"
    kind                  = "StorageV2"
    tier                  = "Standard"
    replication           = "LRS"
    blob-type             = "Block"
    access-tier           = "Cool"
    container-access-type = "private"
    content-type          = "text/html"
    min-tls-version       = "TLS1_2"
  }
}

variable "cdn" {
  description = "All properties for the CDN resources"

  type = object({
    profile-name      = string
    profile-sku       = string
    endpoint          = string
    min-tls-version   = string
    caching-behaviour = string
    origin            = string
    custom-domain     = string
    host-name         = string
  })

  default = {
    profile-name      = "cdnp-crc-test-westeur-001"
    profile-sku       = "Standard_Microsoft"
    endpoint          = "cdne-crc-test-westeur-001"
    min-tls-version   = "TLS1_2"
    caching-behaviour = "IgnoreQueryString"
    origin            = "origin-name"
    custom-domain     = "cdn-custom-domain"
    host-name         = "<YOUR_CUSTOM_DOMAIN>"
  }
}



