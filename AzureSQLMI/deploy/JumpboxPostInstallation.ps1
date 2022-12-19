# Install Chocolatey 
Start-Transcript -Path C:\psLogs.txt -Append

Set-ExecutionPolicy Unrestricted -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
# Install Software
Write-Host "Installing Azure Data Studio"
choco install azure-data-studio -y
choco install azure-cli -y
choco install dotnetcore -y

# Instal Azure SQL migration extension for Azure Data Studio 
Start-Process "C:\Program Files\Azure Data Studio\bin\azuredatastudio" -ArgumentList @("--install-extension microsoft.sql-migration","--force") -Wait

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

#Destination Path
$localTargetDirectory = "C:\tem\output"

#Create Folders
CreateFolder $localTargetDirectory

Stop-Transcript
