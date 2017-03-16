---
layout: post
title: Publish a Jekyll Site to AWS S3 with CircleCI
categories:
    - serverless
    - guides
tags:
    - jekyll
    - AWS
    - S3
    - CircleCI
    - GitHub
---
In this post I'll walk through the process I used to setup continuous publishing for this blog using GitHub, CircleCI, and S3.  I write posts on this site using jekyll, and I already set up a jekyll project in a [previous post]({% post_url 2017-03-16-bootstrapping-this-blog-with-jekyll %}){:target="_blank"}.  

To create a publishing pipeline for the site I'll start by pushing the existing site to a remote repository on GitHub.  Next, I will publish the site to AWS S3 manually and configure the website to use a custom domain. Once I have a working version of the site hosted on S3, I'll setup CircleCI to connect the two sides of the pipeline so that changes pushed to GitHub will automatically flow through to the S3 website.

Here are some notes on the services I'll be using:

* GitHub to store the site repository - [Jump](#github)

    * An [account is required](https://github.com/join), if you are following along sign up now.
    * A free account with public repositories will be fine.

* Amazon Web Services to host the site - [Jump](#aws)

     > *Note*: that an AWS account has a free tier, but it is not free after the first year.  
     
    * An [account is required](https://aws.amazon.com/).  The AWS sign up process can be a little intimidating.
    
    * You *will* need to provide a credit card during sign up; certain services are not free even in the first year.  
    
    * AWS uses a pretty garbled and annoying CAPTCHA.  You may have to try several times before you can decipher the image.
    
    * You will need to provide a telephone number during sign up.  AWS uses an automated system to call for identity verification. 
    
        > *Note*: AWS uses a **second** annoying CAPTCHA at this stage--just in case you were replaced by a robot after the first CAPTCHA.
        
        > *Note*: You may need to retry this step a few times before AWS can place the outbound call.  A few people I know have mentioned this was a problem for them.


* CircleCI to generate and validate the jekyll site - [Jump](#circleci)
 
    * An [account is required](https://github.com/join), if you are following along sign up for CircleCI after creating your GitHub account.
    * CircleCI has a free tier for private repositories, it has an even better free tier for public repositories.  Either one should work fine for building our jekyll site.
        
        > *Note*: CircleCI supports BitBucket as well if you prefer that service to GitHub. 
    
# <a name="github"></a> Publish the Jekyll Site to GitHub

I suspect a good number of readers are already familiar with GitHub.  If this is you, then create a public repository on GitHub and push your site to it.  You can skip to the [next section](#github-end).

However, for those who have been following along and prefer step-by-step instructions, read on.

### Create Remote Repository

Take these steps in your browser.

1. Create your account and log in. 

1. Click the green "New Repository" button on the right side of the homepage.
          
    1. I will use "jamesrcounts.com" as the name, to match the jekyll project name
        
    1. Create a public repository
        
    1. Do not initialize the repository with a readme, or add .gitignore/.gitattributes
        
    1. Click "Create Repository"
    
    ![Create Repository](/media/2017/03/15/create-repository.png)
    
        
### Push to Remote Repository

Run these commands in your local bash terminal.

1. First, add the remote

    ```bash
    git remote add origin ${REPOSITORY_URL}
    ```
       
   Example:
   ```bash
   git remote add origin https://github.com/jamesrcounts/jamesrcounts.com.git
   ```
       
1. Then push the contents
                
   ```bash
   git push -u origin master
   ```
   
### Check the Remote Repository

Refresh your browser and you should see your contents on GitHub.

![Pushed to GitHub](/media/2017/03/07/pushed-to-github.png)

<a name="github-end"></a>

# <a name="aws"></a>Create an AWS S3 Website

To host my site in AWS I will need a storage bucket to put our files into.  Turning a bucket into a website requires some special configuration of the bucket.  I also want to setup a custom domain for the website, and for that, I'll use Amazon's Route53 service.
  
  Finally, before leaving the Amazon section of this post, I'll set up credentials and permissions for CircleCI to use when publishing updates to the site.
    
### Create Bucket(s) 

You can find further details in Amazon's own documentation - [Create Buckets](http://docs.aws.amazon.com/AmazonS3/latest/dev/website-hosting-custom-domain-walkthrough.html#root-domain-walkthrough-s3-tasks)

I will create two buckets `jamesrcounts.com` and `www.jamesrcounts.com` so that I can support requests with and without the `www`.  

Because I'll use AWS Route53 to handle DNS for the website, the name of the bucket matters.  The bucket name must match the domain you intend to use, if you haven't purchased your domain yet, you should do so now.  This is optional.  If you don't want to spend any money, or you just don't care about a custom domain, then you can just use default URL AWS provides you.     

1. After creating your AWS account, sign in and visit [s3](https://console.aws.amazon.com/s3){:target="_blank"}
        
1. Create two buckets - [Instructions](http://docs.aws.amazon.com/AmazonS3/latest/user-guide/create-bucket.html)

    * I'll use the names `jamesrcounts.com` and `www.jamesrcounts.com`
    * I'll pick "US West (Oregon)" as the region, but you should choose a region near you.
    * Click "Create".
    
        ![Create Bucket](/media/2017/03/15/create-bucket.png)    
            
### Upload Site and Configure Primary Bucket

The primary bucket can be either bucket that you created in the previous step. I will be the bucket with the "naked" domain (no `www` prefix).  The goal is that CircleCI should push content into this bucket, as mentioned before.  However, there is a fair bit of configuration that goes into setting up the S3 website, so I want to put some content in the bucket now so that I can be sure that the configuration is correct before setting up CircleCI.
        
1. Build the site

    Run this command from your project root in your local terminal.

    ```bash
    bundle exec jekyll build
    ```
           
1. Copy everything *inside* the `_site` folder to the primary bucket.  

    * You can just drag them in from your file manager and drop them in the blue area of your bucket.
    
        ![Drop Site Files](/media/2017/03/07/drop-site-files.png)
    
    * Then click the "Upload" button to send the files.
            
1. Configure the bucket for website hosting - [Instructions](http://docs.aws.amazon.com/AmazonS3/latest/user-guide/static-website-hosting.html)
    
    1. Click "Properties"
    1. Click "Static website hosting"
    1. Choose "Use this bucket to host a website"
    1. Enter "index.html" as the Index Document.
    1. Click the "Save" button
    
            
1. Although the website URL is now available, we receive a 403 error when trying to access the site.

    ![403 Error](/media/2017/03/07/403-error.png)
        
1. Set public bucket permissions - [Instructions](http://docs.aws.amazon.com/AmazonS3/latest/user-guide/set-bucket-permissions.html)

    1. Click "Permissions"
    1. Click "Bucket Policy"
    1. Paste in a policy to grant read-only permission 
    
        ```json 
        {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Sid": "AddPerm",
              "Effect": "Allow",
              "Principal": "*",
              "Action": [
                "s3:GetObject"
              ],
              "Resource": [
                "arn:aws:s3:::jamesrcounts.com/*"
              ]
            }
          ]
        }
        ```
        
        > *Note*: You need to update the bucket name in your version of the policy    
         
        > *Note*: Many ARNs contain your account number, so you should usually be careful about revealing them publicly.  However, S3 ARNs are part of a global namespace that does not include the account number, so I'm not worried about showing it here -- you could have figured it out anyway from the bucket name.
        
    1. Click "Save"
                    
1. We can now view the site on the public internet!

    ![Publicly Viewable](/media/2017/03/07/publicly-viewable.png)
        
### Configure Secondary Bucket

If you are not going to use a custom domain, then you can probably [skip](#secondary-bucket-end) this step.  I don't see much usability benefit to having one default URL redirect to another default.  It's up to you, but I'll only cover the custom domain case here.  If you want to skip this step, go ahead and delete the secondary bucket now, it is only used for redirects.
        
1. Configure the `www` bucket to redirect to the primary bucket - [Instructions](http://docs.aws.amazon.com/AmazonS3/latest/user-guide/redirect-website-requests.html)

    Take these steps in your browser after navigating to S3.

    1. Open the "www" bucket.
    1. Click Properties.
    1. Click "Static website hosting"
    1. Choose "Redirect requests"
    1. Configure the redirect
        * I'll enter "jamesrcounts.com" for the target bucket
        * I'll enter "http" as the protocol
    1. Click "Save"
    
        ![Redirect Configuration](/media/2017/03/15/redirect-configuration.png)
                
1. Click on "Static website hosting" again, then click on the endpoint URL. 
 
   > *Note*: It may take a few moments to redirect.
            
1. When the browser redirects it may not resolve to a site.

    This depends on how your on how your domain is currently configured.  You may see a default website provided by your registrar, or nothing at all.  Because the primary bucket has a `.com` in it, S3 treats it like an address.  To see the redirect to my site, I need to configure the `jamesrcounts.com` domain to resolve to my primary bucket.

    ![Redirect To Site](/media/2017/03/07/redirect-to-site.png)
            
<a name="secondary-bucket-end"></a>

### Setup Custom Domain 

In this section, I'll use Route53 to provide DNS service for my domain.  You can [skip](#custom-domain-end) this step if you only plan to use the default URL provided by AWS.

If you are following along with the Amazon documentation we've made it to [here](http://docs.aws.amazon.com/AmazonS3/latest/dev/website-hosting-custom-domain-walkthrough.html#root-domain-walkthrough-switch-to-route53-as-dnsprovider).

Do these tasks in your browser after logging into the AWS and navigating to [Route53](https://console.aws.amazon.com/route53/home){:target="_blank"}

1. Create a hosted zone - [Instructions](http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html#Step_CreateHostedZone)
    * Enter the domain name, in my case: `jamesrcounts.com`
    * Click "Create"
        
1. Create alias record for the primary bucket
    1. Click "Create Record Set"
    1. Leave the "Name" field blank.
    1. Choose the "Yes" radio button next to the "Alias" label
    1. Click in the "Alias Target" text box, and a drop-down should offer you the matching bucket as an option.
    
         > *Note*: If you do not see your bucket in the drop down, make sure your bucket name exactly matches the domain you are setting up.  These must match for DNS setup to work.  If the domain doesn't match the bucket name, recreate your bucket with the correct name and try again.
        
    1. Click "Create"
    
        ![Create First Alias](/media/2017/03/07/create-first-alias.png)
        
1. Create an alias for the secondary bucket
 
    * Enter "www" as the name
    * Configure the alias to point at the secondary bucket
            
1. Update DNS at the domain registrar

    This step will vary depending on where you have your domain registered.  You can even use Amazon as your registrar.  I use [hover.com](https://hover.com), so I that's what I'll cover.
    
    1. Visit the hosted zone and copy the collection of name servers.
    
        ![Copy Nameservers](/media/2017/03/07/copy-nameservers.png)
    
    1. I'll log in to Hover, click on my domain and click the "Edit" button next to the nameservers
    
        ![Edit Nameservers](/media/2017/03/07/edit-nameservers.png)
        
    1. Paste in each name server into the record.
    
        ![Updated Nameservers](/media/2017/03/07/updated-nameservers.png)
        
        The standard disclaimer for DNS is always something like "it may take up to 24 hours for the change to propagate" so don't be too surprised if the URL doesn't resolve right away.
        
    1. Once the DNS change has propagated, you will be able to reach your site home page at the custom domain.
            
        ![DNS Resolved](/media/2017/03/07/dns-resolved.png )
        
<a name="custom-domain-end"></a>   
     
### Create IAM User for Site Deployment
                                   
To add/overwrite files in your S3 bucket, CircleCI needs access to the AWS account.  I'll create a specific user for this purpose, granting only the permissions needed to publish.

If you are unfamiliar with IAM, an IAM policy defines a set of rules to access resources in AWS and users are essentially just a set of credentials that can have these rules attached.  

By default, AWS denies all access to resources.  When a newly created user tries to access my primary S3 bucket, AWS will check for a policy that allows access to the bucket.  AWS will deny the request unless I write a policy to allow access and attach it to the user.  Earlier, we set up a bucket policy that allowed public read-only access to the primary bucket so that the bucket could serve web content to anyone.  This policy would allow CircleCI to read the bucket.  To perform writes and deletes, CircleCI will need additional permission.  

Only when associated with polices do users become useful.  You can apply a policy to a user by attaching it directly to the user, or by attaching it to a group that the user is in.

Perform these steps in your browser after logging in an navigating to the [IAM console](https://console.aws.amazon.com/iam/home){:target="_blank"}    
   
1. Click "Policies", then "Create Policy"

1. Click "Select" next to "Create Your Own Policy"
 
1. Fill out the policy information
    
    * I'll use "Publish-jamesrcounts.com" as the name.
    
    * Description is optional, I'll use the following:
     
         ```
         Allows sync access to the jamesrcounts.com S3 bucket.
         ```
 
    * Use a policy document similar to the following:
         
        ```json
        {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Action": [
                "s3:ListBucket"
              ],
              "Resource": [
                "arn:aws:s3:::jamesrcounts.com"
              ]
            },
            {
              "Effect": "Allow",
              "Action": [
                "s3:PutObject",
                "s3:DeleteObject"
              ],
              "Resource": [
                "arn:aws:s3:::jamesrcounts.com/*"
              ]
            }
          ]
        }
        ```
     
        > *Note*: use your own bucket name in the ARNs
                
1. Click "Create Policy"

1. Next, click "Users" then click "Add user"
     
     * Give the user a name, I'll use "Publisher-jamesrcounts.com"
      
     * Then select the checkbox next to "Programmatic access"
     
1. Click "Next: Permissions"
     
1. Click "Attach existing policies directly", then select the checkbox next to "Publish-jamesrcounts.com"
     
1. Click "Next: Review"
     
1. Finally, click "Create user"
     
> **Important! Be sure to click the "Download .csv" button before moving on.  This will be your only chance to download these keys.**

# <a name="circleci"></a> Create CircleCI Pipeline

Now that I have published my site and it is available on my custom domain, I want to setup [CircleCI](https://circleci.com) to auto-publish new content.

The finish line for my new blog site is within reach.  If you're following along, we're almost there.

### Sign Up and Configure First Build
    
1. Start the setup process by clicking the green "Sign Up" button on the CircleCI home page.  

    Since my repository is on GitHub, I'll link my GitHub account to CircleCI.

1. Deselect projects you don't want to build
    
    By default, CircleCI selects all the projects it can access through your linked GitHub account.  You probably don't want to build all of them.
    
    1. Click "Deselect all projects" as needed.  
    
        You will need to do this once per organization/user.
    
    1. Click the check box next to your blog repository.
        
1. Click the blue "Follow and Build" button below the list of projects.
    
1. CircleCI will kick off the first build.  
    
    We haven't provided any instructions to CircleCI, so it will infer what it can by examining the repository.  Once CircleCI sees the code and realizes that the jekyll site is a ruby based project, it will run `bundle install`.  This command will succeed but the build will show up as a failure because we haven't configured any tests.
    
    More importantly, although CircleCI sees the "rubiness" of the project, it does not know that it should run jekyll to produce the site.  I need to tell CircleCI to do so before it will create the outputs I need.
    
    ![Failing Build](/media/2017/03/07/failing-build.png)
    
### Create a `circle.yml` file 

This configuration file tells CircleCI how to build and test our project. - [Documentation](https://circleci.com/docs/1.0/configuration/)

1. Create the circle.yml file in the project root.  Run in your terminal at the project root:

    ```bash
    touch circle.yml
    ```
    
1. Next, configure the machine section with a specific ruby version.

    This gets our feet wet with the `circle.yml` file and resolves a warning during `bundle install` on the build server.
    
    * Figure out the version of ruby you are using locally by running this command in your terminal at the project root:
    
        ```bash
        echo ${RUBY_VERSION}
        ```
    
        ![Ruby Version](/media/2017/03/07/ruby-version.png)
        
    * Add machine configuration to the top of the circle.yml file to tell CircleCI to use the same version.
    
        ```yaml
        machine:
          ruby:
            version: ruby-2.4.0
        ```
     
1. Push this change and CircleCI will start a new build.  The build will still fail because there are no testing instructions.
         
### Setup jekyll build

Before we can setup tests we need something to test.  Let's tell CircleCI how to create the site.
    
1. Add a dependencies section below the machine section

    ```yaml
    dependencies:
      post:
        - bundle exec jekyll build
    ```
    
1. Push and let CircleCI run, it may fail with an invalid date error like this:
    
    ![Invalid Date Error](/media/2017/03/07/invalid-date-error.png)
        
1. Exclude problem file from jekyll build.
   
   After seeing the error message in CircleCI, I tried to reproduce the error locally by running `bundle exec jekyll build`.  I couldn't reproduce the error locally, and surfacing this kind of problem is one reason I like using build servers.  A build server automatically involves a second machine in your delivery process, and that second machine often surfaces problems hidden by your local configuration.       
   
    I searched the error message and found this [github issue](https://github.com/jekyll/jekyll/issues/2938).  The issue explains that the problem file not one of my files, it is actually a test file.  The commenters on the issue recommend excluding files under the `vendor/bundle` path from the build.  
     
    File exclusions are setup in `_config.yml`, a file I haven't touched yet.  This file is in the project root directory and it contains several settings which impact improve the overall look and feel of the site.  There are important items in the file, like the footer contents and site-wide title.  I've been putting off updating these items to focus on writing this post.  Now will be a good time to update these items while also fixing the problem with `vendor/bundle`.  So you should read through this section, even if you don't encounter the build error I saw.
    
    Open _config.yml and update these items:
    
    * `title` - This is the title for the whole site, your blog's name in other words. Think of what you want to call your site.  The first thing which occurs to me is "Head In The Clouds", so I'll call it that.
    
    * `email` - add your email address here.  This address will appear in the footer of every page.
    
    * `description` - This description should be a short blurb describing your site.  It will appear in the footer.
    
    * `twitter_username` - Update this to reflect your twitter handle.
    
    * `github_username` - Also update this to reflect your GitHub handle.
    
    * `exclude` - Here we will add "vendor/bundle" to the list.  We can also exclude "circle.yml" so that it won't be copied to the _site directory.
    
        ```yaml
        exclude:
          - Gemfile
          - Gemfile.lock
          - vendor/bundle
          - circle.yml
        ```
        
    My final _config.yml file looks like this:
     
    ```yaml
    title: Head In The Clouds
    email: jamesrcounts@outlook.com
    description: > 
      I'm Jim Counts, an independent consultant specializing in legacy code, cloud,
      and DevOps.  This blog is where I'll share my thoughts and tips on cloud
      and serverless computing.
    baseurl: "" 
    url: "" 
    twitter_username: jamesrcounts
    github_username:  jamesrcounts
    
    # Build settings
    markdown: kramdown
    theme: minima
    gems:
      - jekyll-feed
    exclude:
      - Gemfile
      - Gemfile.lock
      - vendor/bundle
      - circle.yml

    ```
    
1. Push these changes and the next CircleCI build should finish without errors.  I'm still missing tests and I need to resolve that to get a green build.
        
### Setup Tests 
    
Jekyll produces a static blog site, but there are still things to test. The jekyll docs recommend a tool called HTML Proofer to check for issues like badly formed HTML or broken links. - [HTML Proofer](https://github.com/gjtorikian/html-proofer) 
        
1. I'll add a test block to my circle.yml
    
    ```yaml
    test:
      post:
        - bundle exec htmlproofer ./_site --check-html --disable-external
    ```
        
1. I'll add this line to end of my Gemfile
    
    ```ruby
    gem 'html-proofer'
    ```
       
1. I'll push these changes and the next CircleCI build is finally green!
   
   ![Fixed Build](/media/2017/03/07/fixed-build.png)
           
### Setup pre-commit hook 
   
This part is optional (you can [skip](#pre-commit-hook-end)), but it is annoying to check something in, wait for the tests to run then find a simple error you could have fixed on your machine if you remembered to run html-proofer locally.  So I'll setup a git pre-commit hook to run jekyll build and html-proofer, and bring the failure closer to me in time and space.

> *Note*: This hook will only run on the local repository, it will not automatically propagate to clones, and if you wipe your local repository and clone again, you will have to recreate the hook. 

1. Create an executable script int the `.git/hooks` folder called `pre-commit` - [Documentation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)

    ```bash
    touch .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
    ```
    
1. Open the file in your editor and add commands similar to those in your circle.yml file to create the script.

    > *Note*: This script also builds and tests drafts, so that I can resolve errors while the work is still in progress.

    ```bash
    #!/bin/sh
    
    bundle exec jekyll build --drafts
    bundle exec htmlproofer ./_site --check-html --disable-external
    ```
    
1. Test your work by committing a change

    ```bash
    git commit -am "Added git pre-commit hook"
    ```
<a name="pre-commit-hook-end"></a>

### Configure Deployment 

Now I have a working build.  To finish things up I want the build output delivered to my S3 bucket so that my site will have the latest content added to it whenever I publish to GitHub. - [Guide](https://circleci.com/docs/1.0/continuous-deployment-with-amazon-s3/)
                  
1. Configure Secrets

    1. Open the CSV you downloaded when you created your IAM user for CircleCI.
    
    1. Click the gear next to your project name in the CircleCI dashboard.
    
        ![CircleCI Project Settings](/media/2017/03/07/circleci-project-settings.png)
        
    1. Scroll down to permissions and click "AWS Permissions".  
    
    1. Copy the Access Key ID and Secret Access Key from your CSV file into the appropriate fields here.
    
        ![AWS Permissions](/media/2017/03/07/aws-permissions.png)
        
    1. Click "Save AWS keys".
                
1. Add deployment to `circle.yml`

    CircleCI includes the AWS command line interface in every build runner.  So this means that we can use standard `awscli` commands to sync our content to S3.
    
    * Add the following to circle.yml
    
        ```yaml                
        deployment:
          prod:
            branch: master
            commands:
              - aws s3 sync ./_site s3://jamesrcounts.com/ --delete
        ```
        
1. Push these changes and check your website once the CircleCI build completes.  Everything should be up-to-date!

    ![Everything Up To Date](/media/2017/03/07/everything-up-to-date.png)
            
1. Let's make sure that CircleCI can also delete files.

    * Remove the sample post which jekyll generated.
    
       ```bash
       rm _posts/2017-03-07-welcome-to-jekyll.markdown 
       ```
       
    * Commit and push this change.
    
    * Check the site and see that the sample post is gone!
    
        ![Sample post deleted](/media/2017/03/07/sample-post-deleted.png)
                
# Conclusion
                
In this post, I published the blog you are reading to AWS S3 and created a build pipeline to automatically publish new content using CircleCI.  Now I'm ready to move forward and write new posts on a variety of tech topics. 

For the most part, this series is done, but there are still revisit the blog in future posts.  For example, I would like to enable HTTPS, but I left those steps out because this series was already getting to be pretty long.  I would also like to set up a discussion/comment system.  

For now, if you have any feedback, reach out through twitter or even email.  Thanks for reading.