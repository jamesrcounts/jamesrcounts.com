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
- [Container Pipeline](#container-pipeline)
- [Helm Chart Pipeline](#helm-chart-pipeline)
- [Deployment Pipeline](#deployment-pipeline)
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

## Container Pipeline

## Helm Chart Pipeline

## Deployment Pipeline
