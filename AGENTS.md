# project description

a short gorgo-style booklet, "Gorgo Tasting OpenTofu and Terraform", that teaches infrastructure as code by building a message-of-the-second web server: echo hello world, a go web server in docker, a mysql database of 3600 sayings, the same on kubernetes, and finally on an oracle cloud free tier VM with cloudflare DNS and a let's encrypt certificate.

the booklet is its own repo opentofu. it copies the gorgo booklet layout from cpp but is self-contained: `callout.lua` and `images/` are local copies (paths patched from `../images` to `images`).

# opentofu and terraform

- treat the two as equivalent. every configuration must work in both
- write commands as `tofu`; say once per booklet that terraform users type `terraform`
- do not use features that exist in only one of them (state encryption, variables in backend/source, `for_each` on providers, `.tofu` files, ephemeral resources, stacks). appendix A has the table; keep it current
- the top-level settings block is `terraform { }` in both tools
- `required_version = ">= 1.6"` in every root module

# chapters

- each markdown file starting with `ch` or `app` is a chapter. chapters are numbered automatically by the build
- each chapter opens with four short paragraphs in bold lead-ins: **The need.** **Why it matters.** **Why it is hard.** **The strategy.** they are about the opentofu concepts the chapter introduces (why those concepts are needed, why they are hard), not about the application; the chapter's build is presented at the end of the strategy as the example that applies them. chapter 1 is the model
- new syntax is introduced where a chapter needs it, with why it exists and an intuition for it, not just what it is
- each chapter ends with, in this order: Key Points, New Syntax (a two-column table `| Syntax | What it is |`), Try It (things to change, break, and extend), Exercises
- exercises are a mix of: think about it, what does this do (with a snippet), calculation, where is the bug (with a snippet), write a configuration
- `tofu-answers.md` restates every exercise (including snippets) before its answer, one heading per chapter
- `ch00.md` explains conventions and prerequisites, `conclusion.md` is the wrap-up, `appA.md` collects best practices, recommendations, and common errors and starts with `\appendix`, `appB.md` lists the built-ins (built-in provider, block types, meta-arguments, named values, operators, commonly used functions with an example and its result)
- every function example in appB.md must be evaluated with `tofu console` before it goes in; show the result as a plain value, truncate hashes to eight characters, and describe values that change on every run instead of quoting one
- there is no author intro. do not write one in ben's voice; leave that to ben

# format and style

- pandoc markdown; do not use emdash or endash, use --- or -- instead
- refer to the reader as `you`; tone professional but light; emojis are fine
- setup instructions always cover macOS, Linux, and Windows (winget ids: OpenTofu.Tofu, GoLang.Go, Kubernetes.kind, Kubernetes.kubectl); ch00 has the PowerShell translation table for the shell syntax the sessions use, so sessions stay POSIX
- say "correct", not "right", for correctness ("right now" and "right-hand" are fine)
- do not use the word "shape" in prose; say form, pattern, or example (the oracle `shape` argument in code is the one exception)
- do not wrap sentences. every sentence gets its own line
- configuration blocks are fenced as `terraform` (pandoc has no `hcl` highlighter); also `go`, `dockerfile`, `yaml`; plain fences only for file contents that have no highlighter (go.mod, templates)
- terminal sessions are `session` fences: every typed line starts with `$ ` and the tool's output follows on the next lines with no blank line between; `session.lua` renders the block as an outlined shaded tcolorbox with the `$` lines in bold. never use `bash` fences or a bare output block for something that was run
- a line holding only `...` inside a session stands for output that was left out (say so once in ch00); tool output is trimmed to the interesting lines; ids and timings may differ from a real run but the wording must match the current tool
- callouts are `::: {.tip}` divs whose body starts with `**Tip:**`, `**Trap:**`, or `**Wut:**`; a blank line must precede the opening fence; put `\index{}` lines inside the callout after the fence, never on the line before it
- `\index{term}` at the primary introduction of a term, never inside code blocks, and always followed by a blank line when the next line is a list item, a table, or a code fence (otherwise pandoc glues the list into a paragraph)
- code-block lines at most 90 chars (80 inside callouts): with this font a 93-char line already runs into the margin, so the 96 of the c++ books does not apply here
- avoid a long inline-code token at the end of a bullet sentence; it cannot break and produces an overfull box

# examples

- every configuration shown in the booklet is in `examples/`, one self-contained root module per chapter, named as the chapter names it (`hello-world`, `webserver`, `database`, `kubernetes`, `oracle/infra`, `oracle/app`) plus `examples/modules/`; chapters name directories explicitly ("create the directory `hello-world`"), never "a directory"
- `terraform`, `go`, `yaml`, and `dockerfile` blocks in chapters must match the example files verbatim (modulo comments and blocks marked `# ...`); exercise snippets are the exception
- each chapter that changes the go program carries its own copy of `app/`; keep the copies identical where the chapter did not change them
- run `tofu fmt -check -recursive` in `examples/` and `tofu validate` in every root module before calling a change done
- test applies before quoting output: chapters 1--4 and the chapter 5 app stage (with `-var docker_host=unix:///var/run/docker.sock` and a fake infra state) run locally; chapter 5 infra can only be `tofu init` + `tofu validate` without oracle and cloudflare credentials
- the chapter 2 `github_repository` is plan-only on this machine: the gh token lacks `delete_repo`, so a created repo could not be destroyed
- `examples/.gitignore` ignores lock files on purpose (the examples must init on any platform); appendix A explains that real projects commit them
- never commit state files, `.terraform/`, or a `.tfvars` with a secret; `example.tfvars` is the committed template

# the sayings

- 60 subjects x 60 predicates in `modules/sayings/main.tf` (and the chapter 3 copy in `database/sayings.tf`); `setproduct` gives saying `n` = subject `n / 60` + predicate `n % 60`, keyed by `minute * 60 + second` of local time
- every saying is third person singular present tense so any subject fits any predicate; no apostrophes or quotes, the template escapes them anyway
- keep the two copies of the lists identical

# citations

- appendix A cites the documentation for every bullet and every error-table row with pandoc citations (`[@key]`, several as `[@a; @b]`), placed before the final period; `references.bib` holds the entries (`@misc` with author, title, year, url) and ieee.csl numbers them
- every bib entry must be cited somewhere and every cited key must exist (script the check); the References section prints only cited works
- verify each URL with curl before adding it: opentofu.org and github.com return 404 for wrong paths, but search.opentofu.org and registry.terraform.io return 200 for anything, so cite provider docs as the provider repo's `docs/resources/*.md` file on github
- opentofu has no separate terraform_data page; cite the terraform one

# build

- `make` builds `tofu.pdf`, `tofu-answers.pdf`, and one PDF per chapter with pandoc + latexmk (lualatex); PDFs are gitignored
- fonts: TeX Gyre Pagella and JetBrains Mono with noto fallbacks, as in ~/git/cpp
- the title page uses `images/tofu-gorgo-with-badge.png`

# verify the booklet

- mechanical (script it): no `bash` fences (sessions only); blank line before every `::: {.tip}`; every callout body starts with a label; fence opens equal fence closes; code lines within limits; no unicode dashes outside code; no `\index{}` in code blocks; blank line after `\index{}` before lists
- build to `.tex` in a scratch dir and run latexmk there to get a log; look for `Overfull \hbox` of 10pt or more, `undefined`, and `Missing character`
- `pdftotext tofu.pdf - | grep -E ':::|\{\.tip\}|\\index\{'` must print nothing
- indentation must survive copying from the PDF: the front matter redefines fancyvrb's `\FV@Space` to a real space glyph with ActualText; check with `mutool draw -F txt tofu.pdf` (pdftotext trims leading spaces and cannot show this)
- `pdftotext -bbox` word positions must stay inside 69..544pt; the LaTeX log must have no Overfull box at all (verbatim overflows produce small ones)
- render every page with a table (`pdftoppm -r 60`) and look at it; column overlap shows up in no log
- verify every quoted error message and plan excerpt against the real tool with a throwaway config in the scratchpad before putting it in the text or the answer key

# testing environment

- tofu, kind, and kubectl are installed in ~/.local/bin; docker is the ubuntu snap
- the snap docker cannot see `/tmp` or dot-directories, so `kind load docker-image` needs `TMPDIR=$HOME/tmp` (any visible directory under home)
- the kind cluster for chapter 4 is created from `examples/kubernetes/kind-config.yaml` with `kind create cluster --name motd`; it maps host port 8080, so run chapter 3 with `-var port=8083` while the cluster exists
- delete the cluster, the `motd:*` images, and all state files when done testing

# making changes

- do not commit unless asked
