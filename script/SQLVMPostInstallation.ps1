Start-Transcript -Path C:\psLogs.txt -Append

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

#Download File
$FileName1 = "AdventureWorks2019.bak"

#Destination Path
Write-Host "Creating folders"
$localTargetDirectory = "C:\temp\1clickPoC"
$backupTargetDirectory = "C:\temp\backup"

#Create Folders
CreateFolder $localTargetDirectory
CreateFolder $backupTargetDirectory

Write-Host "Folders were created successfully"

#Download Blob to the Destination Path 
Write-Host "Downloading file"
try {
    $finalPath = $localTargetDirectory + "\" + $FileName1
    Invoke-WebRequest 'https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2019.bak' -OutFile $finalPath
    Write-Host "File AdventureWorks2019.bak was downloaded successfully"    
}
catch {
    
    Write-Host "Error downloading AdventureWorks2019.bak"
}


# Define clear text string for username and password
[string]$userName = 'sqladmin'
[string]$userPassword = 'My$upp3r$ecret'

# Enable FILESTREAM
try {
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
    Write-Host "Filestream was configured successfully"
}
catch {
    Write-Host "Error enabling and configuring Filestream"
}

# Restore Databases
try {
    Write-Host "Restoring database"
    Invoke-Sqlcmd "RESTORE DATABASE [AdventureWorks2019] FROM DISK = N'C:\temp\1clickPoC\AdventureWorks2019.bak' WITH FILE = 1 , MOVE N'AdventureWorks2019'  TO N'F:\SQLData\AdventureWorks2019.mdf', MOVE N'AdventureWorks2019_log' TO N'G:\SQLLog\AdventureWorks2019_log.ldf', NOUNLOAD, STATS = 5;" -Username $userName -Password $userPassword
    Invoke-Sqlcmd "RESTORE DATABASE [AdventureWorks_with_issues] FROM DISK = N'C:\temp\1clickPoC\AdventureWorks2019.bak' WITH FILE = 1 , MOVE N'AdventureWorks2019'  TO N'F:\SQLData\AdventureWorks_with_issues.mdf', MOVE N'AdventureWorks2019_log' TO N'G:\SQLLog\AdventureWorks_with_issues.ldf', NOUNLOAD, STATS = 5;" -Username $userName -Password $userPassword
    Invoke-Sqlcmd "RESTORE DATABASE [AdventureWorksTDE] FROM DISK = N'C:\temp\1clickPoC\AdventureWorks2019.bak' WITH FILE = 1 , MOVE N'AdventureWorks2019'  TO N'F:\SQLData\AdventureWorksTDE.mdf', MOVE N'AdventureWorks2019_log' TO N'G:\SQLLog\AdventureWorksTDE.ldf', NOUNLOAD, STATS = 5;" -Username $userName -Password $userPassword
    Write-Host "Databases were restored successfully" 
}
catch {
    Write-Host "Error restoring databases" 
}
# Create some issues for migration
try {
    Write-Host "Create databases issues for migration" 
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
    Write-Host "Database with issues was created successfully" 
    
}
catch {
    Write-Host "Error creating issues for a databases" 
}

# TDE
try {
    Write-Host "Create master key" 
    Invoke-Sqlcmd "CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'SQLMigration@TDE'" -Username $userName -Password $userPassword -Database 'master'
    Write-Host "Master key was created successfully"
    Write-Host "Create certificate"
    Invoke-Sqlcmd "CREATE CERTIFICATE TDEServerCert WITH SUBJECT = 'DEK Certificate'" -Username $userName -Password $userPassword -Database 'master'
    Write-Host "Certificate was created successfully"
    Write-Host "Create database encryption"
    Invoke-Sqlcmd "CREATE DATABASE ENCRYPTION KEY WITH ALGORITHM = AES_256 ENCRYPTION BY SERVER CERTIFICATE TDEServerCert" -Username $userName -Password $userPassword -Database 'AdventureWorksTDE'
    Write-Host "Database encryption was created successfully"
    Write-Host "Enable TDE"
    Invoke-Sqlcmd "ALTER DATABASE AdventureWorksTDE SET ENCRYPTION ON" -Username $userName -Password $userPassword -Database 'AdventureWorksTDE'
    Write-Host "TDE was enable successfully" 
    Write-Host "Create certificate backup"
    Invoke-Sqlcmd "BACKUP CERTIFICATE TDEServerCert TO FILE = 'C:\temp\1clickPoC\TDEServerCert'" -Username $userName -Password $userPassword -Database 'master'
    Write-Host "Certificate backup was created successfully" 
        
}
catch {
    Write-Host "Error during the TDE steps"   
}


try {
    
    # Create logins
    Write-Host "Creating Logins and users"
    Invoke-Sqlcmd "CREATE LOGIN sqlpoc WITH PASSWORD = 'HavingFun@123' " -Username $userName -Password $userPassword
    Invoke-Sqlcmd "CREATE LOGIN sqlpocapp WITH PASSWORD = 'HavingFun@123' " -Username $userName -Password $userPassword
    Invoke-Sqlcmd "CREATE LOGIN sqlpocreport WITH PASSWORD = 'HavingFun@123' " -Username $userName -Password $userPassword

    # Create users in the AdventureWorks2019 database
    Invoke-Sqlcmd "CREATE USER sqlpoc FOR LOGIN sqlpoc" -Username $userName -Password $userPassword -Database 'AdventureWorks2019'
    Invoke-Sqlcmd "CREATE USER sqlpocapp FOR LOGIN sqlpocapp" -Username $userName -Password $userPassword -Database 'AdventureWorks2019'
    Invoke-Sqlcmd "CREATE USER sqlpocreport FOR LOGIN sqlpocreport" -Username $userName -Password $userPassword -Database 'AdventureWorks2019'

    # Grant users permission in the AdventureWorks2019 database
    Invoke-Sqlcmd "ALTER ROLE db_owner ADD MEMBER sqlpoc" -Username $userName -Password $userPassword -Database 'AdventureWorks2019'
    Invoke-Sqlcmd "ALTER ROLE db_datareader ADD MEMBER sqlpocapp" -Username $userName -Password $userPassword -Database 'AdventureWorks2019'
    Invoke-Sqlcmd "ALTER ROLE db_datawriter ADD MEMBER sqlpocapp" -Username $userName -Password $userPassword -Database 'AdventureWorks2019'
    Invoke-Sqlcmd "ALTER ROLE db_datareader ADD MEMBER sqlpocreport" -Username $userName -Password $userPassword -Database 'AdventureWorks2019'

    Write-Host "Logins and users were created successfully"   
}
catch {
    Write-Host "Error creating logins and users"
}

# File Share 
try {
    Write-Host "Create SMB Share"
    $Parameters = @{
        Name       = 'SQLBackup'
        Path       = 'C:\temp\backup'
        FullAccess = 'Administrators'
    }
    New-SmbShare @Parameters
    Grant-SmbShareAccess -Name "SQLBackup" -AccountName "Everyone" -AccessRight Full -Confirm:$false
    
    Write-Host "SMB Share was create successfully"    
}
catch {
    Write-Host "Error creating SMB Share"   
}


