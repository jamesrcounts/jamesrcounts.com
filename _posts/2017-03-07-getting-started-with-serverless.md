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
I'm really excited about serverless computing.  The major cloud vendors are expanding their serverless offerings every day.  I've spent quite a bit of time experimenting with these technologies and implementing them for customers.  But some of the most interesting work I've been doing I haven't been able to share.  So I decided to start this blog, and come up with some original examples so that I can share what I've learned, find out what people think, and get feedback on how it could be better.

I have another blog, but that one doesn't have much focus, so I decided to start fresh here.  Time permitting I'll import those older posts onto this site.  For now, I wanted to focus on creating the a "hello world" for serverless.  There are many options, and I decided it would be appropriate to chronicle the process of setting up this blog as my first post on serverless.  It may not be the simplest example, but I think it does hit a few of the basics like: 

   * Figuring out what tools you need on your machine.  
   * Finding and signing up for cloud services
   * Setting up a deployment pipeline
   
So while there is not a lot of compute going on, there is a bit of infrastructure, and for me, getting through this process will give me a shiny new blog that I can fill up with all the things I'd like to share (believe me I've got a big Trello board full of post ideas).


Originally this post started as one document, but it became long enough to justify breaking up into 3 parts.  Check the bottom of the post for the link to the next part 
   
> *Note*: Although I'm a polyglot programmer and use both Windows and Mac in my professional work, I'll be using a Mac for writing this particular blog post.  All `commands` will be `bash` commands.  If you are working on a modern version of Windows you should be able to activate bash on your machine, but you still may need ruby or other tools.  I'm not going to cover getting ruby and bash working for windows in this post, but I will try to point out what tools are required for each command so that you can get them setup.

# Tools You Need

The following instructions work as the time of the writing.  I'll try to provide links to relevant resources in case things change and you need the most up to date instructions.

### RVM 

**Requires**: curl
       
RVM is the Ruby Version Manager.  It will allow us to install gems as a regular user without using `sudo` to install as root. 
        
1. Download and run the rvm installer - [Installation Instructions](https://rvm.io/)

    > *Note:* Leading "\\" is not a typo. See this [question](http://stackoverflow.com/questions/15691977/why-start-a-shell-command-with-a-backslash) on stackoverflow for more details. 
  
    ```
    \curl -sSL https://get.rvm.io | bash -s stable
    ```
  
1. On a fresh Mac you may be prompted to install the xcode command line tools.  Click install, then agree to the EULA that appears.

    ![Click Install](/media/2017/03/07/xcode-clt.png)
     
1. Next initialize your shell to use rvm.  *Note: you should only need to do this once.  In the future new shells will automatically load rvm.*

    ```bash
    source ~/.rvm/scripts/rvm
    ```
    
1. You're ready to move on when you can run `rvm`.

    ```bash
    rvm --version
    ```
    
    ![RVM](/media/2017/03/07/rvm-working.png)
        
### homebrew 

**Requires:** ruby, curl

To actually install the latest ruby you may need homebrew.  Homebrew is good to have anyway, so lets install it.  This installation will use the default system ruby, but that's ok.
    
1. Download and run the brew installer. - [Installation instructions](https://brew.sh/)

    ```bash
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    ```
    
1. You're ready to move on when you can run `brew`.

    ```bash
    brew --version
    ```
    
    ![brew](/media/2017/03/07/brew-working.png)
    
### ruby (via RVM)

RVM lets you control which version of ruby you use per-project or per-terminal session depending on how you would like to use it.  It does this by installing a new version of ruby in your user account, and leaving the "system" ruby alone.  This is great because the system uses ruby for some of its own purposes (like installing `brew`) so we don't want to mess it up.  Soon, when we install jekyll we will be setting up the "local" ruby, without interfering with the system installation.

1. Install latest (this can take awhile).
   
    ```bash
    rvm install ruby --latest
    ```
    
1. Confirm that you are running the latest ruby.

    ```bash
    ruby --version
    ```
    
1. Next confirm that you are running a "local" ruby.

    ```bash
    which ruby
    ```
    
1. When you see that ruby is found in your user profile, then you are ready to move on.

    ![Local Ruby](/media/2017/03/07/local-ruby.png)

### jekyll 

1. Now we are ready to install jekyll - [Quick-start guide](https://jekyllrb.com/docs/quickstart/)
    
    ```bash
    gem install jekyll bundler
    ```
    
1. Move on once you see the gems finish installing.

    ![gems](/media/2017/03/07/gems.png)
            
# Next Steps

We've gotten off to a good start in this post.  I got some tooling squared away and I'm ready to bootstrap a new site.
  
Although I've worked in quite a few languages, I actually have relatively little experience with ruby.  So tools like RVM and bundler were new to me.  I'm looking forward to trying out Jekyll in the [next post]({% post_url 2017-03-16-bootstrapping-this-blog-with-jekyll %}).    

Read on if you have time!  Thanks!