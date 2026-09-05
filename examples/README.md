# examples for Gorgo Tasting OpenTofu and Terraform

Every directory is a self-contained root module named the way the chapter names it: `cd` into it, `tofu init`, `tofu apply`.
Replace `tofu` with `terraform` if that is what you use.

| directory | chapter | what it does |
|---|---|---|
| `hello-world-minimal` | 1 | the smallest configuration: `echo hello world` from a provisioner |
| `hello-world` | 1 | the same with a validated variable, an output, and `triggers_replace` |
| `webserver` | 2 | build and run a Go web server in docker and check it |
| `database` | 3 | add MySQL with 3600 seeded sayings, a network, a volume, and a password |
| `kubernetes` | 4 | the same on a kind cluster, using the modules |
| `oracle/infra` | 5 | an Oracle Cloud free tier machine, a Cloudflare DNS record, a Let's Encrypt certificate |
| `oracle/app` | 5 | the chapter 3 module deployed to that machine over ssh behind a Caddy TLS proxy |
| `modules/sayings` | 4 | data-only module: the sayings list and the seed SQL |
| `modules/motd-k8s` | 4 | the application as Kubernetes objects |
| `modules/motd-docker` | 5 | the application as docker containers on any docker host |

Each chapter that changes the Go program carries its own copy of `app/`, so that the directory matches the chapter as written.

Prerequisites per chapter: docker (2 and up), go (2 and 3, to run the server outside a container), kind and kubectl with a cluster named `motd` created from `kubernetes/kind-config.yaml` (4), an Oracle Cloud account configured with `oci setup config`, `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_DNS_API_TOKEN`, and a `terraform.tfvars` following the example in `oracle/infra/example.tfvars` (5).

State files, lock files, and `.terraform/` directories are ignored by git here because the examples are meant to be run anywhere; see Appendix A for why a real project commits its lock file.
