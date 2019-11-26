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

I often tell people that each Azure DevOps pipeline they create should "build one thing."  In practice, people tend to create a single pipeline to handle everything their application needs.  I see pipelines that build infrastructure, compile applications, create docker images, and package helm charts, all in one.  When I tell people these pipelines should be refactored to "build one thing," what I mean is that each pipeline should manage one lifecycle.  If certain artifacts share the same lifecycle, they can go into the same pipeline.  If the lifecycles are different, they should be separated.

An artifact's lifecycle means "when should this artifact be built."  When all artifacts are in the same pipeline, they are all built when any of the sources change.  Your source repository may include a folder for Terraform scripts, one for the helm chart definition, and several for your application source code.   The "phippyandfriends" repository from my previous post is a good example.  Suppose we have one pipeline for the "parrot" application, and I make a change to the Kubernetes cluster configuration in the Terraform script.  When I run this (theoretical) pipeline, the pipeline picks up the Terraform changes as it should.

However, the pipeline also unnecessarily rebuilds the parrot application.  The parrot application should only rebuild when the .Net source code changes, and the infrastructure should only refresh when the Terraform scripts change.  These two pieces of the solution are unlikely to change at the same time for the same reasons, and so they have different lifecycles.  

In my previous post, I didn't follow this guideline, and I created a single pipeline to produce a Docker image and a Helm chart.  This post will refactor that pipeline into three separate pipelines.   The first pipeline will build the Docker image, the next will build the Helm chart, and the final pipeline will handle deployment.

s