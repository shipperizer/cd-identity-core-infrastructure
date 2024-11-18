#!/bin/sh

sudo k8s bootstrap
sudo k8s status --wait-ready --timeout 10m