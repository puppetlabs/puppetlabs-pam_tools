#! /bin/bash

# PT_* are passed into the environment by Bolt.
# shellcheck disable=SC2154
repo_name="${PT_repository_name}"
repo_uri="${PT_repository_uri}"

helm repo add "${repo_name}" "${repo_uri}"
helm repo update
