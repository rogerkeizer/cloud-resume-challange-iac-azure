output "site-info" {
  value = {
    storage_account_name = azurerm_storage_account.sa-crc.name,
    static_website_url   = "https://${azurerm_storage_account.sa-crc.primary_web_host}",
    cdn_url              = "https://${azurerm_cdn_endpoint.cdn-endpoint.name}.azureedge.net"
    host_name            = "https://${azurerm_cdn_endpoint_custom_domain.cdn-custom-domain.host_name}"
  }
}
