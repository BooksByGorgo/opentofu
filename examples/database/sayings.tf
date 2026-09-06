# 60 prefixes x 60 suffixes = 3600 sayings, one for every second of the hour.
# Saying number n pairs prefix n / 60 with suffix n % 60.
# The two lists live in the booklet's repository, one entry per line.
locals {
  motd_url = "https://raw.githubusercontent.com/BooksByGorgo/opentofu/main/examples/motd"
}

data "http" "prefix" {
  url = "${local.motd_url}/prefix.txt"

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "could not fetch prefix.txt: HTTP ${self.status_code}"
    }
  }
}

data "http" "suffix" {
  url = "${local.motd_url}/suffix.txt"

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "could not fetch suffix.txt: HTTP ${self.status_code}"
    }
  }
}

locals {
  prefixes = split("\n", trimspace(data.http.prefix.response_body))
  suffixes = split("\n", trimspace(data.http.suffix.response_body))

  # setproduct pairs every prefix with every suffix, prefixes first:
  # [[p0, s0], [p0, s1], ..., [p1, s0], ...]
  sayings = [
    for pair in setproduct(local.prefixes, local.suffixes) :
    "${pair[0]} ${pair[1]}"
  ]
}
