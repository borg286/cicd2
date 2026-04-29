load("@rules_go//go:def.bzl", "go_binary", "go_library")

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