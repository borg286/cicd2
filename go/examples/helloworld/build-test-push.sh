#!/bin/bash
set -e
set -x

trap 'echo "Script exited with status $?"' EXIT

bazel build //go/examples/helloworld:helloworld_chart.push
bazel run //go/examples/helloworld:helloworld_chart.push