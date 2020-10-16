## Sign in to your Azure account

Connect-AzAccount

## Update variables with desired values

$subscriptionId = "{subscriptionId}" # Replace {subscriptionId} with the ID of the Azure subscription resources will be deployed to
$resourceGroup = "MCASLogs-RG" # The name of the Resource Group to be created
$storageName = "{globally-unique-name}" # A globally unique name for the Storage Account to be created
$location = "eastus" # The location resources will be deployed to in Azure
$containerName = "mcaslogscontainer" # The name of the storage container to be created
$automationName = "MCASLogSim-AA" # The name of the automation account to be created
$runbookName = "MCAS-LogSim" # The name of the runbook to be created
$scheduleName = "Schedule01" # The name of the runbook schedule to be created
$user = "{tenant}.{location}.portal.cloudappsecurity.com" # Replace {tenant} and {location} with your MCAS tenant information
$api = ConvertTo-SecureString "{API Key}" -AsPlainText -Force # Replace {API-Key} with the key generated in MCAS
$localPath = "C:\Microsoft-Cloud-App-Security-master\Scripts\Simulate a Log Collector using Azure Automation" # File path for your cloned repo (with no trailing backslash)
$dataSource = "Log-Sim" # The name of the data source you have created in MCAS

## ------------------------------------------------- ##
##                      Begin                        ##
## ------------------------------------------------- ##

## Look for MCAS PowerShell module and install if needed.

if (Get-InstalledModule -Name MCAS -ErrorAction SilentlyContinue) {
  Write-Host "MCAS module already installed, continuing on." -ForegroundColor Green -BackgroundColor Black
} 
else {
  try {
      Write-Host "MCAS module not found, proceeding to install." -ForegroundColor Green -BackgroundColor Black
      Install-Module -Name MCAS -AllowClobber -Confirm:$False -Force  
  }
  catch [Exception] {
      $_.message 
      exit
  }
}

## Look for Az PowerShell module and install if needed.

if (Get-InstalledModule -Name Az -ErrorAction SilentlyContinue) {
  Write-Host "Az module already installed, continuing on." -ForegroundColor Green -BackgroundColor Black
} 
else {
  try {
      Write-Host "Az module not found, proceeding to install." -ForegroundColor Green -BackgroundColor Black
      Install-Module -Name Az -AllowClobber -Confirm:$False -Force  
  }
  catch [Exception] {
      $_.message 
      exit
  }
}

## Select subscription for deployment

Get-AzSubscription -SubscriptionId "$subscriptionId" | Set-AzContext

## Create Resource Group

New-AzResourceGroup -Name $resourceGroup -Location $location

## Create Storage Account

$storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroup `
  -Name $storageName `
  -SkuName Standard_LRS `
  -Location $location `

$ctx = $storageAccount.Context

## Create Container

New-AzStorageContainer -Name $containerName -Context $ctx -Permission blob

## Upload logs

Set-AzStorageBlobContent -File "$localPath\dummylogs\pa-log.log" `
  -Container $containerName `
  -Blob "pa-log.log" `
  -Context $ctx

$logPath = (Get-AzStorageBlob -blob 'pa-log.log' -Container $containerName -Context $ctx).ICloudBlob.uri.AbsoluteUri

## Create Automation Account and import the MCAS Module from Powershell Gallery

$automationAccount = New-AzAutomationAccount -ResourceGroupName $resourceGroup -Name $automationName -Location $location -Plan Basic

$moduleName = "MCAS"
$moduleVersion = "3.3.7"
New-AzAutomationModule -AutomationAccountName $automationAccount.AutomationAccountName -ResourceGroupName $resourceGroup -Name $moduleName -ContentLinkUri "https://www.powershellgallery.com/api/v2/package/$moduleName/$moduleVersion"

## Create Credential

$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $user, $api

New-AzAutomationCredential -ResourceGroupName $resourceGroup -AutomationAccountName $automationAccount.AutomationAccountName -Name "MCAS-API" -Value $credential

## Create $CASCredential and new data source in MCAS --- NOT WORKING

# $CASCredential = $credential
# New-MCASDiscoveryDataSource -Credential $CASCredential -DeviceType PALO_ALTO -Name $dataSource -ReceiverType FTP

## Create Variables

New-AzAutomationVariable -ResourceGroupName $resourceGroup -AutomationAccountName $automationAccount.AutomationAccountName -Name "storageName" -Value $storageName -Encrypted $false

New-AzAutomationVariable -ResourceGroupName $resourceGroup -AutomationAccountName $automationAccount.AutomationAccountName -Name "containerName" -Value $containerName -Encrypted $false

New-AzAutomationVariable -ResourceGroupName $resourceGroup -AutomationAccountName $automationAccount.AutomationAccountName -Name "dataSource" -Value $dataSource -Encrypted $false

## Import & Publish Runbook

$runbook = Import-AzAutomationRunbook -ResourceGroupName $resourceGroup -AutomationAccountName $automationAccount.AutomationAccountName -Name $runbookName -Type PowerShell -Path $localPath\scripts\runbook.ps1

Publish-AzAutomationRunbook -ResourceGroupName $resourceGroup -AutomationAccountName $automationAccount.AutomationAccountName -Name $runbook.Name

## Create Runbook Schedule and assign it

$startTime = Get-Date "23:59:59"
$endTime = $StartTime.AddYears(1)

$schedule = New-AzAutomationSchedule -ResourceGroupName $resourceGroup -AutomationAccountName $automationAccount.AutomationAccountName -Name $scheduleName -StartTime $startTime -ExpiryTime $endTime -DayInterval 1 

Register-AzAutomationScheduledRunbook -ResourceGroupName $resourceGroup -AutomationAccountName $automationAccount.AutomationAccountName -ScheduleName $schedule.Name -RunbookName $runbook.Name

## Manually trigger the first runbook job after a 3 minute delay

Start-Sleep -s 180
Start-AzAutomationRunbook -ResourceGroupName $resourceGroup -AutomationAccountName $automationAccount.AutomationAccountName -Name $runbook.Name