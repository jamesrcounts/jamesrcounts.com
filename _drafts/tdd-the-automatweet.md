---
layout: post
tags:
    - serverless    
    - lambda
    - AWS
    - S3
    - dotnet
    - rekognition
title: Let's TDD the AutoMaTweet
---

Now I'd like to go through my solution to the March LambdaSharp challege.

Also a question came up a few times during group and discussion: How do I run my Lambda locally?  

The answer was, write a unit test.  Lets do that, I'll solve the challenge again, this time using TDD.

I'd also like to show VS2017 and the AWS toolkit for VS2017.

Stretch goal - CI

# Tools you need

* VS 2017
* AWS Toolkit for VS 2017
* Optional - Resharper

* Other requirements from the challenge

    * AWS account
    * Twitter account
    
    
# Create Project

I'll be starting this project from scratch but it will still be useful to refer to the challenge readme.

I'm doing this for 2 reasons.  First I want to use the templates, second I want to learn all the pieces, logger etc.


* Open VS 2017.

* File New Project

    * You Will see That AWS Lambda has some templates
    
    * Choose "AWS Lambda Project with Tests (.NET Core)"
        * Enter a name - I'll enter "TheAutoMaTweet"
        * Enter a location - I'll put my files at C:\git
        * Check the checkbox to create a git repository.
        * Click OK
        
        ![New Project](/media/2017/03/23/new-project.png)
        
    * Next you will see a blueprint section.  Interestingly these blueprints are not available online when you create a lambda in the AWS console.  I often pick "Empty Function" at this stage, but this time I'll pick "Simple S3 Function" because it looks appropriate for what the AutoMaTweet does.
    
        ![Select Blueprint](/media/2017/03/23/select-blueprint.png)
        
        * Click finish

    * The project template creates a lambda project for us and a test project.
    
        ![Generated Files](/media/2017/03/23/generated-files.png)
    
        * Note that in 2017 it still creates a project json.
        
        * Also note that it creates a proper csproj.  Maybe the project json is just there for compatiblity?  Should be interesting to see if it gets used for anything.
        
        ![Proper csproj](/media/2017/03/23/proper-csproj.png)
        
* First Test

    Since the template created a test lets look at it.
    
     * It is an xunit test
     
     * It has alot of razorburn
     
     
     
    
        
        
        
    