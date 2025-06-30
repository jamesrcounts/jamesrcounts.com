---
layout: post
title: Getting started with serverless
description: "A comprehensive guide to serverless computing for developers. Learn how to set up tools, cloud services, and deployment pipelines for your first serverless project."
keywords: "serverless computing, cloud services, deployment pipeline, ruby, jekyll, homebrew, AWS Lambda, serverless architecture, cloud development"
author: "James Counts"
date: 2017-03-16
last_modified_at: 2017-03-16
categories:
  - serverless
  - cloud-computing
  - development
tags:
    - ruby
    - homebrew
    - jekyll
    - serverless
    - guides
    - aws
    - cloud
    - deployment
    - infrastructure
excerpt: "Learn the fundamentals of serverless computing through a practical example of setting up a blog with cloud services and automated deployment pipelines."
canonical_url: "https://jamesrcounts.com/2017/03/16/getting-started-with-serverless.html"
---
I'm really excited about serverless computing.  The major cloud vendors are expanding their serverless offerings every day.  I've spent quite a bit of time experimenting with these technologies and implementing them for customers.  But some of the most interesting work I've been doing I haven't been able to share.  So I decided to start this blog, and come up with some original examples so that I can share what I've learned, find out what people think, and get feedback on how it could be better.

I have another blog, but that one doesn't have much focus, so I decided to start fresh here.  Time permitting I'll import those older posts onto this site.  For now, I wanted to focus on creating a "hello world" for serverless.  There are many options, and I decided it would be appropriate to chronicle the process of setting up this blog as my first post on serverless.  It may not be the simplest example, but I think it does hit a few of the basics like:

   * Figuring out what tools you need on your machine.
   * Finding and signing up for cloud services
   * Setting up a deployment pipeline

So while there is not a lot of computing going on, there is a bit of infrastructure, and for me, getting through this process will give me a shiny new blog that I can fill up with all the things I'd like to share (believe me I've got a big Trello board full of post ideas).

Originally this post started as one document, but it became long enough to justify breaking up into 3 parts:

   * [Getting the tools you need](/guides/hello-world/getting-tools/)

   * [Bootstrapping this blog](/guides/hello-world/bootstrapping-this-blog-with-jekyll/)

   * [Publishing to S3](/guides/hello-world/publish-jekyll-site-to-s3-with-circleci/)