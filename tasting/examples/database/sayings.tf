# the prefix and suffix lists live in the booklet's public repository
module "sayings" {
  source = "github.com/BooksByGorgo/opentofu//tasting/examples/motd?ref=main"
}
