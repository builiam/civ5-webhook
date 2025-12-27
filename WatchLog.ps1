# Define the Discord Webhook URL
$webhookUrl = "<INSERT DISCORD WEBHOOK URL HERE>"

# Define a hash set to store unique content hashes
$seenHashes = @{}

# Read the log file, tail it, and look for lines with 'JSON'
Get-Content .\Lua.log -Wait -Tail 1 |
    Select-String "JSON" |
    ForEach-Object {
        # Extract the JSON data between the markers
        $jsonContent = [Regex]::Matches($_, '----JSON----(.+)----JSON----').Groups[1].Value

        # Generate a hash of the JSON content
        $jsonHash = [System.Security.Cryptography.HashAlgorithm]::Create("SHA256").ComputeHash([System.Text.Encoding]::UTF8.GetBytes($jsonContent))
        $jsonHashString = [BitConverter]::ToString($jsonHash) -replace "-"

        # Check if this hash has already been seen
        if (-not $seenHashes.ContainsKey($jsonHashString)) {
            # Prepare the payload for Discord (e.g., send JSON data as a message)
            $payload = @{
                content = "$jsonContent"
            }

            # Send the data to Discord Webhook
            Invoke-WebRequest -Uri $webhookUrl -Method POST -Headers @{ 'Content-Type' = 'application/json' } -Body ($payload | ConvertTo-Json) -UseBasicParsing

            # Add the hash to the set to prevent future duplicates
            $seenHashes[$jsonHashString] = $true
        }
    }
