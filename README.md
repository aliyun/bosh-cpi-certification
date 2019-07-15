# BOSH CPI Certification

This repository contains additional tests above and beyond unit and integration
tests. This is meant to complement the existing tests, not to replace.

* What are we testing?
	- BOSH CPI releases
* Why are we testing?
	- To provide a high level of confidence that new releases of BOSH, BOSH stemcells, and BOSH CPIs work together properly
* When will the certification pipeline run?
	- Whenever any of the following are released: (`trigger: true`)
		1. [bosh-release](https://bosh.io/releases/github.com/cloudfoundry/bosh?all=1)
		1. bosh-\<iaas\>-cpi-release
		1. [stemcell](https://bosh.io/stemcells)
      1. Once a day.
* How are we testing?
  - Testing for certification consists of the following test scenarios:
    1. [BATs](https://github.com/cloudfoundry/bosh-acceptance-tests/tree/master) are run for every flavor of stemcells (ubuntu-trusty and centos-7)
    1. A BOSH director upgrade test is run from a previous version family stemcell (e.g. 3363.x to 3421.latest)
    1. Specific IaaS end-2-end tests, if necessary


## BATs - BOSH Acceptance Tests
0. Set up infrastructure environment from scratch. We use [Terraform resource](https://github.com/ljfranklin/terraform-resource) whenever and wherever we can. It works beautifully.
0. Deploy BOSH director with latest bosh-release, IaaS-specific cpi-release, and stemcell
0. Run BATs
0. Tear down BOSH director
0. Tear down infrastructure environment

## BOSH Director Upgrade Test
0. Set up infrastructure environment from scratch, we use [Terraform resource](https://github.com/ljfranklin/terraform-resource) when and wherever we can. It works beautifully.
0. Deploy BOSH director with old bosh-release (255.4), IaaS-specific cpi-release (X), and stemcell (3363.x)
0. Deploy certification-release
0. Redeploy bosh director with latest bosh-release, IaaS-specific, cpi-release, and stemcell
0. Redeploy certification-release with `--recreate`
0. Tear down BOSH director
0. Tear down infrastructure environment

The folder structure looks like this:
```
.
├── iaas
    ├── bats
    |   └── bats-spec.yml
    ├── certification
    |   └── cloud-config-ops.yml
    ├── ops
    |   └── custom-cpi-release.yml
    └── pipeline.yml
```

`iaas/bats/bats-spec.yml`: Manifest with all IaaS-specific configurations for BATs. Make a PR to add the IaaS-specific template to the [BATs template folder](https://github.com/cloudfoundry/bosh-acceptance-tests/tree/master/templates).

`iaas/certification/cloud-config-ops.yml`: Ops file to add IaaS-specific properties to the [certification cloud-config](https://github.com/cloudfoundry-incubator/bosh-cpi-certification/blob/46152f8d50562c39cb70d0f442920c7b78a0c752/shared/assets/certification-release/cloud-config.yml)

`iaas/ops/custom-cpi-release.yml`: Used by the certification pipeline to upload a specific BOSH CPI release version. See example below:
```
- type: replace
  path: /releases/name=bosh-<iaas>-cpi
  value:
    name: bosh-<iaas>-cpi
    url: ((cpi_release_uri))
```

`iaas/pipeline.yml`: Your Concourse certification pipeline YAML configuration. See [example](https://github.com/cloudfoundry-incubator/bosh-cpi-certification/blob/46152f8d50562c39cb70d0f442920c7b78a0c752/gcp/pipeline.yml).

# BOSH CPIs
* [vSphere](https://github.com/cloudfoundry-incubator/bosh-vsphere-cpi-release)
* [AWS](https://github.com/cloudfoundry-incubator/bosh-aws-cpi-release)
* [vCloud](https://github.com/cloudfoundry-incubator/bosh-vcloud-cpi-release)
* [GCP](https://github.com/cloudfoundry-incubator/bosh-google-cpi-release)
* [OpenStack](https://github.com/cloudfoundry-incubator/bosh-openstack-cpi-release)
* [Azure](https://github.com/cloudfoundry-incubator/bosh-azure-cpi-release)
* [SoftLayer](https://github.com/cloudfoundry/bosh-softlayer-cpi-release)
* [RackHD](https://github.com/cloudfoundry-incubator/bosh-rackhd-cpi-release)
* [Photon](https://github.com/cloudfoundry-incubator/bosh-photon-cpi-release)

Others:
* [VirtualBox](https://github.com/cppforlife/bosh-virtualbox-cpi-release)
* [Docker](https://github.com/cppforlife/bosh-docker-cpi-release)
* [Warden](https://github.com/cppforlife/bosh-warden-cpi-release)
