Connect-ExchangeOnline

Set-CalendarProcessing -Identity "oracle@healthcareitleaders.com" -AddOrganizerToSubject $false -DeleteSubject $false -DeleteComments $false

Get-CalendarProcessing -Identity "chime@healthcareitleaders.com" | Format-List



