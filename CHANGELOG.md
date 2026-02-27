# Changelog

All notable changes to this project will be documented in this file.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-27

### Added
- 6-agent orchestration system (master-controller, researcher, coder, reviewer, tester, deployer)
- Single base Dockerfile with thin per-agent layers
- CIS Docker Benchmark compliant compose configurations (cap_drop, no-new-privileges, read-only rootfs, pids_limit)
- 4 operational modes: full team, interactive chat, cowork (pair programming), MCP-enabled
- JSON Schema contracts for task, status, and output manifests
- MCP integration overlay (GitHub, Filesystem, Brave Search, PostgreSQL)
- Shell scripts with signal handling, atomic writes, and base image management
- GitHub Actions CI with validation, linting, build, Trivy security scanning, and structure verification
- Comprehensive documentation (README, ARCHITECTURE, SECURITY, TROUBLESHOOTING)

[1.0.0]: https://github.com/alphaonedev/docker-claude-agents/releases/tag/v1.0.0
