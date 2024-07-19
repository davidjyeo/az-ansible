locals {
  // Define array of region names and map for region codes
  regions = ["UK South"] #, "UK West"]

  region_map = {
    "UK South" = "uks",
    "UK West"  = "ukw"
  }

  // Define the environment map based on workspace name
  workspace_map = {
    "UKPP"  = "pp",
    "UKDV"  = "dv",
    "UKDR"  = "dr",
    "UKPR"  = "pr",
    "UKADV" = "adv"
  }

  // Define vNet address prefixes
  vnet_map = {
    "UK South" = "141.200.1.0/27",
    "UK West"  = "141.200.2.0/27"
  }

  // Get the environment code from the workspace name 
  env = lookup(local.workspace_map, terraform.workspace, "DefaultValue")
}
