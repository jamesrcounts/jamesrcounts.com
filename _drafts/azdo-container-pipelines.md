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
  - [Build and Push a .NET Docker Image](#build-and-push-a-net-docker-image)
    - [Execute a shallow clone](#execute-a-shallow-clone)
    - [Load cached NuGet packages](#load-cached-nuget-packages)
    - [Specify the .Net Core SDK to use for the build](#specify-the-net-core-sdk-to-use-for-the-build)
    - [Run the unit tests](#run-the-unit-tests)
    - [Publish the Application](#publish-the-application)
    - [Build the Docker Image](#build-the-docker-image)
    - [Scan the Docker Image](#scan-the-docker-image)
    - [Push the Docker Image to ACR](#push-the-docker-image-to-acr)
  - [Build and Push a Helm Chart](#build-and-push-a-helm-chart)
    - [Checkout](#checkout)
    - [Initialize Helm](#initialize-helm)
    - [Package Helm Chart](#package-helm-chart)
    - [Push Helm Chart](#push-helm-chart)
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
I am a big fan of Continuous Integration/Continuous Delivery. I've worked with several teams that were new to the concept. Teams accustomed to the "human touch" at every phase of build and deployment find CI/CD scary. A system that moves code changes directly to live environments feels out of control. No team is wrong to worry about ensuring release quality, and automated systems can help. To me, build and release pipelines are all about building trust in the artifacts as they travel from source code to production.
The need to build trust means that before our pipeline produces a build artifact, it should take some steps to ensure the quality of each artifact it produces. For source code, this assurance usually takes the form of automated tests, static analysis, and vulnerability scanning. When building container images, vulnerability scanning should include not only our source code but the base images as well.

With these goals in mind, let's start by building and testing our application!

### Build and Push a .NET Docker Image

Our sample Dotnet application is called "parrot," and it is one of a suite of applications called "phippyandfriends." Each application in the suite uses a different implementation language, and we can deploy all to Kubernetes. But this post focuses on the Dotnet application, even though it does not do much interesting on its own.

I added a simple unit test so that we could see that the pipeline runs our test. And because in Dotnet core running test implicitly builds the application first, our starter pipeline includes only a test step.

In Azure DevOps, we implement our pipeline by writing an "azure-pipelines.yaml" file. Here is the complete pipeline YAML, to build and test the parrot application:

{% gist e6b138e489a2d60ba2204e5344520a94 azure-pipelines.starter.yaml %}

In an Azure DevOps pipeline, I usually start by overriding the build identifier using the "name" property. Next, we configure triggers to control when the pipeline executes. In the case of phippy and friends, there are multiple applications in the same repository, so the trigger restricts this pipeline to only trigger when parrot changes on the master branch. After the triggers, we can define the variables the pipeline shares across all stages. Then we can define the first stage, called "Build."

The Build stage specifies one or more jobs to run. Jobs within a stage run in parallel unless otherwise specified. We'll take advantage of that later. For now, there is only a single job, called "Docker" because it builds and pushes a Docker image to my Azure Container Registry (ACR). The Docker job specifies the virtual machine type it should run on, in this case, the latest available ubuntu agent hosted by Azure DevOps. Within the job are steps:

- Execute a shallow clone
- Load cached NuGet packages
- Specify the .Net Core SDK to use for the build
- Run the unit tests
- Publish the Application
- Build the Docker Image
- Scan the Docker Image
- Push the Docker Image to ACR

#### Execute a shallow clone

I've yet to encounter a build pipeline that requires the entire git history to execute correctly. This pipeline only needs the latest working copy to build the application. Pulling only the latest code can speed up build times on older repositories with longer histories. Including an explicit step to checkout allows for further customization if needed, including the opportunity to clean out the working directory before checkout.

{% gist e6b138e489a2d60ba2204e5344520a94 checkout-step.yaml %}

#### Load cached NuGet packages

Azure Pipelines can cache just about any file added during the build process, including NuGet packages, npm caches, Maven downloads, and more. While pipeline caching is still in preview, saving cached files can reduce build time by saving these dependencies in between runs.

{% gist e6b138e489a2d60ba2204e5344520a94 cache-step.yaml %}

The cache is simple to set up, you specify a key, which can include both simple strings and file paths. When using a file path as part of the key, the contents are hashed to a signature first. In the case of this NuGet caching step, changes to "package-lock.json" automatically invalidate the cache. If Azure Pipelines finds no matching cache item, the task automatically schedules an upload at the end of the pipeline. On a cache miss, Dotnet downloads the NuGet packages as it usually does, then uploads them to the cache once the build succeeds. No upload takes place if the build fails.

{:style="text-align: center;"}
![Caching packages after the job completes][3]

#### Specify the .Net Core SDK to use for the build

To create repeatable pipelines, we should control all inputs to the pipeline, not just our code. So, we specify the dotnet core SDK version for Azure Pipelines to use. This way, when Microsoft updates the default dotnet version on their hosted agents, our pipeline continues to use a version appropriate for the parrot application. More importantly, the version the parrot binaries expect and the version on the Docker base image match.

{% gist e6b138e489a2d60ba2204e5344520a94 pin-dotnet-step.yaml %}

#### Run the unit tests

The next step runs the unit tests in release configuration. This step implicitly builds the application, then runs the unit tests in the unit test project. If the cache failed to restore the NuGet packages, dotnet restore downloads them as part of this process.

{% gist e6b138e489a2d60ba2204e5344520a94 test-step.yaml %}

Writing and running unit tests is meant to increase the level of trust in the system you are building. If the unit tests fail, the build pipeline stops, and later steps won't execute. This behavior makes it hard to miss the overall test/pass status. But it's also nice to view the test results without digging through logs. Luckily the Azure DevOps Dotnet CLI task automatically uploads build results from the build agent so that we can see the results right in the browser.

{:style="text-align: center;"}
![Test results in Azure DevOps][1]

There are many other free or commercial tools that you can integrate with Azure Pipelines to provide additional reports like code coverage or static analysis. You can look for your favorite tools in the [Visual Studio Marketplace under Azure DevOps][2].

#### Publish the Application

Next, add a step to publish the Dotnet code. Despite its name, publishing does not deploy the code anywhere. Instead, publishing gets all the files ready to be incorporated into the Docker image in later steps.

{% gist e6b138e489a2d60ba2204e5344520a94 publish-step.yaml %}

The publishing step should run very fast because the test step already built the code for us. Reusing the code that the pipeline already built not only saves time but aligns our pipeline with a continuous integration principal. The pipeline should only build the code once. Our pipeline generates an audit trail that demonstrates our code has qualities we want. The pipeline shows that these binaries pass our unit tests. The pipeline shows we achieved a certain level of code coverage. The pipeline shows we found no known vulnerabilities in our dependencies. The pipeline shows these qualities and any others we choose to add. At no point do we want to rebuild the binaries and introduce a reason to doubt whether the new binaries are the same as the ones we tested already.

This publishing step invokes the dotnet CLI with the "publish" command and provides the path to the application project file. In the arguments property for the task, we provide two arguments. First, the configuration flag indicates we want to publish a release build. Next, the output flag indicates the directory to move the binaries to. As mentioned, the dotnet CLI does not rebuild this project once it establishes that the binaries are already present. Moving the pre-built binaries is valuable to us because it gives us a simple location to pull those files from when creating the Docker image.

After publishing the binaries to the "dist" directory, we are ready to add steps to build and push a Docker image.

#### Build the Docker Image

The latest Docker task offered by Azure Pipelines can build a Docker image and push it directly to ACR in one step. This pipeline uses the current Docker task but does not take advantage of the combined build and push command. Instead, this step only builds the docker image. Building the docker image as a separate step allows later steps to scan the Docker image for vulnerabilities, just like we can test and scan the dotnet code.

{% gist e6b138e489a2d60ba2204e5344520a94 docker-build.yaml %}

To set up the Docker image build, we supply a service connection to our ACR (called 'ACR' here). Providing the ACR service connection allows the task to infer the login server portion of the image repository name. In this case, "parrot" is the container repository name. Finally, we tell the task where to find the Dockerfile and build context. Again, because multiple applications exist in the phippy and friends repository, we need to be more specific than the task defaults allow. Finally, we specify the build number as a tag for the image. If we want to specify more than one tag, we can specify one per line.

{% gist e6b138e489a2d60ba2204e5344520a94 Dockerfile %}

Because the test step already produced binaries and validated them with our unit tests and other scans, our Dockerfile does not repeat these steps. Instead, we select an appropriate base image and patch all of its packages to remove any known vulnerabilities. To add our application to the image, the Dockerfile only needs to copy the binaries from the publishing location into the appropriate directory on the image.

#### Scan the Docker Image

In this example, this step is only a placeholder. Setting up container scanning in the build pipeline involves some complexity. However, for security-minded teams checking containers for vulnerability and compliance is a necessity. These types of scans further increase our trust and confidence in the image we just built, so that we know it is appropriate for deployment.

{% gist e6b138e489a2d60ba2204e5344520a94 container-scan.yaml %}

This scanning step belongs in the pipeline after the image is available locally, but before the step to push to ACR.

#### Push the Docker Image to ACR

Finally, the pipeline pushes the Docker image to ACR. Again the pipeline uses the Docker task for this step. The ACR service connection provides authentication to the ACR, and the repository and tags properties indicate which images to push from the local cache into the remote registry.

{% gist e6b138e489a2d60ba2204e5344520a94 docker-push.yaml %}

### Build and Push a Helm Chart

Parrot includes a Helm chart definition to facilitate deployment to Kubernetes. Our deployment pipeline benefits from Helm because Helm provides a template engine for customizing our Kubernetes configurations per environment. Helm is the defacto standard for customizing Kubernetes configurations. Other tools may overtake it in the future, but Helm maintains market dominance for now.

Using a Helm chart means the pipeline build stage needs a second job, to produce a second artifact: the helm chart package. Because the package helm chart has no dependencies on the application code or the Docker image, the pipeline can build it in a separate job in the same build stage. When a stage has multiple jobs, each job executes in parallel by default, and we can save a little time by building both artifacts at once.

Here is the complete helm job to add the build stage in "azure-pipelines.yaml" file:

{% gist e6b138e489a2d60ba2204e5344520a94 helm-job.yaml %}

The new job, called "Helm" because it builds and pushes a Helm chart to ACR. Like the Docker job, the Helm job specifies the virtual machine type it should run on, in this case, the latest available ubuntu agent hosted by Azure DevOps. Within the job are steps:

- Checkout
- Initialize Helm
- Package Helm Chart
- Push Helm Chart

#### Checkout

Just like the dotnet and Docker build steps, the helm chart does not need the full git history to build the chart.  So, we execute a shallow clone in the Helm job to retrieve only the latest working copy.

#### Initialize Helm

The pipeline uses the Helm installer task to pin a specific version of Helm to use when building our chart.  We pin the Helm version for the same reasons we pinned the dotnet version earlier--to control as many inputs into our build process as possible.

{% gist e6b138e489a2d60ba2204e5344520a94 initialize-helm.yaml %}

#### Package Helm Chart

After getting our code and tooling in place, the next step in the pipeline uses a Helm deploy task to package the Helm chart.  The Helm deployment task needs to know where the chart source is, and what version to assign the chart, to package the Helm chart.  The final property "save" is set to false because we do not need to install the chart on the local build agent. 

{% gist e6b138e489a2d60ba2204e5344520a94 helm-package.yaml %}

#### Push Helm Chart

Unlike the Docker task, the HelmDeploy task includes no push command to move the local package into ACR.  The pipeline finishes with an Azure CLI task to push the chart into the registry.  The Azure CLI task requires configuration to provide a service connection to an Azure subscription.  This service connection should connect to a subscription containing an ACR instance.  

{% gist e6b138e489a2d60ba2204e5344520a94 helm-push.yaml %}

Once we provide an appropriate connection, we also provide the Azure CLI task with a script to execute.  In this case, our script uses the Azure CLI's "acr helm push" command to store the Helm package in our registry.  When the Azure CLI task executes, it logs in to Azure  with the provided service connection, executes our script, then logs out automatically.

{:style="text-align: center;"}
![Az CLI pushing Helm chart to ACR][4]


[1]: /media/2019/11/01/test-results-azure-devops.png
[2]: https://marketplace.visualstudio.com/search?target=AzureDevOps&category=Azure%20Pipelines&sortBy=Installs
[3]: /media/2019/11/01/cache-packages.png
[4]: /media/2019/11/01/azure-cli.png

-- TODO, caching
-- TODO, link to phippy and friends

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
