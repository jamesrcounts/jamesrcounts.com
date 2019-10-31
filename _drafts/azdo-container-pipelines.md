---
layout: post
title: Azure DevOps Pipelines - Container Releases Demystified
tags:
  - AzureDevOps
  - Kubernetes
  - DevOps
  - AKS
  - ACR
---

<!-- TOC -->

- [The Build Stage](#the-build-stage)
  - [Building and Testing a Dotnet Application](#building-and-testing-a-dotnet-application)
- [Building and Testing The App (only if needed)](#building-and-testing-the-app-only-if-needed)
  - [Caching Nuget Packages](#caching-nuget-packages)
- [Create Docker Image](#create-docker-image)
  - [Security Boundaries](#security-boundaries)
- [A note about Container scanning](#a-note-about-container-scanning)
- [Creating the Helm Chart (only if needed)](#creating-the-helm-chart-only-if-needed)
- [Deploying to AKS](#deploying-to-aks)
- [Why CI/CD?](#why-cicd)
- [A look at a sample application](#a-look-at-a-sample-application)
- [Building your Build Stage](#building-your-build-stage)
- [Deploying to Kubernetes](#deploying-to-kubernetes)

<!-- /TOC -->

Over the past year, I've worked with teams using Azure DevOps pipelines to automate their Kubernetes deployments. We've had much success, but Azure DevOps is a rapidly changing tool. In this post, I'll take another look at deploying to Kubernetes with Azure DevOps pipelines.

## The Build Stage

The build stage creates artifacts for the deployment stage to use during deployment. Kubernetes is a container orchestration service, so our build pipeline needs to create a container image containing the application code. However, we need a second artifact because we use Helm to deploy applications to deploy to Kubernetes. To deploy to Kubernetes with Helm, we need a Helm chart package that describes the application deployment. The build stage for our pipeline needs to build both these artifacts.
I am a big fan of Continuous Integration/Continuous Delivery.  I've worked with several teams that were new to the concept.  Teams accustomed to the "human touch" at every phase of build and deployment find CI/CD scary.  A system that moves code changes directly to live environments feels out of control.  No team is wrong to worry about ensuring release quality, and automated systems can help.  To me, build and release pipelines are all about building trust in the artifacts as they travel from source code to production.
The need to build trust means that before our pipeline produces a build artifact, it should take some steps to ensure the quality of each artifact it produces.  For source code, this assurance usually takes the form of automated tests, static analysis, and vulnerability scanning.  When building container images, vulnerability scanning should include not only our source code but the base images as well.

With these goals in mind, let's start by building and testing our application!

### Building and Testing a Dotnet Application



> The source code for these artifacts are often stored with each other in the same source code repository. However, their lifecycles are often different. It is not necessary to rebuild the Helm chart package every time the application source code changes. It is only necessary to rebuild the Helm chart package when the chart definition changes (for example when the application defines a new configuration value that the chart must now support). Likewise, the same is true of the Docker image. When we update the Helm chart to change supported configuation or defaults (for example when we change the default number of pod replicas) we haven't changed any application code, so we do not need to rebuild the Docker image.
> One way to ensure that

## Building and Testing The App (only if needed)

### Caching Nuget Packages

## Create Docker Image

### Security Boundaries

## A note about Container scanning

## Creating the Helm Chart (only if needed)

## Deploying to AKS

## Why CI/CD?

- Life without Continuous Integration
  - Tests are never run
  - Tests are never written
  - Each build artifact is a unique snowflake
- Life without Continuous Deployment

  - Deployment by document
  - Environments drift
  - Each environment is a unique snowflake

- People “forget” to run existing tests – time, pressure
  - Tends to lead to tests breaking over time
- People “forget” to write new tests – time, pressure,
  - no one runs them anyway
  - half are broken
- Combine the components, if it compiles--run _your_ happy path scenario, if it works–you have a build
  - Your happy path may not match mine
  - What about the unhappy/obscure paths
  - What if even the happy path wont work
  - Given time/pressure, fix as little as possible then release
- Deployment by document only roughly repeatable

  - Has the operator understood the document? Have they read it? Do they keep it - updated?
  - Data, config, settings, features drift due to time/pressure/lack of - understanding
  - Each environment becomes more expensive to maintain over time, tend to keep - fewer of them.
  - Effort goes into managing environments, who has access, how long? Modern day time sharing

- Repeatability

  - Repeatability is the goal
    - Is your build a function? Given the same input does it produce the same output?
    - Is your deploy a function?

- CI Requirements
  - Automated builds
  - (Good) Automated tests
  - Artifacts
- CD Requirements

  - A safe/stable set of environments to deploy to
  - Remove bottlenecks
  - Trust in the CI process

- CI – Dev
  - In the modern era, automated builds aren’t really in dispute. But there was a - time when old timers invoked the c++ compiler by hand. Even they started using - make
  - Surprisingly we continue to struggle with automated tests, as a industry
    - Pretty easy to get people to nod and agree that automated tests are good
    - But its actually hard for most devs to write tests well -- relevant, pragmatic - and useful
    - If tests only slow the process down without providing useful feedback, - organizations will give up on them -- or worse, they will continue to write - useless tests
- When I first got started with CI, I didn’t produce artifacts.
  - The CI server would build and sometimes reveal integration problems
  - The CI server would test and sometimes reveal runtime problems
  - But when I had a green build, I had not setup any way to capture the results, - so I would rebuild the application and deploy that, logically the same as - skipping the whole process.
  - If running tests/creating build artifacts can be bypassed, it will be. People - will do the easiest thing
  - Make the CI process the easiest thing, by automating and curating the process - (not all tests should last forever, for example)
  - Basically, if the process takes too long, the organization will eventually - abandon it
- There is a difference between environment change and environment drift.
  - Change is a controlled, documented, repeatable process
  - Drift is ad-hoc, undocumented, and unknown
  - Not a talk about Infrastructure as Code, but go see a talk about Infrastructure - as Code.
  - To automate a deployment to an environment, you need to know what that - environment looks like
  - If environment changes require you to update your deployment tasks that’s ok – - as long as you knew those changes were coming
- Remove bottlenecks

  - This is about people but its not about removing people
  - For example, are QA people better allocated to ensuring the quality of - production systems, or to gating releases in an isolated environment
  - Which brings us to trust. And business decisions. The better the CI portion - of the pipeline, the higher trust we have in the artifacts it produces
  - When the trust is high enough, we can remove the bottlenecks, manual - verification, product owner gates, etc
  - It’s a process, but the fact is that no organization will allow continuous - deployment if they do not trust the process

- CD - Ops

  - 1. Why did you choose this technology?
    - People can argue semantics, “best practices,” architecture, speed, or - “Technology A” vs. “Technology B” all day long. But, no one can - dispute your experience. Tell people your story. What was your motivation for - choosing this technology, or for replacing “Technology A” with “Technology B?” - What problems were you trying to solve? Chances are, your reasons “why” will - resonate with other people in similar situations.

- What is the best CI/CD solution? Hard to say but I find hosted solutions are almost always better than installed ones in terms of my own user experience.

  - This does not mean you have to host the agents in the cloud though

- CI Benefits
  - Consistent verification process
  - Higher trust in artifacts
  - Confidence that regressions have not occurred
- CD Benefits

  - Consistent deployment process
  - Repeatable process
  - Trust??

- Although the trust can get very high with CI alone, there are limits
- To fully verify the system you must deploy it
- To me this makes a very clear that everyone can use CD, even if the process not - yet fully trusted
- Deploy to a verification environment, run automated tests, manually deploy to - the next environment.
- Continue to improve the trust in the process until trust is high enough to - allow deployment to the next environment

## A look at a sample application

- Sample application
  - Frontend
  - Backend for frontend
  - Seeder (optional)
  - Azure SQL or another data store
- Dev 1 region
- Prod multi-region

- It should already be running in dev? Just to show?

## Building your Build Stage

- Which CI/CD provider should you use?
  - No perfect solution, but prefer hosted solutions in general
  - Gives you all the cloud scale advantages/agility
  - Generally a better UX (competition?)
- What environments do you need to deploy to?
  - CI/CD is a glorified, automated batch script
  - Most can deploy anywhere; but check
- What artifacts do you need?

- Generally end up picking the best service for the client,

  - and many of our clients already have Azure Subscriptions
  - and so Azure DevOps is a good choice for them
  - I’ve used CruiseControl.net, GoCD, Travis CI, Circle CI, AppVeyor, Team City, and a little Jenkins
  - Have always had a better experience with hosted services

- What artifacts do you need?
  - Bin directories
  - NuGet Packages
  - Docker Images
  - Helm Packages
- Where do your artifacts need to go?

  - Blob Storage
  - NuGet feed
  - Docker Image Registry
  - Helm Repository

- Simplest case would be just zipping up the bin directory and in the past we - might have produced things like MSIs or Web Deploy packages
- Now we typically see Nuget, docker helm,
- CI Server often has some kind of storage for artifacts, but with a modern - system we’ll want to put them onto a purpose built repo according to their - format

  - Azure DevOps allows you to create artifact feeds that support: Nuget, npm and - Maven
  - Of course the integration for this feed inside Azure DevOps is very nice, but - there are caveats for using it within a docker container
  - You need to make a decision about your docker style -> usable by everyone - (including local) or strictly for CI?
  - For docker images we have the Azure Container Registry
  - And with a managed instace of Azure Container Registry, we also get the ability - to host helm packages (in all except Classic SKU)

- We can see that our artifacts actually depend on each other. See API
  - We can build, the Helm package independently, but need a docker image to - actually use it
  - Docker image cannot be built without the Nuget Package
  - Init job is similar, Web does not have a dependency on the Nuget package
- This knowledge will certainly influence how you order tasks in an individual CI - pipeline

  - But it will also influence your solution layout (one or many, both can work)
  - And your flow (must wait for nuget package to be built before it can be - integrated on developer machine)
  - Then push the integrated code to create the API build.
  - CI/CD is not always less work, but if you find yourself updating chains of - nuget packages in order to finally expose one new API in the application code - then you may not have the right code architecture in the first place (you lack - coheision)
  - This can be caused by organizing code by ”type” instead of ‘feature’. Subject - of a different talk

- Demo a nuget build

  - https://dev.azure.com/photo-pal/PhotoPal/_build/results?buildId=28
    - Show the nuget package build as it looks in the dashboard
    - Show the yaml
  - Things to consider
    - Nuget package not deployable on its own, so no CD
    - Each application developer must decide to accept the update by updating the - version they reference, then the deployable application will be verified in CD
    - Nuget requires a different build process because you aren’t building a docker - container, but packaging library code

- No CD
  - NuGet packages (for libraries) are not deployable
  - Developer will later accept the update
  - Actual application will be verified as a whole in it’s CD process
- NuGet CI is different

  - Under the hood, still using `dotnet pack` and `dotnet push`
  - However, while using task DSL makes authoring easier, local execution story - would by nice to have
  - Could also do single build script in bash, execute locally or in CI

- These are choices/preferences. How granular to make each pipeline? Always use tasks? Why? Not always possible. Always use script block? Foolish consistency?

- Demo a docker build

  - These pipelines include CD, but we haven’t seen it yet
  - Mostly scripts
    - “Easy” to run the same commands locally
    - First we build docker image and push it
    - Then we build helm package and push it
  - Helm and Docker builds not really related
    - Docker image will rebuild even if only the helm chart changed
    - Helm chart will rebuild even if only the code changed
    - This can be addressed using a path filter (future work)

- Trigger build by updating readme
  - Show yaml
  - Show dashboard
- Copy commands from log to run locally

  - Wont include passwords
  - Same could be done for task
  - For heavy testing may want to write a local script based off what the build - server is trying to do

- 1. Path filters: https://mohitgoyal.co/2018/09/19/- using-path-filters-in-build-definition-in-azure-devops-vsts/

## Deploying to Kubernetes

- Ensure AKS has helm installed at the version you need
  - Installer will update if needed
  - Tiller service account must be installed and configured
- Configure helm to use your private repository
- “Upgrade” your helm package to the version you want to deploy

  - Upgrader will install if needed

- Helm support very new; follow instructions carefully
- Unlike I do

- Polling deadline exceeded?
- Check service account

- UPGRADE FAILED: … has no deployed releases
- First deployment failed, purge history

- https://github.com/helm/helm/issues/3208
- This one is pretty bad, and its not an azure devops issue but a helm issue. - They are discussing/working on it
- The workaround to purge the release history-–destroys history
- But this problem should only be occurring at the frist release, so there should - be no history
- Test the release locally until you are sure its working, then give the release - another try.

  - What about prod?
  - Prod environment should be locked down for demo

- Demo deployment to dev

  - Trigger the remaining builds make sure everything is deployed,
    - Web
    - Api
    - Init
  - Show the apps
  - Show the certs - letsencrypt
  - Show in kubernetes dashboard

- Demo deployment to prod
  - Trigger the remaining builds make sure everything is deployed,
    - Web
    - Api
    - Init
  - Show the apps
  - Show the certs - purchased?
  - Show in kubernetes dashboard

References:
[Tutorial: Using Azure DevOps to setup a CI/CD pipeline and deploy to Kubernetes](https://cloudblogs.microsoft.com/opensource/2018/11/27/tutorial-azure-devops-setup-cicd-pipeline-kubernetes-docker-helm/)
[Announcing Kubernetes integration for Azure Pipelines](https://devblogs.microsoft.com/devops/announcing-kubernetes-integration-for-azure-pipelines/)
