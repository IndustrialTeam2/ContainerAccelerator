# Technical Manual - Industrial Project - Team 2

>## Contents 
> - [Prerequisites](#prerequisites)
> - [Pipeline Setup](#pipeline-setup)
>   - [AWS](#aws)
>   - [Terraform Cloud](#terraform-cloud)
>   - [GitHub Repository](#github-repository)
> - [Sources](#sources)
><br></br>


## Prerequisites
1. Create an [AWS](https://link-url-here.org) account.
2. Create a [Terraform Cloud](https://app.terraform.io/session) account.
3. If it's not setup already, create a [GitHub](https://github.com/) account and fork this repository.
4. Download the [Terraform CLI](https://www.terraform.io/) and add to the repository's working directory.
--------------------------------------------------------------------------------
## Pipeline Setup

### AWS
1. Goto the IAM console and select the `Users` section.
2. Create a new user and give it a meaningful name.
3. Afterwards, click on the new user's name and in the `Permissions` tab, select `Add permissions`:

Under the `permission options` section select `Attach policies directly`

>![Alt text](./res/images/perm_options.png)

Then select `AdministratorAccess`, `IAMFullAccess` and `PowerUserAccess`, and press `Add Permissions` to confirm.

4. Select the `Security credentials` tab and give this user console-access.

> ![Security credenitals image.](./res/images/security_credentials.png)

5. Create an access key tied to this user. 
> ![Showing how to create access key.](./res/images/access_keys.png)

Select the `Command Line Interface (CLI)` option.

> ![Showing to select the CLI option.](./res/images/cli_option.png)

Give it a meaningful description tag value.
 
Make sure to download the csv file provided as that contains the ID and key pair for the access key that has been created, these will be needed for our GitHub repository secrets.

> ![Showing where to download the newly created access keys CSV file.](./res/images/access_keys_csv.png)
> <br></br>
-----------------------------------------------------------------------------
### Encryption Key
This is fairly simple you may either some random text or what you could do is hash a string with a hashing algorithm like `sha256` or `sha512`. This will be stored as GitHub repository secret.

You may use this [sha512 generator website](https://sha512.online/), or some in-house tool to create your own key.


-----------------------------------------------------------------------------
### GitHub Repository 
Within the GitHub repository go to `Settings > Secrets and variables > Actions` and create a few secret variables.

| Variable Name | Value |
| -------- | ------- |
| `AWS_ACCESS_KEY_ID` | Access key ID from the downloaded `csv` file. |
| `AWS_SECRET_ACCESS_KEY` | Secret access key from the downloaded `csv` file. |
| `ENCRYPTION_KEY` | The key generated or made from the [previous step](#encryption-key). |
-----------------------------------------------------------------------------

## Sources

> > ### GitHub actions with Terraform Cloud for AWS: 
> >https://developer.hashicorp.com/terraform/tutorials/automation/github-actions#prerequisites
> >
> >Date Accessed - [27/09/2023]
> 
> > #### GitHub actions workflow file source
> > This is where the `.github` folder in this repository is from.
> > https://github.com/hashicorp-education/learn-terraform-github-actions
> >
> > Date Accessed - [27/09/2023]
> 
> <br></br>