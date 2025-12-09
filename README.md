# infra

This repository mirrors open-source dependencies (Docker images and binary releases) to ensure infrastructure resilience.

## How it works

1.  Define components in subdirectories (e.g., `nezha/`, `komodo/`).
2.  Each component has a `manifest.yaml` specifying the source and sync rules.
3.  Run the `Mirror Container Images & Binaries` workflow manually via GitHub Actions.
4.  All artifacts are stored in your private GHCR and GitHub Releases with versioned tags.

## Manifest Examples

### For Docker Images (`container` type)

```yaml
type: container
source: ghcr.io/nezhahq/nezha
source_repo: nezhahq/nezha
keep_versions: 2
target: ghcr.io/yabloky/nezha # Optional override

### For Binary Releases (`release-binary` type)

type: release-binary
source_repo: nezhahq/agent
asset_pattern: nezha-agent_linux_amd64.zip
keep_versions: 2
tag_prefix: nezha-agent-
