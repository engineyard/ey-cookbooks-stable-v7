EY Cloud Disaster Recovery
==========================

Pre-Requisites
-------------------
1) In another region, configure an environment identical to the live environment and boot instances.

2) Generate SSH keys to be used by the SSH tunnel (do not use a passphrase): `ssh-keygen -t rsa -b 2048 -f ./eydr_key`

3) An Engine Yard Support Engineer must add the SSH keys generated to our metadata.  The names should be eydr_private_key and eydr_public_key and they should be added at the account level.  The carriage returns in the private key must be replaced with \n when adding to the web interface.

4) Add the SSH key generated in step 2 to the dashboard (both environments) so that it is added to the deploy user's authorized_keys file:  [Add An SSH Key](https://support.cloud.engineyard.com/hc/en-us/articles/205407248-Add-an-SSH-Key)

5) An Engine Yard Support Engineer must update the slave environment password to match the master environment password.  This must be done via the awsm console and can not be done by customers. [Internal Reference: DOC-2184](https://engineyard.jiveon.com/docs/DOC-2184)

Configure
---------
1) Configure the following attributes in the dr_replication cookbook:

```
default[:dr_replication] = {
  :<framework_env> => {
    :master => {
      :public_hostname => "" # The public hostname of the master database
    },
    :initiate => {
      :public_hostname => "" # MySQL ONLY - The public hostname of the database you want to sync the data from (can be the slave or master)
    },
    :slave => {
      :public_hostname => "" # The public hostname of the disaster recovery database
    }
  }

  default[:establish_replication] = false # Set to true to establish replication during Chef run
  default[:failover] = false # Set to true to failover to D/R environment during Chef run
```

2) Upload and apply Chef cookbooks:

```
ey recipes upload --apply -e <master_environment_name>
ey recipes upload --apply -e <slave_environment_name>
```

Steps to Failover
-----------------
1) Set the failover attribute to true and establish_replication to false:

```
default[:establish_replication] = false
default[:failover] = true
```

2) Upload and apply

Notes
-----
* Deployments must be done on both environments to keep the application code up to date
* Custom recipes must be applied on both environments to keep configurations up to date
