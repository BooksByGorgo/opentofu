# the prefix and suffix lists live in the booklet's public repository
module "sayings" {
  source = "github.com/BooksByGorgo/opentofu//examples/motd?ref=main"
}

locals {
  # setproduct pairs every prefix with every suffix, prefixes first:
  # [[p0, s0], [p0, s1], ..., [p1, s0], ...]
  sayings = [
    for pair in setproduct(module.sayings.prefixes, module.sayings.suffixes) :
    "${pair[0]} ${pair[1]}"
  ]
}
