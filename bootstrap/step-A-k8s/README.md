# 1️⃣ Option 1 – k3d Quick Start (dev/CI)
```bash
k3d cluster create
```

# 2️⃣ Option 2 – Talos via Terraform (bare‑metal / VM)
```bash
cd step-A-k8s
terraform init
terraform apply \
  -var="talosconfig_path=<path to talosconfig>" \
  -var="controlplane_node_ip=192.168.xxx.yyy" \
  -var="controlplane_base_config_path=<path to controlplane.yaml>"
```
