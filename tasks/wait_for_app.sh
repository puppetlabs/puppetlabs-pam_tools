#! /bin/bash

# PT_* are passed into the environment by Bolt.
# shellcheck disable=SC2154
KOTS_SLUG="${PT_kots_slug}"
# shellcheck disable=SC2154
app_hostname="${PT_app_hostname}"
KOTS_NAMESPACE="${PT_kots_namespace:-default}"
APP_TIMEOUT="${PT_app_timeout:-600s}"
STS_TIMEOUT="${PT_sts_timeout:-300s}"
HTTP_TIMEOUT="${PT_http_timeout:-60s}"

# Cribbed from https://github.com/puppetlabs/holodeck-manifests/blob/5728ae46735c3ea93007f6c98d3594cb174e9d75/Makefile#L489-L507

# Wait for KOTS to create resources and declare ready. KOTS will declare an app
# ready if the Deployment is ready even if the latest ReplicaSet is not, so
# also wait for all deployment and statefulset rollouts to complete.
kots_app_ready_within() {
    timeout "$1" bash -c \
        "until [[ \$(kubectl kots -n \"${KOTS_NAMESPACE}\" get app | grep \"${KOTS_SLUG}\" | grep ready) ]]; do sleep 5; done"
}

deploy_sts_ready_within() {
    kubectl -n "${KOTS_NAMESPACE}" get deployment,statefulset \
      -l "app.kubernetes.io/part-of=${KOTS_SLUG}" -o name \
        | xargs -P100 -n1 -t kubectl rollout status --watch --timeout="$1"
}

if ! kots_app_ready_within "${APP_TIMEOUT}" || ! deploy_sts_ready_within "${STS_TIMEOUT}"; then
    echo "${KOTS_SLUG} not ready within timeout"
    echo
    echo "kubectl-kots get app:"
    kubectl kots -n "${KOTS_NAMESPACE}" get app;
    echo
    echo "kubectl get pods:"
    kubectl get pods -A;
    exit 1;
fi

# check HTTP *and* HTTPS
http_ok_within() {
  timeout "$1" bash -c \
      "while [ \"\$(curl --insecure --location --silent --output /dev/null --write-out '%{http_code}' \"https://${app_hostname}\")\" != '200' ] || \
             [ \"\$(curl --insecure --location --silent --output /dev/null --write-out '%{http_code}' \"http://${app_hostname}\")\" != '200' ];
       do
           sleep 3
       done"
}

check_return_code() {
    protocol=$1
    timeout "$2" bash -c \
      "curl --insecure --location --silent --output /dev/null --write-out '%{http_code}' ${protocol}://${app_hostname}"
}

if ! http_ok_within "${HTTP_TIMEOUT}"; then
    echo
    echo "http/s return codes not 200 within timeout"
    echo "https returned: $(check_return_code https "${HTTP_TIMEOUT}")"
    echo "http returned: $(check_return_code http "${HTTP_TIMEOUT}")"
    echo
    echo "kubectl get pods:"
    kubectl -n "${KOTS_NAMESPACE}" get pods -A;
    exit 2
fi
