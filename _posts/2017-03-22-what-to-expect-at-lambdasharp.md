---
layout: post
title: "What to Expect at a LambdaSharp Meetup - Building a Twitter Bot with AWS Lambda"
description: "Join me for a hands-on experience at the LambdaSharp meetup where we built an automated Twitter bot using AWS Lambda, S3, and Rekognition. Learn about serverless development, .NET Core, and image recognition."
author: James Counts
date: 2017-03-22
categories:
  - Serverless Development
  - AWS
  - .NET
  - Meetups
tags:
  - serverless
  - lambda
  - AWS
  - S3
  - dotnet
  - rekognition
  - twitter-bot
  - image-recognition
  - meetup
  - san-diego
  - visual-studio-code
  - net-core
  - tweetinvi
  - cloudwatch
  - iam
  - s3-events
  - hands-on-coding
  - team-challenge
featured_image: /media/2017/03/22/the-challenge.jpg
image_alt: "LambdaSharp meetup challenge setup with laptops and coding materials"
canonical_url: "https://jamesrcounts.com/2017/03/22/what-to-expect-at-lambdasharp-meetup.html"
---

I feel lucky to live in San Diego because we have a great MeetUp here called [LambdaSharp](https://www.meetup.com/lambdasharp/), hosted by [@MindTouch](https://twitter.com/MindTouch).  It is a perfect MeetUp for me, I'm a longtime .net programmer, and a serverless computing enthusiast.  If that describes you too, or even if it half describes you, then you should come to the next meeting and check it out.  There is room in this group for .net devs curious about AWS, or AWS devs curious about .net.  There is even room for beginners interested in learning about both.

Last night was my first time going to the meeting, so I didn't quite know what to expect.  Since the MeetUp description said "BRING YOUR LAPTOP!", I assumed we would do some hands-on coding.  I also knew there would be a "challenge".  I suppose I could have read the description a little more closely because it was clear about how we would work together on the challenge.  Oh well, it was fun to be surprised.

{:style="text-align: center;"}
![The Challenge](/media/2017/03/22/the-challenge.jpg)

After a meet and greet (pizza, soda, beer!), we gathered together for a short intro to the challenge at hand.  Then we split into random teams by counting off group numbers.  My friend [@Paul](https://twitter.com/paulwhitmer) and I ended up in different groups.  ProTip: if you came with a friend you *might* be able to game the system by sitting far away from them.  I briefly considered this but decided to play along with the whole idea of "meeting new people".  After picking teams, we took our laptops to separate areas of the very nice MindTouch break area and offices (my team snagged the board room).

The challenge of the month was to build a Twitter Bot that automatically posts images we upload to an S3 bucket.  You can read all the challenge details on [GitHub](https://github.com/LambdaSharp/March2017-ImageTweeterChallenge). Although we could use any tools we felt comfortable with, the challenge mentors were there to provide help with the recommended tools: Visual Studio Code and .NET Core 1.0.  The challenge has four levels.

* The first level simply involved setting up your infrastructure: S3 bucket, IAM policy, IAM role, and "Hello World" lambda.   Once we setup our infrastructure and wired-up the lambda to the S3 bucket event, level one was complete when we showed (via CloudWatch logs) that the lambda ran after we uploaded an image to the bucket.

* The second level allowed us to get our feet wet handling the data in the S3Event received by lambda when the image arrived.  We completed this step by logging the bucket name and object key to CloudWatch and moved on to level 3.

* The real fun begins at level 3, where we posted the image as a Tweet.  The organizers provided us with temporary credentials to the [@The AutoMaTweet](https://twitter.com/the_automatweet) account, and we used [tweetinvi](https://github.com/linvi/tweetinvi) as our twitter SDK.  The S3Event only contains metadata about the object in S3, not the contents.  So, we read the contents using the [AWS .net S3 client](https://www.nuget.org/packages/AWSSDK.S3/), then provided the bytes to tweetinvi so that it could post them to twitter.

* Finally to achieve "Boss" level, we needed to analyze the image with Amazon Rekognition.  Rekognition is a relatively new service from AWS, which can provide face detection, emotional analysis, or object labels.  This was my first time using the service, but AWS provides [a .net Rekognition client](https://www.nuget.org/packages/AWSSDK.Rekognition/) which follows the same patterns as the other clients in the SDK, so it was super easy to figure it out (the [API reference](https://docs.aws.amazon.com/sdkfornet/v3/apidocs/items/Rekognition/NRekognition.html) is always helpful in these situations, too).  The hardest part about Rekognition is spelling Rekognition.

{:style="text-align: center;"}
![Truck Labels](/media/2017/03/22/truck-labels.png)

For the challenge, we only needed Rekognition to produce object labels.  For example, we uploaded a picture of a truck and Rekognition told us the objects it thought the image showed. Rekognition labeled the image with objects like Tire, Automobile, Forest, etc.  Rekognition also provides a confidence level with the label, which lets us know how likely it thinks that the rusty truck is also a "Sports Car" or "Hot Rod".  We were working quick and dirty so we ignored those confidence levels and just added as many as would fit in the tweet.  Most likely it wasn't very confident in the "Hot Rod" guess, and some teams filtered out low confidence labels.

We worked in two sessions.  After the first hour of hacking, we had a fifteen-minute break and then we separated again to do 45 more minutes of code.  After the coding sessions, we all came back together to talk about what we learned, share our code, and demo.  For our demo, I uploaded a batch of 10 images to the S3 bucket.  Lambda handled the burst of events like a champ, scaling out to meet the need.   Those teams that achieved "Boss" level got together for a group photo then the meeting broke up.  All-in-all a fun night with friendly people and some interesting tech.

{:style="text-align: center;"}
![The Bosses](/media/2017/03/22/bosses.jpg)

You can try the challenge yourself, fork it on [GitHub](https://github.com/LambdaSharp/March2017-ImageTweeterChallenge) and see if you can be a boss too.  Happy coding!