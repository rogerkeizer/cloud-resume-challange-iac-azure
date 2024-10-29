terraform {
  required_version = "1.9.8"
  backend "azurerm" {
    resource_group_name  = "rg-tfstate-test-westeur-001"
    storage_account_name = "sttfstatetestwesteur001"
    container_name       = "tfstatecrciac"
    key                  = "tfstatecrciac.key"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.6"
    }
  }
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

# Create resource group
resource "azurerm_resource_group" "rg-crc" {
  name     = var.rg_name
  location = var.location

  tags = var.tags
}

# Create storage account for Static Website
resource "azurerm_storage_account" "sa-crc" {
  name                     = var.storage-account.name
  resource_group_name      = var.rg_name
  account_kind             = var.storage-account.kind
  account_tier             = var.storage-account.tier
  account_replication_type = var.storage-account.replication
  location                 = var.location
  min_tls_version          = var.storage-account.min-tls-version

  static_website {
    index_document     = "index.html"
    error_404_document = "404.html"
  }

  tags = var.tags

  depends_on = [azurerm_resource_group.rg-crc]
}

# Upload index.html to container
resource "azurerm_storage_blob" "index-html" {
  name                   = "index.html"
  storage_account_name   = var.storage-account.name
  storage_container_name = var.storage-account.container
  type                   = var.storage-account.blob-type
  source                 = "../files/index.html"
  content_type           = var.storage-account.content-type
  content_md5            = filemd5("../files/index.html")
  access_tier            = var.storage-account.access-tier
}

# Upload 404.html to container
resource "azurerm_storage_blob" "error-404-html" {
  name                   = "404.html"
  storage_account_name   = var.storage-account.name
  storage_container_name = var.storage-account.container
  type                   = var.storage-account.blob-type
  source                 = "../files/404.html"
  content_type           = var.storage-account.content-type
  content_md5            = filemd5("../files/404.html")
  access_tier            = var.storage-account.access-tier
}

# Create CDN Profile
resource "azurerm_cdn_profile" "cdn-profile" {
  name                = var.cdn.profile-name
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = var.cdn.profile-sku

  tags = var.tags

  depends_on = [azurerm_resource_group.rg-crc]
}

# Create CDN Endpoint
resource "azurerm_cdn_endpoint" "cdn-endpoint" {
  name                          = var.cdn.endpoint
  profile_name                  = var.cdn.profile-name
  location                      = var.location
  resource_group_name           = var.rg_name
  is_http_allowed               = true
  is_https_allowed              = true
  querystring_caching_behaviour = var.cdn.caching-behaviour
  is_compression_enabled        = true

  origin {
    name      = var.cdn.origin
    host_name = azurerm_storage_account.sa-crc.primary_web_host
  }

  origin_host_header = azurerm_storage_account.sa-crc.primary_web_host

  delivery_rule {
    name  = "EnforceHTTPS"
    order = "1"

    request_scheme_condition {
      operator     = "Equal"
      match_values = ["HTTP"]
    }

    url_redirect_action {
      redirect_type = "Found"
      protocol      = "Https"
    }
  }

  content_types_to_compress = [
    "application/eot",
    "application/font",
    "application/font-sfnt",
    "application/javascript",
    "application/json",
    "application/opentype",
    "application/otf",
    "application/pkcs7-mime",
    "application/truetype",
    "application/ttf",
    "application/vnd.ms-fontobject",
    "application/xhtml+xml",
    "application/xml",
    "application/xml+rss",
    "application/x-font-opentype",
    "application/x-font-truetype",
    "application/x-font-ttf",
    "application/x-httpd-cgi",
    "application/x-javascript",
    "application/x-mpegurl",
    "application/x-opentype",
    "application/x-otf",
    "application/x-perl",
    "application/x-ttf",
    "font/eot",
    "font/ttf",
    "font/otf",
    "font/opentype",
    "image/svg+xml",
    "text/css",
    "text/csv",
    "text/html",
    "text/javascript",
    "text/js",
    "text/plain",
    "text/richtext",
    "text/tab-separated-values",
    "text/xml",
    "text/x-script",
    "text/x-component",
    "text/x-java-source",
  ]

  tags = var.tags

  depends_on = [azurerm_cdn_profile.cdn-profile]
}

# data "azurerm_dns_zone" "dns-zone" {
#   name                = "rogerkeizer.net"
#   resource_group_name = azurerm_resource_group.rg-crc.name
# }

# resource "azurerm_dns_cname_record" "cname-record" {
#   name                = "resume2"
#   zone_name           = data.azurerm_dns_zone.dns-zone.name
#   resource_group_name = azurerm_resource_group.rg-crc.name
#   ttl                 = 3600
#   target_resource_id  = azurerm_cdn_endpoint.cdn-endpoint.id
# }

#To map a domain to this endpoint, create a CNAME record with your DNS provider for custom domain that points to endpoint.
resource "azurerm_cdn_endpoint_custom_domain" "cdn-custom-domain" {
  name            = var.cdn.custom-domain
  cdn_endpoint_id = azurerm_cdn_endpoint.cdn-endpoint.id
  host_name       = var.cdn.host-name
  # host_name       = "${azurerm_dns_cname_record.cname-record.name}.${data.azurerm_dns_zone.dns-zone.name}"

  cdn_managed_https {
    certificate_type = "Dedicated"
    protocol_type    = "ServerNameIndication"
  }
}
