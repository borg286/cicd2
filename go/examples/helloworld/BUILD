load("@rules_go//go:def.bzl", "go_binary", "go_library")
load("@rules_oci//oci:defs.bzl", "oci_image", "oci_push")
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")

go_library(
    name = "helloworld_lib",
    srcs = ["main.go"],
    importpath = "cicd/go/examples/helloworld",
    visibility = ["//go/examples/helloworld:__pkg__"],
    deps = [],
)

go_binary(
    name = "helloworld",
    embed = [":helloworld_lib"],
    visibility = ["//go/examples/helloworld:__pkg__"],
)

pkg_tar(
    name = "app_layer",
    srcs = [":helloworld"],
    package_dir = "/usr/local/bin",
)


oci_image(
    name = "image",
    base = "@distroless_base",
    tars = [":app_layer"],
    entrypoint = ["/usr/local/bin/helloworld"],
)

oci_push(
    name = "push_oci",
    image = ":image",
    repository = "zot-registry.zot-system.svc.cluster.local:5000/go/examples/helloworld",
)
load("@rules_helm//helm:defs.bzl", "helm_chart")
helm_chart(
    name = "helloworld_chart",
    chart = "Chart.yaml",
    values = "values.yaml",
    templates = glob(["templates/**"]),
    images = ["//go/examples/helloworld:push_oci"], 
    registry_url = "oci://zot-registry.zot-system.svc.cluster.local:5000/charts",
    stamp = 1,
    env = {
        "HELM_EXPERIMENTAL_OCI": "1",
        "INSECURE_REGISTRY_URLS": "zot-registry.zot-system.svc.cluster.local:5000",
    },
    opts = ["--plain-http"],
)
