#!/bin/bash
set -e
bazel build //go/examples/helloworld:helloworld_chart.push
bazel run //go/examples/helloworld:helloworld_chart.push