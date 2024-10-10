**WIP** 

This folder contains the following YAML based Github Pipeline defintions

-  validate.yml

   Pull Request Validation Pipeline, that validates incoming changes against a scratch org fetched from the pool
   
- quickbuild-build-deploy.yml

   Pipeline that gets triggered on a merge to the trunk (develop), resulting in building a set of packages, deploying to a dev sandbox ( and then build a set of validated packages and finally publish that to artifact repository

- release-build-publish.yml

   Triggered on a merge to a release/x branch. Assumes a change has been created/tested in develop/dev (quickbuild-build-deploy.yml) and needs to be included in the release via a cherry-pick to the release branch. This builds and publishes off the relase branch making it avialble for the release pipeline.


- release.yml
   A release pipeline that utilizes the release defintion to fetch artifacts from artifactory and then deploy to a sandbox 



- env-operations
  - prepare-ci-poool.yml
     Pipeline to prepare command is used to build scratch org pools for CI purposes

  - prepare-dev-poool.yml
     Pipeline to prepare command is used to build scratch org pools for development
   
  - pool-cleaner.yml
     Pipeline to drop the entire pools and facilatate for recreation at end of a day

  - delete-scratchorg-pool.yml
     Delete a particular scratch org fetched from the pool, to be used where the devs dont have access to delete scratch orgs from command line (Free Developer License) 


The sample pipelines utilise an azure pipelines variable group called DEVHUB which contains the following variables. As a prerequisite, this has to be setup manually
- DEVHUB_SFDX_AUTH_URL   : The auth url to DevHub, You can retrieve the auth URL by following the ling here https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_auth_sfdxurl.htm

- DEV_SFDX_AUTH_URL: The auth url to Developer Sandbox, You can retrieve the auth URL by following the ling here https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_auth_sfdxurl.htm


- ST_SFDX_AUTH_URL: The auth url to ST Sandbox, You can retrieve the auth URL by following the ling here https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_auth_sfdxurl.htm


- SIT_SFDX_AUTH_URL: The auth url to SIT Sandbox, You can retrieve the auth URL by following the ling here https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_auth_sfdxurl.htm

- UAT_SFDX_AUTH_URL: The auth url to UAT Sandbox, You can retrieve the auth URL by following the ling here https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference_auth_sfdxurl.htm


- Implementation of destructive changes in GitHub Actions

  As the destructive changes are to be run only when a Pull request is created or merged, only validate on PR & deploy on PR close workflows are modified. In the workflows, installation of SFDX Git Delta plugin step is added & Delta package generation is executed.

  For the runValidations & runDeployments, sf validation & deployment commands have one added parameter --post-destructive-changes "src/destructiveChanges/destructiveChanges.xml" to execute destructive deployment in the org.

  An empty destructiveChanges.xml is saved inside repository under src/destructiveChanges. This is done in case validation/deploy workflows are triggered which are not related to pull request creation. These validate/deploy workflows does not execute Git Delta & as a result the empty destructiveChanges.xml get executed through validate/deploy commands. In this case if the changes have deletion in the commits on the branch, they would not be considered during validation/deployment on branch.



