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

        1. The wizard will generate a suitable name for the distribution id.

        1. Restrict bucket access.  Yes - to disable the S3 URL and require requests to go through CloudFront

        1. Create a new access identity.  Keep the prefix `access-identity-` but add or change the suffix.  I'll use `access-identity-jamesrcounts.com`.

        1. Click yes to update the bucket policy.  Although we already have a bucket policy, we want to make sure our new access identity has access.

        1. No need for custom headers

        1. Select Redirect HTTP to HTTPS to avoid errors when people try HTTP.

        1. For the blog website, we only need GET, HEAD methods

        1. Leave TTL as default

        1. Compress objects automatically: yes

        1. Lambda associations?

        1. Create distribution


        TODO: DNS
        TODO: / => index.html
