---
layout: post
title: "Testing and Debugging AWS Lambda Functions: A Complete Guide for Developers"
description: "Learn how to effectively test and debug AWS Lambda functions using unit tests, integration tests, and proper logging strategies. Includes C# examples and best practices for serverless development."
canonical_url: "https://jamesrcounts.com/2017/05/13/on-testing-and-debugging-lambdas.html"
author: "James Counts"
date: 2017-05-13
categories:
  - AWS
  - Serverless
  - Development
tags:
  - AWS Lambda
  - serverless
  - testing
  - unit testing
  - integration testing
  - debugging
  - C#
  - .NET
  - AWS SDK
  - CloudWatch
  - dependency injection
  - mocking
  - Moq
  - S3
  - Kinesis
  - API Gateway
  - production debugging
  - logging
  - IAM
  - credentials
url: /testing-debugging-aws-lambda-functions-guide
---

<style type="text/css">
a + em {
    display: block;
    text-align: center;
    font-size: small;
    }
</style>

When I am talking to friends and customers about actually using Lambdas to get real work done, we eventually start talking about testing.  Many developers, myself included, spent the better part of our careers getting good at testing in all its various forms (unit, integration, etc).  In fact, some of us have spent a good chunk of time online and in user groups and at work trying to convince others that they needed to get good at testing too because it is such an important part of ensuring quality and maintainability.  After all this, serverless comes along, so shiny and new, and we're supposed to forget everything we know about testing and abandon the practice?

Well... no.

I'll admit to being a little baffled at first when the conversation around Lambda turns in this direction.  Then I thought back to my first couple Lambdas and realized that I had the same questions.  It's not like anyone is out there saying "it's not possible to test Lambdas", but I think that people are uncertain how to do it, and this leads to doubts about how to test, and the fear that it isn't possible to test.  For myself, after implementing a couple Lambdas in node, python, and dotnet, I got comfortable with what a Lambda was, and realized that really there should be nothing stopping me from using the same testing tools I've been getting good at all these years.

I think the key misunderstanding when it comes to Lambda and unit testing is the idea that you can only run a Lambda in the cloud.  After all, how can you unit test something that only AWS can execute?  That assumption is wrong.  You can run a Lambda on any computer.  Once you get comfortable with that idea, then it follows that you can run it on *your* computer, and then use all the testing tools and tricks you are used to using.

## What is a Lambda?

{:style="text-align: center;"}
[![Valims Lambda by Tumas Puikkonen](/media/2017/05/13/valmis-lambda-tumas-puikkonen.jpg)](https://flic.kr/p/5SyKow){:target="_blank"}
*Valims Lambda by Tumas Puikkonen (CC BY 2.0)*

A Lambda is a program, just like any other.  Let's check the anatomy of a basic C# Lambda.  This one happens to respond to Kinesis events:

```csharp
public class Function
{
    public void FunctionHandler(
        KinesisEvent kinesisEvent,
        ILambdaContext context)
    {
        // ... omitted ...
    }
}
```

* This is an ordinary public class with no base class and a default constructor.
* This class has an ordinary public method on it.

The handler method takes two parameters: event data and a context.  Both of these parameters are dependencies you take from Amazon.  Dependencies by themselves are not sufficient to prevent testing.  Even bad, difficult to work with dependencies (I'm looking at you `SqlException`) are not sufficient to prevent testing because we can usually find a way to work around them.  So, what kind of dependencies are these: difficult or easy?

The answer is "easy dependencies".  The event data types are well defined in the AWS SDK, they have public constructors and read-write properties.  This means that your unit test can instantiate instances of `KinesisEvent` (or whatever `*Event` you are using), configure the event in whatever way is necessary to exercise your code.

The second parameter is the `ILambdaContext`.  This context contains metadata about the Lambda execution environment.  There are a few interesting things about this context.  First, it's totally optional.  We could just remove the parameter if we don't need to know anything about the execution context.  Second, `ILambdaContext` is an interface. If we do need the context (often because we want access to `ILambdaContext.Logger`) then we can create a test double with any mocking framework, or even by hand.  Third, we don't even need to fool around with mocking frameworks to get our hands on an `ILambdaContext` instance--Amazon already provides a test double for you: `TestLambdaContext`.  `TestLambdaContext` is exactly what it sounds like, a lambda context for use with tests.

A Lambda is a public class, with a public method that takes two parameters.  Both parameters are easy to work with in tests.  Any other dependencies you take on are part of your own use case, they are not intrinsic to Lambda.

## Some unit testing scenarios

### A Lambda that returns a value

The simplest case is a pure logic Lambda that returns a value.  You will see non-void Lambdas when you use Lambda as a back end for an API Gateway endpoint.  The unit test will create an instance of your event data, and an instance of `TestLambdaContext` if necessary.  Finally, create an instance of your `Function` class, then invoke `FunctionHandler` passing the event and the context.  Catch the result and write an assert against the value.

### A Lambda that interacts with the world

A slightly more complex and common scenario is that the Lambda needs to interact with other services, whether they are AWS services or public/private APIs.  As they did with `ILambdaContext`, AWS did a good job designing their client SDKs.  Each SDK client implements an interface, you can and should choose to depend on the interface instead of the concrete type.  Once you depend on the interfaces, you can use constructor injection to inject mocks and verify calls to the mocks as part of your assertions.

> Amazon does not provide you with a Dependency Injection framework for this, but I always like to tell people that Dependency Injection is a **principle** not a framework.

> The same goes for Inversion of Control--its a pattern, people, not a container.

{:style="text-align: center;"}
[![Test Rig by aacckk](/media/2017/05/13/test-rig-aacckk.jpg)](https://flic.kr/p/bskY6z){:target="_blank"}
*Test Rig by aacckk (CC BY-SA 2.0)*

In my opinion, if you have a strategy, any strategy, for replacing your dependencies with test doubles, then congrats you've got enough dependency injection for testing.  The project "blueprints" Amazon provides use a common two-constructor strategy.  This example depends on interacting with S3:

```csharp
IAmazonS3 S3Client { get; set; }

public Function()
{
    S3Client = new AmazonS3Client();
}

public Function(IAmazonS3 s3Client)
{
    S3Client = s3Client;
}
```

Lambda will use the parameterless constructor, your tests will use the second constructor to pass in mocks.

> Tip: Because AWS will reuse Lambda `Function` instances and invoke `FunctionHandler` for more than one event, you get a slight(?) performance boost by constructing the client in the constructor.  Be aware that the same client will be used across invocations (don't call `Dispose` on it for example).

Now your test will look something like this (using `Moq` for mocks):

```csharp
var s3Client = new Mock<IAmazonS3>();
var function = new Function(s3Client.Object);
function.FunctionHandler(s3Event, null);
s3Client.Verify(s3 => s3.GetObjectAsync("mybucket", "myfile", CancellationToken.None);
```
Remember how I said you could create your own events in the test?  Here's what that looks like:

```csharp
var s3Event = new S3Event
{
    Records = new List<S3EventNotification.S3EventNotificationRecord>
    {
        new S3EventNotification.S3EventNotificationRecord
        {
            S3 = new S3EventNotification.S3Entity
            {
                Bucket = new S3EventNotification.S3BucketEntity {Name = "mybucket" },
                Object = new S3EventNotification.S3ObjectEntity {Key = "myfile" }
            }
        }
    }
};
```

### Integration Tests

Testing against mocks is not very satisfying, especially as the number of dependencies that need to be mocked go up.  If your mocks start interacting with each other then you are dangerously close to not actually proving anything in your tests.  I'm not completely against mocks, sometimes you need them.

> Saying that mocks suck is like saying screwdrivers suck.  Screwdrivers are actually pretty good for screwing in screws, they are not so great for brain surgery.

Other times you need "the real thing".  That's where integration tests come in.  The dependency injection constructor is good for more than mocks.  You don't have to use mocks, you can use `AmazonS3Client`.  Providing control is the point of the second constructor.  You control the client instance, and its configuration, credentials, region, etc.

Maybe your test bucket is in a different region than production.  You can control for this in your test:

```csharp
IAmazonS3 s3Client = new AmazonS3Client(RegionEndpoint.USWest2);
var function = new Function(s3Client);
function.FunctionHandler(s3Event, null);
```

When you use this strategy your test will actually make calls to S3 or Kinesis or make HTTP calls out into the real world.  So all these things must exist, your bucket or your stream or your API endpoint.  Of course, this is no different than any other integration test with plain old non-Lambda code.

## It's just code

To make a long story short, a lambda **can** be executed in the AWS lambda service, but it can just as easily be executed on your computer.  Once you get over the hurdle of realizing that you can just run the code on your own machine, then it's easy to see that the entire set of testing tools you are used to using can be used to test Lambdas.

Unit and integration testing are totally possible using common frameworks, but that's not the only option.  I recently worked on a project where I found it easier to write a console program and fire off the Lambda from `void Main()`.

Keep in mind that whatever route you choose, there is some configuration to do related to credentials. You need to provide credentials when running on your machine, and there are several ways to do this (machine config via `aws configure`, or credentials configured by the AWS toolkit for Visual Studio).  To get the closest experience to running in AWS, use an implicit set of credentials (described above) rather than hard-coding your credentials into the test code (never a good idea).  Also, your test will be more useful if the credentials you use belong to an IAM User that has the exact same permissions as the IAM Role which the Lambda will execute under. Don't just use your admin credentials and assume everything will work later.

{:style="text-align: center;"}
[![Code by Tom Bech](/media/2017/05/13/code-tom-bech.jpg)](https://flic.kr/p/9BkXKV){:target="_blank"}
*Code by Tom Bech (CC BY 2.0)*

Maybe I'm a crackpot, but I haven't been bitten by "works on my machine" type issues.  What has worked in my local tests, has worked in AWS.  Up until recently all of my thoughts on testing mostly revolved around hunches and small experiments.  But I've been working with real production Lambdas lately, for real clients and these techniques have not let me down yet.  Give it a try.  If fear that you won't be able to unit test and calculate code coverage has been keeping you away from trying serverless, get over your fear, you can do it.  These examples are in C#, but I don't see why you couldn't achieve the same results in Java, JavaScript, Python or any of the other languages supported by Lambda.

 It's all just code.

## But, but what about debugging production?

Of course, I have made all these points to some people (in more compact rant format), and we finally end up with this as the last question.  "Great speech Jim, but how do I debug Lambdas in production?"

My first response is "Who the heck debugs in production?"

The answer to the first question of "how" is simple.  Like a lot of what I've covered so far, debugging Lambdas in production is no different that debugging anything else in production: you read the logs.

> Most operations teams are not going to let you walk up to a production instance and attach your debugger to it!  The AWS operations team feels the same way.

You wouldn't normally attach your debugger to *anything* in production (I'm sure I'll hear from the guy who does it every day).   Lambda is no different in this regard, except perhaps that you don't even have the option to attach a debugger.  The answer to debugging in production is to have a well-thought-out logging strategy, use it consistently, and fetch your logs from CloudWatch when you need to figure out what's going on.


I hope this helps, feel free to reach out via twitter or email and let me know what you think.
