---
layout: post
title: Safe Terraform Pipelines with Azure DevOps
tags:
  - AzureDevOps
  - Terraform
  - DevOps
---

<!-- TOC -->

- [How Does Terraform Work?](#how-does-terraform-work)
- [Building a safe Terraform pipeline](#building-a-safe-terraform-pipeline)
  - [Setup Remote State](#setup-remote-state)
  - [Create Infrastructure Build Stage](#create-infrastructure-build-stage)
    - [Download a specific version of `terraform`](#download-a-specific-version-of-terraform)
    - [Add credentials to the environment](#add-credentials-to-the-environment)
    - [Run `terraform init`](#run-terraform-init)
    - [Run `terraform plan`](#run-terraform-plan)
    - [Package the Terraform config folder](#package-the-terraform-config-folder)
    - [Publish the build artifact](#publish-the-build-artifact)
  - [Setup Deployment Environment](#setup-deployment-environment)
  - [Create Infrastructure Deployment Stage](#create-infrastructure-deployment-stage)
    - [Download the build artifact](#download-the-build-artifact)
    - [Extract artifact files](#extract-artifact-files)
    - [Download a specific version of `terraform`](#download-a-specific-version-of-terraform-1)
    - [Add credentials to the environment](#add-credentials-to-the-environment-1)
    - [Run `terraform apply`](#run-terraform-apply)
- [Review the Plan](#review-the-plan)
- [The Big Picture](#the-big-picture)

<!-- /TOC -->

To use Terraform in Azure DevOps pipelines we must account for the real world risks involved with changing infrastructure. You must understand the tools Terraform provides to deal with the associated risk and adapt them to the features offered in Azure DevOps. It is simple to get Terraform working in automation when you choose to "turn the safeties off". Like many DevOps tasks, Terraform automation must follow an evolution from simply making the process work, to making it right, and finally making it fast. This post intends to show how to move from "make it work" to "make it right".

## How Does Terraform Work?

You might already know how Terraform works, but it pays to think about how Terraform works when building Azure DevOps pipelines. Terraform manages infrastructure by:

- Tracking infrastructure state in a state file
- Comparing the current state to the desired state expressed by the terraform configuration code
- Creating a plan to update the actual state to match the desired state
- Applying the plan
- Saving off the new state

There are a few ways to tell Terraform to go through these steps. However, with few exceptions, the way you invoke Terraform does not alter this workflow. One way or another, Terraform will go through these steps in order to change infrastructure. This perhaps leads to some confusion and bad habits as teams adopt the tool because there is a simplified workflow/series of commands that hides some complexity. The simplified workflow is good for demos and learning Terraform development. A more sophisticated workflow is good for operating Terraform in the real world.

Terraform has great documentation, and the [getting started guide][1] is no exception. The second step of the guide introduces newcomers to the most [simplified Terraform workflow][2]. The simplified Terraform workflow looks like this:

- Write (or copy/clone) some Terraform configuration
- Execute `terraform init` to initialize the Terraform project directory
- Execute `terraform apply` to create/modify infrastructure

This workflow is fine for a total newcomer. When I first started using Terraform I primarily wanted to learn to write the code to create resources. For me, using (a much older version of) this guide helped keep the focus on learning the HashiCorp Configuration Language (HCL) Terraform uses. Although the workflow was simplified (which I didn't realize at the time), I still managed to see infrastructure running in the cloud within minutes. It was great.

Great as it was, the getting started guide is not a guide for operating Terraform in the real world. Any attempt to automate the simplified workflow will fall flat at the `apply` step. In the simplified workflow the `apply` step is interactive, and interactivity is simply a killer in automated environment. The usual response to this problem seems to be to ask "How do we make `apply` non-interactive?" I would argue this is the wrong question. It's much better to understand _why_ `apply` is interactive by default.

I summarized Terraform's steps for managing infrastructure. In the simplified workflow all steps are compressed into the single execution of `terraform apply`. When invoking `apply` with default arguments, Terraform will happily run all the steps up until "creating a plan" and store the resulting plan _in memory_. Terraform then shows you the plan and asks you to confirm that you want use the plan to make changes to your infrastructure. Terraform's default safety mechanism is you, the DevOps person who just invoked the command. To apply the plan you type `yes` and hit enter, and Terraform begins the actual infrastructure changes. Terraform relies on _you_ to do your job which means reviewing the plan, thinking it over, and making a good decision about whether the changes are safe.

To run Terraform in a pipeline in the real world, where screwing up your infrastructure has real world consequences like bankruptcy and unemployment, you must solve for two constraints:

- How do we make `apply` non-interactive?
- How do we make `apply` safe?

I often see the first question answered without consideration for the second. A quick study of the [command line switches][3] for `apply` offers a tempting but dangerous solution: the `-auto-approve` switch. This switch simply bypasses the prompt to approve the plan and immediately applies the changes! Rumor has it that this switch was only created for Terraform demos. Yet this convenience feature is the "solution" many blogs and labs "put into production". Using it breaks the implicit contract you have with Terraform: you are the safety feature and you are supposed to review the plan before applying it.

Reviewing the plan is important. If you don't review the plan, you are exposed to unwanted infrastructure changes. You can--and should--practice code reviews for proposed Terraform configuration changes. There are two problems with relying on code inspection in lieu of plan inspection. Humans are not always top notch when it comes to interpreting code execution, thats why we have bugs. Second, looking at the code alone tells you nothing about the current infrastructure state. The plan gives terraform the chance to tell us:

> Given the world as I see it (the up-to-date state) and given how you have said you want the world to be (the current configuration files) this is what I'm going to do (the plan).

The great thing about the plan is that it is what Terraform telling us what it _will_ do, not our guess at what it _should_ do. Plan inspection is the safety mechanism Terraform supplies, to `apply` safely in automation, we must provide a way to use this mechanism and supply approval.

## Building a safe Terraform pipeline

Now that we understand the importance of reviewing the Terraform plan and providing explicit approval, lets create pipelines that leverage these Terraform features. Imagine we have a very simple Terraform configuration ([like this][4]) that we want to deploy with automation. I've taken this example from the Terraform getting started guide and it deploys these resources:

- An Azure resource group
- A virtual network
- A subnet
- A public IP
- A network security group that allows SSH
- A network interface
- A virtual machine

### Setup Remote State

To get this project ready for automation we need to set it up to use a remote backend for storage. Terraform's ["Remote State"][5] feature provides a mechanism to allow multiple developers to collaborate on the same Terraform code base. It is perfectly correct to use remote state in Terraform automation, because the build agents are ephemeral and state changes need to be shared across an agent pool. When using an Azure Storage Account for remote state storage our workflow will automatically benefit from encryption at rest, role based access control, and locking mechanisms to ensure multiple agents are unable to modify state concurrently.

I have no objection to using storage accounts for storage (in general--some organizations will have additional security concerns). I do think the way that some blogs/demos show this setup is a bit odd, because they often create the storage account and reconfigure Terraform to use it as part of the same pipeline that creates and applies the plan. As someone who develops IaC with Terraform day in and day out, this setup wouldn't work for me. To write and test Terraform code I need a working Terraform configuration. If the Terraform configuration is only executable after a "Replace Tokens" step rewrites the backend configuration, then I have no mechanism to even run a plan locally to verify my changes look acceptable.

So we will setup our Terraform code so that we do not need to replace any tokens at build time, and we will not make the Terraform automation pipeline responsible for creating the storage account--bootstrapping Terraform is not its responsibility. Mixing the responsibility for bootstrapping Terraform with the responsibility for running Terraform is actually a _bad idea_. When the responsibilities are separated, the Terraform pipeline will fail if it can't find the backend storage. This is a good thing: you _want_ to know if your storage has been deleted or misconfigured, because if Terraform cannot find that stored state, it will simply create new state and try to redeploy all your infrastructure. Protecting against this failure case is far more important than the one-time convenience of auto-bootstrapping your backend.

So lets use a script to bring up a storage account with acceptable settings for a Terraform backend:

{% gist c854e1b2bcc2d7208ca2844a758d95ab azure-create-terraform-backend.sh %}

This script will create a resource group and a storage account and basic configuration for _durability_ and _history_ by enabling transparent replication to a second Azure region, and opting in to soft-deletes so that older versions of Terraform state can be recovered if your state file somehow gets into an unrecoverable configuration. This script does not address any security features like the storage account firewall, Advanced Threat Protection, or logging and monitoring. Requirements for security will vary by team and industry, but this storage account configuration does take advantage of default security features like Role-based Access Control, transparent encryption and HTTPs-only access.

With this least-common-denominator configuration, we are still much better off than we are when we keep our state file on our local machine. With Remote State in an Azure Storage Account, our state file is backed up, versioned, encrypted and password protected. Thats pretty cool, but we have to configure Terraform to use the storage account we just created.

In older versions of Terraform (before Terraform 12), configuring the backend storage provider to use Azure Storage Accounts required providing the storage account access key. Terraform added new authentication methods for Azure in Terraform 12, and we can now access our Remote State using our own user principal if we are logged into the Azure CLI on our local machine. One less secret to manage! It makes configuring the Terraform backend super simple:

{% gist c854e1b2bcc2d7208ca2844a758d95ab terraform-backend.tf %}

To configure the backend storage I've added a `backend` block to the `terraform` block. In this block I need to tell Terraform where to find the state file by specifying the resource group, storage account, blob container and finally the file name (called `key` in the configuration). The file name can be anything, since we haven't yet put any state in Azure--this is where Terraform save the state once we do.

I do _not_ need to provide any credentials inside the source code. In fact, even if you are still on Terraform 11 and using the storage account access key, you will not need to provide credentials. Passing credentials to Terraform is a common problem and Terraform provides a feature called ["Partial Configuration"][6] to solve this problem in a flexible way. Partial Configuration gives Terraform the ability to pull configuration from several sources including config files, environment variables and command line switches. This means you can pass your secrets to Terraform in any way that meets your security requirements. In the case of Azure CLI authentication, we don't need to pass credentials to Terraform at all--Terraform will use the session established by the CLI if we are already[logged in][7].

Once logged into the Azure CLI, run `terraform init` to update your configuration to use the storage account you specified. You should see a prompt asking if you want to move the existing state to the storage account. After replying `yes`, you will see a message indicating that the update to use remote state succeeded.

{:style="text-align: center;"}
![Initializing the backend, prompt to copy existing state, success message][8]

By visiting your `terraform` blob container in the account, you will see the state file successfully saved using the key you specified.

{:style="text-align: center;"}
![View of tfstate file in Storage Account][9]

Now that our remote state is set, we are ready to create an `azure-pipelines.yaml` file to define the Build stage.

### Create Infrastructure Build Stage

When it comes to creating a safe Terraform pipeline, the most important design consideration is choosing to call `terraform plan` with the right arguments. In the simplified getting-started workflow we did not even call `plan`--not explicitly at least. The workflow still works because `apply` will implicitly call `plan` when no plan is available. When calling `plan` you will see output identical to the `apply` output, up until the prompt to review and approve. The prompt to approve does not appear when you call `plan`, `plan` just exits.

This default behavior is fine as a debugging tool, `plan` allows us to double check our intention against what Terraform thinks our code is trying to say. Terraform always wins any disagreement, if we don't like the plan we need to change our code. Outside debugging, the default behavior of `plan` does not help us make our workflow any safer. Even if we like what we see in the `plan` output, Terraform does not persist this plan. Terraform will generate a new plan during `apply` and ask for approval. We can change this behavior by using the [`-out` parameter][10] when calling `plan`. In fact, the default invocation of `plan` nags you if you fail to use this parameter:

{:style="text-align: center;"}
![Terraform output noting the out parameter was not specified][11]

When using the `-out` parameter you get all the same debugging goodness of `plan` but Terraform also saves the plan to a file. Once you have a saved plan, you can pass the plan to `apply`. When `apply` receives an explicit plan during invocation, Terraform skips the rework of recalculating the plan. More importantly, Terraform assumes that by invoking `apply` with an explicit plan, you have reviewed and approved that plan, and skips the interactive prompt for approval. Reading the [docs][3], the whole purpose of this behavior is that:

> Explicit execution plans files can be used to split plan and apply into separate steps within automation systems.

Automated build pipelines are exactly the type of "automation systems" the documentation is referring to. From now on if you are reviewing a proposed Terraform automation pipeline that doesn't split plan and apply thats a design smell worth looking into. Now that we understand the purpose of calling `plan` to create an explicit saved plan, we begin to understand that the build artifact for our pipeline should be the saved plan. In between build and deployment there should be an review and approval step. Finally the deployment should consume the explicit, saved, approved plan.

With these theoretical underpinnings, lets write our pipeline yaml. Here is the `azure-pipelines.yaml` build stage in its entirety:

{% gist c854e1b2bcc2d7208ca2844a758d95ab azure-pipelines.yaml %}

Remember that our goal when is to create safe Terraform automation, and the design of this build stage supports that goal. This stage has these steps:

- Download a specific version of `terraform`
- Add credentials to the environment
- Run `terraform init`
- Run `terraform plan`
- Package the Terraform configuration
- Publish the build artifact

I've implemented these steps as external scripts to make them easier to show in the sections to follow, but they should also work just fine as inline scripts if you prefer.

> Note: To adopt this YAML as written you will need to configure a [service connection][25] called "Azure MSDN"

#### Download a specific version of `terraform`

Although Terraform is installed by default on Azure DevOps hosted build agents, choosing a specific version of Terraform ensures consistent results even if Microsoft updates the pre-installed version. You may also do this to take advantage of newer Terraform versions without waiting for Microsoft to update. The consistency is the key--you should be in control of the inputs to your pipeline, whether that is code or tool versions.

{% gist c854e1b2bcc2d7208ca2844a758d95ab terraform-download.sh %}

This script references two variables defined at the top of the pipeline yaml. The first variable indicates the version of Terraform you want to use. The second is the [verification SHA provided by Hashicorp][13]. It is a good idea to verify integrity when downloading software from the internet to ensure it has not been tampered with or garbled in transmission. I'll be honest, I usually skip that while downloading software to my own machine (I don't always eject my USB keys properly either!) But I do run this verification when downloading software in a pipeline. If a vendor doesn't provide the SHA themselves then shame on them, however I can still calculate the value myself and put it into my pipeline variables. When managing several Terraform pipelines, I'll put these values in a shared variable library, but for this example I've shown them inline.

Once the script confirms the integrity of the `terraform` binary, it moves the program to the proper `bin` directory, prints the version, and removes the downloaded zip file.

#### Add credentials to the environment

Both `init` and `plan` will use the same credentials so this step configures them once and avoids a redundant Azure CLI login/logout.

{% gist c854e1b2bcc2d7208ca2844a758d95ab environment-setup.sh %}

This script executes inside an [Azure CLI task][14]. Azure CLI tasks are great when you need to execute Azure CLI commands because they automatically log in to Azure using the Service Principal associated with the Azure subscription or Service Connection for your project (I'm using a Service Connection in this example). After login, the task sets your default subscription which is important when you have more than one subscription associated with an Azure tenant. Next the task executes your script, and finally clears your account credentials when the task ends.

There is one more option important to note: `addSpnToEnvironment`. This option makes the Service Principal credentials available to the script running inside the task. The script shown above captures these variables and sets them as pipeline secret variables. Pipeline secret variables are an awesome feature. When Azure DevOps sets a variable with the `issecret=true` flag, it will create an environment variable with the value encrypted. Azure DevOps will only decrypt the value for a task when that variable is explicitly mapped into a task. I've done this mapping using an `env` block in the "Terraform Init" and
"Terraform Plan" tasks that follow.

#### Run `terraform init`

Because the Azure DevOps build agent starts with a clean slate, we need to execute `init` to get the project ready for `plan`. This will use the credentials configured in the previous step to read the remote state from our Azure Storage Account.

{% gist c854e1b2bcc2d7208ca2844a758d95ab terraform-init.sh %}

The pipeline scripts call `init` and other Terraform commands with arguments to make Terraform more friendly in automation. These arguments are passed both as environment variables and as CLI switches. The build YAML declares a global variable `TF_IN_AUTOMATION` [recommended by the docs][15] to make "some minor adjustments to its output to de-emphasize specific commands to run [and] that there is some wrapping application that will help the user with the next step." Even with this variable declared, suppress interactive prompts with `-input=false`, if we allowed Terraform to ask questions during the build there would be no way to dismiss the prompts. Without this option, the build would wait for a response that never comes and eventually timeout.

> Note: if you are still using the older log viewing experience in Azure DevOps take advantage of the `-no-color` flag. That version of the viewer did not understand the color codes emitted by Terraform to colorize the output.

#### Run `terraform plan`

Now we read the code, compare it to the deployed infrastructure, and save an explicit plan. This is where the magic happens.

{% gist c854e1b2bcc2d7208ca2844a758d95ab terraform-plan.sh %}

This script follows the same pattern as the init script. Terraform receives credentials from the injected environment secrets, suppresses interactive input and calls `plan` with an `-out` parameter to save the plan to a local file. Terraform has now calculated an explicit plan--this is the key build artifact. The remainder of the pipeline will package this artifact into a format usable by the deployment stage.

#### Package the Terraform config folder

Because Azure DevOps disposes the build agent when the build completes, the agent which eventually runs `apply` is guaranteed to be different than the agent running `plan`. We can refer back the HashiCorp guide ["Running Terraform in Automation"][12] for details on working with these constraints. In short, the explicit plan file by itself is not executable by Terraform, we must preserve the working directory as a whole so that the work done by `init` is available for `apply`. To ensure the artifact preserves file executable bits and other permissions we use a tar archive.

#### Publish the build artifact

Hopefully self explanatory. The pipeline needs to publish the tarball it just created. This makes it available to the Release pipeline after a human has reviewed and approved the plan.

### Setup Deployment Environment

Our build stage has produced an explicit plan. We have the artifact we need to make `apply` non-interactive. To also make the `apply` safe, we must stop `apply` from running until after we have had a chance to review and approve the plan. We use an Azure DevOps Environment for this purpose. While an [Environment][16] provides a few different features, Approvals are most important to this discussion. When a deployment stage targets an Environment, Azure DevOps will evaluate all configured approval checks before allowing the deployment to proceed. To support a Terraform DevOps workflow with plan approval we will configure an Environment with a manual approval check.

If we target an Environment that doesn't exist, then Azure DevOps will create it automatically. However, we want to create it manually first, to ensure that the manual approval check is applied to every deployment. An Environment is not configured as part of the `azure-pipelines.yaml` definition, instead login to Azure DevOps and choose `Environments` under pipelines, then choose `Create Environment`:

{:style="text-align: center;"}
![Azure DevOps view showing Environments under Pipelines, and highlighting the Create environment button][17]

Next, type an environment name and click the `Create` button. You do not need to add a resource, choose `None`. I named my environment `dev`:

{:style="text-align: center;"}
![Azure DevOps view showing New Environment dialog, name is filled out with the value dev and None is selected for resource][18]

The environment is can now be used, but we want to configure a manual approval check before continuing on to configuring the deployment stage.

{:style="text-align: center;"}
![Azure DevOps view showing the "Get Started!" message, indicating the environment configuration is complete][19]

To configure Checks for the environment use the vertical ellipsis menu to access the Checks menu item.

{:style="text-align: center;"}
![Azure DevOps view showing the vertical ellipsis menu expanded, which Checks highlighted][20]

Click `Create` to create a manual approval.

{:style="text-align: center;"}
![Azure DevOps view showing the Create button highlighted][21]

Add an appropriate approver and instructions. I added myself as an approver. Then click `Create`.

{:style="text-align: center;"}
![Azure DevOps view showing create approvals dialog.  James R Counts has been added as an approver, the message 'Please review the Terraform plan and approve it if appropriate' has been entered.  The Create button is highlighted.][22]

Azure DevOps will display the Check for you on success.

{:style="text-align: center;"}
![Azure DevOps view showing a configured approval.  James R Counts is an approver, the instructions are 'Please review the Terraform plan and approve it if appropriate'.][23]

The environment is now ready to use with a Terraform pipeline. In the next section we will setup the deployment stage, and configure the deployment to target this environment. Because the deployment will target this environment, it will automatically wait for approval before executing.

Remember, we are building to a workflow to build an explicit plan, review and supply approval, and finally apply the plan to the infrastructure. Using environments with checks gives us the opportunity to fulfill our part of the workflow: review and approve.

### Create Infrastructure Deployment Stage

Now that we have an environment with an approval check configured, we in the home stretch. Here is the `azure-pipelines.yaml` in its entirety, updated to include the deployment stage:

{% gist c854e1b2bcc2d7208ca2844a758d95ab azure-pipelines.complete.yaml %}

Our deployment stage has these steps:

- Download the build artifact
- Extract artifact files
- Download a specific version of `terraform`
- Add credentials to the environment
- Run `terraform apply`

The `environment: dev` property in the `DeployDev` job definition causes this job to target the `dev` environment we created in the previous step. Because the job targets the environment, all checks configured for that environment must pass before any steps in this job can run.

As before, I've implemented these steps as external scripts to make them easier
to show in the sections to follow, but they should work just fine as inline scripts if you prefer.

#### Download the build artifact

Our explicit plan is part of the build artifact created during the build stage. We must always assume that different stages will run on different Azure DevOps build agents. So the first thing to do is download that build artifact to the current agent.

#### Extract artifact files

The build artifact itself is a gzipped tar archive, and we must extract it before we can access the explicit plan and use it. The Terraform documentation mentions that this archive must be unpacked to the _exact_ matching absolute path as the location on the build agent. However, in practice, I've found that a matching relative path to `System.DefaultWorkingDirectory` works fine when dealing with the `azurerm` provider.

#### Download a specific version of `terraform`

Since this job will run on a new build agent, we can't be certain that the version of Terraform we want is installed. So this step reuses the previous `teerraform-download.sh` script to ensure we are pinned at the expected version of the `terraform` binary.

#### Add credentials to the environment

Terraform `apply` will use the same type of credentials as `init` and `plan` in the build stage. Once again, we reuse the script to perform the same task on the deployment agent.

#### Run `terraform apply`

Now we have prepared the deployment agent and are ready to deploy the explicit plan.

{% gist c854e1b2bcc2d7208ca2844a758d95ab terraform-apply.sh %}

This script follows the same pattern as the other terraform scripts. Terraform receives credentials from the injected environment secrets, suppresses interactive input and calls `apply` with the name of the explicit plan as an argument. Terraform will read the stored plan, assume it has been reviewed and approved, and update the infrastructure immediately.

## Review the Plan

The pipeline we've designed can build an explicit Terraform plan, prompt for approval to deploy the plan, and finally deploy it once approval is granted. To approve the deployment, we must review the plan, and nothing in the pipeline itself explains how to do that. It turns out to be a simple task in Azure DevOps.

Although the explicit plan is stored in the build artifact, we do not need to download the artifact, unpack it, and read it. In fact, the explicit plan is not designed to be human readable. Terraform does provide a command ([`show`][24]) to convert the plan into a human readable format, but this step is still extra work. In Azure DevOps we have an easier option: the build log.

Terraform's default behavior is to print the plan in human readable format to `stdout` and in Azure DevOps this means the plan is captured in the log. You can visit the build log page and review the plan there. If the configuration changes are not fresh in your mind (or a teammate made the changes), it's a good idea to quickly review the commits or PR that generated the build. When evaluating the plan you should consider what Terraform says will happen as well as what the author intended. Having the code fresh in your mind while reviewing the plan will let you do both.

## The Big Picture

Once you understand what Terraform expects from you when running in the local interactive mode, you can adapt an Azure DevOps pipeline to meet these expectations. In the simple interactive workflow, _you_ are the safety check, and Terraform enforces this as best it can by prompting you when it executes `apply`. The desire to automate the execution of Terraform configuration does not remove the need to keep the safety check in place. While most examples online simply disable the check with `-auto-approve`, this post shows how to keep the check and build a safer pipeline.

Instead of taking the `-auto-approve` short cut, real world pipelines should generate explicit plans using the `plan` command with the `-out` parameter. Deployment stages should consume the same plan during `apply`--but only after you've reviewed Terraform's proposed changes and decided they are in fact changes that you want. To achieve this, run Terraform in _both_ pipeline stages: build and deployment.

The build stage creates an artifact containing the explicit plan:

- Build
  - Fetch the code
  - Generate the explicit plan
  - Package the Terraform configuration with the plan as an artifact

We review the plan, then approve and run the deployment stage:

- Deployment
  - Fetch build artifact
  - Apply the plan

Changing infrastructure has real consequences. Infrastructure as Code gives us the tools needed to make this process safer and accelerate our ability to deliver platforms to run applications and ultimately the business. Terrafrom mitigates many sources of human error found in traditional infrastructure management techniques, but operating a powerful system at full speeds has its own risks too. Continuous Delivery pipelines are wonderful, but its also ok to slow down and review before making changes. Ask yourself what is the bigger risk: downtime or delay?

Slow down, create a gate, and read your plan before clicking "Approve"

[1]: https://learn.hashicorp.com/terraform?track=azure#azure
[2]: https://learn.hashicorp.com/terraform/azure/build_az
[3]: https://www.terraform.io/docs/commands/apply.html
[4]: https://github.com/jamesrcounts/terraform-getting-started-azure/blob/v0.0.1/main.tf
[5]: https://www.terraform.io/docs/state/remote.html
[6]: https://www.terraform.io/docs/backends/config.html#partial-configuration
[7]: https://docs.microsoft.com/en-us/cli/azure/reference-index?view=azure-cli-latest#az-login
[8]: /media/2019/09/01/init-remote-state.png
[9]: /media/2019/09/01/remote-state-in-storage.png
[10]: https://www.terraform.io/docs/commands/plan.html#out-path
[11]: /media/2019/09/01/default-plan-note-out-parameter.png
[12]: https://learn.hashicorp.com/terraform/development/running-terraform-in-automation#plan-and-apply-on-different-machines
[13]: https://releases.hashicorp.com/terraform/0.12.8/terraform_0.12.8_SHA256SUMS
[14]: https://docs.microsoft.com/en-us/azure/devops/pipelines/tasks/deploy/azure-cli?view=azure-devops
[15]: https://learn.hashicorp.com/terraform/development/running-terraform-in-automation#controlling-terraform-output-in-automation
[16]: https://docs.microsoft.com/en-us/azure/devops/pipelines/process/environments?view=azure-devops
[17]: /media/2019/09/01/create-environment.png
[18]: /media/2019/09/01/create-environment-settings.png
[19]: /media/2019/09/01/create-environment-get-started.png
[20]: /media/2019/09/01/create-environment-checks.png
[21]: /media/2019/09/01/create-environment-create-check.png
[22]: /media/2019/09/01/create-environment-create-check-settings.png
[23]: /media/2019/09/01/create-environment-configured-approval.png
[24]: https://www.terraform.io/docs/commands/show.html
[25]: https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints?view=azure-devops&tabs=yaml
