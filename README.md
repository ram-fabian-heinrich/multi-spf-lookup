# SPF Record Lookup Script

This PowerShell script performs DNS lookups to find the SPF records for a list of domains. 

## How to Use

1. Save the script as `SpfLookup.ps1`.

2. Prepare your input file. The input file should contain a list of domains, one domain per line.

   Example: 
   ```csv
   "example.com"
   "example.org"
   ```
    Optionally, if you are running an Exchange Server and wish to generate this list from your server's accepted domains, you can do so with the following PowerShell command in the Exchange Management Shell:

    ```powershell
    (Get-AcceptedDomain | Select-Object DomainName | ConvertTo-Csv -NoTypeInformation) | Select-Object -Skip 1 | Set-Content -Path "C:\temp\accepted_domains_$(get-date -f yyyy-MM-dd_HH_mm).csv"
    ```

    This will create a text file with one domain per line, which you can then use as the input for the `SpfLookup.ps1` script. 

4. Run the script from the command line, specifying the path to your input file and the path where you want to save the output CSV file. Here's an example:

    ```powershell
    .\SpfLookup.ps1 -inputFile "C:\path\to\your\input.csv" -outputFile "C:\path\to\your\output.csv"
    ```

    Replace `"C:\path\to\your\input.csv"` with the path to your input file and `"C:\path\to\your\output.csv"` with the path where you want to save the output CSV file.

5. The output CSV file will contain one row for each domain. Each row will contain the domain name and one or more SPF records. If a domain has multiple SPF records, each record will be in a separate column. If no SPF record is found for a domain or there's a problem looking up the SPF record, the script will add an informative placeholder.

## Prerequisites

- PowerShell 3.0 or later

- Permissions to read the input file and write to the location where the output file is saved

- To run PowerShell scripts, you might need to change the execution policy in PowerShell. You can do this by running the command `Set-ExecutionPolicy RemoteSigned` or `Set-ExecutionPolicy Unrestricted` in PowerShell with administrative privileges. Be aware that this does lower the security settings on your machine, so make sure you understand the implications.

## Limitations

- The script assumes that each line in your input file contains a single domain name.

- The script only looks up SPF records, which are stored in TXT records in DNS. Other types of DNS records are not processed.

- The script does not handle wildcard domains.

- The script does not verify the validity of the SPF records.
