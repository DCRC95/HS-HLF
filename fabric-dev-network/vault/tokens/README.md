This directory stores **local-only** Vault tokens used by the dev stack.

- Create `root.token` with the dev token emitted by `vault server -dev`.
- Never commit real tokens; the `.gitignore` rule keeps everything except this README out of git.
- For staging/prod, switch to OIDC or AppRole auth and supply short-lived wrapped tokens via a secure secret store instead of flat files.

