$releaseDir = "C:\Deploy\Releases\$env:RELEASE_VERSION"

Write-Host "Running database migration..."

# Example if your release contains an EF bundle:
#
# & "$releaseDir\efbundle.exe"
#
# Add your actual migration command here.

Write-Host "Migration completed."
