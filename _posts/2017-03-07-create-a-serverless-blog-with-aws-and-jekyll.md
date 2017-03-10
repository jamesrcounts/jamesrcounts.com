---
layout: post
title: Create a serverless blog with AWS and jekyll
---
# Introduction
Although I'm a polyglot programmer and use both Windows and Mac in my professional work, I'll be using a Mac for writing this particular blog post.  All `commands` will be `bash` commands.  If you are working on a modern version of Windows you should be able to activate bash on your machine, but you still may need ruby or other tools.  I'm not going to cover getting ruby and bash working for windows in this post, but I will try to point out what tools are required for each command so that you can get them setup.
    
## Initial setup
### Tools you need on your machine.

The following instructions work as the time of the writing.  I'll try to provide links to relevant resources in case things change and you need the most up to date instrucitons.

1. Install RVM - [Installation Instructions](https://rvm.io/)

    **Requires**: curl
           
    RVM is the Ruby Version Manager.  It will allow us to install gems as a regular user without using `sudo` to install as root. 
        
    * Download and run the rvm installer
    
        *Note:* Leading "\\" is not a typo. See this [question](http://stackoverflow.com/questions/15691977/why-start-a-shell-command-with-a-backslash) on stackoverflow for more details. 
      
        ```bash
        \curl -sSL https://get.rvm.io | bash -s stable
        ```
      
    * On a fresh Mac you may be prompted to install the xcode command line tools.  Click install, then agree to the EULA that appears.
    
        ![Click Install](/media/2017/03/07/xcode-clt.png)
        
    * Next initialize your shell to use rvm.  *Note: you should only need to do this once.  In the future new shells will automatically load rvm.*
    
        ```bash
        source ~/.rvm/scripts/rvm
        ```
        
    * You're ready to move on when you can run `rvm`.
    
        ```bash
        rvm --version
        ```
        
        ![RVM](/media/2017/03/07/rvm-working.png)
        
1. Install homebrew - [Installation instructions](https://brew.sh/)

    **Requires:** ruby, curl

    To actually install the latest ruby you may need homebrew.  Homebrew is good to have anyway, so lets install it.  This will use the default system ruby, but that's ok.
        
    * Download and run the brew installer.
    
        ```bash
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        ```
        
    * You're ready to move on when you can run `brew`.
    
        ```bash
        brew --version
        ```
        
        ![brew](/media/2017/03/07/brew-working.png)
    
1. Install latest ruby using RVM

    RVM lets you control which version of ruby you use in on a per-project or per-terminal session depending on how you would like to use it.  It does this by installing a new version of ruby in your user account, and leaving the "system" ruby alone.  This is great because the system uses ruby for some of its own purposes (like installing `brew`) so we don't want to mess it up.  Soon, when we install jekyll we will be setting up the "local" ruby, without interfering with the system installation.
    
    * Install latest (this can take awhile).
       
        ```bash
        rvm install ruby --latest
        ```
        
    * Confirm that you are running the latest ruby.
    
        ```bash
        ruby --version
        ```
        
    * Next confirm that you are running a "local" ruby.
    
        ```bash
        which ruby
        ```
        
    * When you see that ruby is found in your user profile, then you are ready to move on.
    
        ![Local Ruby](/media/2017/03/07/local-ruby.png)

1. Install jekyll - [Quick-start guide](https://jekyllrb.com/docs/quickstart/)

    * Now we are ready to install jekyll.  
        
        ```bash
        gem install jekyll bundler
        ```
        
    * Move on once you see the gems finish installing.
    
        ![gems](/media/2017/03/07/gems.png)
            
## Create a jekyll site
### Content for your website   

Now that you have the tools you need to create content for a static website, lets do it.
    
1. Initialize your jekyll site - [Quick Start](https://jekyllrb.com/docs/quickstart/)

    I originally thought that jekyll was a converter that converted markdown to other formats.  But I was wrong.  I actually can handle many formats besides markdown, and it has more structure than a simple converter as we'll see.  It's somewhat analogous to `npm init` when creating a new javascript project.  An even better analogy would be something like `express myapp` to scaffold out a new expressjs website.  Anyway the command is quite simple.
    
    1. Use `jekyll new` to scaffold a new website.
    
        ```bash
        jekyll new ${project_name}
        ```
        
        In my case the command is:
     
        ```bash
        jekyll new jamesrcounts.com
        ```
    1. Next `cd` into the site folder.
     
        ```bash
        cd jamesrcounts.com
        ```
        
    1. Use jekyll's preview server to start the site.
    
        *Note*: jekyll does produce "static" sites which don't require a back-end to render.  The preview server is simply a convenience for local development.
        
        ```bash
        bundle exec jekyll serve
        ```
        
    1. You are ready to move on if you can see the site running locally in your browser.  
    
        Navigate to [http://localhost:4000](http://localhost:4000)
        
        ![Jekyll Site](/media/2017/03/07/jekyll-site.png)
    
1. Create local git repository

    Now that we have initialized our site.  Lets turn it into a git repository.
    
    1. Navigate to your site folder and run:
        
        ```bash
        git init .
        ```
        
    1. Normally the next thing I like to do is create a `.gitignore` file.  But jekyll already created one for us, nice.
    
        ```
        # .gitignore
        _site
        .sass-cache
        .jekyll-metadata
        ```
        
    1. Add the initial files.
    
        ```bash
        git add .
        ```
        
    1. Now commit them.
    
        ```bash
        git commit -m "Initial jekyll site"
        ```
        
    We don't need to worry about pushing to a remote just yet.  Lets move on to creating some custom content for our site.
    
1. Create some custom content
    
    This part is optional.  If you are only interested in the serverless aspects you can skip ahead just using the files jekyll generated as content.
      
      However, I'm actually going to use this site as my new blog, so I'll document the process for taking this post and getting it into the jekyll site.  
      
      Until this point I haven't had a jekyll site to put it in.  Now I can finally move this file into the proper folder and finish the rest of this post as part of the site.

    1. Create a folder for drafts - [Working with drafts](https://jekyllrb.com/docs/drafts/)
    
        To start, I'll make this post into a draft.  Jekyll supports this concept, but I'll need to create the folder manually.
                
        Run this command in the site folder.
            
        ```bash
        mkdir _drafts    
        ```
    
    1. Next I'll copy this file from where the temporary folder where I have been writing to the `_drafts` folder.
    
        ```bash
        cp ../../jamesrcounts.com/getting_started_serverless.md ./_drafts/
        ```
             
    1. Now I can switch over to editing and previewing the file in the new location.
    
        To launch the jekyll site with drafts enabled run this command:
        
        ```bash
        bundle exec jekyll serve --drafts
        ```
        The draft blog post shows up as if I had published it today.
    
        ![Draft on Homepage](/media/2017/03/07/draft-on-homepage.png)
        
        I can click into the post, but when I do I see that the theme is not applied, and the image links are missing.
        
        ![Initial view of post](/media/2017/03/07/initial-post-view.png)
        
    1. Add front matter to the post - [Front Matter](https://jekyllrb.com/docs/frontmatter/)
    
        Front matter is a chunk of YAML that you add to the top of your markdown file.  When you add front matter, you convert plain-old-markdown files into jekyll files.
        
        I'll add this chunk of front matter to the top of this file.
        
        ```yaml
        ---
        layout: post
        title: Create a serverless blog with AWS and jekyll
        ---
        ```
        
        Now we can see a big improvement to the post styling, but media links are still broken.
        
        ![Broken Media Links](/media/2017/03/07/broken-media-links.png)
        
     1. Create a folder for media - [Writing Posts](https://jekyllrb.com/docs/posts/#including-images-and-resources)
     
        Jekyll's documentation points out that a common solution to including images and other blobs is to create a top-level folder like `assets` or `downloads`.  Jekyll is not very opinionated here.  Anything it sees in the root directory it will either copy to the `_site` directory as-is, or it will pre-process the input if it finds front matter in the file.  
        
        I looked at a few example sites that the jekyll documentation links to, and found that I like the top level folder idea, but I'll include sub-folders to avoid a giant sea of blobs. This is for my own convenience, neither jekyll or the web care how I organize these blobs.
        
        I'll use `mkdir -p` to create my destination folder and it's parents in one go.
        
        ```bash
        mkdir -p media/2017/03/07
        ```
        
        The year/month/day directory structure will make a little more sense once I publish this post out of draft mode.  I doubt I'll be posting so often that having a folder for the day will get confusing, and if that happens, I can change things for new posts without breaking anything.   Anyway, this is good enough for now.  
        
        Next I'll copy the media files from the old location.
        
        ```brew
        cp ../../jamesrcounts.com/media/* media/2017/03/07/
        ```
        
        And now, the image links are working.
        
        ![Working Images](/media/2017/03/07/working-images.png)
        
    1. Now would be a good time to make sure we are all checked in.
    
        ```bash
        git add .
        git commit -m "Added first draft"
        ```
        
     1. Finally I will publish this post by moving it out of the draft folder into the posts folder.  In the post folder, Jekyll requires that the filename is prefixed if YEAR-MONTH-DAY.
     
         ```bash
         mv _drafts/getting_started_serverless.md _posts/2017-03-07-create-a-serverless-blog-with-aws-and-jekyll.md
         ```
         
         As I moved the file, I thought of a better name, so I made that change as well.
         
     1. Now I can restart the server without the `--drafts` flag, and I should still be able to see this post.

# Publish
## Continuous Deployment

Now that the basics are all worked out.  I'll setup the blog for continuous deployment to S3.  I'll use the following online services.

* GitHub to store the repository - [Account Required](https://github.com/join)
    * A free account with public repositories will be fine.

* CircleCI for builds - [Account Required](https://github.com/join)
    * Sign up for GitHub first, you will use that account when creating your CircleCI account.
    * CircleCI has a free tier for private repositories, it has an even better free tier for public repositories.  Either one should work fine for building our jekyll site.
    * *Note*: CircleCI supports BitBucket as well, if you prefer that service to GitHub. 
    
* Amazon Web Services - [Account Required](https://aws.amazon.com/)

    Note that an AWS account has a free tier, but it not free after the first year.  The amazon signup process can be a little intimidating, here are some notes:
    
    * When signing up you *will* need to provide a credit card, as certain services are not free even in the first year.  
    * Also be aware that the CAPTCHA they use is pretty garbled and annoying, you may have to try several times before you can find one that you can decipher.
    * You will need to provide a telephone number so that their automated system can call you to verify your identity. (Note there is a **second** annoying CAPTCHA at this stage.)  You may also need to retry this step a few times, amazon seems to have some trouble placing outbound calls reliably.

1. Setup Github
    
    If you are familiar with GitHub, then create a repository and push your site to it, then skip to the next section.  If you prefer detailed step-by-step instructions, follow on.

    1. Create remote repository
        
        1. After creating your account click the green "New Repository" button on the right side of the homepage.
          
        1. Pick a repository name.  I will use "jamesrcounts.com" to match the jekyll project name.
        
        1. I will create a public repository.
        
        1. Do not initialize the repository with a readme, or add .gitignore/.gitattributes.
        
        1. Click "Create Repository"
        
    1. Configure the new repository as a remote in your local repository.
        
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

1. Setup AWS S3 Bucket

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
            * I'll enter "https" as the protocol
        1. Click "Save"
                
        1. Click on "Static website hosting" again, then click on the endpoint URL.  It may take a few moments to redirect.
         
        1. When it eventually redirects it may not resolve to a site, depending on how your domain is currently configured.  We need to configure the domain to resolve to our bucket.
        
            ![Redirect To Site](/media/2017/03/07/redirect-to-site.png)
        


1. Connect to CircleCI

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
           
           
           
           
           
    