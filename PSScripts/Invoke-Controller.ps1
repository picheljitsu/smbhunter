function Invoke-Controller{

    [CmdletBinding(DefaultParameterSetName='basic_output')]
    Param (
        [Parameter(ParameterSetName='basic_output')]
        [Alias('p')]
        [int]$port,
        [Parameter(Mandatory=$false)]
        [string]$Output="Host"


    )

    #Data is sent in CSV format (no header)
    #
    #Parse data from client. 
    function ps_output($array_log_str){

        $array_log = $array_log_str -split (',')

 
        $ps_object = New-Object PSObject
        $ps_object | Add-Member -Name "Timestamp" -MemberType NoteProperty -value $array_log[4]
        $ps_object | Add-Member -Name "Source" -MemberType NoteProperty -value $array_log[0]
        $ps_object | Add-Member -Name "PID" -MemberType NoteProperty -value $array_log[1]
        $ps_object | Add-Member -Name "Local Connection" -MemberType NoteProperty -value $array_log[2]
        $ps_object | Add-Member -Name "Remote Connection" -MemberType NoteProperty -value $array_log[3]
        $ps_object | Add-Member -Name "Process Name" -MemberType NoteProperty -value $array_log[5]
        $ps_object | Add-Member -Name "Command Line" -MemberType NoteProperty -value $array_log[6]
        
        return $ps_object

        }

    clear-host

    gc "C:\users\potatobox\Documents\bearfarts.txt"

    try { netsh advfirewall firewall delete rule name="ctoc $port" | Out-Null
          netsh advfirewall firewall add rule name="ctoc $port" dir=in action=allow protocol=TCP localport=$port | Out-Null
          write-host "[+] Port $port opened in firewall..."
          }
    catch { write-host "[!] Warning. Unable to establish a firewall rule.  Hosts may not be able to connect." }
    

    Write-output "[*] Starting Listener on 0.0.0.0:$port [TCP]"
    write-output "`n"
    #write-output "Host IP`t`t`tPID`t`tLocal Connection`t`tRemote Connection`t`tProcess`t`t`t`tCommandLine"

    $array_output = @()

    while($true){
        try {
        $listener = New-object System.Net.Sockets.TcpListener $port
        $listener.Start()

        $client_connection_object = $listener.AcceptTcpClient()
        }
        catch { write-host -nonewline 
        "[!] Unable to start listener on port $port.  
        Verify that the port is not in use by another program or restart this window" 

        exit

        }

        $remoteclient = $client_connection_object.Client.RemoteEndPoint.Address.IPAddressToString
        $data_stream = $client_connection_object.GetStream()
        $data_stream.ReadTimeout = [System.Threading.Timeout]::Infinite

        $receivebuffer = New-Object Byte[] $client_connection_object.ReceiveBufferSize
        $encodingtype = new-object System.Text.ASCIIEncoding

        while ($client_connection_object.Connected){
            try{ $Read = $data_stream.Read($Receivebuffer, 0, $Receivebuffer.Length) }
            catch { $output_stream = $NULL }
            if($read -eq 0){
                    $close_connection = $encodingtype.GetBytes("end")
                    $data_stream.Write($close_connection , 0, $close_connection.Length) 
                    break
                    }         
                     
            else{     
                 $close_connection = $encodingtype.GetBytes("end")
                 $data_stream.Write($close_connection , 0, $close_connection.Length) 
                 [Array]$Bytesreceived += $Receivebuffer[0..($Read -1)]

                 }
            if ($data_stream.DataAvailable) {$close_connection = $encodingtype.GetBytes("end");$data_stream.Write($close_connection , 0, $close_connection.Length) ;continue}

            else{

                $logconnection = $EncodingType.GetString($Bytesreceived).trimend('`n`r')

                $logconnection = $logconnection -split ([char]10)

                foreach($log in $logconnection){

                    $log = $log -replace "`r`n|`r|`n|`n`r",""

                    if($log.length -ne 0){

                        $output_stream = "$remoteclient,$log"
                        $hashentry = ps_output $output_stream
                        $array_output += $hashentry
                        $hashentry

                        }
                    }





                [Array]::Clear($Receivebuffer, 0, $Read)
                
                }



            try{

                if ($PSVersionTable.CLRVersion.Major -lt 4){
                    $client_connection_object.Close(); $data_stream.Close(); $listener.Stop()
                    }
                else {$data_stream.Dispose(); $client_connection_object.Dispose(), $listener.Stop()}

                Write-Verbose "[**] TCPClient Connected : $($client_connection_object.Connected)"
                Write-Verbose "[**] TCPListener was stopped gracefully"
                Write-Verbose "[**] TCPNetworkStream was closed/disposed gracefully`n"
               

                }

            catch { Write-Warning "Failed to close TCP Stream"}
                                
            }
        }
    }

    
    