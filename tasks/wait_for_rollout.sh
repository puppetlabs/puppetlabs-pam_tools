#! /bin/bash

# PT_* are passed into the environment by Bolt.
# shellcheck disable=SC2154
SELECTOR="${PT_selector}"
NAMESPACE="${PT_namespace}"
TIMEOUT="${PT_timeout}"

deploy_sts_ready_within() {
    kubectl -n "${NAMESPACE}" get deployment,statefulset \
      -l "${SELECTOR}" -o name \
        | xargs -P100 -n1 -t kubectl rollout status --watch --timeout="$1"
}

if ! deploy_sts_ready_within "${TIMEOUT}"; then
    echo "${SELECTOR} not ready within timeout"
    echo
    echo "kubectl get pods:"
    kubectl -n "${KOTS_NAMESPACE}" get pods -A;
    exit 1;
fi
