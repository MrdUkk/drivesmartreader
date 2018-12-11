'====================================================================================================
'
'            HDD SMART XML TO WMI SCRIPT FOR SCCM 2007/2012 by dUkk   (c) 2014
'
'====================================================================================================

Set objArgs = WScript.Arguments

'with no params it should create our custom namespace and give domain users write permissions on it
if objArgs.Count < 1 Then
   WScript.Echo "running in Admin mode, creating namespace and class..."
   set objWMIService = GetObject("winmgmts:\\.\root")
   set objItem = objWMIService.Get("__Namespace")
   set objNamespace = objItem.SpawnInstance_
   objNamespace.Name = "MYCustomNS"
   objNamespace.Put_

   'wmic /namespace:\\root\MyCustomNS path __systemsecurity call getSD
   'allow Domain users to write instances in this NS
   strSD = array(1, 0, 4, 129, 232, 0, 0, 0, 248, 0, 0, 0, 0, 0, 0, 0, 20, 0, 0, 0, 2, 0, 212, 0, 9, 0, 0, 0, 0, 2, 20, 0, 19, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 5, 11, 0, 0, 0, 0, 2, 20, 0, 19, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 5, 19, 0, 0, 0, 0, 2, 20, 0, 19, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 5, 20, 0, 0, 0, 0, 0, 36, 0, 11, 0, 0, 0, 1, 5, 0, 0, 0, 0, 0, 5, 21, 0, 0, 0, 250, 13, 219, 122, 190, 15, 50, 39, 91, 31, 2, 51, 1, 2, 0, 0, 0, 2, 24, 0, 63, 0, 6, 0, 1, 2, 0, 0, 0, 0, 0, 5, 32, 0, 0, 0, 32, 2, 0, 0, 0, 18, 24, 0, 63, 0, 6, 0, 1, 2, 0, 0, 0, 0, 0, 5, 32, 0, 0, 0, 32, 2, 0, 0, 0, 18, 20, 0, 19, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 5, 20, 0, 0, 0, 0, 18, 20, 0, 19, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 5, 19, 0, 0, 0, 0, 18, 20, 0, 19, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 5, 11, 0, 0, 0, 1, 2, 0, 0, 0, 0, 0, 5, 32, 0, 0, 0, 32, 2, 0, 0, 1, 2, 0, 0, 0, 0, 0, 5, 32, 0, 0, 0, 32, 2, 0, 0)
   Set WbemServices = CreateObject("Wbemscripting.SWbemlocator").ConnectServer(,"root\MYCustomNS")
   Set security = WbemServices.get("__systemsecurity=@")
   security.setsd(strSD)

   'Set loc = CreateObject("WbemScripting.SWbemLocator")
   'Set WbemServices = loc.ConnectServer(, "root\MYCustomNS")

   On Error Resume Next
   Set WbemObject = WbemServices.Get("DiskSMARTInfo")
   If Err Then
      On Error Goto 0
      Set WbemObject = WbemServices.Get
      WbemObject.Path_.Class = "DiskSMARTInfo"
      WbemObject.Properties_.Add "Item", 19
      WbemObject.Properties_.Add "DiskID", 19
      WbemObject.Properties_.Add "Model", 8
      WbemObject.Properties_.Add "Serial", 8
      WbemObject.Properties_.Add "AttrName", 8
      WbemObject.Properties_.Add "AttrValue", 19
      WbemObject.Properties_.Add "AttrWorst", 19
      WbemObject.Properties_.Add "AttrRaw", 19
      WbemObject.Properties_.Add "AttrTreshold", 19

      WbemObject.Properties_("Item").Qualifiers_.Add "key", True
      WbemObject.Put_
   End if

   WScript.Echo "now run in user context with command line: cscript.exe storages.vbs user"
   WScript.Quit(0)

'with some params: we should inventory hdds and write to our namespace gathered info
Else
   Set WbemServices = CreateObject("Wbemscripting.SWbemlocator").ConnectServer(,"root\MYCustomNS")

   For Each obj In WbemServices.Get("DiskSMARTInfo").Instances_
       WScript.Echo "Dropping old store key " & obj.Item
           obj.Delete_
   Next

   On Error Resume Next

   Set objXMLDoc = CreateObject("Microsoft.XMLDOM")
   objXMLDoc.async = False
   objXMLDoc.ValidateOnParse = False
   IF objXMLDoc.load(objArgs(0)) THEN
      WScript.Echo "XML Loaded success"
   ELSE
      WScript.Echo "XML Load ERROR#: " & objXMLDoc.parseError.errorCode & ": " & objXMLDoc.parseError.reason
        '"Line #: " & .Line & vbCrLf & _
       ' "Line Position: " & .linepos & vbCrLf & _
      '  "Position In File: " & .filepos & vbCrLf & _
     '   "Source Text: " & .srcText & vbCrLf
          WScript.Quit(-1)
   END IF

   Set Root = objXMLDoc.documentElement

   CurKey = 0
   Set objNodes = Root.selectNodes("/smart/drive")
   For Each objNode In objNodes

    For Each subNode In objNode.childNodes

        Set WbemObject = WbemServices.Get("DiskSMARTInfo").SpawnInstance_
        WbemObject.Item = CurKey
        WbemObject.DiskID = objNode.getAttribute("id")
        WbemObject.Model = objNode.getAttribute("model")
        WbemObject.Serial = objNode.getAttribute("serial")
        WbemObject.AttrName = subNode.getAttribute("name")
        WbemObject.AttrValue = subNode.getAttribute("value")
        WbemObject.AttrWorst = subNode.getAttribute("worst")
        WbemObject.AttrRaw = subNode.getAttribute("raw")
        WbemObject.AttrTreshold = subNode.getAttribute("treshold")

        WbemObject.Put_
        CurKey = CurKey + 1
    Next


   Next

   WScript.Echo "storages iventory done"

End If

WScript.Quit(0)
