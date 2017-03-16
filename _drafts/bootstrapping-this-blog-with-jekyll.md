---
layout: post
title: Bootstrapping this blog with jekyll
categories: 
    - serverless
    - guides
tags:
    - jekyll
---

I've been writing this series of posts on setting up my blog while I've been setting up this blog.  To get things started I just created a folder and put a markdown file in it, and started writing the first post.  

The first step to setting up my blog was to get the required tools for running jekyll.  I covered that in [the first part of the series]({% post_url 2017-03-07-create-a-serverless-blog-with-aws-and-jekyll %}){:target="_blank"}.  

Now that I have the tools, I need to create the jekyll site, then move the content I've already written into it.  Then I can finish the series from within the site itself.

Here's what I'll cover in this post:

   * Creating a jekyll site - [Jump](#jekyll)
   * Creating a local git repository - [Jump](#git)
   * Moving existing content into the jekyll site - [Jump](#migrate-to-jekyll)
            
# <a name="jekyll"></a> Create a jekyll site

I originally thought that jekyll was a converter that just converted markdown to other formats.  But I was wrong, I probably had jekyll confused with the very useful [pandoc](http://pandoc.org/){:target="_blank"} tool.  

Besides markdown, Jekyll can handle many other formats.  Jekyll is more than a simple converter, jekyll sites have structure.  Creating a jekyll site reminds me of using `npm init` to create a new javascript project.  An better analogy would be something like `express myapp` to scaffold  a new expressjs website.  That's what `jekyll new` does, it creates a scaffold site for me that I can start customizing with my own content.

### Initialize your jekyll site 
    
1. Use `jekyll new` to scaffold a new website. - [Quick Start](https://jekyllrb.com/docs/quickstart/)

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

    > *Note*: jekyll does produce "static" sites which don't require a back-end to render.  The preview server is simply a convenience for local development.
    
    ```bash
    bundle exec jekyll serve
    ```
    
1. You are ready to move on if you can see the site running locally in your browser.  

    Navigate to [http://localhost:4000](http://localhost:4000){:target="_blank"}
    
    ![Jekyll Site](/media/2017/03/07/jekyll-site.png)
    
# <a name="git"></a> Create local git repository

Now that we have initialized our site.  Lets turn it into a git repository.  One of the things I like about jekyll is that everything in jekyll is just code and blob files.  There is no database or backend.  I can use git as my backup and versioning system.

I assume that many of you will already be familiar with git, and you can feel free to skim or [skip](#git-end) this section.  Just make sure that you initialize a new repository and make your first commit with the files jekyll generated.
    
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
    
 <a name="git-end"></a>
    
# 1. <a name="migrate-to-jekyll"></a> Create some custom content
    
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
        
        ```bash
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

# Next Steps

We've come pretty far in this post.  I got some tooling squared away and bootstrapped a new site.  Although I've worked in quite a few languages, I actually have relatively little experience with ruby.  So tools like RVM and bundler were new to me.  Of course, this was also my first experience with Jekyll but I like it so far. 

I learned alot, but I still need to setup a deployment pipeline in order to get these posts into your hands.  To find out how I set that up, [read on]({% post_url 2017-03-15-publish-jekyll-site-to-s3-with-circleci %}).            