---
layout: post
title: 'Terraform Pipelines with Azure DevOps: Getting Started'
tags:
  - AzureDevOps
  - DevOps
  - Terraform
---

In 2019 I became frustrated with articles about integrating Terraform
and Azure DevOps. None of the examples looked safe because they skipped
what I feel is the most critical part of working with Terraform:
reviewing the plan before deployment. So, I [wrote my
guide](http://jamesrcounts.com/2019/10/14/azdo-safe-terraform-pipelines.html)
to show how I would (and how I do) integrate Terraform with Azure DevOps
pipelines.

Both Terraform and Azure DevOps have continued to evolve since 2019, so
it's time for a refresh! Let's look at how things look today.

- [How Does Terraform Work?](#how-does-terraform-work)
- [Building a safe Terraform pipeline](#building-a-safe-terraform-pipeline)
  - [Setup Remote State](#setup-remote-state)

## How Does Terraform Work?

You might already know how Terraform works. But I like to review the
workflow before building pipelines. An engineer using Terraform to drive
infrastructure configuration changes will work through the following
steps:

{:style="text-align:center"}
![Terraform Development Cycle](/media/2021/07/07/terraform-dev-cycle.png){:style="text-align:center;width:3.26238in;height:3.1721in"}


#### Code <!-- omit in toc -->

Write or modify Terraform configuration written in the HashiCorp
Configuration Language (HCL)

#### Plan <!-- omit in toc -->

Terraform will evaluate the configuration against the current deployed
configuration and the last known state of the deployment.

#### Review <!-- omit in toc -->

Terraform provides a report of the differences between the current
infrastructure state and the changes implied by the latest code, and any
differences caused by infrastructure drift from any other source.

#### Approve <!-- omit in toc -->

After reviewing the plan, the engineer decides to deploy the changes.
Alternatively, the engineer may not like Terraform's proposed changes
and can choose to skip the deployment and go back to coding.

#### Apply <!-- omit in toc -->

After receiving approval, Terraform updates the infrastructure and
records its changes in a state file for use with the next iteration of
the development cycle.

{:style="text-align:center;font-style: italic;background: lightsteelblue;border-radius: 24px;padding: 20px;"}
This workflow is interactive. Terraform prints the proposed changes to
the console, and the engineer types 'yes' to indicate approval.
Interactivity is a problem for build pipelines!

We can't just sacrifice the approval step because Terraform doesn't have
an intrinsic method to decide the proposed changes are safe. This
knowledge comes from the engineer. Below, I'll show how to make
Terraform "non-interactive" in a build pipeline without sacrificing
safety.

## Building a safe Terraform pipeline

Terraform creates a plan which outlines what changes the tool will make
to the infrastructure. Because Terraform cannot decide whether changes
are safe, the operator (you) must make this decision. Supporting this
plan inspection is the primary goal of the setup described below, but it
isn't the only problem. Let's work through an [example Terraform
configuration](https://github.com/jamesrcounts/terraform-getting-started-azure/tree/2021.06)
with the following components:

{:style="text-align:center"}
![Example Terraform Configuration](/media/2021/07/07/terraform-example-configuration.png){:style="text-align:center;width:5.91754in;height:3.22917in"}

-   A virtual network
-   A subnet
-   A public IP
-   A network security group that allows SSH
-   A network interface
-   A virtual machine

### Setup Remote State

To get this project ready for automation, we need to set it up to use a
remote backend for state storage. Terraform automation requires an
external state store because the build agents are transient, and the
entire agent pool must share state changes. You should create a script
using your favorite tool (Azure CLI, PowerShell, or even Terraform
itself) to create an Azure Storage Account. The account should support
the following features at a minimum:

-   Encryption at rest
-   Transparent geo-replication (RA-GZRS)
-   Soft delete for blobs and containers
-   Blob versioning
-   HTTPS only access
-   Private access only
-   Minimum TLS version 1.2

Real-world deployments for security-conscious organizations will also
include:

-   Storage account firewall
-   Advanced Threat Protection
-   Customer managed encryption keys
-   Azure Monitor diagnostics and logging

If you ignore all other advice about storage account configuration and
enable just one feature from the lists above, make sure to use blob
versioning.

{:style="text-align:center;font-style: italic;background: lightsteelblue;border-radius: 24px;padding: 20px;"}
Blob versions allow you to recover older versions of the state file.
Older state file versions can help you reset your configuration when
other recovery options fail.

To configure backend storage, add a backend block to the terraform
block. To see where I have this configured in the example, check the
versions file in the infrastructure folder (shown below).

[infrastructure/versions.tf:](https://github.com/jamesrcounts/terraform-getting-started-azure/blob/2021.06/infrastructure/versions.tf)
```hcl
terraform {
  required_version = ">= 0.15"

  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3"
    }
  }
}
```

This backend block supports variables that specify the resource group,
account, container and blob name. However, rather than specify them as
hardcoded values I’ve created an external file for these values.

infrastructure/azurerm.backend.tfvars:
```javascript
container_name       = "state"
key                  = "terraform-pipelines.tfstate"
storage_account_name = "saexcitedcougar"
resource_group_name  = "rg-backend-excited-cougar"
```

{:style="text-align:center;font-style: italic;background: lightsteelblue;border-radius: 24px;padding: 20px;"}
By declaring the backend configuration outside the configuration code
base, I can choose different backends for different environments. For
example, my local machine may use a sandbox, while my build pipeline
targets a live deployment.

In the case of a local run on my laptop, Terraform uses Azure CLI
authentication to access this backend. I will need to authenticate using
az login before invoking Terraform. In a build pipeline, we'll provide
Service Principal credentials using environment variables.

If you already have a local state file, execute `terraform init
-backend-config azurerm.backend.tfvars` to update your backend. Terraform
will prompt you to move your state file into the storage account.

{:style="text-align:center"}
![Update Terraform Backend](/media/2021/07/07/terraform-update-backend.png){:style="text-align:center;"}

By visiting the state blob container in the account, you can verify the
state file successfully saved using the specified key.

{:style="text-align:center"}
![View the remote state in the portal](/media/2021/07/07/terraform-view-remote-state.png){:style="text-align:center;"}

With the remote state now set up, the following section explains how to
create the build stage.