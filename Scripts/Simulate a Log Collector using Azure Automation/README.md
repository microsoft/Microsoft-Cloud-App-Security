# Simulate a Log Collector using Azure Automation

## Overview
[Microsoft Cloud App Security](https://www.microsoft.com/en-us/microsoft-365/enterprise-mobility-security/cloud-app-security) allows users to [discover and manage shadow IT](https://docs.microsoft.com/en-us/cloud-app-security/tutorial-shadow-it) in their environment.  One way to use MCAS Discovery features is by configuring automatic log upload from your Firewall/Proxy using a [log collector](https://docs.microsoft.com/en-us/cloud-app-security/discovery-docker).  
This script allows you to simulate a log collector by uploading randomized daily logs to MCAS (using Palo Alto log formatting), enabling you to test Discovery features in their MCAS tenant with as little infrastructure as possible.

If you do not have them already, the following PowerShell modules will be installed:
* [Az Module](https://docs.microsoft.com/en-us/powershell/azure/new-azureps-module-az?view=azps-4.8.0)
* [MCAS Module](https://github.com/Microsoft/MCAS)

The following resources will be deployed in Azure:
* Resource Group
* Storage Account containing dummy Palo-Alto logs
* An Automation Account containing
    * A PowerShell Runbook
    * A daily schedule for the runbook
    * A credential object containing an API token

*Note: Never run a PowerShell script without checking it first.*

---  

## Instructions
### Generate an API token in MCAS
* From the MCAS Portal
    * Click the **Settings Cog** and select **Security extensions**
    * From **API tokens** use the plus to **Generate a new token**
    * Take note of the token that is generated
* More information can be found [here](https://docs.microsoft.com/en-us/cloud-app-security/api-authentication)

<p align = "left">
<img src="./media/api.PNG?raw=true" height="160">
</p> <p></p>

### Create a Data Source in MCAS
* From the MCAS Portal
    * Click the **Settings Cog** and select **Log Collectors**
    * Add a new **Data Source**
        * Set the **Source** to **PA Series Firewall**
        * Set the **Receiver Type** to **FTP**
* More information can be found [here](https://docs.microsoft.com/en-us/cloud-app-security/discovery-docker-ubuntu)

<p align = "left">
<img src="./media/data-source.PNG?raw=true" height="160">
</p> <p></p>

### Prepare scripts
* [Clone](https://docs.github.com/en/free-pro-team@latest/desktop/contributing-and-collaborating-using-github-desktop/cloning-a-repository-from-github-to-github-desktop) this repo locally
* In `deploy.ps1`
    * Update the variable set (lines 7-> 18) with desired values
    * `$storagename` must be a globally unique value
    * When setting `$user` 
        * `{tenant}` and `{location}` can be found by clicking the **Question Mark** in the MCAS Portal and selecting **About**
        * do **not** include `https://`
        * i.e. `contoso.us3.portal.cloudappsecurity.com`
    * When setting `$localPath` 
        * set to your cloned local repo
        * do not included a trailing backslash
        * i.e. `C:\Users\Contoso\Documents\Microsoft-Cloud-App-Security-master\Scripts\Simulate a Log Collector using Azure Automation`

### Deploy to Azure
* Run `deploy.ps1` with administrative privileges
    * When prompted, sign in with credentials which have privileges to create the relevant resources in Azure (see [Overview](#Overview))
    * Note: It will take several minutes for the script to complete

### Validate initial log upload
* When the script completes it will start a runbook job. To validate logs were sucessfully received:
* From the MCAS Portal
    * Click the **Settings Cog** and select **Governance Log**
    * You should see a log entry with **Action type** *Parse Cloud Discovery Log*

<p align = "left">
<img src="./media/governance-log.PNG?raw=true" height="160">
</p> <p></p>

---  

## Contributors
[Dan Edwards](https://github.com/dan-edwards/)  
[Sebastien Molendijk](https://github.com/Sebmolendijk/)

---  