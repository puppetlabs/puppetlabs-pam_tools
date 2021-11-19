#! /bin/bash

set -e

# PT_* are passed into the environment by Bolt.
# shellcheck disable=SC2154
NAMESPACES="${PT_namespaces}"
# shellcheck disable=SC2154
TIMEOUT="${PT_timeout}"

function ts() {
  date +'%Y%m%d-%H:%M:%S'
}

function contains() {
  local match=$1
  declare -a array
  local array=($2)
  for e in "${array[@]}"; do
    if [ "${e}" == "${match}" ]; then
      return 0
    fi
  done
  return 1
}

function waitForPods() {
  wait_timeout=$1
  declare -a namespaces
  namespaces=($2)
  declare -a all_namespaces
  all_namespaces=($(kubectl get namespace -o name | sed -e 's/namespace\///'))
  if [ -z "${namespaces[*]}" ]; then
    namespaces=("${all_namespaces[@]}")
  fi
  completed_or_evicted_pods=$(kubectl get pods -A | grep -E 'Completed|Evicted' | awk '{ print $2 }')
  code=0
  for n in "${namespaces[@]}"; do
    echo "Checking namespace: ${n}"
    if ! contains "${n}" "${all_namespaces[*]}"; then
      echo "The namespace ${n} does not exist!"
      exit 2
    fi
    for p in $(kubectl get pods -o name -n "${n}" | sed -e 's/pod\///'); do
      # Skip if this is a completed job or evicted pod, since they are already
      # done, and won't become 'ready'
      if ! [[ "${completed_or_evicted_pods}" =~ $p ]]; then
        echo "$(ts) Waiting on ${p} for ${wait_timeout}"
        if ! kubectl wait --for=condition=Ready "pod/${p}" -n "${n}" "--timeout=${wait_timeout}"; then
          echo "$(ts) Timed out waiting on ${p}"
          kubectl logs "pod/${p}" -n "${n}" || true
          echo
          code=1
        fi
      fi
    done
  done
  return $code
}

waitForPods "${TIMEOUT}s" "${NAMESPACES}"
exit $?
