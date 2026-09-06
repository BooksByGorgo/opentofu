# a data-only module: the two lists as outputs, so that any configuration can
# pull them straight from this repository with
#   source = "github.com/BooksByGorgo/opentofu//examples/motd?ref=main"
output "prefixes" {
  description = "The 60 sentence beginnings, one per line in prefix.txt."
  value       = split("\n", trimspace(file("${path.module}/prefix.txt")))
}

output "suffixes" {
  description = "The 60 sentence endings, one per line in suffix.txt."
  value       = split("\n", trimspace(file("${path.module}/suffix.txt")))
}
