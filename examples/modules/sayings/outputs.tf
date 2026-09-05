output "list" {
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
