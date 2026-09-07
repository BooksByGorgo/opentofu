# A data-only module: no variables, no resources, four outputs.
# Any configuration can pull it straight from this public repository with
#   source = "github.com/BooksByGorgo/opentofu//tasting/examples/motd?ref=main"
# 60 prefixes x 60 suffixes = 3600 sayings, one for every second of the hour.
# Saying number n pairs prefix n / 60 with suffix n % 60.

locals {
  prefixes = split("\n", trimspace(file("${path.module}/prefix.txt")))
  suffixes = split("\n", trimspace(file("${path.module}/suffix.txt")))

  # setproduct pairs every prefix with every suffix, prefixes first:
  # [[p0, s0], [p0, s1], ..., [p1, s0], ...]
  sayings = [
    for pair in setproduct(local.prefixes, local.suffixes) :
    "${pair[0]} ${pair[1]}"
  ]
}

output "prefixes" {
  description = "The 60 sentence beginnings, one per line in prefix.txt."
  value       = local.prefixes
}

output "suffixes" {
  description = "The 60 sentence endings, one per line in suffix.txt."
  value       = local.suffixes
}

output "sayings" {
  description = "The 3600 sayings, indexed by second of the hour."
  value       = local.sayings
}

output "sql" {
  description = "SQL that creates and fills the sayings table."
  value = templatefile("${path.module}/sayings.sql.tftpl", {
    sayings = local.sayings
  })

  precondition {
    condition     = length(local.sayings) == 3600
    error_message = "need exactly 3600 sayings, one per second of the hour."
  }
}
