---
layout: post
title: One Pipeline, One Lifecycle
tags:
  - AzureDevOps
  - Kubernetes
  - DevOps
  - AKS
  - ACR
---

<!-- TOC -->

- [Initial Pipeline](#initial-pipeline)
- [Separate Build and Deploy](#separate-build-and-deploy)
- [Separate Docker and Helm Builds](#separate-docker-and-helm-builds)
  <!-- /TOC -->

I often tell people that each Azure DevOps pipeline they create should "build one thing." In practice, people tend to create a single pipeline to handle everything their application needs. I see pipelines that build infrastructure, compile applications, create docker images, and package helm charts, all in one. When I tell people to refactor these pipelines to "build one thing," I mean that each pipeline should manage one lifecycle. If certain artifacts share the same lifecycle, they can go into the same pipeline. If the lifecycles are different, they should be separated.

An artifact's lifecycle means "when should this artifact be built." When all artifacts are in the same pipeline, they are all built when any of the sources change. Your source repository may include a folder for Terraform scripts, one for the helm chart definition, and several for your application source code. The "phippyandfriends" repository from my previous post is a good example. Suppose we have one pipeline for the "parrot" application, and I make a change to the Kubernetes cluster configuration in the Terraform script. When I run this (theoretical) pipeline, the pipeline picks up the Terraform changes as it should.

However, building the pipeline this way also unnecessarily rebuilds the parrot application. The parrot application should only rebuild when the .Net source code changes, and the infrastructure should only refresh when the Terraform scripts change. These two pieces of the solution are unlikely to change at the same time for the same reasons, and so they have different lifecycles.

In my previous post, I didn't follow this guideline, and I created a single pipeline to produce a Docker image and a Helm chart. This post refactors that pipeline into three separate pipelines. The first pipeline builds the Docker image, the next builds the Helm chart, and the final pipeline handles deployment.

## Initial Pipeline

Please take a look at the final pipeline from my earlier post on container pipelines. As you can see, the pipeline includes a build stage and a deploy stage:

{% gist e6b138e489a2d60ba2204e5344520a94 azure-pipelines.complete.yaml %}

However, in the build stage, we have two jobs, one to build the container image, and one to package the Helm chart. So there are a total of three lifecycles managed by this pipeline:

1. The container image should only build when its content (the dotnet application) changes.
1. The Helm package should only occur when the chart changes.
1. The application should deploy when either artifact changes.

## Separate Build and Deploy

As a first step, separate the deploy stage into a new pipeline.  Do this by copying the "azure-pipelines.yml" as "azure-pipelines.deploy.yml." Then remove the build stage from the deploy pipeline and the deploy stage from the build pipeline.  The build pipeline needs a little cleanup to remove extra variables afterward, and the deploy pipeline needs additional setup to trigger when the build pipeline completes.

{% gist 56df043b6a49ef2f59c1396b1dc50fcb azure-pipelines.build.yml %}

The most significant difference between the build pipeline and the original "complete" pipeline is that the new pipeline does not contain the stages to deploy to the development or production environments.  This file is much shorter because those stages are gone now.  Also, note that the trigger block now ignores changes to the new deploy pipeline.  We have no reason to rebuild our container image or helm chart when the pipeline definition for deployment changes.  This exclusion is our first example of where the lifecycles for the different pipelines diverge.

The remaining changes to the build pipeline relate to cleanup.  The build pipeline jobs do not need the variables defining the AKS hosts.  Other than an update to the Helm version and normalizing the NuGet package path variable name, removing the unnecessary variables were the only changes needed to clean up the build pipeline.

{% gist 56df043b6a49ef2f59c1396b1dc50fcb azure-pipelines.deploy.yml %}

The deploy pipeline includes a new block: "resources."  This block defines any resource used by the pipeline created by a source other than the pipeline itself.  In this case, the resource block creates a reference to the build pipeline. It indicates that the build pipeline triggers the deployment pipeline on completion.  The deploy pipeline also triggers when the deployment YAML file changes, so this file is listed in the included trigger paths (rather than excluded as it was in the build pipeline).

Remember that this pipeline started as a copy of the original combined pipeline.  The build stage is no longer needed, and the variables supporting those jobs are removable at this point.  Instead, this pipeline includes a new variable: "imageTag."  The "imageTag" variable captures the "runName" variable from the pipeline resource that triggered the deploy pipeline.  In the build pipeline, Azure DevOps used the run name (aka Build Number) to tag the container images when pushing to the Azure Container Registry.  The deploy pipeline uses the same tag during Helm deployment to specify the correct image version.  

As in the build pipeline, the remaining updates to the deployment pipeline are to support the upgrade to Helm 3.

## Separate Docker and Helm Builds
