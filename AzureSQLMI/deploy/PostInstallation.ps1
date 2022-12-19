Set-ExecutionPolicy Unrestricted -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# Function to create folders
function CreateFolder {
    param (
        [Parameter()] [String] $FolderName
    )

    if (Test-Path $FolderName) {
   
        Write-Host "Folder Exists"
    }
    else {
      
        #PowerShell Create directory if not exists
        New-Item $FolderName -ItemType Directory
        Write-Host "Folder Created successfully"
    }
    
}

#Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201
if (-not(Get-InstalledModule Az.Storage -ErrorAction silentlycontinue)) {
    Write-Host "Module does not exist"
    Write-Host "Installing NuGet"
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    Write-Host "NuGet Installed"
    Write-Host "Installing Az.Storage"
    Install-Module Az.Storage -Force
    Write-Host "Module installed successfully"
}
else {
    Write-Host "Module exists"
}

#Download File
$FileName1 = "AdventureWorks2019.bak"

#Destination Path
$localTargetDirectory = "C:\temp\1clickPoC"

#Create Folders
CreateFolder $localTargetDirectory

#Download Blob to the Destination Path 
Write-Host "Downloading file"
$finalPath = $localTargetDirectory + "\" + $FileName1
Invoke-WebRequest 'https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2019.bak' -OutFile $finalPath
Write-Host "File downloaded"

#Install Software
Write-Host "Installing Azure Data Studio"
choco install azure-data-studio -y
choco install azure-cli -y

# Define clear text string for username and password
[string]$userName = 'sqladmin'
[string]$userPassword = 'My$upp3r$ecret'

# Enable FILESTREAM
Write-Host "Enabling Filestream"
$instance = "MSSQLSERVER"
$wmi = Get-WmiObject -Namespace "ROOT\Microsoft\SqlServer\ComputerManagement15" -Class FilestreamSettings | Where-Object { $_.InstanceName -eq $instance }
$wmi.EnableFilestream(3, $instance)
Get-Service -Name $instance | Restart-Service
Write-Host "SQL Server was restarted"
Write-Host "Configuring Filestream"
Import-Module "sqlps" -DisableNameChecking
Invoke-Sqlcmd "EXEC sp_configure filestream_access_level, 2" -Username $userName -Password $userPassword
Invoke-Sqlcmd "RECONFIGURE" -Username $userName -Password $userPassword
Write-Host "Filestream configured"
# Restore Databases
Write-Host "Restoring database"
Invoke-Sqlcmd "RESTORE DATABASE [AdventureWorks2019] FROM DISK = N'C:\temp\1clickPoC\AdventureWorks2019.bak' WITH FILE = 1 , MOVE N'AdventureWorks2017'  TO N'F:\SQLData\AdventureWorks2019.mdf', MOVE N'AdventureWorks2017_log' TO N'G:\SQLLog\AdventureWorks2019_log.ldf', NOUNLOAD, STATS = 5;" -Username $userName -Password $userPassword
Invoke-Sqlcmd "RESTORE DATABASE [AdventureWorks_with_issues] FROM DISK = N'C:\temp\1clickPoC\AdventureWorks2019.bak' WITH FILE = 1 , MOVE N'AdventureWorks2017'  TO N'F:\SQLData\AdventureWorks_with_issues.mdf', MOVE N'AdventureWorks2017_log' TO N'G:\SQLLog\AdventureWorks_with_issues.ldf', NOUNLOAD, STATS = 5;" -Username $userName -Password $userPassword

# Create some issues for migration
Invoke-Sqlcmd "ALTER DATABASE [AdventureWorks_with_issues] ADD FILEGROUP [Filestream_data] CONTAINS FILESTREAM " -Username $userName -Password $userPassword
Invoke-Sqlcmd "ALTER DATABASE [AdventureWorks_with_issues] ADD FILE ( NAME = N'AdventureWorks_fs', FILENAME = N'F:\SQLData\AdventureWorks_fs' ) TO FILEGROUP [Filestream_data]" -Username $userName -Password $userPassword

$query = @'
CREATE TABLE [dbo].[Photos](
	[Id] [UNIQUEIDENTIFIER] ROWGUIDCOL  NOT NULL,
	[PhotoCatalogID] [INT] NULL,
	[Photo] [VARBINARY](MAX) FILESTREAM  NULL,
	UNIQUE NONCLUSTERED 
	(
		[PhotoCatalogID] ASC
	),
	UNIQUE NONCLUSTERED 
	(
		[Id] ASC
	)
	) ON [PRIMARY] FILESTREAM_ON [Filestream_data]
GO
'@

Invoke-Sqlcmd -Query $query -Username $userName -Password $userPassword -Database 'AdventureWorks_with_issues'
Write-Host "Restore completed"