\appendix

# Best Practices, Recommendations, and Common Errors

This appendix is the booklet's reference card.
The chapters introduce these ideas where they come up; this is where they are collected, with the reasoning kept short and a pointer to the documentation for each item.
Everything here applies to OpenTofu and Terraform alike unless a line says otherwise, and the two projects' documentation sites cover the same ground in the same words most of the time [@OpenTofuDocs; @TerraformDocs].

## Best practices

### Organizing configuration

\index{best practices!organization}

- **One directory per root module, one state per root module.**
  A root module is a unit of `apply`.
  Things with different lifecycles (a cluster and what runs on it, infrastructure and application) go in different root modules, as Chapters 4 and 5 do [@OTF_ModuleComposition; @TerraformStyle].
- **Use the conventional file names.**
  `versions.tf` (the `terraform` block), `providers.tf`, `variables.tf`, `outputs.tf`, `main.tf`, and more files named for what they hold (`network.tf`, `dns.tf`).
  The tool does not care; the next reader does [@OTF_ModuleStructure; @TerraformStyle].
- **Name resources for their role, not their type:** `web`, not `web_container`.
  The type is already in the address.
  Use underscores in names, never dashes, and keep names short: they appear in every plan [@TerraformStyle; @OTF_Style].
- **Keep modules small and single purpose,** with every variable described and every output named for what it is.
  A module is a function; write it like one [@OTF_ModuleStructure].
- **Do not abstract too early.**
  Three similar resources are fine.
  The third copy of a whole configuration is the moment to write a module [@OTF_ModuleDev].
- **Give every variable a `type` and a `description`,** and a `validation` block when a wrong value would fail late or expensively [@OTF_Variables].
- **Prefer references to `depends_on`.**
  A reference is a dependency the reader can see.
  Use `depends_on` only when nothing can be referenced, and comment why [@OTF_DependsOn].

### Versions and providers

\index{best practices!versions}

- **Constrain the provider major version** with `~>` in `required_providers`, and set `required_version` to the oldest tool version you tested [@OTF_VersionConstraints; @OTF_ProviderRequirements].
- **Commit `.terraform.lock.hcl`.**
  It pins exact provider versions and checksums so that everyone gets the same plugins.
  When the team spans platforms, run `tofu providers lock -platform=linux_amd64 -platform=darwin_arm64` and commit the result, or `init` on the other platform fails with a checksum error [@OTF_LockFile; @OTF_ProvidersLock].
  (The examples in this booklet ignore the lock file for that reason; a real project should not.)
- **Upgrade providers deliberately** with `tofu init -upgrade`, read the changelog first, and commit the lock file change on its own [@OTF_Init].
- **Never commit `.terraform/`.**
  It is a cache [@OTF_LockFile].

### State

\index{best practices!state}

- **Never commit state.**
  It holds secrets and it changes on every apply.
  `.gitignore` gets `*.tfstate`, `*.tfstate.*`, `.terraform/`, and `crash.log` before the first apply [@OTF_StateSensitive].
- **Use a remote backend with locking** as soon as two people or one CI job touch a configuration: S3 and compatible stores (Oracle Object Storage among them), Azure Blob, Google Cloud Storage, a Kubernetes secret, or an HTTP backend.
  Locking prevents two applies from interleaving; encryption at rest covers the secrets [@OTF_StateRemote; @OTF_StateLocking; @OTF_Backends].
- **Never edit state by hand.**
  `tofu state list`, `show`, `mv`, `rm`, and `tofu import` cover what is needed, and `moved`, `removed`, and `import` blocks do the same declaratively and reviewably [@OTF_StateCmd; @OTF_Refactoring; @OTF_Import].
- **Back up state** before anything unusual, with `tofu state pull > backup.tfstate` [@OTF_StatePull].
- **One state per environment,** by directory or by backend key, not by `workspace` unless the differences are truly only variable values [@OTF_Workspaces].

### Planning and applying

\index{best practices!workflow}

- **Always read the plan.**
  The summary line first, then every `-/+`.
  A replacement of anything stateful is a stop-and-think moment [@OTF_Plan].
- **Save the plan in automation:** `tofu plan -out=tfplan` then `tofu apply tfplan`.
  A saved plan applies exactly what was reviewed, and applying a stale one fails instead of surprising you [@OTF_Plan; @OTF_Apply].
- **Run `fmt`, `validate`, and `plan` in CI on every pull request,** and apply from CI on merge, so that state changes are serialized and logged [@OTF_CoreWorkflow; @TF_Automate].
- **Avoid `-target`.**
  It is for surgery, not routine.
  A configuration that needs `-target` to apply cleanly has a dependency problem to fix [@OTF_Plan].
- **Do not `-auto-approve` anything that matters.**
  Interactively, read and type `yes`; in CI, apply a saved plan that was reviewed [@OTF_Apply].
- **Treat `destroy` as a real command.**
  Protect stateful resources with `lifecycle { prevent_destroy = true }` and remove the protection only in the same change that intends the destruction [@OTF_Destroy; @OTF_Lifecycle].

### Secrets

\index{best practices!secrets}

- **Credentials come from the environment or the vendor's own config files,** never from `.tf` or committed `.tfvars` files.
  `TF_VAR_name` sets a variable from the environment [@OTF_EnvVars; @OTF_ProviderConfiguration].
- **Mark secret variables and outputs `sensitive`,** and wrap values read from another configuration's outputs in `sensitive()` [@OTF_Variables; @OTF_SensitiveFn].
- **Remember that state holds the plain value regardless.**
  Sensitivity is about the terminal and the logs; the backend's access control is about the state [@OTF_StateSensitive].
- **Generate secrets with the `random` provider or fetch them from a secret manager** rather than typing them, so that they are never in a shell history [@RandomProvider].

### Changing infrastructure

\index{best practices!change}

- **Prefer immutable artifacts.**
  An image tagged with its content hash (Chapter 4) is a change the tool can see; `latest` is not [@K8sImages; @K8sConfigBest].
- **Provisioners are a last resort.**
  They run only at creation, their failures leave resources tainted, and their commands are invisible to the plan.
  Prefer a provider, cloud-init, or a proper configuration management tool, and use `terraform_data` with `local-exec` for the small glue that has no better home [@OTF_Provisioners; @TF_TerraformData].
- **Make replacement chains explicit** with `replace_triggered_by` when the provider cannot see the dependency (a seed file and the volume it loads into) [@OTF_Lifecycle].
- **Add `precondition` and `postcondition` blocks** for assumptions that would otherwise fail late, and `check` blocks for "did it work" [@OTF_CustomConditions; @OTF_Checks].
- **Refactor with `moved` blocks,** not by destroying and recreating.
  Renaming a resource or moving it into a module is a `moved { from = ...; to = ... }` and a plan that says "no changes" [@OTF_Refactoring].

## Recommendations

### Tools

\index{recommendations!tools}

- `tofu fmt -recursive` and `tofu validate` in a pre-commit hook [@OTF_Fmt; @OTF_Validate; @PreCommit].
- **tflint** for lint rules the tool does not enforce (unused variables, deprecated arguments, provider-specific checks) [@TFLint].
- **trivy** or **checkov** for security scanning of configurations (open security groups, unencrypted storage) [@Trivy; @Checkov].
- **terraform-docs** to generate the variables and outputs tables of a module's README from its files [@TerraformDocsTool].
- **tenv** (or a similar version manager) to install and switch between OpenTofu and Terraform versions per project [@Tenv].
- An editor with the language server, which gives completion for every provider's arguments [@OTF_LS].

### Working with the tool

\index{recommendations!working}

- `tofu console` to try an expression before putting it in a file [@OTF_Console].
- `tofu show` to read the state or a saved plan; `tofu show -json tfplan` for scripts [@OTF_Show].
- `tofu graph | dot -Tsvg > graph.svg` to see the dependency graph when the order surprises you [@OTF_Graph].
- `tofu plan -refresh-only` to see drift (changes made outside the tool) without planning any fixes, and `tofu apply -refresh-only` to accept it into the state [@OTF_Plan; @OTF_Refresh].
- `tofu apply -replace=ADDRESS` to force one resource to be recreated, instead of tainting or deleting things [@OTF_Plan].
- `TF_LOG=DEBUG tofu plan` when a provider does something inexplicable; it prints every API call [@OTF_Debugging].
- `tofu test` with `.tftest.hcl` files for modules that deserve tests [@OTF_Test].
- `tofu providers schema -json` to see every argument a provider accepts when the documentation and reality disagree [@OTF_ProvidersSchema].

### Staying compatible with both tools

\index{compatibility}

Everything in this booklet works in both.
Features to avoid, or to fence off, if a configuration must run under either [@OTF_Migration]:

| Only in OpenTofu | Only in Terraform |
|:--------------------|:--------------------|
| State encryption (`encryption` block) [@OTF_Encryption] | HCP Terraform and `cloud` block features [@TF_Cloud] |
| Variables in `backend` and module `source` [@OTF_New18] | Terraform Stacks [@TF_Stacks] |
| `for_each` on `provider` blocks [@OTF_New19] | `ephemeral` resources and write-only arguments [@TF_Ephemeral; @TF_WriteOnly] |
| `-exclude` flag [@OTF_New19] | `terraform query` and list resources [@TF_Query] |
| `.tofu` file extension [@OTF_New18] | Some newer built-in functions [@TerraformDocs] |
| Provider mirrors from OCI registries [@OTF_New110; @OTF_OCI] | |

Both have `check` blocks, `import`, `moved`, and `removed` blocks, `terraform_data`, provider-defined functions, and `test` [@OTF_New17].
The version numbers do not line up: OpenTofu started at 1.6 (equivalent to Terraform 1.5), so `required_version = ">= 1.6"` means something slightly different under each tool [@OTF_Migration].

## Common errors

\index{common errors}

The message, what it usually means, and what to do.
Messages are abbreviated.

### Setup

| Message | Cause and fix |
|:----------------|:------------------------|
| `Required plugins are not installed` or `Missing required provider` | Run `tofu init` [@OTF_Init]. |
| `Inconsistent dependency lock file` | The lock file and the constraints disagree; `tofu init` if a constraint changed, `tofu init -upgrade` to move to newer versions [@OTF_LockFile; @OTF_Init]. |
| `Backend initialization required` | The backend settings changed; `tofu init -migrate-state` to move state, `-reconfigure` to point at existing state [@OTF_Init; @OTF_Backends]. |
| `Failed to query available provider packages` | Wrong `source` address, a typo in the version, or no network. Check the registry page for the exact address [@OTF_ProviderRequirements]. |
| `Unsupported OpenTofu Core version` | `required_version` excludes the tool you are running; upgrade the tool or loosen the constraint [@OTF_Settings]. |
| `Error acquiring the state lock` | Another apply is running, or one crashed and left the lock; wait, then `tofu force-unlock ID` only when you are sure it is stale [@OTF_StateLocking; @OTF_ForceUnlock]. |

### Configuration

| Message | Cause and fix |
|:----------------|:------------------------|
| `Unsupported argument` (with "Did you mean") | A misspelled argument, or an argument from a different provider version [@OTF_Validate]. |
| `Missing required argument` | The resource type needs it; the docs list which are required [@OTF_ResourceSyntax]. |
| `Reference to undeclared resource` or `undeclared input variable` | A typo in a reference, or a missing `variable` block. Remember `var.`, `local.`, `data.`, `module.` prefixes [@OTF_References]. |
| `Invalid function argument` or `Invalid template interpolation value` | A type mismatch, often a number where a string is needed; use `tostring`, `tonumber`, or check the type in `tofu console` [@OTF_Types; @OTF_ToString]. |
| `Invalid for_each argument ... known after apply` | `for_each` keys must be known at plan time; use static keys, derive them from configuration rather than from another resource's attributes, or split into two applies [@OTF_ForEach]. |
| `Cycle:` followed by addresses | Resources reference each other in a loop; break it with a data source, a local, or by removing an unneeded `depends_on` [@OTF_GraphInternals; @OTF_DependsOn]. |
| `Duplicate resource` | Two blocks with the same type and name, often in two files [@OTF_ResourceSyntax]. |
| `Invalid value for variable` | A `validation` block rejected the value; the message is whatever the author wrote [@OTF_Variables]. |
| `Resource precondition failed` | A `precondition` was false; fix the assumption or the configuration [@OTF_CustomConditions]. |

### Planning and applying

| Message | Cause and fix |
|:----------------|:------------------------|
| `Saved plan is stale` | State changed since the plan was saved; plan again [@OTF_Apply]. |
| `Objects have changed outside of OpenTofu` | Drift. Read what changed; `apply -refresh-only` to accept it, or a normal apply to revert it [@OTF_Plan; @OTF_Refresh]. |
| `Provider produced inconsistent final plan` | A provider bug or a value that changed between plan and apply; re-run, then report it if it repeats [@OTF_Debugging]. |
| `Instance cannot be destroyed` | `prevent_destroy` is doing its job; remove it deliberately if you mean it [@OTF_Lifecycle]. |
| `local-exec provisioner error` | The command failed; the resource is tainted and the next apply recreates it. Fix the command [@OTF_Provisioners]. |
| `Check block assertion failed` | A warning: the apply succeeded but the check did not. Look at what the check tests [@OTF_Checks]. |
| `Provider configuration not present` | A resource in state belongs to a provider you removed from the configuration; add the provider back long enough to destroy it, or `tofu state rm` it [@OTF_ProviderConfiguration]. |
| `Error: ... already exists` or HTTP 409 | The thing exists but not in state; `tofu import` it or an `import` block, or remove the stray one [@OTF_Import; @OTF_ImportCli]. |

### Providers used in this booklet

| Message | Cause and fix |
|:----------------|:------------------------|
| `Bind for 0.0.0.0:8080 failed: port is already allocated` | Another process or container owns the port; change the variable [@DockerNetwork]. |
| `Conflict. The container name "/motd-db" is already in use` | A container the tool does not know about; remove it or import it [@DockerRun; @OTF_ImportCli]. |
| `Cannot connect to the Docker daemon` | Docker is not running, or the socket needs your user in the `docker` group, or the `host` is wrong [@DockerPostInstall; @DockerProvider]. |
| `timed out waiting for the condition` (Kubernetes) | The rollout never became ready; `kubectl describe pod` and `kubectl logs` say why [@K8sProviderDeployment; @K8sDebugPods]. |
| `ImagePullBackOff` | The cluster cannot pull the image: not loaded into kind, not pushed to the registry, or no pull secret [@K8sImages; @KindLoad]. |
| `Unauthorized` (Kubernetes) | The kubeconfig context is wrong or expired [@K8sKubeconfig]. |
| `Out of host capacity` (Oracle) | No free tier machines in that availability domain; try another `ad_index` or region [@OCIFreeTier; @OracleFreeTier]. |
| `NotAuthorizedOrNotFound` (Oracle) | The compartment OCID is wrong, or the profile in `~/.oci/config` lacks permission, or the region differs from the resource's [@OCIErrors; @OCIProvider]. |
| `Authentication error (10000)` (Cloudflare) | The token is missing, wrong, or lacks `Zone.DNS: Edit` on that zone [@CFToken; @CFProvider]. |
| `urn:ietf:params:acme:error:rateLimited` | Too many certificates for the name; wait, and use the staging server while testing [@LERateLimits; @LEStaging; @LetsEncrypt]. |
| `NXDOMAIN` during the DNS challenge | The TXT record has not propagated; the provider retries, and a low TTL on the zone helps [@ACMEProvider; @LEChallenges]. |
| `Permission denied (publickey)` over SSH | The key in `ssh_public_key` is not the one your agent offers, or cloud-init has not finished creating the user [@OCIAccess; @CloudInit]. |
