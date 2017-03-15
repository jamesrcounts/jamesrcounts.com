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
In this post I'll walk through the process I used to setup continuous publishing for this blog using GitHub, CircleCI and S3.  I write my blog posts using jekyll so there are some jekyll specific steps included in the build process.  Although I'm not trying to ensure that this post is so general that it covers every scenario, it should still be useful (with some adaptations) for any static site.

By the end of the post I'll have setup the following:

* GitHub to store the site repository - [Jump](#github)

    * An [account is required](https://github.com/join), if you are following along sign up now.
    * A free account with public repositories will be fine.

* CircleCI to generate and validate the jekyll site
 
    * An [account is required](https://github.com/join), if you are following along sign up for CircleCI after creating your github account.
    * CircleCI has a free tier for private repositories, it has an even better free tier for public repositories.  Either one should work fine for building our jekyll site.
        
        > *Note*: CircleCI supports BitBucket as well, if you prefer that service to GitHub. 
    
* Amazon Web Services to host the site

     > *Note*: that an AWS account has a free tier, but it is not free after the first year.  
     
    * An [account is required](https://aws.amazon.com/).  The AWS sign up process can be a little intimidating.
    
    * You *will* need to provide a credit card during sign up; certain services are not free even in the first year.  
    
    * AWS uses a pretty garbled and annoying CAPTCHA.  You may have to try several times before you can decipher the image.
    
    * You will need to provide a telephone number during sign up.  AWS uses an automated system to call for identity verification. 
    
        > *Note*: AWS uses a **second** annoying CAPTCHA at this stage--just in case you were replaced by a robot after the first CAPTCHA.
        
        > *Note*: You may need to retry this step a few times before AWS can place the outbound call.  A few people I know have mentioned this was a problem for them.
      
# <a name="github"></a> Publish the Jekyll Site to GitHub

I suspect a good number of readers are already familiar with GitHub.  If this is you, then create a public repository on GitHub and push your site to it.  You can skip to the [next section](#github-end).

However, for those who have been following along and prefer step-by-step instructions, read on.

### Create Remote Repository

1. Create your account and login. 

1. Click the green "New Repository" button on the right side of the homepage.
          
    1. I will use "jamesrcounts.com" as the name, to match the jekyll project name
        
    1. Create a public repository
        
    1. Do not initialize the repository with a readme, or add .gitignore/.gitattributes
        
    1. Click "Create Repository"
    
    ![Create Repository](/media/2017/03/15/create-repository.png)
    
        
1. Push the site to the remote repository.
    
    1. First add the remote

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
       
1. Refresh your browser and you should see your contents on GitHub.

    ![Pushed to GitHub](/media/2017/03/07/pushed-to-github.png)

<a name="github-end"></a>

1. <a name="aws"></a>Setup AWS S3 Bucket

    To host our site in AWS we will need a storage bucket to put our files into.  To configure this bucket properly, and integrate with CircleCI later, we will also setup a user for CircleCI which has permission to put objects into the bucket. 
    
    1. Create Bucket(s) - [Create Buckets](http://docs.aws.amazon.com/AmazonS3/latest/dev/website-hosting-custom-domain-walkthrough.html#root-domain-walkthrough-s3-tasks)
    
        I will create two buckets `jamesrcounts.com` and `www.jamesrcounts.com` so that I can support requests with and without the `www`.  Eventually, I'll use AWS Route53 to handle DNS for the website, so the name of the bucket actually matters.  You can use any available name for the bucket, and just use the default URL provided by Amazon.  However, if you want to eventually host this site under your own domain name, you should go buy the domain now and name the bucket appropriately.
        
        1. After creating your AWS account, sign in and visit [s3](https://console.aws.amazon.com/s3)
        
        1. Create two buckets - [Instructions](http://docs.aws.amazon.com/AmazonS3/latest/user-guide/create-bucket.html)
            * I'll use the names `jamesrcounts.com` and `www.jamesrcounts.com`
            * I'll pick "US West (Oregon)" as the region, but you should choose a region near you.
            * I don't need any optional features like versioning, logging, or tags right now.
            * I'll leave the permissions at thier default values for now.
            
    1. Next upload the site to the primary bucket.
    
        Later we will use CircleCI to push content into the bucket.  For now we will just create and copy the files manually.
        
        1. Build the site
        
            ```bash
            bundle exec jekyll build
            ```
           
        1. Copy everything *inside* the _site folder to your primary bucket (without the "www" prefix).  
        
            You can just drag them in from your file manager and drop them in the blue area of your bucket.
            
            ![Drop Site Files](/media/2017/03/07/drop-site-files.png)
            
            Then click the "Upload" button to send the files.
        
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
        1. Paste in a policy to grant permission (notice that you need to update the bucket name in your version of the policy)
        
            ```json 
            {
              "Version":"2012-10-17",
              "Statement":[{
                "Sid":"AddPerm",
                    "Effect":"Allow",
                  "Principal": "*",
                  "Action":["s3:GetObject"],
                  "Resource":["arn:aws:s3:::jamesrcounts.com/*"
                  ]
                }
              ]
            }
            ```
        
        1. Click "Save"
            
    1. We can now view the site on the public internet!
    
        ![Publicly Viewable](/media/2017/03/07/publicly-viewable.png)
        
    1. Configure the `www` bucket to redirect to the primary bucket - [Instructions](http://docs.aws.amazon.com/AmazonS3/latest/user-guide/redirect-website-requests.html)
    
        1. Open the "www" bucket.
        1. Click Properties.
        1. Click "Staic website hosting"
        1. Choose "Redirect requests"
        1. Configure the redirect
            * I'll enter "jamesrcounts.com" for the target bucket
            * I'll enter "http" as the protocol
        1. Click "Save"
                
        1. Click on "Static website hosting" again, then click on the endpoint URL.  It may take a few moments to redirect.
         
        1. When it eventually redirects it may not resolve to a site, depending on how your domain is currently configured.  We need to configure the domain to resolve to our bucket.
        
            ![Redirect To Site](/media/2017/03/07/redirect-to-site.png)
        
1. Setup Custom Domain - [Instructions](http://docs.aws.amazon.com/AmazonS3/latest/dev/website-hosting-custom-domain-walkthrough.html#root-domain-walkthrough-switch-to-route53-as-dnsprovider)

    1. Login to the AWS console then visit Route53
    1. Create a hosted zone - [Instructions](http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html#Step_CreateHostedZone)
        1. Follow the link for specific instructions.
        1. Enter the domain name, in my case: `jamesrcounts.com`
        1. Click "Create"
        
    1. Create alias records for the first bucket
        1. Click "Create Record Set"
        1. For the first alias, leave the "Name" field blank.
        1. Choose the "Yes" radio-button next to the "Alias label"
        1. Click in the "Alias Target" text box, and a drop down should offer you the matching bucket as an option.
        
            *Note*: If you do not see your bucket in the drop down, make sure your bucket name exactly matches the domain you are setting up.  These must match for S3 website hosting to work.  If the domain doesn't match the bucket name, recreate your bucket with the correct name and try again.
            
        1. Click "Create"
        
            ![Create First Alias](/media/2017/03/07/create-first-alias.png)
            
    1. Create a second alias, except this time use "www" as the name, and configure the alias to point at the secondary bucket.
            
1. Update DNS at the domain registrar

    This step will vary depending on where you have your domain registered.  You can even use Amazon as your registrar.  I use hover.com, so I that's what I'll cover.
    
    1. Visit the hosted zone and copy the collection of name servers.
    
        ![Copy Nameservers](/media/2017/03/07/copy-nameservers.png)
    
    1. I'll login to Hover, click on my domain and click the "Edit" button next to the nameservers
    
        ![Edit Nameservers](/media/2017/03/07/edit-nameservers.png)
        
    1. Paste in each name server into the record.
    
        ![Updated Nameservers](/media/2017/03/07/updated-nameservers.png)
        
        The standard disclaimer for DNS is always something like "it may take up to 24 hours for the change to propagate" so don't be too surprised if the URL doesn't resolve right away.
        
    1. Once the DNS change has propagated, you will be able to reach your site home page, as long as you ask for the index specifically.
    
        For example: http://jamesrcounts.com/index.html
        
        ![DNS Resolved](/media/2017/03/07/dns-resolved.png )

1. Connect to CircleCI - [Home Page](http://circleci.com)

    Now that we have a way to reach our site through a custom domain, and a version of the site is published, lets setup CircleCI to auto-publish new content.
    
    Get the process started by clicking the green "Sign Up" button on the home page.  In my case I'll link my GitHub account to CircleCI.

    1. Deselect projects you don't want to build
    
        By default, CircleCI selects all the projects it can access through your linked GitHub account.  You probably don't want to build all of them.
        
        1. Click "Deselect all projects" as needed.  You will need do do this once per organization/user.
        
        1. Click the check box next to the your blog repository.
        
    1. Click the blue "Follow and Build" button below the list of projects.
    
    1. CircleCI will kick off the first build.  
    
        We haven't provided any instructions to CircleCI, so it will do what it can.  Once it sees the code and realizes that it's a ruby project, CircleCI will run `bundle install`.  This will succeed but the build will still show up as a failure because we haven't configured any tests.
    
        More importantly, CircleCI does not know that it should process the project using jekyll.  We need to tell CircleCI to do so, and then it will create the outputs that we need.
        
        ![Failing Build](/media/2017/03/07/failing-build.png)
    
    1. Create a `circle.yml` file - [Documentation](https://circleci.com/docs/1.0/configuration/)
    
        This file tells CircleCI how to build and test our project.
        
        1. Create the circle.yml file in the project root.
        
            ```bash
            touch circle.yml
            ```
        
        1. Next configure the machine by telling it what version of ruby you want to use.  
        
            This resolves an warning during `bundle install` on the build server, and gets our feet wet with circle.yml.
        
            * Figure out the version of ruby
            
                ```bash
                echo ${RUBY_VERSION}
                ```
            
                ![Ruby Version](/media/2017/03/07/ruby-version.png)
                
            * Add machine configuration to the top of the circle.yml file
            
                ```yaml
                machine:
                  ruby:
                    version: ruby-2.4.0
                ```
             
             Push this change and CircleCI will start a new build.  The build will still fail because there are no testing instructions.
             
    1. Setup jekyll build
    
        Before we can setup tests we need something to test.  Lets tell CircleCI how to create the site.
        
        1. Add a dependencies section below the machine section
        
            ```yaml
            dependencies:
              post:
                - bundle exec jekyll build
            ```
            
            Push and let CircleCI run, it may fail with an invalid date error like this:
            
            ![Invalid Date Error](/media/2017/03/07/invalid-date-error.png)
            
        1. Exclude problem file from jekyll build.
           
           Although I'm bothered that I could not reproduce this error locally by running `bundle exec jekyll build`, I'm happy that I have a build server.  One of the great things about a build server is that it provides a second machine to test your code on, surfacing problems that are hidden by your local configuration.
            
            I found this [github issue](https://github.com/jekyll/jekyll/issues/2938) after some googling.  The issue explains that the problem file is actually a test file, not one of ours.  Looking at the error again I can see that indeed the file is beneath the `vendor/bundle` folder, and not one of mine.  The commentors on the issue reccomend exluding files under this path from the build.  
             
            Lets update `_config.yml`.  This file is in your project root directory and it contains several settings which impact improve the over all look and feel of our site.  I've been putting it off to focus on writing this post.  Since we are here we will update them all.
            
            * `title` - This is the title for the whole site, your blog's name in other words. Think of what you want to call your site.  I'm going to call mine "Head In The Clouds", since its the first thing that occurs to me.
            
            * `email` - add your email address here.  This address will appear in the footer of every page.
            
            * `description` - This description should be a short blurb describing your site.  It will appear in the footer.
            
            * `twitter_username` - Update this to reflect your twitter handle.
            
            * `github_username` - Also update this to reflect your github handle.
            
            * `exclude` - Here we will add "vendor/bundle" to the list.  Since we are here we can also exclude "circle.yml" so that it wont be copied to the _site directory.
            
                ```yaml
                exclude:
                  - Gemfile
                  - Gemfile.lock
                  - vendor/bundle
                  - circle.yml
                ```
                
            My final file looks like this:
             
            ```yaml
            title: Head In The Clouds
            email: jamesrcounts@outlook.com
            description: > 
              I'm Jim Counts, independent consultant specializing in legacy code, cloud,
              and devops.  This blog is where I'll share my thoughts and tips on cloud
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
            Push these changes and the next CircleCI build should finish without errors.  We're still missing tests though.
            
        1. Setup tests - [HTML Proofer](https://github.com/gjtorikian/html-proofer)
        
            Although I'm only using jekyll to produce a static blog site, there are still things to test.  The jekyll docs recommend a tool called HTML Proofer to check for issues like badly formed HTML or broken links. 
            
            I'll add a test block to my circle.yml
            
            ```yaml
            test:
              post:
                - bundle exec htmlproofer ./_site --check-html --disable-external
            ```
            
            And I'll add this line to end of my Gemfile
            
            ```ruby
            gem 'html-proofer'
            ```
           
           After I push these changes, the next CircleCI build is finally green!
           
           ![Fixed Build](/media/2017/03/07/fixed-build.png)
           
   1. Setup pre-commit hook - [Documentation](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
       
       This part is optional, but its annoying to check something in, wait for the tests to run then find a simple error you could have fixed on your machine if you remembered to run html-proofer locally.  So I'll setup a git pre-commit hook to run jekyll build and html-proofer, and bring the failure closer to me in time and space.
       
        *Note*: This hook will only run on the local repository, it will not automatically propagate to clones, and if you wipe your local repository and clone again, you will have to recreate the hook. 
       
       1. Create an executable script int the `.git/hooks` folder called `pre-commit`
       
            ```bash
            touch .git/hooks/pre-commit
            chmod +x .git/hooks/pre-commit
            ```
            
       1. Open the file in your editor and add the commands from your circle.yml file to create the script.
       
            ```bash
            #!/bin/sh
            
            bundle exec jekyll build
            bundle exec htmlproofer ./_site --check-html --disable-external
            ```
            
       1. Test your work by committing a change
       
            ```bash
            git commit -am "Added git pre-commit hook"
            ```
   
   1. Configure Deployment - [Guide](https://circleci.com/docs/1.0/continuous-deployment-with-amazon-s3/)
   
        Now we have a working build.  To finish things up we want to have the build output delivered to our S3 bucket, so that our site will have the latest content added to it whenever we publish to GitHub.
        
        1. Create IAM user for site deployment
                              
            To add/overwrite files in your S3 bucket, CircleCI will need access to your AWS account.  I'll create a specific user for this purpose, with only the permissions needed to publish.
            
            An IAM policy defines a set of access rules for resources in AWS.  When the policy is attached to an IAM user, group or role then the policy will be evaluated for that user, group or role.  By default, all access is denied.  If my user tried to access an S3 bucket without any policies attached, the request would be denied.  However, when I write a policy to allow access, and attach it to the user, then that policy will allow access.
            
            By itself a user is basically just a set of credentials.  Only when associated with a policy does the user become useful.  You can apply a policy to a user directly, by attaching it to the user, or indirectly, by attaching it to a group that the member is part of.
            
            * Create Policy
            
                * Login to AWS and navigate to the IAM console.
                
            * Click Policy, then "Create Policy"
            
            * Click "Select" next to "Create Your Own Policy"
            
            * Fill out the policy information
               
                * I'll use "Publish-jamesrcounts.com" as the name.
                * Description is optional, I'll use the following:
                
                    ```
                    Allows sync access to the jamesrcounts.com S3 bucket.
                    ```
                
            * Use a policy doucment similar to the following:
            
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
            
            User your own bucket names in the ARNs.
            
            *Note*: Many ARNs contain your account number, so you should usually be careful about revealing them publicly.  However, S3 ARNs are part of a global namespace that does not include the account number, so I'm not worried about showing it here -- you could have figured it out anyway from the bucket name.
                           
            * Create User 
            
                * Login and navigate to the IAM console.
                
                * Click Users, then Click "Add user"
                
                * Give the user a name, I'll use "Publisher-jamesrcounts.com"
                 
                * Then select the checkbox next to "Programmatic access"
                
                * Click "Next: Permissions"
                
                * Click "Attach existing policies directly", then select the checkbox next to "Publish-jamesrcounts.com"
                
                * Click "Next: Review"
                
                * Finally, click "Create user"
                
                * **Important** Be sure to click the "Download .csv" button before moving on.  This will be your only chance to download these keys.
            
        1. Configure Secrets
        
            * Open the CSV you downloaded in the previous step.
            * Log in to CircleCI
            
            * Click the gear next to your project name in the CircleCI dashboard.
            
                ![CircleCI Project Settings](/media/2017/03/07/circleci-project-settings.png)
                
            * Scroll down to permissions and click "AWS Permissions".  
            
            * Copy the Access Key ID and Secret Access Key from your CSV file into the appropriate fields here.
            
                ![AWS Permissions](/media/2017/03/07/aws-permissions.png)
                
            * Don't forget to click "Save AWS keys".
                
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
        
            * Removing the sample post which jekyll generated.
            
               ```bash
               rm _posts/2017-03-07-welcome-to-jekyll.markdown 
               ```
               
            * Commit and push this change.
            
            * Check the site and see that the sample post is gone!
            
                ![Sample post deleted](/media/2017/03/07/sample-post-deleted.png)
                
# Conclusion
                
That about wraps it up for this post.  It came out alot longer than I expected and its still rough.  Don't be surprised if I come back to it to break it up and polish the content.

Hasta la vista until then.
            