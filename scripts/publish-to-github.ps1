param(
  [string]$RepositoryUrl = "https://github.com/mgomara01/gtm-engineering-os.git"
)
$ErrorActionPreference = "Stop"
if (git remote get-url origin 2>$null) { git remote remove origin }
git remote add origin $RepositoryUrl
git push --set-upstream origin main
