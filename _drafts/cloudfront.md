# Goals

- [ ] Setup cloudfront
- [ ] Setup HTTPS
- [ ] Redirect `www` without using second bucket?
- [ ] Force all to HTTPS

# Setup cloudfront

1. Create a bucket

    * Does not need any special permissions.
    
1. Add content to the bucket
    
    * Content needs permissions: Public Read
    * This would be covered by bucket policy in the blog example?
    
1. Create a cloudfront distribution

    * Its under networking [Cloudfront](https://console.aws.amazon.com/cloudfront/home){:target="_blank"}
    
    1. Click "Create Distribution" ![Create Distribution](/media/2017/03/17/create-distribution.png)
    
    1. Click "Web" ![Web Distribution](/media/2017/03/17/web-distribution.png)
    
    1. Configure Distribution
    
        1. Select your bucket ![Select Bucket](/media/2017/03/17/select-bucket.png)

