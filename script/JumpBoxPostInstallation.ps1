Start-Transcript -Path C:\psLogs.txt -Append

# Install Chocolatey 
try {
    Set-ExecutionPolicy Unrestricted -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))   
}
catch {
    Write-Host "Error to install chocolatey and set execution policy"
}

try {
    # Installing Windows Terminal
    Write-Host "Installing Windows Terminal"
    choco install microsoft-windows-terminal -y
}
catch {
    Write-Host "Error to install Windows Terminal"
}


try {
    # Install dotnet 
    Write-Host "Installing DotNet Core"
    choco install dotnetcore -y
    Write-Host "dotnetcore was installed successfully"
    Write-Host "Installing Dotnet 6"
    choco install dotnet-6.0-sdk -y
    Write-Host "dotnet-6.0-sdk was installed successfully"
    Write-Host "Installing Dotnet 7 runtime"
    choco install dotnet-runtime -y
    Write-Host "dotnet-runtime was installed successfully"

    Write-Host "Setting variable"
    $env:Path += "C:\Program Files\dotnet;"
    [Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
    refreshenv
}
catch {
    Write-Host "Error to installing dotnet"
}

    try {
    # Install Software
    Write-Host "Installing Azure Data Studio"
    choco install azure-data-studio -y
    Write-Host "Azure Data Studio was installed successfully"
    Write-Host "Installing Azure CLI"
    choco install azure-cli -y
    Write-Host "Azure CLI was installed successfully"

    $env:Path += "C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin;"
    [Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
    refreshenv   
}
catch {
    Write-Host "Error to install Azure Data Studio or Azure CLI"
    Write-Host "Error to set variables: 'C:\Program Files\dotnet;' and 'C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin;'"
}

try {
    Write-Host "Installing PowerShell module"
    Install-PackageProvider -Name NuGet -Force -Confirm:$false
    Install-Module -Name Az.DataMigration -Force -Confirm:$false 
    Write-Host "Az.DataMigration was installed successfully"
}
catch {
    Write-Host "Error to install PowerShell module"
}

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
        Write-Host "Folder was created successfully"
    }
    
}

Write-Host "Creating folders"
#Destination Path
$OutputTargetDirectory = "C:\temp\output"
$ProjectsTargetDirectory = "C:\temp\projects"
$SHIRTargetDirectory = "C:\temp\SHIR"

#Create Folders

CreateFolder $OutputTargetDirectory
CreateFolder $ProjectsTargetDirectory
CreateFolder $SHIRTargetDirectory
Write-Host "Folders were created successfully"

# Adding some Nuget sources
Write-Host "Adding Nuget source"
try {
    dotnet nuget add source https://api.nuget.org/v3/index.json -n nuget.org
    Write-Host "Nuget source added correctly"
}
catch {
    Write-Host "Error adding Nuget source" 
}

# Installing SqlPackage - This is not working!
Write-Host "Installing SqlPackage"
try {
    Set-Location "C:\Program Files\dotnet"
    dotnet tool install -g microsoft.sqlpackage
    $env:Path += "C:\Windows\System32\config\systemprofile\.dotnet\tools;"
    [Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
    refreshenv
    Write-Host "SqlPackage throught dotnet was installed successfully"
}
catch {
    Write-Host "Error to install SqlPackage" 
    Write-Host "Error to set variables: 'C:\Windows\System32\config\systemprofile\.dotnet\tools;'" 
}

Write-Host "Installing SqlPackage through msi"
try {
    Invoke-WebRequest -Uri https://aka.ms/dacfx-msi -OutFile C:\temp\DacFramework.msi; 
    Start-Process msiexec.exe -Wait -ArgumentList '/I C:\temp\DacFramework.msi /quiet'; 
    $env:Path += "C:\Program Files\Microsoft SQL Server\160\DAC\bin;"
    [Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
    refreshenv
    Write-Host "SqlPackage throught msi was installed successfully"

}
catch {
    Write-Host "Error to install SqlPackage" 
}

try {
    # Downaloading and installig Integration Runtime
    Write-Host "Downloading Integration Runtime"
    Invoke-WebRequest -Uri https://download.microsoft.com/download/E/4/7/E4771905-1079-445B-8BF9-8A1A075D8A10/IntegrationRuntime_5.29.8528.1.msi -OutFile C:\temp\SHIR\IntegrationRuntime_5.29.8528.1.msi; 
    Write-Host "Installing Integration Runtime"
    Start-Process msiexec.exe -Wait -ArgumentList '/I C:\temp\SHIR\IntegrationRuntime_5.29.8528.1.msi /quiet'; 
 }
catch {
    Write-Host "Error to install Integration Runtime"
 }

try {
    # add extension
    Write-Host "Adding AZ extension"
    az extension add --name datamigration --verbose
}
catch {
    Write-Host "Error to add datamigration AZ extension "
}

try {
    # Installing Azure SQL migration extension for Azure Data Studio
    Write-Host "Installing Azure SQL migration extension"
    Start-Process -filePath "C:\Program Files\Azure Data Studio\bin\azuredatastudio" -ArgumentList "--install-extension Microsoft.sql-migration","--force"
}
catch {
    Write-Host "Error to install Azure SQL migration extension"
}

Stop-Transcript


