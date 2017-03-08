---
layout: post
title: Getting Started with Serverless
---
## Create a jekyll blog in S3

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
        title: Getting Started with Serverless
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
     
1. Create an AWS account
