<#
.SYNOPSIS
This script performs DNS lookups to find the SPF records for a list of domains.
.DESCRIPTION
The script reads a list of domains from a CSV file, looks up the SPF records for each domain, 
and writes the results to an output CSV file. 
The output file will contain one row for each domain. Each row will contain the domain name, 
a status message, and one or more SPF records.
.PARAMETER inputFile
Path to the CSV file containing the list of domains. The file should contain one domain per line.
.PARAMETER outputFile
Path to the CSV file where the results will be saved.
.EXAMPLE
.\SpfLookup.ps1 -inputFile "C:\path\to\your\input.csv" -outputFile "C:\path\to\your\output.csv"
.NOTES
- The script only looks up SPF records, which are stored in TXT records in DNS.
- The script does not handle wildcard domains.
- The script does not verify the validity of the SPF records.
- In case of failure, a status message will be written in the 'status' column of the output file.
.LINK
https://github.com/ram-fabian-heinrich/multi-spf-lookup/
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$inputFile,

    [Parameter(Mandatory=$true)]
    [string]$outputFile
)

# Initialize a variable to keep track of the maximum number of spf records found for a domain
$maxSpfRecords = 1

# Process each domain
$domains = Import-Csv $inputFile -Header 'DomainName'
$totalDomains = $domains.Count
$currentDomain = 0
$failedDomains = 0

$domainData = $domains | ForEach-Object {
    
    $domain = $_.PSObject.Properties.Value

    # Update progress
    $currentDomain++
    Write-Progress -Activity "Checking SPF records" -Status "$currentDomain of $totalDomains domains checked" -PercentComplete (($currentDomain / $totalDomains) * 100)

    $row = [ordered]@{}

    # Lookup TXT records
    try {
        $txtRecords = Resolve-DnsName $domain -Type TXT -ErrorAction Stop

        # Extract spf records
        $spfRecords = $txtRecords | Where-Object { $_.Strings -like 'v=spf1*' }

        # If there's no spf record, put an informative placeholder
        if ($null -eq $spfRecords) {
            throw @('No spf record found')
        }

        # Update the maximum number of spf records if necessary
        if ($spfRecords.Count -gt $maxSpfRecords) {
            $maxSpfRecords = $spfRecords.Count
        }

        # Add the domain and spf records to the row
        $row['domain'] = $domain
        for ($i = 0; $i -lt $spfRecords.Count; $i++) {
            $row["spf-record-$($i+1)"] = $spfRecords[$i].Strings[0]
        }
        $row['status'] = 'Success'
    } 
    catch {
        # If there was a problem looking up the spf records, add an informative placeholder
        $row['domain'] = $domain
        $row['spf-record-1'] = ''
        $row['status'] = 'Failed to lookup spf record: ' + $_
        $failedDomains++; 
    }

    # Return the row
    New-Object PSObject -Property $row
}

# Create the header for the output file
$header = "domain;status"
for ($i = 1; $i -le $maxSpfRecords; $i++) {
    $header += ";spf-record-$i"
}

# Write the header and domain data to the output file
$header | Out-File $outputFile -Encoding utf8
$domainData | Export-Csv $outputFile -Delimiter ';' -NoTypeInformation -Append -Encoding UTF8

# Inform user about number of domains checked and where outputFile is saved
Write-Output @("Number of domains checked: " + $totalDomains + "`nNumber of failed lookups: " + $failedDomains + "`nSaved spf records report to: " + $outputFile)
