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
    
        * Note that in 2017 it still creates a project json in the test project.  Well, it's still in preview.  There is no project json in the produciton project.
        
        * Also note that it creates a proper csproj.  Maybe the project json is just there for compatiblity?  Should be interesting to see if it gets used for anything.
        
        ![Proper csproj](/media/2017/03/23/proper-csproj.png)
        
* First Test

    Since the template created a test lets look at it.
    
     * It is an xunit test
     
     * It has alot of razorburn
     
        ![Razor Burn](/media/2017/03/23/razor-burn.png)

     * It is more complex than i expected, but then again this is the first time i used a blueprint.
     
     * It appears to actualy want to use the s3Client to interact with S3.  
     
     * Lets see if we can deal with the razor burn by building.  Then we can examine what this complex test is trying to do.  If it passes we can refactor it.
    
    * Build succeeds yet razor burn persists.
    
    * rebuild still works razor burn persists.
    
    * Lets see if there is a new version of the toolkit. Nope.
    
    * Notice that there is no project.json in produciton project, and there is no razorburn/reference errors.  
    
        ![Bad Project Json](/media/2017/03/23/bad-project-json.png)

    * Lets get rid of project json.
    
        * Close the visual studio solution.
        
        * Delete `TheAutoaMaTweet.Tests\project.json`
        
        * Open solution.
        
        * Razor burn is gone.
        
        ![Burn Free](/media/2017/03/23/burn-free.png)

    * Build
    * Commit
    
    Now we can get serious about understanding this genereated test.
    
# The Test Cleanup

First lets run [CodeMaid](http://www.codemaid.net/) to cleanup the file. 

Aside - CodeMaid is a little tool i like for cleaning up and reorganizing code.  The main thing I like is that you can configure it to run cleanup on file save.  The types of cleanup it does incldues removing unused namespace imports and removing excessive blank lines and whitespace.

The First thing I notice is that the test is rather long.  Lets try and figure out the AAA parts of it.

## Arrange

The test constructs an S3 Client in the USWest2 region.  Although I'm using the same region, this appears to just be a default in the template, since I never specified that during project setup.

The test creates a new bucket in this region.

Next put a simple text file in the bucket.

Manually construct an S3 event that refers to the newly created item in the bucket.  This means the unit test does not rely on configuring the actual S3 notifications we use in production.  Nor does it create test files in our production bucket.  The event notification is simulated.  This is probably the most important part.  However, relying on an actual file in the bucket prevents this from being a pure unit test, assuming that item is used in any way.

Next we construct the C# object which hosts the lambda entry point.  When constructing here, we pass in the s3Client we created at the top of the test.

## Act

To act, we invoke the "FunctionHandler" method on the "Function" class.  These default names are terrible, we'll change them soon.  We pass in the S3event which we created in the arrange section, the S3 event that describes the test file we put into the test bucket.

Looks like this example function returns a result, which is stored in the test as a variable called "contentType"

## Assert

In the assertion section, we assert that the contentType returned by the function invocation is "text/plan".  This makes sense because that is what we put into the bucket moments ago.


## Cleanup

There is a `finally` block which removes the test bucket.

TODO: Make a note about authentication, Lambda uses roles, test uses default credentials from the user profile.
        
        
        
    