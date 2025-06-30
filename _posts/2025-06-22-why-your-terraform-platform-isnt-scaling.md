---
title: "Why Your Terraform Platform Isn't Scaling—and What to Do About It"
date: 2025-06-22
layout: post
tags: [terraform, infrastructure-as-code, terraform-cloud, azure, devops, platform-engineering, automation]
excerpt: >
  Your Terraform automation is great—until you need a new workspace, service principal, or landing zone. Then you're back to tickets and manual processes. Here's how to automate the back office that supports your infrastructure platform.
image: /media/2025/06/22/workspace-request-flow.png
author: James Counts
description: >
  Learn how to build a scalable Terraform platform that automates workspace creation, service principals, and landing zones. Stop relying on tickets and manual processes for infrastructure automation.
keywords: >
  terraform platform engineering, infrastructure automation, terraform cloud workspace management,
  azure devops automation, service principal automation, landing zone automation,
  infrastructure as code best practices, terraform scaling, platform engineering patterns
canonical_url: https://jamesrcounts.com/2025/06/22/why-your-terraform-platform-isnt-scaling.html
og_title: "Why Your Terraform Platform Isn't Scaling—and What to Do About It"
og_description: >
  Your Terraform automation is great—until you need a new workspace, service principal, or landing zone.
  Then you're back to tickets and manual processes. Here's how to automate the back office that supports your infrastructure platform.
og_image: /media/2025/06/22/workspace-request-flow.png
twitter_card: summary_large_image
twitter_title: "Why Your Terraform Platform Isn't Scaling"
twitter_description: >
  Learn how to build a scalable Terraform platform that automates workspace creation, service principals, and landing zones.
twitter_image: /media/2025/06/22/workspace-request-flow.png
---

Most Terraform blog posts start at the middle layer—deploying infrastructure like networks, services, or security policies. But that assumes something important: that your Terraform platform is already in place.

Before you deploy a single subnet or virtual machine, you need to establish the foundation that makes Terraform work at scale. That foundation is the root layer—and getting it right means the difference between a fragile pile of scripts and a scalable, governed infrastructure platform.

In this post, I'll share how I structure the root layer to support multi-environment, multi-team Terraform setups using Terraform Cloud and GitHub (or Azure DevOps). This isn't theory—it's what I've learned after multiple iterations across real-world orgs.

## Production Was Perfect. Everything Else Still Ran on Tickets.

{:.img-wrapper}
{% responsive_image path: media/2025/06/22/terraform-backend-frustration.png alt: "Frustrated developer on phone with hand on head, looking at a monitor listing manual setup tasks like Ticketing System, Service Principal, and Repo Access" %}

In many cloud environments, infrastructure as code has revolutionized how we deploy applications. Terraform, pipelines, and Git workflows let us spin up production-ready systems with confidence and speed.
But there's a catch: the automation itself often runs on an *unautomated* foundation.

While application environments are managed as code, the back office—the systems that support your infrastructure—remains a patchwork of manual processes, ticket queues, and tribal knowledge. Think service principals, repo permissions, pipeline bootstrapping, secrets rotation.

This is a problem I first ran into at a financial services company during one of my earliest large-scale Terraform automation projects. On the surface, we had it figured out. Our Terraform setup was clean. New Azure resources—VMs, subnets, storage—could be provisioned by anyone on the team, no tickets, no waiting. Just a PR, a plan, and a merge. It felt like DevOps was finally working.

But that illusion cracked the moment we needed to touch the platform *behind* the automation.

If I needed a new service principal in Entra ID, I had to open a ServiceNow ticket.
If I needed access to a Git repo or a shared pipeline library in Azure DevOps, I needed to hunt down the Project Collection Administrator.
If we wanted a new workspace in Terraform Cloud, forget it—we were back to tribal knowledge and manual steps.

The production environment was a modern, automated marvel.
The platform that powered it? A legacy ops bottleneck with no change control and no repeatability.

It was frustrating, but more than that—it was dissonant.

> I could build secure, repeatable landing zones with Terraform, but I couldn't automate the identity, pipelines, or secrets that made those zones possible in the first place.

That was the real pain: **living in two different worlds**. One where DevOps worked. One where it didn't.

Eventually, I realized: the automation platform *is part of the platform*. And if it's not managed like code, the rest of your automation is standing on sand.

## Automating the Automation Platform

Imagine spinning up a brand-new cloud **environment**—a subscription or resource group and a workspace—complete with its own identity, secrets, and pipelines, all wired into your CI/CD platform. No tickets. No Byzantine approvals. No tribal knowledge.

{:.img-wrapper}
{% responsive_image path: media/2025/06/22/bootstrap-before-after.png alt: "Side-by-side comic showing manual IAM provisioning on the left and automated Terraform-based setup on the right, highlighting the shift from tickets to code" %}


In this model, you're not just deploying *services* with Terraform. You're defining the environment **in which those services will live**.

* A scoped Entra ID service principal with the right roles? Code.
* A private Git repo with permissions set and a pipeline ready to go? Code.
* A secure secret store wired into your deployment workflow? Code.
* A Terraform Cloud workspace with tagging, policies, and access controls? All in code.

The environment scaffolding itself becomes reproducible: not just VMs and networks, but the **platform plumbing**—identity, access, and automation.

Even the back-office systems—Terraform Cloud, Azure DevOps, Entra ID—are treated as first-class infrastructure, managed and governed through code just like the application stack.

It's faster. Safer. Repeatable. And crucially, it scales without central bottlenecks.

This is the kind of foundation I started calling the **root layer**: a baseline of automation that treats *the environment* as infrastructure, and manages the platform itself as code.

## Scalable Platform Automation, by Design

The root layer isn't a single Terraform module — it's a layered architecture that automates the scaffolding of your platform and its delivery environments. Each layer plays a different role, with a different cadence of change:

{:.img-wrapper}
{% responsive_image path: media/2025/06/22/terraform-root-architecture.png alt: "Diagram showing three-layer Terraform workspace design: Root Workspace manages the Terraform Cloud org, Workspaces Workspace provisions environments, and Shared Modules Workspace provides reusable building blocks." %}


### 🧱 Root Workspace

The foundation. This is applied once (or very rarely) and manages your **Terraform Cloud organization** at the highest level. It establishes global constructs, such as teams, policies, and projects. Most importantly, it enables the automation of Terraform Cloud itself, allowing workspaces, modules, and environments to be managed *as code*.

### 🧭 Workspaces Workspace

This layer runs **each time a new environment or project-level landing zone is needed**. It creates:

* Workspaces (including its own and the root workspace)
* Azure credentials with the proper scope and RBAC roles
* Variable sets and their associations with workspaces
* Optionally, Git repositories (when a new repo is needed)

This workspace is revisited as projects grow, new zones are required, or shared pipelines need to be extended. It's the engine behind scaling your platform one secure, self-contained environment at a time.

### 🧩 Shared Modules Workspace

This workspace provides reusable infrastructure building blocks, such as an App Service module or a shared Virtual Network (VNet) template. Each shared module gets:

* Its own Git repository (always 1:1)
* A Terraform Cloud registry entry
* Automated registration and webhook setup so updates flow directly from Git

This workspace runs **whenever a new shared capability is developed**, helping teams reuse best-practice infrastructure without duplicating code.

---

Together, these workspaces provide a platform that can be deployed securely, consistently, and without ticket-driven friction. You don't just automate environments. You automate the ability to create and evolve environments as your organization grows.

## Getting Started: Bootstrapping the Root Workspace

If you're ready to adopt this layered platform model, the first step is to bootstrap the **root workspace**—the foundation that allows Terraform Cloud to be managed as code.

Terraform Cloud can't manage itself until something external creates the organization and initial workspace, so we begin with a short-lived, locally executed Terraform configuration.

### Bootstrapping Steps

1. **Author the organization configuration** in a local Terraform workspace on your laptop.
2. **Apply that configuration locally** to create the Terraform Cloud organization.
3. **Configure the VCS connection**:

   * For **GitHub**, this can be done via Terraform.
   * For **Azure DevOps**, you must manually create the OAuth client in the UI. This is a required ClickOps step.
4. **In a separate module/folder**, author the code for managing workspaces. This code will:

   * Create the **root workspace** in Terraform Cloud.
   * Create the governance Git repository.
   * Reference the OAuth client as a data resource (manual or automated).
5. **Push the code** to the governance repository in your Git provider.
6. **Update the backend block** in your Terraform config to use the cloud backend tied to the root workspace.
7. **Reinitialize the root workspace**, uploading the local state to Terraform Cloud.

At this point, your root workspace is fully operational, managing the Terraform Cloud organization itself, backed by version-controlled code.

But that's just the beginning. Next, you'll bootstrap the **workspaces workspace**, which provisions delivery environments and wires them into your platform.

## Bootstrapping the Workspaces Workspace

Once the root workspace is online, the next step is to bootstrap the **workspaces workspace**—the Terraform workspace responsible for provisioning landing zones and wiring up delivery environments.

The process mirrors the root workspace bootstrap, but with more complexity. While the root workspace only interacts with Terraform Cloud, the workspaces workspace must also communicate with Azure, Entra ID, and your version control system. That means **all required credentials must be in place before Terraform can even generate a plan.**

{:.img-wrapper}
{% responsive_image path: media/2025/06/22/terraform-bootstrap-permissions-kit.png alt: "Cartoon-style illustration of an IT admin packing a 'Terraform Bootstrap Kit' backpack with credentials like Azure roles, Entra permissions, Terraform Cloud token, and Azure DevOps personal access token" %}

### Required Credentials

To bootstrap the workspaces workspace, you'll need:

* **Terraform Cloud token** (as used by the root workspace)
* **VCS token** (GitHub or Azure DevOps)
* **A privileged Azure service principal**, with:

  * **Azure Permissions:**

    * `Reader` on the subscription (so Terraform can inspect it)
    * `User Access Administrator` (To assign roles to child service principals)
  * **Entra ID Permissions:**

    * `Cloud Application Administrator` (to create service principals)
    * `Privileged Role Administrator` (Only if you plan to assign Entra ID roles to child principals)

This service principal is essential. The workspaces workspace uses it to create additional service principals for each landing zone, so it must have broad authority across Azure and Entra.

> Note: During bootstrap, Terraform authenticates as the user running the code. This user must be highly privileged in the tenant. Use `az login` beforehand to provide the required Azure and Entra tokens locally.

### Bootstrapping Steps

1. **Author the workspaces workspace configuration** locally.

   * Ensure all external credentials are passed in via workspace variables (Terraform Cloud, GitHub/Azure DevOps).
   * Configure this workspace to create its own Azure service principal as described above.
   * **Create variable sets** in Terraform Cloud containing the Azure and VCS credentials. (You should already have a set for Terraform Cloud from the root workspace setup.)

2. **Run the workspace locally**, just as you did the root workspace.

   * This creates the workspaces workspace in Terraform Cloud.
   * You may reuse the same Git repository (I typically organize root-layer workspaces into separate folders in one repo).

3. **Push the code to Git**.

4. **Update the backend block** to point to Terraform Cloud.

5. **Reinitialize the workspace**, pushing its state to Terraform Cloud.

Once bootstrapped, the workspaces workspace can fully automate environment creation: spinning up project-specific service principals, assigning roles, creating Git repos, configuring pipelines, and wiring everything into Terraform Cloud workspaces.

## Creating the Shared Modules Workspace

The final component of the root layer is the **shared modules workspace**. Unlike the root and workspaces workspaces, this one doesn't require special bootstrapping—it can be defined and provisioned directly by the **workspaces workspace**, just like any other environment-specific workspace.

Because its role is to publish reusable infrastructure modules, it only needs credentials for two systems:

* **Terraform Cloud** — already handled by the root workspace
* **Version Control System** (GitHub or Azure DevOps) — already configured for the workspaces workspace

### Provisioning Steps

Once the necessary credentials are in place, you can define the shared modules workspace inside the workspaces workspace codebase:

1. **Add a new workspace definition** for the shared modules workspace in the workspaces workspace.
2. **Apply the workspaces workspace** to create the new workspace in Terraform Cloud and associate it with a Git repository.
3. **Author module management code** in that Git repo to:

   * Create a new repository for each shared module.
   * Register each module in the Terraform Cloud private registry.
   * Set up webhooks so the registry tracks changes to the module codebase.
4. **Push the module management code to Git** and let Terraform Cloud do the rest.

This workspace now serves as your publishing engine for infrastructure building blocks—like App Service templates, shared VNets, or other reusable constructs—ensuring they're delivered and tracked with the same rigor as any other environment.

---

At this point, your root layer is complete:

* The **root workspace** manages Terraform Cloud itself.
* The **workspaces workspace** provisions environments and organizational scaffolding.
* The **shared modules workspace**, delivers reusable infrastructure components.

With this structure in place, you're ready to use the workspaces workspace to provision real, production-ready landing zones—securely, consistently, and with zero ticket friction.

## Proven in the Field

This approach isn't just theory. I've implemented variations of this root layer architecture across demos, internal tools, and production environments for real-world organizations—including teams in **financial services**, **non-profits**, the **health sector**, **energy**, and **startups**.

In each case, separating concerns across the root, workspaces, and shared modules workspaces gave teams the confidence to move faster—with less friction, stronger governance, and fewer surprise dependencies.

I've watched this pattern scale from small pilots to enterprise-wide platforms. It enables autonomy without chaos, governance without gridlock.

And most importantly, it helps teams **ship infrastructure like software**, without getting stuck in ticket queues.

## What You Might Be Thinking

### Why not just use one workspace?

You might wonder why we use **three separate workspaces** instead of a single, monolithic Terraform configuration to manage everything. The answer comes down to **scope, security, and lifecycle**.

Each workspace in the root layer has a different purpose, cadence, and trust boundary:

* The **root workspace** manages your Terraform Cloud organization itself. It changes rarely and requires elevated permissions, but only for Terraform Cloud.
* The **workspaces workspace** is your platform automation engine. It provisions project-level environments and needs broad access to Azure, Entra ID, and your VCS. It changes more frequently as new teams and environments are added.
* The **shared modules workspace** manages reusable building blocks. It operates independently from environment provisioning and evolves on its own timeline as new modules are developed.

Keeping these concerns separate makes it easier to:

* Apply the principle of least privilege to each workspace
* Delegate ownership without compromising the whole platform
* Test and evolve parts of your automation independently

It also improves performance and manageability over time. As your environment grows, so does the Terraform state. Separating workspaces means smaller, more focused state files—which translates into faster refresh times and easier troubleshooting as the platform scales.

A monolithic configuration might work for a single team or proof of concept, but it doesn't hold up in a real-world platform engineering scenario. **Separation is what keeps the root layer resilient and scalable.**

### Isn't this overkill for a small team?

Yes—if you're just experimenting with Terraform or spinning up a dev sandbox, this model might feel heavy. But it isn't meant for one-off environments. This is for teams building a **reusable, secure platform** that others will consume.

Even smaller orgs benefit from separating the concerns of identity, pipelines, secrets, and infrastructure. You don't need a massive team to justify this setup—you just need a need for repeatability.

I've seen this approach succeed with three-person SRE teams and ten-person app teams. It's about **how many environments you expect to create**, and **how often you want to do it without friction**.

### Isn't it risky to let Terraform manage service principals?

It's natural to be cautious about automating privileged operations. But the alternative is worse: having those actions done manually, out of band, with inconsistent controls and zero audit trail.

The access still needs to exist—whether provisioned by Terraform or by a sysadmin clicking around the portal. With Terraform, you get a repeatable, reviewable process and a complete change history. You can also automate revocation and cleanup when environments are decommissioned.

If security and compliance are concerns (and they should be), infrastructure as code gives you the best shot at managing them responsibly.

### Isn't this tied too tightly to Terraform Cloud?

It's true that I use Terraform Cloud for most implementations—it's easy to get started and removes a lot of the heavy lifting.

But this architecture doesn't require it. I've implemented similar root-layer setups using Azure DevOps as the CI/CD backbone, with pipelines responsible for managing Terraform backends and executing plans.

It's more effort to set up the equivalent of TFC's remote execution model yourself, but it can be done. The patterns still apply. In fact, they're even more important when you're building the plumbing by hand.

### Doesn't this just recreate the same internal platform that already frustrated us?

It might look that way on the surface—but this time, it's different.

This root layer isn't hidden behind tickets or maintained by a shadow platform team. It's written in code. It lives in Git. It evolves with your organization.

And most importantly: **you can fork it.** If a team needs to move faster, or create a slightly different delivery model, they're not stuck. They're empowered.

This isn't about central control—it's about shared autonomy, delivered through code.

## Ready When You Are

{:.img-wrapper}
{% responsive_image path: media/2025/06/22/workspace-request-flow.png alt: "Illustration of a developer requesting a new environment. Terraform Workspaces Workspace provisions resources and scaffolding in Azure and GitHub." %}


If you've made it this far, you're probably already thinking about how to bring something like this to your own organization. That's great. Start with the root workspace. Take your time. Keep the pieces small and focused.

And if you want to compare notes—or would like help getting your root layer off the ground—I'd be happy to connect. You can find me on [LinkedIn](https://www.linkedin.com/in/jamesrcounts/) or reach out through my site.

Infrastructure gets better when we treat it like software. Platforms do too.
