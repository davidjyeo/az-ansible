module "naming" {
  # for_each = toset(local.regions)
  source = "Azure/naming/azurerm"
  suffix = ["ans-adv-uks-01"]
}

module "regions" {
  source = "Azure/regions/azurerm"
}

# resource "random_integer" "region_index" {
#   max = length(local.test_regions) - 1
#   min = 0
# }

# resource "random_integer" "zone_index" {
#   max = length(module.regions.regions_by_name[local.test_regions[random_integer.region_index.result]].zones)
#   min = 1
# }

# module "get_valid_sku_for_deployment_region" {
#   # source            = "../../modules/sku_selector"
#   source            = "./.terraform/modules/avm-res-compute-virtualmachine/modules/sku_selector"
#   deployment_region = local.test_regions[random_integer.region_index.result]
# }
