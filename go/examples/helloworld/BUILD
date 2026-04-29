load("@rules_go//go:def.bzl", "go_binary", "go_library")
load("@rules_oci//oci:defs.bzl", "oci_image")
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
    registry = "oci://zot-registry.zot-system.svc.cluster.local:5000",
    repository = "go/examples/helloworld",
)