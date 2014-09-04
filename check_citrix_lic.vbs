' Script : check_citrix_lic.vbs
' Description : Check Citrix Licenses in use and return an output on one line for nagios
' Original author: Dejan MARKOVIC (http://www.itpointofview.com)
' 
' NRPE Handler: 
' check_citrix_lic=cscript.exe //T:30 //NoLogo scripts\check_citrix_lic.vbs
' 
' Exemplary output: 'OK: Citrix licenses used: MPS_ADV_CCU (77/130) | MPS_ADV_CCU=89;117;104;0;130'
'
' 9/2014 changes by Simon Meggle <simon.meggle@consol.de>: 
'   - english translation
'   - reformatted output with Status, number of total/used licenses
'   - fixed interchanged warn/crit values in perfdata
'   - added min/max to perfdata
'---------------------------------------------------------------------------
dim lictable
 
ErrorLevel = 0
Errorstr = "OK: " 

'32 or 64 bit
On Error Resume Next
 
Set WshShell = WScript.CreateObject("WScript.Shell")
X = WshShell.RegRead("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\PROCESSOR_ARCHITECTURE")
 
'you have to change the path if you are not in english; at least for myfiles folder (for example mesfichiers in french)
If X = "x86" Then
    CommandLine = """c:\program files\citrix\licensing\ls\lmstat"" -a -c ""c:\program files\citrix\licensing\myfiles"""
Else
    CommandLine = """c:\program files (x86)\citrix\licensing\ls\lmstat"" -a -c ""c:\program files (x86)\citrix\licensing\myfiles"""
End If
 
Set objShell = CreateObject("WScript.Shell")
Set oExec = objShell.Exec(CommandLine)
 
'calculate return the used licences
function calc (chain,line,position)
    result = 0
    if InStr(line, chain) Then
        lictable = split(line)
        result = result + CInt(lictable(position))
    end if
    calc = result
end function
 
' threshold returns individual license usage by text
function threshold(used,total,msg1,text)
    if used = 0 then
        threshold = msg1 & ""
    else
        if used > (total*90/100) Then
            threshold = msg1 & "CRITICAL: " & text & " (" & used & "/" & total & ") "
            errorlevel = 2
	    errorstr = "CRITICAL: "
        else if used > (total*80/100) Then
                threshold = msg1 & "WARNING: " & text & " (" & used & "/" & total & ") "
                if errorlevel < 1 then 
			errorlevel = 1
			errorstr = "WARNING: "
		end if
            else
                threshold = msg1 & text & " (" & used & "/" & total & ") "
            end if
        end if
    end if
'Wscript.StdOut.WriteLine threshold
end function
 
'provide text for graph purpose
function sessions(used,total,msg1,text)
    if used = 0 then
        sessions = msg1 & ""
    else
        sessions = msg1 & text & "=" & used & ";" & round((total*90/100)) & ";" & round((total*80/100)) & ";0;" & total & " "
    end if
'Wscript.StdOut.WriteLine sessions
end function
 
Do Until oExec.StdOut.AtEndOfStream
    Input = oExec.StdOut.ReadLine

    if InStr(Input, "Error") Then
        licerror = 1    'Error while parsing
    else
        MPS_ENT_CCU_TL = MPS_ENT_CCU_TL + calc("MPS_ENT_CCU:",Input,6)   'Enterprise license edition
        MPS_ENT_CCU_CL = MPS_ENT_CCU_CL + calc("MPS_ENT_CCU:",Input,12)
 
        MPS_PLT_CCU_TL = MPS_PLT_CCU_TL + calc("MPS_PLT_CCU:",Input,6)   'Platinum license edition
        MPS_PLT_CCU_CL = MPS_PLT_CCU_CL + calc("MPS_PLT_CCU:",Input,12)
 
        MPS_STD_CCU_TL = MPS_STD_CCU_TL + calc("MPS_STD_CCU:",Input,6)   'Standard license edition
        MPS_STD_CCU_CL = MPS_STD_CCU_CL + calc("MPS_STD_CCU:",Input,12)
 
        MPS_ADV_CCU_TL = MPS_ADV_CCU_TL + calc("MPS_ADV_CCU:",Input,6)   'Advanced license edition
        MPS_ADV_CCU_CL = MPS_ADV_CCU_CL + calc("MPS_ADV_CCU:",Input,12)
 
        MPS_SMB_RN_TL = MPS_SMB_RN_TL + calc("MPS_SMB_RN:",Input,6)  'Access essential license edition
        MPS_SMB_RN_CL = MPS_SMB_RN_CL + calc("MPS_SMB_RN:",Input,12)
 
        CAG_SSLVPN_CCU_TL = CAG_SSLVPN_CCU_TL + calc("CAG_SSLVPN_CCU:",Input,6)  'Access Gateway license edition
        CAG_SSLVPN_CCU_CL = CAG_SSLVPN_CCU_CL + calc("CAG_SSLVPN_CCU:",Input,12)
 
        CAG_AAC_CCU_TL = CAG_AAC_CCU_TL + calc("CAG_AAC_CCU:",Input,6)   'Access Gateway Advanced Access Control license edition
        CAG_AAC_CCU_CL = CAG_AAC_CCU_CL + calc("CAG_AAC_CCU:",Input,12)
 
        CNS_SSLVPN_CCU_TL = CNS_SSLVPN_CCU_TL + calc("CNS_SSLVPN_CCU:",Input,6)  'Access Gateway Enterprise Users (citrix netscaler ssl vpn) license edition
        CNS_SSLVPN_CCU_CL = CNS_SSLVPN_CCU_CL + calc("CNS_SSLVPN_CCU:",Input,12)
 
        MPM_ADV_RC_TL = MPM_ADV_RC_TL + calc("MPM_ADV_RC:",Input,6)  'Password Manager Advanced edition Concurrent user license edition
        MPM_ADV_RC_CL = MPM_ADV_RC_CL + calc("MPM_ADV_RC:",Input,12)
 
        MPM_ADV_RN_TL = MPM_ADV_RN_TL + calc("MPM_ADV_RN:",Input,6)  'Password Manager Advanced edition Named user license edition
        MPM_ADV_RN_CL = MPM_ADV_RN_CL + calc("MPM_ADV_RN:",Input,12)
 
        CPM_ENT_RC_TL = CPM_ENT_RC_TL + calc("CPM_ENT_RC:",Input,6)  'Password Manager Enterprise edition Concurrent user license edition
        CPM_ENT_RC_CL = CPM_ENT_RC_CL + calc("CPM_ENT_RC:",Input,12)
 
        CPM_ENT_RN_TL = CPM_ENT_RN_TL + calc("CPM_ENT_RN:",Input,6)  'Password Manager Enterprise edition Named user license edition
        CPM_ENT_RN_CL = CPM_ENT_RN_CL + calc("CPM_ENT_RN:",Input,12)
 
        CPM_ADV_RN_TL = CPM_ADV_RN_TL + calc("CPM_ADV_RN:",Input,6)  'Password Manager Advanced edition Named user license edition
        CPM_ADV_RN_CL = CPM_ADV_RN_CL + calc("CPM_ADV_RN:",Input,12)
 
        CPM_ADV_RC_TL = CPM_ADV_RC_TL + calc("CPM_ADV_RC:",Input,6)  'Password Manager Advanced edition concurrent user license edition
        CPM_ADV_RC_CL = CPM_ADV_RC_CL + calc("CPM_ADV_RC:",Input,12)
 
        CSS_ENT_CCU_TL = CSS_ENT_CCU_TL + calc("CSS_ENT_CCU:",Input,6)   'Application streaming to clients desktop license edition
        CSS_ENT_CCU_CL = CSS_ENT_CCU_CL + calc("CSS_ENT_CCU:",Input,12)
 
        CAS_ENT_CCU_TL = CAS_ENT_CCU_TL + calc("CAS_ENT_CCU:",Input,6)   'Application streaming license edition
        CAS_ENT_CCU_CL = CAS_ENT_CCU_CL + calc("CAS_ENT_CCU:",Input,12)
 
        CESEP_ENT_CCU_TL = CESEP_ENT_CCU_TL + calc("CESEP_ENT_CCU:",Input,6) 'Edgesight for endpoint license edition
        CESEP_ENT_CCU_CL = CESEP_ENT_CCU_CL + calc("CESEP_ENT_CCU:",Input,12)
 
        CESPS_ENT_CCU_TL = CESPS_ENT_CCU_TL + calc("CESPS_ENT_CCU:",Input,6) 'Edgesight for Presentation server license edition
        CESPS_ENT_CCU_CL = CESPS_ENT_CCU_CL + calc("CESPS_ENT_CCU:",Input,12)
 
        MPS_VDS_RN_TL = MPS_VDS_RN_TL + calc("MPS_VDS_RN:",Input,6)  'Citrix desktop server named user license edition
        MPS_VDS_RN_CL = MPS_VDS_RN_CL + calc("MPS_VDS_RN:",Input,12)
 
        MPS_GFXA_CCU_TL = MPS_GFXA_CCU_TL + calc("MPS_GFXA_CCU:",Input,6)    'Graphic extension for PS4 Adv license edition
        MPS_GFXA_CCU_CL = MPS_GFXA_CCU_CL + calc("MPS_GFXA_CCU:",Input,12)
 
        MPS_GFXE_CCU_TL = MPS_GFXE_CCU_TL + calc("MPS_GFXE_CCU:",Input,6)    'Graphic extension for PS4 Ent license edition
        MPS_GFXE_CCU_CL = MPS_GFXE_CCU_CL + calc("MPS_GFXE_CCU:",Input,12)
 
        ' Section Netscaler
        CNS_AAC_SERVER_TL = CNS_AAC_SERVER_TL + calc("CNS_AAC_SERVER:",Input,6)  'Netscaler Accelerator license edition
        CNS_AAC_SERVER_CL = CNS_AAC_SERVER_CL + calc("CNS_AAC_SERVER:",Input,12)
 
        CNS_SSE_SERVER_TL = CNS_SSE_SERVER_TL + calc("CNS_SSE_SERVER:",Input,6)  'Netscaler Switch Standard license edition
        CNS_SSE_SERVER_CL = CNS_SSE_SERVER_CL + calc("CNS_SSE_SERVER:",Input,12)
 
        CNS_SEE_SERVER_TL = CNS_SEE_SERVER_TL + calc("CNS_SEE_SERVER:",Input,6)  'Netscaler Switch Enterprise license edition
        CNS_SEE_SERVER_CL = CNS_SEE_SERVER_CL + calc("CNS_SEE_SERVER:",Input,12)
 
        CNS_AGEE_SERVER_TL = CNS_AGEE_SERVER_TL + calc("CNS_AGEE_SERVER:",Input,6)   'Netscaler Gateway Enterprise license edition
        CNS_AGEE_SERVER_CL = CNS_AGEE_SERVER_CL + calc("CNS_AGEE_SERVER:",Input,12)
 
        CNS_GSLB_SERVER_TL = CNS_GSLB_SERVER_TL + calc("CNS_GSLB_SERVER:",Input,6)   'Netscaler Global Server Load Balancing addon license edition
        CNS_GSLB_SERVER_CL = CNS_GSLB_SERVER_CL + calc("CNS_GSLB_SERVER:",Input,12)
 
        CNS_APPC_SERVER_TL = CNS_APPC_SERVER_TL + calc("CNS_APPC_SERVER:",Input,6)   'Netscaler AppCompress addon license edition
        CNS_APPC_SERVER_CL = CNS_APPC_SERVER_CL + calc("CNS_APPC_SERVER:",Input,12)
 
        CNS_APPF_SERVER_TL = CNS_APPF_SERVER_TL + calc("CNS_APPF_SERVER:",Input,6)   'Netscaler Application Firewall license edition
        CNS_APPF_SERVER_CL = CNS_APPF_SERVER_CL + calc("CNS_APPF_SERVER:",Input,12)
 
        CNS_APPCE_SERVER_TL = CNS_APPCE_SERVER_TL + calc("CNS_APPCE_SERVER:",Input,6)    'Netscaler AppCompressExtreme addon license edition
        CNS_APPCE_SERVER_CL = CNS_APPCE_SERVER_CL + calc("CNS_APPCE_SERVER:",Input,12)
         
        CNS_CACHE_SERVER_TL = CNS_CACHE_SERVER_TL + calc("CNS_CACHE_SERVER:",Input,6)    'Netscaler Cache addon license edition
        CNS_CACHE_SERVER_CL = CNS_CACHE_SERVER_CL + calc("CNS_CACHE_SERVER:",Input,12)
 
        CNS_PROXGSLB_SERVER_TL = CNS_PROXGSLB_SERVER_TL + calc("CNS_PROXGSLB_SERVER:",Input,6)   'Netscaler Proxy GSLB addon license edition
        CNS_PROXGSLB_SERVER_CL = CNS_PROXGSLB_SERVER_CL + calc("CNS_PROXGSLB_SERVER:",Input,12)
    end if
Loop
 
'Message text
message1 = ""
message1 = threshold(MPS_PLT_CCU_CL,MPS_PLT_CCU_TL,message1,"MPS_PLT_CCU")
message1 = threshold(MPS_ENT_CCU_CL,MPS_ENT_CCU_TL,message1,"MPS_ENT_CCU")
message1 = threshold(MPS_STD_CCU_CL,MPS_STD_CCU_TL,message1,"MPS_STD_CCU")
message1 = threshold(MPS_ADV_CCU_CL,MPS_ADV_CCU_TL,message1,"MPS_ADV_CCU")
message1 = threshold(MPS_SMB_RN_CL,MPS_SMB_RN_TL,message1,"MPS_SMB_RN")
message1 = threshold(CAG_SSLVPN_CCU_CL,CAG_SSLVPN_CCU_TL,message1,"CAG_SSLVPN_CCU")
message1 = threshold(CAG_AAC_CCU_CL,CAG_AAC_CCU_TL,message1,"CAG_AAC_CCU")
message1 = threshold(CNS_SSLVPN_CCU_CL,CNS_SSLVPN_CCU_TL,message1,"CNS_SSLVPN_CCU")
message1 = threshold(MPM_ADV_RC_CL,MPM_ADV_RC_TL,message1,"MPM_ADV_RC")
message1 = threshold(MPM_ADV_RN_CL,MPM_ADV_RN_TL,message1,"MPM_ADV_RN")
message1 = threshold(CPM_ENT_RC_CL,CPM_ENT_RC_TL,message1,"CPM_ENT_RC")
message1 = threshold(CPM_ENT_RN_CL,CPM_ENT_RN_TL,message1,"CPM_ENT_RN")
message1 = threshold(CPM_ADV_RN_CL,CPM_ADV_RN_TL,message1,"CPM_ADV_RN")
message1 = threshold(CPM_ADV_RC_CL,CPM_ADV_RC_TL,message1,"CPM_ADV_RC")
message1 = threshold(CSS_ENT_CCU_CL,CSS_ENT_CCU_TL,message1,"CSS_ENT_CCU")
message1 = threshold(CAS_ENT_CCU_CL,CAS_ENT_CCU_TL,message1,"CAS_ENT_CCU")
message1 = threshold(CESEP_ENT_CCU_CL,CESEP_ENT_CCU_TL,message1,"CESEP_ENT_CCU")
message1 = threshold(CESPS_ENT_CCU_CL,CESPS_ENT_CCU_TL,message1,"CESPS_ENT_CCU")
message1 = threshold(MPS_VDS_RN_CL,MPS_VDS_RN_TL,message1,"MPS_VDS_RN")
message1 = threshold(MPS_GFXA_CCU_CL,MPS_GFXA_CCU_TL,message1,"MPS_GFXA_CCU")
message1 = threshold(MPS_GFXE_CCU_CL,MPS_GFXE_CCU_TL,message1,"MPS_GFXE_CCU")
' Section Netscaler
message1 = threshold(CNS_AAC_SERVER_CL,CNS_AAC_SERVER_TL,message1,"CNS_AAC_SERVER")
message1 = threshold(CNS_SSE_SERVER_CL,CNS_SSE_SERVER_TL,message1,"CNS_SSE_SERVER")
message1 = threshold(CNS_SEE_SERVER_CL,CNS_SEE_SERVER_TL,message1,"CNS_SEE_SERVER")
message1 = threshold(CNS_AGEE_SERVER_CL,CNS_AGEE_SERVER_TL,message1,"CNS_AGEE_SERVER")
message1 = threshold(CNS_GSLB_SERVER_CL,CNS_GSLB_SERVER_TL,message1,"CNS_GSLB_SERVER")
message1 = threshold(CNS_APPC_SERVER_CL,CNS_APPC_SERVER_TL,message1,"CNS_APPC_SERVER")
message1 = threshold(CNS_APPF_SERVER_CL,CNS_APPF_SERVER_TL,message1,"CNS_APPF_SERVER")
message1 = threshold(CNS_APPCE_SERVER_CL,CNS_APPCE_SERVER_TL,message1,"CNS_APPCE_SERVER")
message1 = threshold(CNS_CACHE_SERVER_CL,CNS_CACHE_SERVER_TL,message1,"CNS_CACHE_SERVER")
message1 = threshold(CNS_PROXGSLB_SERVER_CL,CNS_PROXGSLB_SERVER_TL,message1,"CNS_PROXGSLB_SERVER")
 
'performance data
message2 = ""
message2 = sessions(MPS_PLT_CCU_CL,MPS_PLT_CCU_TL,message2,"MPS_PLT_CCU")
message2 = sessions(MPS_ENT_CCU_CL,MPS_ENT_CCU_TL,message2,"MPS_ENT_CCU")
message2 = sessions(MPS_STD_CCU_CL,MPS_STD_CCU_TL,message2,"MPS_STD_CCU")
message2 = sessions(MPS_ADV_CCU_CL,MPS_ADV_CCU_TL,message2,"MPS_ADV_CCU")
message2 = sessions(MPS_SMB_RN_CL,MPS_SMB_RN_TL,message2,"MPS_SMB_RN")
message2 = sessions(CAG_SSLVPN_CCU_CL,CAG_SSLVPN_CCU_TL,message2,"CAG_SSLVPN_CCU")
message2 = sessions(CAG_AAC_CCU_CL,CAG_AAC_CCU_TL,message2,"CAG_AAC_CCU")
message2 = sessions(CNS_SSLVPN_CCU_CL,CNS_SSLVPN_CCU_TL,message2,"CNS_SSLVPN_CCU")
message2 = sessions(MPM_ADV_RC_CL,MPM_ADV_RC_TL,message2,"MPM_ADV_RC")
message2 = sessions(MPM_ADV_RN_CL,MPM_ADV_RN_TL,message2,"MPM_ADV_RN")
message2 = sessions(CPM_ENT_RC_CL,CPM_ENT_RC_TL,message2,"CPM_ENT_RC")
message2 = sessions(CPM_ENT_RN_CL,CPM_ENT_RN_TL,message2,"CPM_ENT_RN")
message2 = sessions(CPM_ADV_RN_CL,CPM_ADV_RN_TL,message2,"CPM_ADV_RN")
message2 = sessions(CPM_ADV_RC_CL,CPM_ADV_RC_TL,message2,"CPM_ADV_RC")
message2 = sessions(CSS_ENT_CCU_CL,CSS_ENT_CCU_TL,message2,"CSS_ENT_CCU")
message2 = sessions(CAS_ENT_CCU_CL,CAS_ENT_CCU_TL,message2,"CAS_ENT_CCU")
message2 = sessions(CESEP_ENT_CCU_CL,CESEP_ENT_CCU_TL,message2,"CESEP_ENT_CCU")
message2 = sessions(CESPS_ENT_CCU_CL,CESPS_ENT_CCU_TL,message2,"CESPS_ENT_CCU")
message2 = sessions(MPS_VDS_RN_CL,MPS_VDS_RN_TL,message2,"MPS_VDS_RN")
message2 = sessions(MPS_GFXA_CCU_CL,MPS_GFXA_CCU_TL,message2,"MPS_GFXA_CCU")
message2 = sessions(MPS_GFXE_CCU_CL,MPS_GFXE_CCU_TL,message2,"MPS_GFXE_CCU")
' Section Netscaler
message2 = sessions(CNS_AAC_SERVER_CL,CNS_AAC_SERVER_TL,message2,"CNS_AAC_SERVER")
message2 = sessions(CNS_SSE_SERVER_CL,CNS_SSE_SERVER_TL,message2,"CNS_SSE_SERVER")
message2 = sessions(CNS_SEE_SERVER_CL,CNS_SEE_SERVER_TL,message2,"CNS_SEE_SERVER")
message2 = sessions(CNS_AGEE_SERVER_CL,CNS_AGEE_SERVER_TL,message2,"CNS_AGEE_SERVER")
message2 = sessions(CNS_GSLB_SERVER_CL,CNS_GSLB_SERVER_TL,message2,"CNS_GSLB_SERVER")
message2 = sessions(CNS_APPC_SERVER_CL,CNS_APPC_SERVER_TL,message2,"CNS_APPC_SERVER")
message2 = sessions(CNS_APPF_SERVER_CL,CNS_APPF_SERVER_TL,message2,"CNS_APPF_SERVER")
message2 = sessions(CNS_APPCE_SERVER_CL,CNS_APPCE_SERVER_TL,message2,"CNS_APPCE_SERVER")
message2 = sessions(CNS_CACHE_SERVER_CL,CNS_CACHE_SERVER_TL,message2,"CNS_CACHE_SERVER")
message2 = sessions(CNS_PROXGSLB_SERVER_CL,CNS_PROXGSLB_SERVER_TL,message2,"CNS_PROXGSLB_SERVER")
 


if (message1 = "") AND (message2 = "") then
    message = "OK: No licenses used."
else
    message = message1 & "|" & message2
end if
if licerror = 1 then
    message = "Error while parsing the license file. " & message
    if errorlevel < 1 then errorlevel = 3
end if
 
Wscript.StdOut.WriteLine errorstr & "Citrix licenses used: " & message
wscript.quit(errorlevel)

