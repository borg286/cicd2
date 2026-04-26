# Key Skills for Faster GitOps Setup

This document lists skills that would have helped me complete the CockroachDB and Atlas setup faster and with fewer errors.

## 1. Flux CD Advanced Patterns
- **Description**: A skill or knowledge base covering advanced Flux CD patterns, specifically:
    - Handling Custom Resource Definitions (CRDs) and Operator installations to avoid race conditions where custom resources are applied before CRDs are registered.
    - Best practices for using OCI repositories for Helm charts, including `apiVersion` compatibility checks for the target cluster.
- **How it would have helped**: I would have implemented the separation of operator and cluster Kustomizations from the start, and avoided using the unsupported `v1beta2` API version for the OCI repo.

## 2. Helm Chart & Repository Discovery
- **Description**: A procedural skill or tool for querying Helm repository contents or finding correct chart names for popular open-source software when external web search is restricted or unavailable.
- **How it would have helped**: I would not have spent time guessing the chart name for the CockroachDB operator and could have identified the correct Git source approach sooner.

## 3. Robust File Manipulation in Artifacts
- **Description**: Instructions or workarounds for dealing with intermittent "file does not exist" errors when editing recently created files in the artifact directory.
- **How it would have helped**: I would have used `write_to_file` with `Overwrite: true` as the primary method rather than retrying failed `replace_file_content` calls.
