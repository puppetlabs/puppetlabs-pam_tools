<!-- omit in toc -->
# pam_tools

Bolt module providing tasks and plans for installing and managing Puppet Application Manager projects.

1. [Description](#description)
1. [Setup](#setup)
1. [Usage](#usage)
  * [kots_install](#kots_install)
1. [Reference](#reference)
1. [Development](#development)
  * [Testing](#testing)
  * [Changelog](#changelog)

## Description

Tooling to assist with installation and removal of [PAM] applications in a k8s cluster. The tasks are wrappers around kubectl and kubectl-kots invocations, and assume the existance of a compatible k8s cluster providing for the application requirements.

Compatible with the following cluster types:

* [kURL], specifically [puppet-application-manager-standalone]; not yet tested with a [puppet-application-manager] HA cluster.
* [k3s]
* [GKE] TODO
* [Docker Desktop] TODO
* [KinD] TODO

## Setup

Assuming Bundler is installed:

```
bundle install
bundle exec bolt module install
```

## Usage

### kots_install

Basic configuration for auto install is generated automatically, but you can
pass a YAML config file as well.
(see one of the ${KOTS\_APP-config.yaml examples from
[holodeck-manifests/dev](https://github.com/puppetlabs/holodeck-manifests/tree/main/dev))

Atm, cd4pe fits into the current kurl vm's 8GB of memory, and connect has
config generated which configures down to 8GB for dev.

## Reference

See [REFERENCE.md](./REFERENCE.md).

(To regenerate the reference docs, run: `bundle exec rake strings:generate:reference`)

## Development

### Testing

```
bundle exec rake validate check lint rubocop spec
```

### Changelog

To update the [CHANGELOG](./CHANGELOG.md), generate a [Github token], and run:

```
export CHANGELOG_GITHUB_TOKEN=<the-token>
bundle exec changelog
```

[PAM]: https://github.com/puppetlabs/puppet-application-manager
[kURL]: https://kurl.sh/
[k3s]: https://k3s.io/
[GKE]: https://cloud.google.com/kubernetes-engine
[Docker Desktop]: https://www.docker.com/products/docker-desktop
[KinD]: https://kind.sigs.k8s.io/
[puppet-application-manager]: https://kurl.sh/puppet-application-manager
[puppet-application-manager-standalone]: https://kurl.sh/puppet-application-manager-standalone
[Github token]: https://github.com/settings/tokens
