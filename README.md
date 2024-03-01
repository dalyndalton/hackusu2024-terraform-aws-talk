# Managing AWS Infrastructure using Terraform

Aws is cool, like really cool

## AWS
### Getting started with AWS
1. Make the root account (think of it as the organization account)
    - This is NOT THE ACCOUNT you should use for your daily tasks
2. Make an IAM Identity Account to use for your daily tasks
    - You can give this account "Admin Access using IAM roles and Groups" in the console for now, eventually these groups and roles can be defined and limited using terraform.
3. Set up the AWS CLI
    - install it using the aws website for your desired platform
    - Log in to your Admin User account using `aws configure sso`
    - Youll need a few pieces of information:
        - Your SSO start url

> Note: be very VERY careful when using api tokens and keys related to your AWS Account, and always set up multi-factor authentication

## Terraform

Terraform is a state management, or Infrastructure as Code tool, that can be used to manage not just aws, but all sorts of cloud providers and services.


### Project #1 : Setting up billing and alerts for your AWS Account

Most all the services that I'll be showing are free, forever, but also have limitations and use case restrictions.  Its best to recieve email alerts as soon as you start getting chared, rather than learn at the end of the month that you were charged $13,000 dollars in cloud compute fees because you leaked your aws key to github.

Project 1 shows a billing alert being constructed in terraform.  Modifying the alert is as easy as modifying in GIT and running terraform apply (and changing your email of course)

### Project #2 : Running a simple "hello world" webserver on lambda w/ a database

Using only free resources, you can build a simple webserver that returns the last time a page was visited.  While the funcitonality is simple, this is also the same setup you could use to host your own discord server, only needing an http endpoint to hit to make requests to.

## Project #3 : Reusing your code to stand up way too much infrastructure

Here again using the free resources, you can see a demonstration of how easy it is to share configuration across many different resources using patterns like depenency injection.