<!-- omit in toc -->
# pam_tools

Bolt module providing tasks and plans for installing and managing Puppet Application Manager projects.

* [Description](#description)
* [Setup](#setup)
* [Usage](#usage)
  * [Installing a Replicated app](#installing-a-replicated-app)
    * [Credentials](#credentials)
  * [k3d and KinD](#k3d-and-kind)
  * [Getting Ingress IP](#getting-ingress-ip)
  * [Accessing the Kots admin-console](#accessing-the-kots-admin-console)
* [Reference](#reference)
* [Development](#development)
  * [Testing](#testing)
  * [Changelog](#changelog)

## Description

Tooling to assist with installation and removal of [PAM] applications in a k8s cluster. The tasks are wrappers around kubectl and kubectl-kots invocations, and assume the existance of a compatible k8s cluster providing for the application requirements.

Compatible with the following cluster types:

* [kURL], specifically [puppet-application-manager-standalone]; not yet tested with a [puppet-application-manager] HA cluster.
* [k3s]
* [GKE]
* [Docker Desktop]
* [k3d] (see below)
* [KinD] (see below)

## Setup

Assuming [Bolt is installed], to run the module's tasks and plans:

```
bolt module install
```

is sufficient to install the module dependencies.

## Usage

The tasks and plans expect to interact with a working kubectl environment configured to reach the k8s cluster you want to provision.

In particular, the target you run bolt against should have:

* [kubectl]
* [kubectl-kots]
* [ruby] \(because most of the tasks are Ruby\)
* [helm] \(optional, depending on whether you are installing helm charts\)

installed.

* TODO add some basic puppet classes for installing the tools
* TODO add a tools container to run against instead

Given the above tools are in place on the target, and either the default kubernetes config, or the config pointed to be an exported KUBECONFIG environment variable, is set to talk to your cluster, then you should be able to run tasks and plans against the target successfully.

In particular, when working with a GKE cluster, you will probably be using a target of localhost.

### Installing a Replicated app

The pam_tools::install_published plan lets you install a Replicated application into a cluster with just a +license_file+.

Basic configuration for auto install is generated automatically, but you can pass a YAML config file as well. (See the [default config template](./templates/default-app-config.yaml.epp), or one of the ${KOTS\_APP}-config.yaml examples from [holodeck-manifests/dev](https://github.com/puppetlabs/holodeck-manifests/tree/main/dev))

If your cluster is below the minimum cpu and memory requirements for the application, be aware that the application preflights will halt deployment and the installation will silently fail. You'll need to include '--skip-preflights=true' in the +kots_install_options+ parameter to get past that.

By default, Kots is installed with puppet-application-manager/stable, but if installation fails attempting to set cluster-role privileges, you can set +pam_variant+ to minimal-rbac, and pass '--skip-rbac-check=true' in the +kots_install_options+ to get around this. Alternately, this can be fixed by a service account with admin privileges for the cluster.

#### Credentials

If you do not supply a password, the install plan will generate one for you. This password is used both for the Kots admin-console and the application being installed. The plan output will include details for the hostname you should use to reach the application, and, if applicable, the application user and the password if it was generated for you.

### k3d and KinD

These are 'k3s in docker' and 'k8s in docker' environments, respectively. In both cases, the entire kubernetes environment is installed in a container managed by docker on a vm. This introduces an additional proxy layer to get host ports connected to the container, so when specifying the initial cluster creation, you need to ensure that 80 and 443 are proxied by docker so that the plan is able to test that applications are up after install. The method for doing this is implementation dependent.

For k3d, it's simply adding some port arguments:

```sh
k3d cluster create test -p 80:80@loadbalancer -p 443:443@loadbalancer
```

For KinD, the port configuration is passed in a yaml configuration file. An example from holodeck-manifests proxying 80 and 443 is [here](https://github.com/puppetlabs/holodeck-manifests/blob/main/dev/kind-ingress-ports.yaml). So, assuming ${SRCDIR} is defined, you could create the cluster like this:

```sh
kind create cluster --config "${SRCDIR}/holodeck-manifests/dev/kind-ingress-ports.yaml"
```

### Getting Ingress IP

Run the pam_tools::get_ingress_ip task to retrieve the ip address of the cluster's ingress.

This is specific to an ingress that is using a LoadBalancer service. An ingress relying on a NodePort service doesn't provide an accessible ip in its service definition. The ip in these cases would be the ip of each node in the cluster.

### Accessing the Kots admin-console

For a kurl host, you can just go to *ingress_ip*:8800.

In gke, there is no automatic proxy set up, but you can call `kubectl-kots admin-console` to set up a local forward and then reach the admin-console on localhost:8800.

## Reference

For detailed documentation see [REFERENCE.md](./REFERENCE.md).

(To regenerate the reference docs, run: `bundle exec rake strings:generate:reference`)

## Development

Assuming Bundler is installed:

```
bundle install
```

will install the rest of the development gem dependencies.

This will also install Bolt as a gem, which, depending on how your Ruby environment is setup, may show you [warnings when running Bolt] if the gem executable is found in your path before your system Bolt.

### Testing

```
bundle exec rake validate check lint rubocop spec
```

### Changelog

To update the [CHANGELOG](./CHANGELOG.md), generate a [Github token], and run:

```
export CHANGELOG_GITHUB_TOKEN=<the-token>
bundle exec rake changelog
```

[PAM]: https://github.com/puppetlabs/puppet-application-manager
[kURL]: https://kurl.sh/
[k3s]: https://k3s.io/
[GKE]: https://cloud.google.com/kubernetes-engine
[Docker Desktop]: https://www.docker.com/products/docker-desktop
[k3d]: https://k3d.io/
[KinD]: https://kind.sigs.k8s.io/
[puppet-application-manager]: https://kurl.sh/puppet-application-manager
[puppet-application-manager-standalone]: https://kurl.sh/puppet-application-manager-standalone
[Github token]: https://github.com/settings/tokens
[Bolt is installed]: https://puppet.com/docs/bolt/latest/bolt_installing.html
[warnings when running Bolt]: https://github.com/puppetlabs/bolt/issues/1779
[kubectl]: https://kubernetes.io/docs/tasks/tools/#kubectl
[kubectl-kots]: https://github.com/replicatedhq/kots/releases
[helm]: https://github.com/helm/helm/releases
