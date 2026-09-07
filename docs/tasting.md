---
layout: default
title: "Gorgo Tasting OpenTofu and Terraform"
nav_order: 2
has_children: true
has_toc: false
---

# Gorgo Tasting OpenTofu and Terraform

<div style="float: left; margin: 0 1.5rem 1rem 0; max-width: 200px;">
  <img src="{{ '/images/tofu-gorgo-with-badge.png' | relative_url }}" alt="Gorgo, Queen of Sparta, holding an OpenTofu book" style="width: 100%;">
</div>

A short booklet that teaches infrastructure as code by building a message-of-the-second web server.
It starts with `echo hello world`, moves to a Go web server in Docker, adds a MySQL database of 3600 sayings, runs the same thing on Kubernetes, and ends on an Oracle Cloud free tier machine with Cloudflare DNS and a Let's Encrypt certificate.
Every configuration works in both OpenTofu and Terraform.

The tested configurations for every chapter are in the [examples directory](https://github.com/BooksByGorgo/opentofu/tree/main/tasting/examples) of the repository.

<div style="clear: both;"></div>

{% include tasting-chapters.html %}
