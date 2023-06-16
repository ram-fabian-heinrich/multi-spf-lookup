param (
    [Parameter(Mandatory=$true)]
    [string]$inputFile,

    [Parameter(Mandatory=$true)]
    [string]$outputFile
)

# Initialize a variable to keep track of the maximum number of SPF records found for a domain
$maxSpfRecords = 1

# Process each domain
$domainData = Get-Content $inputFile | ForEach-Object {
    $domain = $_
    $row = [ordered]@{}

    # Lookup TXT records
    try {
        $txtRecords = Resolve-DnsName $domain -Type TXT
        # Extract SPF records
        $spfRecords = $txtRecords | Where-Object { $_.Strings -like 'v=spf1*' }

        # If there's no SPF record, put an informative placeholder
        if ($null -eq $spfRecords) {
            $spfRecords = @('No SPF record found')
        }

        # Update the maximum number of SPF records if necessary
        if ($spfRecords.Count -gt $maxSpfRecords) {
            $maxSpfRecords = $spfRecords.Count
        }

        # Add the domain and SPF records to the row
        $row['domain'] = $domain
        for ($i = 0; $i -lt $spfRecords.Count; $i++) {
            $row["spf-record-$($i+1)"] = $spfRecords[$i].Strings[0]
        }
    } 
    catch {
        # If there was a problem looking up the SPF records, add an informative placeholder
        $row['domain'] = $domain
        $row['spf-record-1'] = 'Failed to lookup SPF record'
    }

    # Return the row
    New-Object PSObject -Property $row
}

# Create the header for the output file
$header = "domain"
for ($i = 1; $i -le $maxSpfRecords; $i++) {
    $header += ";spf-record-$i"
}

# Write the header and domain data to the output file
$header | Out-File $outputFile -Encoding utf8
$domainData | Export-Csv $outputFile -Delimiter ';' -NoTypeInformation -Append -Encoding UTF8
