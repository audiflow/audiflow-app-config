# audiflow-app-config

Static JSON config for the audiflow Flutter app. Hosted via GitHub Pages. Read by the app's force-update / maintenance gate at boot and on resume.

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

- `https://<owner>.github.io/audiflow-app-config/v1/app_config.json`
- `https://<owner>.github.io/audiflow-app-config/v1/app_config.stg.json`
- `https://<owner>.github.io/audiflow-app-config/v1/app_config.dev.json`

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

This repo is intentionally **owner-write only**. The app uses it as a remote kill switch, so a hostile merge could brick users.

Required settings:

- Repository → Settings → Collaborators: only the owner.
- Repository → Settings → Branches → add ruleset for `main`:
  - Require a pull request before merging
  - Require review from Code Owners
  - Restrict who can push to matching branches → owner only
  - Block force pushes
- Repository → Settings → General → Issues: disabled (optional).
- Repository → Settings → Actions → General → Workflow permissions: read-only by default; only `deploy.yml` needs Pages write.
- `CODEOWNERS` covers `/v1/`.

If the playlist repo template later opens PRs, those land in a different repo. This repo never accepts external PRs.

## Local validation

```bash
./scripts/validate.sh
```

Runs `ajv` against every `v1/*.json` and checks the `minVersion <= recommendedVersion` invariant.
