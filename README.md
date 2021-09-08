<!-- omit in toc -->
# pam_tools

Bolt module providing tasks and plans for installing and managing Puppet Application Manager projects.

1. [Description](#description)
1. [Setup](#setup)
1. [Usage](#usage)
1. [Reference](#reference)

## Description

Tooling to assist with installation and removal of [PAM] applications in a k8s cluster. The tasks are wrappers around kubectl and kubectl-kots invocations, and assume the existance of a compatible k8s cluster providing for the application requirements.

Compatible with the following cluster types:

* [kURL], specifically [puppet-application-manager-standalone]; not yet tested with a [puppet-application-manager] HA cluster.
* [k3s]
* [GKE] TODO
* [KinD] TODO

## Setup

Assuming Bundler is installed:

```
bundle install
bundle exec bolt module install
```

## Usage

Include usage examples for common use cases in the **Usage** section. Show your
users how to use your module to solve problems, and be sure to include code
examples. Include three to five examples of the most important or common tasks a
user can accomplish with your module. Show users how to accomplish more complex
tasks that involve different types, classes, and functions working in tandem.

## Reference

See [REFERENCE.md](./REFERENCE.md).

[PAM]: https://github.com/puppetlabs/puppet-application-manager
[kURL]: https://kurl.sh/
[k3s]: https://k3s.io/
[GKE]: https://cloud.google.com/kubernetes-engine
[KinD]: https://kind.sigs.k8s.io/
[puppet-application-manager]: https://kurl.sh/puppet-application-manager
[puppet-application-manager-standalone]: https://kurl.sh/puppet-application-manager-standalone

