---
layout: post
title: 'Container Releases to Kubernetes with Azure DevOps'
tags:
  - AzureDevOps
  - DevOps
  - Docker
  - Kubernetes
---

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/container-hero.png alt: "Container Releases to Kubernetes with Azure DevOps." %}

Over the past couple of years, I've continued to work with teams using
Azure DevOps pipelines to automate their Kubernetes deployments. The
ecosystem around Azure DevOps, Kubernetes, and .Net continue to evolve.
While my previous articles on [container
pipelines](http://jamesrcounts.com/2019/11/18/azdo-container-pipelines.html)
and refactoring to [separate build artifacts by
lifecycle](http://jamesrcounts.com/2020/02/08/one-lifecycle.html) still
contain a lot of great info, the examples have gone stale. It’s time to
refresh and to see if we can take our pipeline game a little further
than before.

- [Create CI/CD Plan](#create-cicd-plan)
  - [Application(s) to Deploy](#applications-to-deploy)
  - [Environment](#environment)
  - [Artifacts](#artifacts)
  - [CI/CD Flow](#cicd-flow)
- [Build Stage: Container Image](#build-stage-container-image)
  - [Pipeline Trigger](#pipeline-trigger)
  - [Pipeline Stage](#pipeline-stage)
    - [Shallow Clone](#shallow-clone)
    - [Load Caches](#load-caches)
    - [Pin .Net/Node Versions](#pin-netnode-versions)
    - [Restore Packages](#restore-packages)
    - [Run Unit Tests](#run-unit-tests)
    - [Publish Application](#publish-application)
    - [Build Docker Image](#build-docker-image)
    - [Scan Docker Image](#scan-docker-image)
    - [Push Docker Image](#push-docker-image)
- [Build Stage: Package Helm Chart](#build-stage-package-helm-chart)
  - [Pipeline Trigger](#pipeline-trigger-1)
  - [Pipeline Stage](#pipeline-stage-1)
    - [Shallow Clone](#shallow-clone-1)
    - [Pin Helm Version](#pin-helm-version)
    - [Check Helm Chart](#check-helm-chart)
    - [Save Helm Chart](#save-helm-chart)
    - [Push Helm Chart](#push-helm-chart)
- [Setup Deployment Environments](#setup-deployment-environments)
  - [Development Environment](#development-environment)
  - [Production Environment](#production-environment)
- [Deployment Pipeline](#deployment-pipeline)
  - [Deployment Trigger](#deployment-trigger)
  - [Deployment Stages](#deployment-stages)
  - [Deployment Template](#deployment-template)
    - [Disable Checkout](#disable-checkout)
    - [Pin Helm Version](#pin-helm-version-1)
    - [Prepare Deployment](#prepare-deployment)
    - [Deploy Helm Chart](#deploy-helm-chart)
- [CI/CD in Action](#cicd-in-action)
  - [Change Deployment Configuration](#change-deployment-configuration)
  - [Change Application Code](#change-application-code)
- [Review](#review)

## Create CI/CD Plan

Before setting up pipelines, first, create a plan for how deployments
should work. Planning does not need to be big design upfront, it can be
simple, but a little up front thinking can save you some refactoring time
later.

Start by answering the following questions:

-   What application am I trying to deploy?
-   Where do I need to deploy it?
-   What artifacts do I need for deployment?

If you don’t yet have all the answers, that’s ok. Hopefully, by the end
of this example, you will have a better idea.

### Application(s) to Deploy

For this example, I’ll focus on one of the apps from
[phippyandfriends](https://github.com/jamesrcounts/phippyandfriends/tree/2021.06):
parrot. Parrot is a .Net application and provides the user interface
that displays the other applications detected by captainkube.

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/parrot-and-phippy.png alt: "Screenshot of Parrot application in the browser." %}

### Environment

Since this is an article about deploying to Kubernetes, we’ll deploy to
an Azure Kubernetes Cluster instance. For demonstration purposes, I’ll
show how to deploy parrot to multiple environments: a development
sandbox and a production environment. Apart from necessary differences
like hostnames and certificates, each tier will have the same
configuration.

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/environment-topology.png alt: "Hosting environment topology." %}

### Artifacts

Our pipelines must produce two artifacts before we can deploy to the
target environment. The first artifact will be a container image for the
application and all its dependencies. The second artifact will be a helm
chart describing the Kubernetes objects to add to each environment. The
parrot folder contains the definition for both these artifacts. We need
to:

-   Build the parrot application and package it into a container image
-   Package the helm chart templates

We'll want to rebuild our container image if either the parrot
application or parrot’s Dockerfile change. However, if the helm chart
changes (without any application or Dockerfile changes), rebuilding the
container image is a waste of compute cycles. Likewise, repackaging the
helm chart when only the application has changed is a waste.

> Build artifacts should only change when the inputs that define them
have changed. A change in any input artifact should trigger
deployment.

### CI/CD Flow

After reviewing everything, we can sketch a CI/CD flow that looks like
this:

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/ci-cd-plan.png alt: "CI/CD Plan." %}

Because the container image and helm chart do not necessarily change
together for the same reasons simultaneously, they have separate
lifecycles. Our CI/CD flow will support these lifecycles using different
pipelines for each artifact. The sources for each build artifact are
co-located in the same repository (along with several other apps and the
infrastructure definition), and filters on our CI triggers will ensure
that each pipeline only executes when it needs to.

Each build pipeline acts as a CD Trigger for a shared deployment
pipeline. The deploy pipeline will trigger when either the container
image version or the helm package version changes.

## Build Stage: Container Image

### Pipeline Trigger

[parrot/azure-pipelines.docker.yaml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/parrot/azure-pipelines.docker.yaml#L3)

```yaml
trigger:
  batch: true
  paths:
    include:
      - parrot
    exclude:
      - 'parrot/src/parrot/charts'
      - 'parrot/azure-pipelines.deploy.yaml'
      - 'parrot/azure-pipelines.helm.yaml'
  branches:
    include:
      - main
```

The CI Trigger runs anytime that a commit contains changes to files in
the “parrot” folder, except for changes in the exclusion list. The
excluded files are the “charts” folder and the pipeline definitions for
the helm packaging pipeline and the deployment stage. With these filters
in place, the container image build pipeline should only run if the
application or Dockerfile changes.

### Pipeline Stage 

[parrot/azure-pipelines.docker.yaml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/parrot/azure-pipelines.docker.yaml#L30)
```yaml
- stage: Build
  displayName: 'Build Docker Image'
  jobs:
    - job: Docker
      displayName: 'Build and Push Docker Image'
      pool:
        vmImage: 'ubuntu-latest'

      steps:
        - checkout: self
          fetchDepth: 1

        - task: Cache@2
          displayName: Cache NuGet packages
          inputs:
            key: 'nuget | "$(Agent.OS)" | $(Build.SourcesDirectory)/parrot/src/parrot/packages.lock.json'
            restoreKeys: |
              nuget | "$(Agent.OS)"
            path: $(nuget_packages)

        - task: Cache@2
          displayName: Cache npm
          inputs:
            key: 'npm | "$(Agent.OS)" | $(Build.SourcesDirectory)/parrot/src/parrot/package-lock.json'
            restoreKeys: |
              npm | "$(Agent.OS)"
            path: $(npm_config_cache)

        - task: UseDotNet@2
          displayName: 'Use .NET Core SDK version 3.1.408'
          inputs:
            packageType: 'sdk'
            version: '3.1.408'

        - task: NodeTool@0
          displayName: 'Use Node version 11.x'
          inputs:
            versionSpec: '11.x'

        - task: Bash@3
          displayName: 'Restore NPM packages'
          inputs:
            targetType: 'inline'
            script: 'npm ci'
            workingDirectory: 'parrot/src/parrot'

        - task: DotNetCoreCLI@2
          displayName: 'Run Unit Tests'
          inputs:
            command: 'test'
            projects: 'parrot/tests/parrot.UnitTests/parrot.UnitTests.csproj'
            arguments: '--configuration $(BuildConfiguration) --logger:trx'
            testRunTitle: 'Unit Tests'

        - task: DotNetCoreCLI@2
          displayName: 'Publish Application'
          inputs:
            command: 'publish'
            publishWebProjects: false
            projects: 'parrot/src/parrot/parrot.csproj'
            arguments: '--configuration $(BuildConfiguration) --output parrot/src/parrot/out'
            zipAfterPublish: false
            modifyOutputPath: false

        - task: Docker@2
          displayName: 'Build Docker Image'
          inputs:
            containerRegistry: 'ACR'
            repository: '$(containerRepository)'
            command: 'build'
            Dockerfile: 'parrot/src/parrot/Dockerfile'
            buildContext: 'parrot/src/parrot'
            tags: '$(Build.BuildNumber)'

        - template: ../pipeline-templates/trivy-scan.yml
          parameters:
            imageName: $(LOGIN_SERVER)/$(containerRepository):$(Build.BuildNumber)
            failTaskOnFailedScan: true

        - task: Docker@2
          displayName: 'Push Docker Image'
          inputs:
            containerRegistry: 'ACR'
            repository: '$(containerRepository)'
            command: 'push'
            tags: '$(Build.BuildNumber)'
```

The stage has these steps:

-   Shallow Clone
-   Load Caches
-   Pin .Net/Node Versions
-   Restore Packages
-   Run Unit Tests
-   Publish Application
-   Build Docker Image
-   Scan Docker Image
-   Push Docker Image

This stage is the only stage in the container image build pipeline. It
will build and test the Parrot application code, package it into a
container image, and scan the container image for vulnerabilities. If
all those steps pass without errors, the stage will push the container
image into the backend Azure Container Registry (ACR).

#### Shallow Clone

[parrot/azure-pipelines.docker.yaml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/parrot/azure-pipelines.docker.yaml#L39)

```yaml
- checkout: self
  fetchDepth: 1
```

By default, the pipeline will download the entire commit history. This
configuration overrides the default and instructs Azure DevOps to
download only the latest working copy.


#### Load Caches

[parrot/azure-pipelines.docker.yaml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/parrot/azure-pipelines.docker.yaml#L42-L56)

```yaml
- task: Cache@2
  displayName: Cache NuGet packages
  inputs:
    key: 'nuget | "$(Agent.OS)" | $(Build.SourcesDirectory)/parrot/src/parrot/packages.lock.json'
    restoreKeys: |
      nuget | "$(Agent.OS)"
    path: $(nuget_packages)

- task: Cache@2
  displayName: Cache npm
  inputs:
    key: 'npm | "$(Agent.OS)" | $(Build.SourcesDirectory)/parrot/src/parrot/package-lock.json'
    restoreKeys: |
      npm | "$(Agent.OS)"
    path: $(npm_config_cache)
```

Azure DevOps caching can save and restore files and directories in
between pipeline runs. Caching can result in build speed up if your
dependencies are numerous or only available from slow mirrors. These
tasks set up caching for the package types that Parrot uses: NuGet and
npm.

#### Pin .Net/Node Versions

[parrot/azure-pipelines.docker.yaml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/parrot/azure-pipelines.docker.yaml#L58-L67)
```yaml
- task: UseDotNet@2
  displayName: 'Use .NET Core SDK version 3.1.408'
  inputs:
    packageType: 'sdk'
    version: '3.1.408'

- task: NodeTool@0
  displayName: 'Use Node version 11.x'
  inputs:
    versionSpec: '11.x'
```

Although Microsoft pre-installs many versions of .Net and node on hosted
build agents, our code requires specific versions. Declaring the
versions needed by our code ensures that our pipeline always uses that
version, even when new updates come out or defaults change.

#### Restore Packages

[parrot/azure-pipelines.docker.yaml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/parrot/azure-pipelines.docker.yaml#L69-L74)

```yaml
- task: Bash@3
  displayName: 'Restore NPM packages'
  inputs:
    targetType: 'inline'
    script: 'npm ci'
    workingDirectory: 'parrot/src/parrot'
```

Because this pipeline builds and tests the application outside the
container image build step below, the next step is to restore the NPM
packages so that .Net may publish them with the application.

#### Run Unit Tests

[parrot/azure-pipelines.docker.yaml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/parrot/azure-pipelines.docker.yaml#L76-L82)
```yaml
- task: DotNetCoreCLI@2
  displayName: 'Run Unit Tests'
  inputs:
    command: 'test'
    projects: 'parrot/tests/parrot.UnitTests/parrot.UnitTests.csproj'
    arguments: '--configuration $(BuildConfiguration) --logger:trx'
    testRunTitle: 'Unit Tests'
```

The next step runs the unit tests in release configuration. .Net will
restore packages and build the application first if needed. If the cache
contains packages from a previous run, this step will take advantage of
the cache. Otherwise, .Net will restore the binaries in the usual way,
and an automatically generated post-build task will save them in Azure
DevOps for later use.

Shouldn’t this all be done in the Dockerfile? Multi-stage container
image build definitions can handle many of these steps without polluting
the runtime image with build SDKs and artifacts. The choice to place
build and test steps outside the container image build step provides
additional flexibility for the types of tests to run. Even though the
all-in-one Dockerfile approach is elegant, I’ve worked with more than
one team that abandoned its advantages to enable more advanced testing
scenarios.

> Tests are one way to build trust in the artifacts we intend to
release. Code that passes our tests is more likely to work in
production than code that fails our tests. Achieving truly
“continuous” integration and deployment flows means creating
automation to demonstrate that the artifact's “trust level” is high.
Given a choice between elegance and showing the code is trustworthy,
choose to establish trust.

#### Publish Application

[parrot/azure-pipelines.docker.yaml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/parrot/azure-pipelines.docker.yaml#L84-L92)
```yaml
- task: DotNetCoreCLI@2
  displayName: 'Publish Application'
  inputs:
    command: 'publish'
    publishWebProjects: false
    projects: 'parrot/src/parrot/parrot.csproj'
    arguments: '--configuration $(BuildConfiguration) --output parrot/src/parrot/out'
    zipAfterPublish: false
    modifyOutputPath: false
```

The publishing step organizes the code built and tested by the testing
step into a folder suitable for copying into the container image. By
copying the same binaries that the pipeline created in the previous
step, we continue to build trust. Our logs will show that we deploy the
same binaries that passed our tests with no intervening rebuild.

#### Build Docker Image

[parrot/azure-pipelines.docker.yaml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/parrot/azure-pipelines.docker.yaml#L94-L102)
```yaml
- task: Docker@2
  displayName: 'Build Docker Image'
  inputs:
    containerRegistry: 'ACR'
    repository: '$(containerRepository)'
    command: 'build'
    Dockerfile: 'parrot/src/parrot/Dockerfile'
    buildContext: 'parrot/src/parrot'
    tags: '$(Build.BuildNumber)'
```

This step uses our Dockerfile (shown below) to create a container image
for the parrot application and tag the image with the pipeline build
number. For now, the pipeline does not push the container image to ACR.
Instead, the container image remains cached on the local agent.

[parrot/src/parrot/Dockerfile:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/parrot/src/parrot/Dockerfile)
```Dockerfile
FROM mcr.microsoft.com/dotnet/core/aspnet:3.1.5-alpine

RUN apk update && apk upgrade --no-cache

WORKDIR /app
COPY ./out .

ENTRYPOINT ["dotnet", "parrot.dll"]
```

The Dockerfile selects an appropriate base image and patches all its
packages to remove any known vulnerabilities. To add our application to
the image, the Dockerfile copies binaries from the publishing location
into the appropriate directory on the image.

{:style="text-align:center;font-style: italic;background: lightsteelblue;border-radius: 24px;padding: 20px;"}
There is no need to run unit tests or rebuild the binaries inside the
Docker build step, the pipeline already produced binaries and
validated them before reaching this step.

#### Scan Docker Image

[pipeline-templates/trivy-scan.yml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/pipeline-templates/trivy-scan.yml)
```yaml
- task: Bash@3
  displayName: 'Pin Trivy'
  env: 
    TRIVY_VERSION: ${{ parameters.trivyVersion }}
  inputs:
    targetType: 'inline'
    script: |
      set -euo pipefail

      wget https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.deb
      sudo dpkg -i trivy_${TRIVY_VERSION}_Linux-64bit.deb

- task: Bash@3
  displayName: 'Container Image Scan'
  env:
    IMAGE_NAME: ${{ parameters.imageName }}
  inputs:
      targetType: 'inline'
      script: |
        set -euo pipefail
        
        trivy image \
          --ignore-unfixed \
          --format template \
          --template "@pipeline-templates/junit.tpl" \
          -o junit-report.xml \
          ${IMAGE_NAME}

- task: PublishTestResults@2
  displayName: 'Publish Trivy Scan Results'
  inputs:
      testResultsFormat: 'JUnit' 
      testResultsFiles: 'junit-report.xml' 
      failTaskOnFailedTests: ${{ parameters.failTaskOnFailedScan }}
      testRunTitle: 'Trivy Image Scan'

```

Before pushing the container image to the registry for use, this
pipeline scans the image using a free scanner called
[trivy](https://aquasecurity.github.io/trivy/v0.18.3/). Trivy will scan
OS packages and application dependencies for known vulnerabilities.
Trivy will report any vulnerabilities in the Alpine apks, the .Net NuGet
packages, and the node npm packages in the case of the parrot image.

This shared template contains all the steps needed to download trivy,
scan the image, and report the results to the Azure DevOps test results
tab. By default, the template will terminate the build pipeline when
trivy detects vulnerabilities. The template includes an option to run in
“report-only” mode without failing the build.

> Trivy has options to enable fine-grained [vulnerability
> filtering](https://aquasecurity.github.io/trivy/v0.18.3/examples/filter/),
> including a “.trivyignore” file where teams can accept the risk for
> each vulnerability.

#### Push Docker Image

[parrot/azure-pipelines.docker.yaml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/parrot/azure-pipelines.docker.yaml#L109-L115)
```yaml
- task: Docker@2
  displayName: 'Push Docker Image'
  inputs:
    containerRegistry: 'ACR'
    repository: '$(containerRepository)'
    command: 'push'
    tags: '$(Build.BuildNumber)'
```

After the vulnerability scan completes, the pipeline sends the container
image to ACR. This step completes the container image build pipeline.

## Build Stage: Package Helm Chart

### Pipeline Trigger

[parrot/azure-pipelines.helm.yaml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/parrot/azure-pipelines.helm.yaml#L3-L14)
```yaml
trigger:
  batch: true
  paths:
    include:
      - parrot/src/parrot/charts
      - parrot/azure-pipelines.helm.yaml
  branches:
    include:
      - main
```

The stage trigger includes the “charts” folder but no other sources
besides the pipeline definition itself. Exclusions are not needed in
this case because the contents of the charts folder only change when the
chart definition changes.

### Pipeline Stage

[pipeline-templates/helm-package.yml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/pipeline-templates/helm-package.yml)

```yaml
stages:
  - stage: package
    displayName: 'Package Helm Chart'
    jobs:
      - job: Helm
        displayName: 'Build and Push Helm Chart'
        pool:
          vmImage: 'ubuntu-latest'

        steps:
          - checkout: self
            fetchDepth: 1

          - task: HelmInstaller@1
            displayName: 'Initialize Helm'
            inputs:
              helmVersionToInstall: 'latest'

          - task: Bash@3
            displayName: 'Check Helm Chart'
            inputs:
              targetType: 'inline'
              script: |
                set -euo pipefail

                helm lint $(chart_path) --strict

          - task: Bash@3
            displayName: 'Save Helm Chart'
            inputs:
              targetType: 'inline'
              script: |
                set -euo pipefail

                helm chart save $(chart_path) $(artifact)

          - task: AzureCLI@2
            condition: and(succeeded(), ne(variables['Build.Reason'], 'PullRequest'))
            displayName: 'Push Helm Chart'
            inputs:
              addSpnToEnvironment: true
              azureSubscription: 'Azure'
              scriptLocation: 'inlineScript'
              scriptType: 'bash'
              inlineScript: |
                set -euo pipefail

                echo $servicePrincipalKey | \
                  helm registry login $(LOGIN_SERVER) \
                    --username $servicePrincipalId \
                    --password-stdin

                helm chart push $(artifact)
```

The stage has these steps:

-   Shallow Clone
-   Pin Helm Version
-   Check Helm Chart
-   Save Helm Chart
-   Push Helm Chart
  
#### Shallow Clone

The pipeline does not need the entire commit history to create the Helm
package, so this stage executes a shallow clone, as described
[above](#shallow-clone).

#### Pin Helm Version

[pipeline-templates/helm-package.yml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/pipeline-templates/helm-package.yml#L14-L17)

```yaml
- task: HelmInstaller@1
  displayName: 'Pin Helm Version'
  inputs:
    helmVersionToInstall: '3.6.0'
```

The Helm installer task pins a specific Helm version on the agent. The
Helm version is an input to our build process, just like the versions of
.Net and node.

#### Check Helm Chart

[pipeline-templates/helm-package.yml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/pipeline-templates/helm-package.yml#L19-L26)

```yaml
- task: Bash@3
  displayName: 'Check Helm Chart'
  inputs:
    targetType: 'inline'
    script: |
      set -euo pipefail

      helm lint $(chart_path) --strict
```

Helm’s lint command checks charts for possible issues and emits errors
and warnings if it finds any problems. With strict mode enabled, both
errors and warnings cause the check (and therefore the build) to fail.
This early failure creates an opportunity to correct problems with the
chart before attempting a deployment.

> The check helps find both simple typos and subtler problems like a
> mismatch between a Kubernetes API schema and the properties in the
> template.

#### Save Helm Chart

[pipeline-templates/helm-package.yml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/pipeline-templates/helm-package.yml#L28-L35)
```yaml
- task: Bash@3
  displayName: 'Save Helm Chart'
  inputs:
    targetType: 'inline'
    script: |
      set -euo pipefail

      helm chart save $(chart_path) $(artifact)
```

Helm 3 introduced OCI integration as an [experimental
feature](https://github.com/helm/community/blob/5e8bcded7ed93ce7112ab898aabda527cf82bb78/hips/hip-0006.md).
This support allows ACR users to store Helm charts in the same registry
as their container images using the same conventions. Because the
capability is still considered experimental, [the pipeline must set a
flag
(HELM_EXPERIMENTAL_OCI)](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/phippy/azure-pipelines.helm.yml#L21-L22)
to enable support.

> Saving a chart with the Helm CLI will create a single-layer OCI
> artifact (the same format container images use) in the agent’s cache.
> The contents of the layer are just the YAML files forming the Helm
> chart.

#### Push Helm Chart

[pipeline-templates/helm-package.yml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/pipeline-templates/helm-package.yml#L37-L53)

```yaml
- task: AzureCLI@2
  condition: and(succeeded(), ne(variables['Build.Reason'], 'PullRequest'))
  displayName: 'Push Helm Chart'
  inputs:
    addSpnToEnvironment: true
    azureSubscription: 'Azure'
    scriptLocation: 'inlineScript'
    scriptType: 'bash'
    inlineScript: |
      set -euo pipefail

      echo $servicePrincipalKey | \
        helm registry login $(LOGIN_SERVER) \
          --username $servicePrincipalId \
          --password-stdin

      helm chart push $(artifact)
```

The pipeline uses an Azure CLI to push our chart artifact to ACR. The
“addSpnToEnvironment” option injects the service principal credentials
into the script process so that the script can log in to ACR using
Helm’s registry login support (also experimental). Once logged into the
registry, Helm can send our chart to ACR using the push command.

## Setup Deployment Environments

The demo environment includes two AKS clusters. The development cluster
should allow complete CI/CD, but we will configure the production
environment to require manual approval before deployment. Azure DevOps
Environments separate the logical definition of an environment and its
governance from the pipeline definition. The deployment pipeline will
reference the configured environment, and any permissions and checks
configured on the environment then apply to the pipeline.

### Development Environment

First, log in to Azure DevOps and choose Environments under pipelines,
then select Create Environment:

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/create-environment.png alt: "Create Azure DevOps Environment." %}

Next, type an environment name and choose “Kubernetes” as the resource,
then select “Next.” I named the first environment dev.

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/new-environment.png alt: "New Environment Dialog." %}{:style="max-width:45%"}

Next, choose your cluster and namespace and select “Validate and
create.”

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/new-environment-k8s.png alt: "New Environment Kubernetes configuration." %}{:style="max-width:45%"}

Because we do not want a manual deployment gate on the development
cluster, the development environment configuration is now ready.

### Production Environment

To create the production environment, follow the same initial steps to
create an environment called “prd” for the production AKS instance.
Next, use the top-right menu to select “Approvals and checks.”

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/approvals-and-checks.png alt: "Approvals and Checks menu item." %}

Select “Approvals.” Then enter an appropriate user or group to supply
approvals. Next, choose “Create.”

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/manual-approval.png alt: "Manual Approval Dialog." %}

Deployments that target the production environment will now request
approval before making changes.

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/configured-approval.png alt: "Configured Manual Approval." %}

## Deployment Pipeline

### Deployment Trigger

[parrot/azure-pipelines.deploy.yaml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/parrot/azure-pipelines.deploy.yaml#L3-L21)
```yaml 
resources:
  pipelines:
    - pipeline: build
      source: 'parrot-docker'
      trigger: true
      branch: main
    - pipeline: helm
      source: 'parrot-helm'
      trigger: true
      branch: main

trigger:
  batch: true
  paths:
    include:
      - parrot/azure-pipelines.deploy.yaml
  branches:
    include:
      - main
```

Our CI/CD flow requires the deployment pipeline should trigger any time
the application or deployment configuration artifacts change. The
resource block connects pipelines in Azure DevOps by specifying the
names of the build pipelines and whether each build pipeline should
trigger the deployment pipeline. The deployment pipeline declares both
the “parrot-docker” and the “parrot-helm” pipelines as triggers to meet
the requirement.

> If you want to consume artifacts from another pipeline without
> triggering a run, set the “trigger” property to false.

### Deployment Stages

[parrot/azure-pipelines.deploy.yaml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/parrot/azure-pipelines.deploy.yaml#L43-L54)
```yaml
stages:
  - template: '../pipeline-templates/helm-deployment.yml'
    parameters:
      baseDomain: boss-crawdad-dev.$(aksHost)
      environment: dev.apps
      kubernetesCluster: aks-boss-crawdad-dev

  - template: '../pipeline-templates/helm-deployment.yml'
    parameters:
      baseDomain: boss-crawdad-prd.$(aksHost)
      environment: prd.apps
      kubernetesCluster: aks-boss-crawdad-prd
```

Like the helm packaging step, the helm deployment steps are identical
except for a few variables, so I’ve implemented the stage as a shared
template. The environment name is one of the template parameters,
ensuring that the development deployment uses continuous delivery and
the production deployment pauses for approval.

### Deployment Template

[pipeline-templates/helm-deployment.yml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/pipeline-templates/helm-deployment.yml)
```yaml
parameters:
- name: baseDomain 
  type: string
  default: ""
- name: environment
  type: string
- name: kubernetesCluster
  type: string

stages:
  - stage:
    variables:
      ${{if parameters.baseDomain}}:
        overrideValues: 'ingress.basedomain=${{ parameters.basedomain }},image.tag=$(imageTag),image.repository=$(LOGIN_SERVER)/$(containerRepository)'
      ${{if not(parameters.baseDomain)}}:
        overrideValues: 'image.tag=$(imageTag),image.repository=$(LOGIN_SERVER)/$(containerRepository)'
    displayName: Helm Deploy
    jobs:
      - deployment: 
        displayName: ${{ parameters.environment }} Deployment
        pool:
          vmImage: 'ubuntu-latest'
        environment: ${{ parameters.environment }}
        strategy:
          runOnce:
            deploy:
              steps:
                - checkout: none

                - task: HelmInstaller@1
                  displayName: 'Pin Helm Version'
                  inputs:
                    helmVersionToInstall: '3.6.0'

                - task: AzureCLI@2
                  displayName: 'Prepare Deployment'
                  env:
                    AKS_RG: $(AZURE_ENV_RG)
                    REGISTRY_SERVER: $(LOGIN_SERVER)
                    CHART_PATH: $(local_chart_path)
                  inputs:
                    addSpnToEnvironment: true
                    azureSubscription: 'Azure'
                    failOnStandardError: true
                    scriptLocation: 'inlineScript'
                    scriptType: 'bash'
                    inlineScript: |
                      set -euo pipefail

                      helm version

                      echo "Login to AKS"
                      az aks get-credentials \
                        --resource-group ${AKS_RG} \
                        --name '${{ parameters.kubernetesCluster }}' \
                        --admin \
                        --overwrite-existing

                      echo "Sanity Check"
                      helm list -A

                      echo "Registry Login"
                      echo $servicePrincipalKey | \
                        helm registry login ${REGISTRY_SERVER} \
                          --username $servicePrincipalId \
                          --password-stdin

                      echo "Retrieve Artifact"
                      helm chart pull $(artifact)

                      echo "Unpack Artifact"
                      helm chart export "$(artifact)" --destination ./${CHART_PATH}

                      echo "Sanity Check"
                      helm show chart ./${CHART_PATH}/$(containerRepository)

                - task: HelmDeploy@0
                  displayName: 'Deploy Helm Chart'
                  inputs:
                    connectionType: 'Azure Resource Manager'
                    azureSubscription: 'Azure'
                    azureResourceGroup: $(AZURE_ENV_RG)
                    kubernetesCluster: '${{ parameters.kubernetesCluster }}'
                    useClusterAdmin: true
                    namespace: 'apps'
                    command: 'upgrade'
                    chartType: 'FilePath'
                    chartPath: './$(local_chart_path)/$(containerRepository)'
                    releaseName: '$(containerRepository)'
                    overrideValues: $(overrideValues)
```

The deployment template has the following steps:

-   Disable Checkout
-   Pin Helm Version
-   Prepare Deployment
-   Deploy Helm Chart

#### Disable Checkout

[pipeline-templates/helm-deployment.yml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/pipeline-templates/helm-deployment.yml#L28)
```yaml
- checkout: none
```                                                                                                                         
The deployment stage inputs are the build pipeline artifacts, not the
source code. The template disables checkout because it doesn’t need any
data from the git repository to do its job.

#### Pin Helm Version

The deployment stage pins the Helm version for the same reasons as the
packaging stage shown [above](#pin-helm-version).

#### Prepare Deployment

[pipeline-templates/helm-deployment.yml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/pipeline-templates/helm-deployment.yml#L35-L75)
```yaml
- task: AzureCLI@2
  displayName: 'Prepare Deployment'
  env:
    AKS_RG: $(AZURE_ENV_RG)
    REGISTRY_SERVER: $(LOGIN_SERVER)
    CHART_PATH: $(local_chart_path)
  inputs:
    addSpnToEnvironment: true
    azureSubscription: 'Azure'
    failOnStandardError: true
    scriptLocation: 'inlineScript'
    scriptType: 'bash'
    inlineScript: |
      set -euo pipefail

      helm version

      echo "Login to AKS"
      az aks get-credentials \
        --resource-group ${AKS_RG} \
        --name '${{ parameters.kubernetesCluster }}' \
        --admin \
        --overwrite-existing

      echo "Sanity Check"
      helm list -A

      echo "Registry Login"
      echo $servicePrincipalKey | \
        helm registry login ${REGISTRY_SERVER} \
          --username $servicePrincipalId \
          --password-stdin

      echo "Retrieve Artifact"
      helm chart pull $(artifact)

      echo "Unpack Artifact"
      helm chart export "$(artifact)" --destination ./${CHART_PATH}

      echo "Sanity Check"
      helm show chart ./${CHART_PATH}/$(containerRepository)
```

This step prepares the agent for deployment by fetching credentials for
the Kubernetes cluster, pulling the OCI artifact from ACR, and unpacking
it to a local directory.

> As OCI support in Helm matures, the steps for deploying an OCI
> artifact should become less involved.

#### Deploy Helm Chart

[pipeline-templates/helm-deployment.yml:](https://github.com/jamesrcounts/phippyandfriends/blob/2021.06/pipeline-templates/helm-deployment.yml#L77-L90)
```yaml
- task: HelmDeploy@0
  displayName: 'Deploy Helm Chart'
  inputs:
    connectionType: 'Azure Resource Manager'
    azureSubscription: 'Azure'
    azureResourceGroup: $(AZURE_ENV_RG)
    kubernetesCluster: '${{ parameters.kubernetesCluster }}'
    useClusterAdmin: true
    namespace: 'apps'
    command: 'upgrade'
    chartType: 'FilePath'
    chartPath: './$(local_chart_path)/$(containerRepository)'
    releaseName: '$(containerRepository)'
    overrideValues: $(overrideValues)
```

With the build agent configured with the prerequisites, this helm deploy
task releases the application to the AKS cluster. When AKS receives the
chart for deployment and schedules the parrot pods, the cluster node
will pull the appropriate container image from our ACR instance.

## CI/CD in Action

After completing the pipeline configurations, we can change the source
code to ensure they work as intended. Before making any changes, we can
see that the Helm package is at version 0.1.8, the container image is at
version 0.2.5, and the deployment number is at 0.2.14.

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/pipelines-starting-state.png alt: "Screenshot showing pipeline starting state." %}{:style="max-width:90%"}

### Change Deployment Configuration

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/pr-4.png alt: "Pull request 4 changes number of replicas." %}{:style="max-width:90%"}

This pull request changes the Helm chart by updating the default number
of parrot replicas in the deployment.

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/run-helm-pipeline.png alt: "Helm pipeline running." %}{:style="max-width:90%"}

When merged, the “parrot-helm” pipeline triggers detect the change and
queue a build. In contrast, the “parrot-docker” pipeline detects no
changes, and Azure DevOps does not schedule a build for the container
image.

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/run-deploy.png alt: "Deployment pipeline running." %}{:style="max-width:90%"}

The “parrot-helm” pipeline completes quickly and triggers the
“parrot-deploy” pipeline.

> We shortened the time until we can deploy the new deployment by
> skipping the application and container image build.

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/production-approval-wait.png alt: "Pipeline waits for approval before production." %}{:style="max-width:90%"}

The pipeline deploys the new configuration to the development cluster
immediately because we configured no approval checks on the development
environment. The pipeline waits to deploy to the production environment,
which has a manual approval requirement.

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/deployment-trigger.png alt: "Deployment triggered by Helm pipeline." %}{:style="max-width:90%"}

We can confirm that the Helm build pipeline triggered the deployment by
reviewing the summary information for the deployment.

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/approval-dialog.png alt: "Manual approval dialog." %}{:style="max-width:50%"}

An authorized user (in this case, me) can provide approval for the
production deployment using the Azure DevOps user interface.

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/post-deployment-state.png alt: "All pipelines completed." %}{:style="max-width:90%"}

After the deployment to production, we can review the pipelines and see
that Azure DevOps has completed all pipeline runs.

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/parrot-replicas.png alt: "Parrot replica change confirmed." %}{:style="max-width:90%"}

By reviewing the AKS workloads, I can confirm that the parrot deployment
now has two replicas.

### Change Application Code

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/pr-5.png alt: "PR to update parrot header text." %}{:style="max-width:90%"}

By submitting this pull request to make a trivial change to the
application code, we’ll see a similar process play out.

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/run-docker-pipeline.png alt: "Docker pipeline running." %}{:style="max-width:90%"}

The change to application code triggers the container image build, but
not the Helm package build.

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/deployment-trigger-2.png alt: "Deployment triggered by Docker pipeline." %}{:style="max-width:90%"}

On completion, the container image build triggers the deployment.

{:.img-wrapper}
{% responsive_image path: media/2021/07/11/post-deployment-state-2.png alt: "All pipelines completed." %}{:style="max-width:90%"}

After I approve the production deployment, we can see that all pipeline
runs have been completed.

## Review

This article shows how to develop a CI/CD flow that handles multiple
environments with differing approval requirements. By considering the
environments we needed to deploy to and the application to deploy, we
identified which build artifacts we required and created separate
pipelines to handle each artifact. Each pipeline trigger has appropriate
filters to ensure that artifacts only change when their source files
change. This pattern makes it easier to reason about each deployment's
changes because the CI/CD flow reuses unchanged artifacts. As a bonus,
reusing artifacts speeds up the time to deployment.

Azure DevOps Environments have gained some nice features since my last
review. Unfortunately, the feature set lags behind classic release
pipelines even after a couple of years of development. Given Microsoft’s
GitHub acquisition in June 2018, it is fair to speculate that attention
and focus have shifted to driving innovation in GitHub Actions instead.
Building the same CI/CD flow in GitHub actions would be an interesting
exercise for a future article!