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

Aside - CodeMaid is a little tool i like for cleaning up and reorganizing code.  The main thing I like is that you can configure it to run cleanup on file save.  The types of cleanup it does includes removing unused namespace imports and removing excessive blank lines and whitespace.

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
        
## Running the test

Note: Required Resharper 2017.1 (currently in EAP)
        
The test runs and passes as written.  But it still looks like an integration test because its interacting with S3.  This doesn't make it a bad test, but I'd like to look at the generated function to see why it was necessary to put a file in S3 for this test to work.


# Implementation code

* First cleanup with codemaid
* run tests - still works
* We have two constructers
    * One constructs a S3client locally.
    * One takes s3client as a parameter
    * We use the parameterized one in the test.  This allows us to control how we pass in credentials, region, etc in the client.
    * In production, the lambda will get its credentials from its role.
    * Even in test we are using default credentials from `.aws/credentials`.
    * But having the client in the constructor fits a performance optimization pattern I heard about on the AWS podcast.  In the podcast they recommended that service clients (like S3 client) are constructed outside the handler function.  This is because AWS will reuse the lambda for multiple invocations if possible, and by constructing the client outside the handler, you can save time on subsequent invocations.  It probably won't make or break any speed records to do this, but its an easy enough optimization.
* Commit this code.
* Slight refactoring: Chain Constructors; Rerun tests
* Important! The test constructor takes an interface
* Readonly property for the S3Client - Also `IS3Client`
* Handler
    * Uses null-safe access to retrieve the first S3 Record in the event.
    * Exit if null
    * Use the client to retrieve object metadata from S3 -- this is mockable.
    * Return the content type header from the metadata
    
    * Take note of the error handler in the `catch` block.  Here, errors are logged to CloudWatch.  There are several ways to log to CloudWatch, `Console.WriteLine` works fine, but in the hackathon we used `LambdaLogger`.  Here we see a third method: `context.Logger`.  Context is passed in as an argument to the handler function.
    
    Ok so now we know how the initial test/implementation works and that we can safely mock the interaction with S3.  Lets do a couple simple refactorings.
    
 # Initial Refactorings
 
 ## Rename Handler Method
 
 I just hate the name `FunctionHandler`.  Ideally we give the method a descriptive verb name.  Lets do `TweetImageWithDescription`.
 
 I'll also delete the XML doc comment.
 
 I Run the unit test and it still works because the automated refactoring updated the test.  Note that there is an important config file `aws-lambda-tools-defaults.json` and that the automated refactoring did not update this file.
 
 This line tells lambda where to find the entrypoint in the C# code we submit. 
  
  ```json
  
  "function-handler": "TheAutoMaTweet::TheAutoMaTweet.Function::FunctionHandler"
  ```
 We need to update it so that it reflects the new name.
 
 ```json
 
  "function-handler": "TheAutoMaTweet::TheAutoMaTweet.Function::TweetImageWithDescription"
  ```
# Rename class

Having a class named `Function` is also too weird for me. I'll call it `TweetBot`.

Save and run tests, they still pass.  Next update `function-handler` again.

 ```json
 
  "function-handler": "TheAutoMaTweet::TheAutoMaTweet.TweetBot::TweetImageWithDescription"
  ```
  
# Clean up comments

I'll get rid of the remaning XML comments.

So my current baseline looks like this 

```csharp
using System;
using System.Threading.Tasks;
using Amazon.Lambda.Core;
using Amazon.Lambda.S3Events;
using Amazon.Lambda.Serialization.Json;
using Amazon.S3;

[assembly: LambdaSerializer(typeof(JsonSerializer))]

namespace TheAutoMaTweet
{
    public class TweetBot
    {
        public TweetBot() : this(new AmazonS3Client())
        {
        }

        public TweetBot(IAmazonS3 s3Client)
        {
            S3Client = s3Client;
        }

        private IAmazonS3 S3Client { get; }

        public async Task<string> TweetImageWithDescription(S3Event evnt, ILambdaContext context)
        {
            var s3Event = evnt.Records?[0].S3;
            if (s3Event == null)
                return null;

            try
            {
                var response = await S3Client.GetObjectMetadataAsync(s3Event.Bucket.Name, s3Event.Object.Key);
                return response.Headers.ContentType;
            }
            catch (Exception e)
            {
                context.Logger.LogLine(
                    $"Error getting object {s3Event.Object.Key} from bucket {s3Event.Bucket.Name}. Make sure they exist and your bucket is in the same region as this function.");
                context.Logger.LogLine(e.Message);
                context.Logger.LogLine(e.StackTrace);
                throw;
            }
        }
    }
}
```
# The challenge

## Level 1: Trigger Lambda function from S3

Now that we are up and running with a basic project.  Lets conquer level 1.  

Level 1 is basically about setting up your infrastructure.  You ned an IAM role, and a bucket. 

Of course you will need a lambda too, but the AWS toolkit will handle that for us when we deploy from visual studio.

You need to create the pieces in order.  First, you create the IAM role, because you need to specify the role when deploying the lambda.

Next you need to deploy the lambda, because you need to specify the lambda when you setup an event notificaion in S3.

Finally you create the S3 bucket and setup event notifications to the lambda.

### Create IAM role

There are several ways to do this.  During the hackathon I used the AWS console, and one of my teammates used HashiCorp's terraform and CloudFormation.

Here I'll use the AWS CLI.  Mostly because I think it will be the most succinct way to provide you with instructions (I can avoid telling you where to click and what info to enter into forms).

I really like Terraform too, but I want to stay focused on the hackathon challenges for now.
   
*Requires*: AWS CLI

So here is our process to create a new IAM Role and associate a policy.

1. Create an assume role policy document.  This is a JSON file which contains a "trust policy"  The trust policy belongs to the *role* and describes what *entities* this role will trust.  Lets break that down.

    * For our purposes the entity is going to be the AWS Lambda service.
    * When a role has a trust relationship with Lambda, it means that AWS will allow lambda to use this role.
    * A role is a bit like a user, but for services.  It has this trust relationship defined, and will also have policies attached to it.  
    * When Lambda uses (aka assumes) this role, it will be able to perform actions as described by the the attached policies.
    * So the trust policy is what AWS uses to ensure that "not just anybody" can assume the role and use the permissions granted by the attached policy.
 
    Run these commands in `powershell`.
    
    Tip, you can get this file from the challenge github repo [here](https://raw.githubusercontent.com/jamesrcounts/March2017-ImageTweeterChallenge/master/aws/policies/lambda_role_trust_relationship.json).
    
    1. Create a file called trust-policy.json
        
        ```powershell
        notepad trust-policy.json
        ```
       When prompted, click "Yes" to create a new file. 
       
    2. Paste these contents into the file and save:
    
        ```json
        {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Sid": "",
              "Effect": "Allow",
              "Principal": {
                "Service": "lambda.amazonaws.com"
              },
              "Action": "sts:AssumeRole"
            }
          ]
        }
        ```
    3. Close notepad and run this command:
    
        Note: the role name is not important as long as you are consistent when you deploy the lambda.  Also, the debug parameter is optional but it can give you a great idea about what's happening under the hood.  Basically there is no magic, the AWS CLI just creates a signed REST request and uses HTTPS to send the request to AWS.
        
        ```powershell
        aws iam create-role --role-name automatweet_lambda_role --assume-role-policy-document file://.
        /trust-policy.json --debug
        ```
    
    1. Next, we need to associate a policy with our role.
    
        ```powershell
        aws iam attach-role-policy --role-name automatweet_lambda_role --policy-arn arn:aws:iam::aws:policy/CloudWatchLogsFullAccess
        ```
    
# Now we can deploy our lambda from visual studio

I'll just deploy the example lambda first.  In the Visual Studio Solution Explorer, right click on the Lambda project.

1. Click "Publish Lambda"

![Deploy Lambda](/media/2017/03/23/deploy-lambda.png)

1. The AWS Toolkit will launch a wizard.   Start by clicking the little "Account Profile" dude.

![Account Profile](/media/2017/03/23/account-profile.png)

1. Fill out this form completely.  Even though it says the Account Number is optional, you will need it in order to make the rest of the wizard work the way it should.        

If you don't know your account number try running this command in powershell.

```powershell
aws sts get-caller-identity --output text --query 'Account'
```

Click ok when finished.

![Profile Settings](/media/2017/03/23/profile-settings.png)

1. Next choose your region, I will leave mine in Oregon, but you can pick a region near you where both Lambda and Rekognition are supported.

1. Next give the function a name.  I'll call mine `automatweeter`

1. The wizard prefills the rest of the information this page with info from the `aws-lambda-tools-defaults.json` file that we edited earlier.  Check the check box to "Save settings for future deployments" then click next.

 ![Function Details](/media/2017/03/23/function-details.png)

1. On the advanced function details page you should be able to use the dropdown menu to pick the role we created earlier.  You could also create a new role here too.  In the past this dropdown has not always worked unless you entered your Account Number in the credentials profile.  Since we did that, it should work for you.

1. Leave the memory and execution time at the default values for now.  We can revisit them once our application is complete and we have a realistic idea for the resources it consumes.

1. We do not need to access any VPC resources, so leave these values at default.  

1. For the moment we don't need any environment variables.  Although when we get to the stage of actually tweeting from our lambda, environment variables will be a good place to pass secrets to our function.

1. Click Upload.

![Advanced Function Details](/media/2017/03/23/function-details-advanced.png)

# Now create the s3 bucket

1. The name must be unique so you should substitute a suffix like your name for example.  The unit test generated by the AWS toolkit uses a datestamp to ensure uniqueness.  That is fine too.  You can use the console or run an aws cli command like the one below:

    ```powershell
    aws s3api create-bucket --bucket $MY_BUCKET --region $MY_REGION --create-bucket-configuration LocationConstraint=$MY_REGION
    ```
    Example
    
    ```powershell
    aws s3api create-bucket --bucket automatweeter-jcounts --region us-west-2 --create-bucket-configuration LocationConstraint=us-west-2
    ```

1. Before we can wire the lambda to the s3 event we need to set permissions that allow s3 to invoke the lambda on our behalf. This happens behind the scenes if you setup the event in the S3 console, but we have to do this manually when using the AWS CLI.

Create a file called s3-lambda-permission.json and paste the following block into it.

```json
{
    "FunctionName": "automatweeter", 
    "StatementId": "s3-automatweeter-invoke", 
    "Action": "lambda:InvokeFunction", 
    "Principal": "s3.amazonaws.com", 
    "SourceArn": "arn:aws:s3:::${YOUR_BUCKET_NAME}", 
    "SourceAccount": "${YOUR_ACCOUNT_ID}"
}
```

Be sure to update your bucket name and account id.  

Now you can execute the following to add permissions.

```powershell
aws lambda add-permission --cli-input-json file://./s3-lambda-permission.json
```
1. Create a file called `notification.json` and put these contents in there:

```json
{
    "LambdaFunctionConfigurations": [
      {
        "Id": "image-added-event",
        "LambdaFunctionArn": "${YOUR_LAMBDA_ARN}",
        "Events": [
          "s3:ObjectCreated:*"
        ]
      }
    ]
  }
```

You will need to substitute in the correct value for `Bucket` and `LambdaFunctionArn`.    You can get the `LambdaFunctionArn` value by running this aws cli command.

```powershell
aws lambda get-function --function-name automatweeter --output text --query 'Configuration.FunctionArn'
```

Next, create the notification configuration on the bucket.

```powershell
aws s3api put-bucket-notification-configuration --bucket automatweeter-jcounts --notification-configuration file://./notification.json --region us-west-2
```

Now we should be all set to pass level 1 of the challenge.  We need to verify that the event notificaiton is wired correctly by adding an image to our s3 bucket and using cloudwatch to verify that the lambda fired.

Lets do it.

Navigate to your s3 bucket and drop an image file into it.

![Drag Image](/media/2017/03/23/drag-image.png)

Click "Upload" in the dialog that appears.

Now, navigate to your lambda function, then click the monitoring tab:

![Monitoring Tab](/media/2017/03/23/monitoring-tab.png)

Click the "View logs in CloudWatch" link.  This will take you to the CloudWatch log group for your lambda function.  Click the most recent stream from the list.

![Log Group](/media/2017/03/23/log-group.png)

Oh Noes!  We haz errors!

![I Can Haz Permission Errors](/media/2017/03/23/i-can-haz-errors.png)

Although S3 has permission to invoke the lambda, the Lambda still executes in it's assigned role, and that role does not provide permission to access in S3.

Normally at this stage of the challenge, we would not be reading from S3, only examining the S3Event.  However, the code blueprint provided by the AWS Toolkit includes an example of reading an S3Object, so we got to this permission problem a little sooner.

Lets stick to the challenge goals, and just comment out the problem code for now.

# Update lambda



