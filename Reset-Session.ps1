$icon = "$pwd\icon.png"
$logo = "$pwd\logo.png"
Set-Location "C:\RDS\Scripts\Reset-Session"
#Your XAML goes here :)
$inputXML = @"
<Window x:Class="ResetUserSession.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:ResetUserSession"
        mc:Ignorable="d"
        Title="BOYCE RDS SESSION RESET" Height="550.326" Width="414.368" FontSize="16" ResizeMode="NoResize" WindowStartupLocation="CenterScreen" Icon="$icon">
    <Grid Grid.IsSharedSizeScope="True">
        <Image HorizontalAlignment="Left" Height="100" Margin="10,10,0,0" VerticalAlignment="Top" Width="331.701" Source="$logo"/>
        <Label x:Name="lbl_User" Content="User:" HorizontalAlignment="Left" Margin="34.332,156.833,0,0" VerticalAlignment="Top" FontSize="16"/>
        <Label x:Name="lbl_server" Content="Server" HorizontalAlignment="Left" Margin="34.332,193.113,0,0" VerticalAlignment="Top" FontSize="16"/>
        <Label x:Name="lbl_Server_Value" Content="Servername" HorizontalAlignment="Left" Margin="132.333,193.113,0,0" VerticalAlignment="Top" FontSize="16"/>
        <Label x:Name="lbl_User_Value" Content="Username" HorizontalAlignment="Left" Margin="132.333,156.833,0,0" VerticalAlignment="Top" FontSize="16"/>
        <Label x:Name="lbl_Application" Content="Application" HorizontalAlignment="Left" Margin="34.332,229.393,0,0" VerticalAlignment="Top" FontSize="16"/>
        <Label x:Name="lbl_Reason" Content="Reason" HorizontalAlignment="Left" Margin="34.332,298.047,0,0" VerticalAlignment="Top" FontSize="16"/>
        <ComboBox x:Name="cbo_Application" HorizontalAlignment="Left" Margin="132.333,238.713,0,0" VerticalAlignment="Top" Width="248.035"/>
        <RichTextBox x:Name="rtb_Reason" HorizontalAlignment="Left" Height="154" Margin="132.333,298.047,0,0" VerticalAlignment="Top" Width="248.035">
            <FlowDocument/>
        </RichTextBox>
        <Button x:Name="btn_Submit" Content="Reset" HorizontalAlignment="Left" Margin="305.368,469.04,0,0" VerticalAlignment="Top" Width="75" Height="31.293"/>
        <Label x:Name="lbl_Application_Error" Content="Required" HorizontalAlignment="Left" Height="27.374" Margin="34.332,248.673,0,0" VerticalAlignment="Top" Width="76.001" Foreground="Red" FontSize="12" Visibility="Hidden"/>
        <Button x:Name="btn_Cancel" Content="Cancel" HorizontalAlignment="Left" Margin="225.368,469.04,0,0" VerticalAlignment="Top" Width="75" Height="31.293" IsCancel="True"/>
        <Label x:Name="lbl_Reason_Error" Content="Required" HorizontalAlignment="Left" Height="27.374" Margin="34.332,317.327,0,0" VerticalAlignment="Top" Width="76.001" Foreground="Red" FontSize="12" Visibility="Hidden"/>
    </Grid>
</Window>
"@ 
 
$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML
 
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {
    $Form = [Windows.Markup.XamlReader]::Load( $reader )
}
catch {
    Write-Warning "Unable to parse XML, with error: $($Error[0])`n Ensure that there are NO SelectionChanged or TextChanged properties in your textboxes (PowerShell cannot process them)"
    throw
}

#$form.ShowInTaskbar = $false

#===========================================================================
# Load XAML Objects In PowerShell
#===========================================================================
  
$xaml.SelectNodes("//*[@Name]") | ForEach-Object { "trying item $($_.Name)";
    try {
        Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name) -ErrorAction Stop
    }
    catch {
        throw
    }
}
 
Function Get-FormVariables {
    if ($global:ReadmeDisplay -ne $true) {
        Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow; $global:ReadmeDisplay = $true
    }
    write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
    get-variable WPF*
}
 
Get-FormVariables
 
#===========================================================================
# Use this space to add code to the various form elements in your GUI
#===========================================================================

# Set a date variable
$mydate = (get-date -U "%Y%m%d %H%M")
# Define the list of possible servers.
$Servers = ("A-RDS01","A-RDS02","A-RDS03")

# Define email variables.
$PSEmailServer = "boyceca-com.mail.protection.outlook.com"
$HTMLHead = $null
$HTMLBody = $null
$Body = $null


# Define the list of apps that the user can choose from.
$Apps = ("APS","Batch Processing/Tax Lodgement","Central Console","Helpdesk","KIES","Phoenix Live","Tax Manager","Timesheets","Fees","Remote Desktop Connections") | Sort-Object

# Who is running this script.
$User = $env:username

# Set the value of the labels.
$WPFlbl_User_Value.Content = $User
$WPFlbl_Server_Value.Content = $env:COMPUTERNAME

# Add the apps to the dropdown
ForEach($App in $Apps)
    {
        $WPFcbo_Application.AddText($App)
    }

# Remove the required warning on app selection

$WPFcbo_Application.Add_SelectionChanged({
  $WPFlbl_Application_Error.Visibility = "Hidden"
})

# Cancel button to close the window.
$WPFbtn_Cancel.Add_Click({
    $form.Close()
})

$WPFbtn_Submit.Add_Click({
    $OK = 0
    $WPFrtb_Reason.SelectAll()
    If($WPFcbo_Application.Text -eq $null -or $WPFcbo_Application.Text -eq "")
        {
            $WPFlbl_Application_Error.Visibility = "Visible"
            $OK ++
        }
      else 
        {
          $WPFlbl_Application_Error.Visibility = "Hidden"
        }
    

    if($WPFrtb_Reason.Selection.Text.Length -lt 5) {
        write-host "reason error"
        $WPFrtb_Reason.BorderBrush = "Red"
        $WPFlbl_Reason_Error.Visibility = "Visible"
        $OK ++
    }
    else 
      {
        $WPFrtb_Reason.BorderBrush = "#FFABADB3" 
        $WPFlbl_Reason_Error.Visibility = "Hidden"
      }
    If($OK -eq 0) {
      $WPFbtn_Submit.IsEnabled = "False"
      $WPFlbl_Reason_Error.Visibility = "Hidden"
      $WPFrtb_Reason.BorderBrush = "#FFABADB3"
        $HTMLBody += @"
<!doctype html>
<html>
  <head>
    <meta name="viewport" content="width=device-width">
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <title>RDS Session Reset</title>
    <style>
    @media only screen and (max-width: 620px) {
      table[class=body] h1 {
        font-size: 28px !important;
        margin-bottom: 10px !important;
      }
      table[class=body] p,
            table[class=body] ul,
            table[class=body] ol,
            table[class=body] td,
            table[class=body] span,
            table[class=body] a {
        font-size: 16px !important;
      }
      table[class=body] .wrapper,
            table[class=body] .article {
        padding: 10px !important;
      }
      table[class=body] .content {
        padding: 0 !important;
      }
      table[class=body] .container {
        padding: 0 !important;
        width: 100% !important;
      }
      table[class=body] .main {
        border-left-width: 0 !important;
        border-radius: 0 !important;
        border-right-width: 0 !important;
      }
      table[class=body] .btn table {
        width: 100% !important;
      }
      table[class=body] .btn a {
        width: 100% !important;
      }
      table[class=body] .img-responsive {
        height: auto !important;
        max-width: 100% !important;
        width: auto !important;
      }
    }
    @media all {
      .ExternalClass {
        width: 100%;
      }
      .ExternalClass,
            .ExternalClass p,
            .ExternalClass span,
            .ExternalClass font,
            .ExternalClass td,
            .ExternalClass div {
        line-height: 100%;
      }
      .apple-link a {
        color: inherit !important;
        font-family: inherit !important;
        font-size: inherit !important;
        font-weight: inherit !important;
        line-height: inherit !important;
        text-decoration: none !important;
      }
      .btn-primary table td:hover {
        background-color: #34495e !important;
      }
      .btn-primary a:hover {
        background-color: #34495e !important;
        border-color: #34495e !important;
      }
    }
    </style>
  </head>
  <body class="" style="background-color: #f6f6f6; font-family: sans-serif; -webkit-font-smoothing: antialiased; font-size: 14px; line-height: 1.4; margin: 0; padding: 0; -ms-text-size-adjust: 100%; -webkit-text-size-adjust: 100%;">
    <table border="0" cellpadding="0" cellspacing="0" class="body" style="border-collapse: separate; mso-table-lspace: 0pt; mso-table-rspace: 0pt; width: 100%; background-color: #f6f6f6;">
      <tr>
        <td style="font-family: sans-serif; font-size: 14px; vertical-align: top;">&nbsp;</td>
        <td class="container" style="font-family: sans-serif; font-size: 14px; vertical-align: top; display: block; Margin: 0 auto; max-width: 580px; padding: 10px; width: 580px;">
            <div class="content" style="box-sizing: border-box; display: block; Margin: 0 auto; max-width: 580px; padding: 10px;">

                <!-- START CENTERED WHITE CONTAINER -->
                <span class="preheader" style="color: transparent; display: none; height: 0; max-height: 0; max-width: 0; opacity: 0; overflow: hidden; mso-hide: all; visibility: hidden; width: 0;">$User has reset their session</span>
                <table class="main" style="border-collapse: separate; mso-table-lspace: 0pt; mso-table-rspace: 0pt; width: 100%; background: #ffffff; border-radius: 3px;">

                    <!-- START MAIN CONTENT AREA -->
                    <tr>
                        <td class="wrapper" style="font-family: sans-serif; font-size: 14px; vertical-align: top; box-sizing: border-box; padding: 20px;">
                        <table border="0" cellpadding="0" cellspacing="0" style="border-collapse: separate; mso-table-lspace: 0pt; mso-table-rspace: 0pt; width: 100%;">
                            <tr>
                                <td><img height="auto" src="https://cpb-ap-se2.wpmucdn.com/blog.une.edu.au/dist/e/1353/files/2018/01/Boyce-CA-2013-Horizontal-Standard-1ouf6c5.png" style="border: 0;display: block;outline: none;text-decoration: none;height: auto;width: 100%;line-height: 100%;-ms-interpolation-mode: bicubic;" width="180"></td>
                            </tr>
                            <hr />
                            <tr></tr>
                            <tr>
                                <h3>RDS SESSION RESET</h3>
                            </tr>
                            <tr>
                                <p>This alert is purely informational. No action needs to be taken unless this is happening frequently.
                            </tr>
                            <table>
                                <tr>
                                    <th style="padding: 0 90 0 0;">Time</th>
                                    <th style="padding: 0 50 0 0;">User</th>
                                    <th style="padding: 0 50 0 0;">Server</th>
                                    <th style="padding: 0 90 0 0;">Application</th>
                                    <th style="padding: 0 500 0 0;">Reason</th>
                                </tr>
                                <tr>
                                    <td style="font-family: sans-serif; font-size: 14px; vertical-align: top; padding: 0 10 0 0;">$MyDate</td>
                                    <td style="font-family: sans-serif; font-size: 14px; vertical-align: top; padding: 0 10 0 0;">$User</td>
                                    <td style="font-family: sans-serif; font-size: 14px; vertical-align: top; padding: 0 10 0 0;">$env:COMPUTERNAME</td>
                                    <td style="font-family: sans-serif; font-size: 14px; vertical-align: top; padding: 0 10 0 0;">$($WPFcbo_Application.Text)</td>
                                    <td style="font-family: sans-serif; font-size: 14px; vertical-align: top;">$($WPFrtb_Reason.Selection.Text)</td>
                                </tr>
                            </table>
                        </table>
                        <!-- END MAIN CONTENT AREA -->
                </table>

          <!-- END CENTERED WHITE CONTAINER -->
          </div>
        </td>
        <td style="font-family: sans-serif; font-size: 14px; vertical-align: top;">&nbsp;</td>
      </tr>
    </table>
  </body>
</html>
"@
[string]$Body = ConvertTo-Html -Head $HTMLHead -Body $HTMLBody
        Send-MailMessage -From "RDS_Reset@boyceca.com" -To "jsmith@boyceca.com" -Subject "RDS reset by $User" -BodyAsHtml -Body $Body
    
    foreach ($Server in $Servers) 
    {
        If ($Server -ne $LocalServer)
            {
                qwinsta /Server:$Server | Where-Object{$_ -like "*$user*"} | LogOff
            }

    }

qwinsta /Server:$LocalServer | Where-Object{$_ -like "*$user*"} | LogOff
$WPFbtn_Submit.IsEnabled = "True"
  }
})



#Adding code to a button, so that when clicked, it pings a system
# $WPFbutton.Add_Click({ Test-connection -count 1 -ComputerName $WPFtextBox.Text
# })

#===========================================================================
# Shows the form
#===========================================================================

$Form.ShowDialog() | out-null
