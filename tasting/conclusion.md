# Conclusion

You started with a configuration that ran `echo` and ended with a service on the internet, with a name, a certificate, a database, and a rollout strategy, all described in files that a colleague could apply from nothing.
Here are the key takeaways:

- **Describe the end state, not the steps.**
  OpenTofu computes the steps, shows them as a plan, and applies only the difference.
  Applying twice is safe.
- **State is memory.**
  It maps your blocks to real things, it holds secrets, and it never goes into git.
- **Providers are the vocabulary.**
  Every resource type comes from one, credentials come from the environment, and the lock file keeps everyone on the same versions.
- **References are dependencies.**
  Order comes from what mentions what, and `depends_on` is for the rare case with nothing to mention.
- **Validate in layers.**
  `fmt`, `validate`, `validation` blocks, `precondition`, the plan, and `check` blocks, each catching what the one before could not.
- **Make change visible.**
  Content hashes and content-addressed tags turn "the source changed" into a plan line.
- **Ready means ready.**
  Health checks and readiness probes make "created" mean "serving", and everything downstream gets sequenced for free.
- **Modules are functions.**
  Variables in, resources in the middle, outputs out, and a module with no resources is still a useful function.
- **Split by lifecycle.**
  Clusters and machines in one configuration, applications in another, with remote state carrying the outputs across.
- **Know where things run.**
  Paths, commands, and bind mounts live on the provider's target, and `upload` carries content across the boundary.
- **Secrets are only as sensitive as you say.**
  Mark them, wrap what crosses states in `sensitive()`, and protect the state that holds them.

Everything you built here can be torn down with `tofu destroy`, in the reverse order it was built, and rebuilt with `tofu apply`.
That round trip is the whole promise of infrastructure as code, and now you have made it work five times.
Go describe something.

---

*Content outline and editorial support from Ben.
Words by Claude.*
