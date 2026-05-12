# audiflow-app-config

Static JSON config for the audiflow Flutter app. Hosted via GitHub Pages from this **public** repo. Read by the app's force-update / maintenance gate at boot and on resume.

This repo is owned by the `audiflow` org but is intentionally **write-restricted to the maintainer**. The config is a remote kill switch — a hostile merge could brick installed apps. Public read is acceptable: the URL is already embedded in the shipped app binary, so secrecy of the JSON buys nothing. Security comes from write control + (optionally) client-side signature verification, not from hiding the file.

## Layout

```
v1/
├── app_config.json       # prod
├── app_config.stg.json   # staging
└── app_config.dev.json   # dev
schema/
└── app_config.schema.json
```

Served at:

- `https://audiflow.github.io/audiflow-app-config/v1/app_config.json`
- `https://audiflow.github.io/audiflow-app-config/v1/app_config.stg.json`
- `https://audiflow.github.io/audiflow-app-config/v1/app_config.dev.json`

App build wires these URLs via `--dart-define-from-file=.env.{dev,stg,prod}`, key `FORCE_UPDATE_CONFIG_URL`.

## Schema

See `schema/app_config.schema.json`. Invariants:

- `schemaVersion` is an integer the client recognizes (currently `1`).
- `minVersion`, `recommendedVersion` are semver.
- `minVersion <= recommendedVersion`.
- `maintenanceMode` boolean.
- `messageKey` non-empty.

App rejects (fail-open to `NoUpdate`) anything violating these.

## Editing

1. Branch from `main`.
2. Edit a file under `v1/`.
3. Open a PR. CI validates JSON + schema.
4. Merge → GitHub Pages redeploys.
5. Verify the URL serves the new JSON (CDN TTL is short — minutes).

## Access control

Public read, **maintainer-only write**. External PRs are ignored (closed without merge) unless coordinated with the maintainer first.

Required org/repo settings:

- Settings → Collaborators & teams: only `@reedom` (or an `audiflow` maintainers team containing only the maintainer).
- Settings → Rules → Rulesets → add ruleset targeting `main`:
  - Require a pull request before merging
  - Require review from Code Owners
  - Restrict who can push to matching branches → maintainer only
  - Block force pushes
  - Block branch deletion
- Settings → General → Features → Issues: disabled (optional, reduces drive-by noise).
- Settings → Actions → General → Workflow permissions: **read** by default. Only `deploy.yml` needs Pages write, granted via job-level `permissions:`.
- Settings → Actions → General → Fork pull request workflows: require approval for all outside collaborators (default).
- `CODEOWNERS` covers `/v1/`, `/schema/`, `/.github/`, and the repo root.

The smartplaylist repo (which accepts public PRs) lives in a different repo. This repo never merges third-party content.

## Local validation

```bash
./scripts/validate.sh
```

Runs `ajv` against every `v1/*.json` and checks the `minVersion <= recommendedVersion` invariant.
