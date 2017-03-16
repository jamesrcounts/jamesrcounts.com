---
layout: post
title: Getting started with serverless
categories:
    - serverless
    - guides
tags:
    - ruby
    - homebrew
    - jekyll
---
# Introduction
Although I'm a polyglot programmer and use both Windows and Mac in my professional work, I'll be using a Mac for writing this particular blog post.  All `commands` will be `bash` commands.  If you are working on a modern version of Windows you should be able to activate bash on your machine, but you still may need ruby or other tools.  I'm not going to cover getting ruby and bash working for windows in this post, but I will try to point out what tools are required for each command so that you can get them setup.
    
## Initial setup
### Tools you need on your machine.

The following instructions work as the time of the writing.  I'll try to provide links to relevant resources in case things change and you need the most up to date instructions.

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
            
# Next Steps

We've gotten off to a good start in this post.  I got some tooling squared away and I'm ready to bootstrap a new site.
  
Although I've worked in quite a few languages, I actually have relatively little experience with ruby.  So tools like RVM and bundler were new to me.  I'm looking forward to trying out Jekyll in the [next post]({% post_url 2017-03-16-bootstrapping-this-blog-with-jekyll %}).            