B4A=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=11.2
@EndOfDesignText@
#DesignerProperty: Key: BooleanExample, DisplayName: Show Seconds, FieldType: Boolean, DefaultValue: True
#DesignerProperty: Key: TextColor, DisplayName: Text Color, FieldType: Color, DefaultValue: 0xFFFFFFFF, Description: Text color

Sub Class_Globals
	Private mEventName As String 'ignore
	Private mCallBack As Object 'ignore
	Public mBase As B4XView
	' pnlLayout is used to load xCLV
	Private pnlLayout As B4XView 
	Private clv1 As CustomListView
	Private objMapOfList As clsMapOfList
	Private Dialog As B4XDialog
	' pnlDialog is used to contain B4XDialog
	Private pnlDialog As B4XView
	' pnlInput is used to contain InputDialog
	Private pnlInput As B4XView
	Private edtHead, edtItem, edtQty As EditText
	Private sprHead As Spinner
	' OHead record the text before change
	Private edtOHead As EditText
	' OItem record the item before change
	Private edtOItem As EditText
	' OQty record the qty before change
	Private edtOQty As EditText
	Private lblHead As Label
	' bitmap for header and footer of clv1
	Private bmHeader, bmFooter, bmCollapsed As B4XBitmap
	Private xui As XUI 'ignore
	Public Tag As Object
	Private timer As Timer
End Sub

Public Sub Initialize (Callback As Object, EventName As String)
	mEventName = EventName
	mCallBack = Callback
	objMapOfList.Initialize(Me)
	' this panel is used to contain B4XDialog
	pnlDialog = xui.CreatePanel("")	
	Dialog.Initialize(pnlDialog)	
	timer.Initialize("timer", 100)
	If bmHeader.IsInitialized = False Then
		bmHeader = modCommon.getBitmap("H")
	End If
	If bmFooter.IsInitialized = False Then
		bmFooter = modCommon.getBitmap("F")
	End If
	If bmCollapsed.IsInitialized = False Then
		bmCollapsed = modCommon.getBitmap("C")
	End If
End Sub

'Base type must be Object
Public Sub DesignerCreateView (Base As Object, Lbl As Label, Props As Map)
	mBase = Base
    Tag = mBase.Tag
    mBase.Tag = Me 
  	' Dim clr As Int = xui.PaintOrColorToColor(Props.Get("TextColor")) 'Example of getting a color value from Props		
	Dim pnlParent As B4XView = mBase.Parent
	pnlLayout = xui.CreatePanel("")
	pnlInput = xui.CreatePanel("")
	pnlParent.AddView(pnlLayout, 0, 0, 100%x, 100%y)
	pnlParent.AddView(pnlDialog, 0, 0, 100%x, 100%y)
	pnlParent.AddView(pnlInput, 0, 0, 100%x, 100%y)
	CallSubDelayed(Me, "LoadPanelLayout")	
End Sub

Private Sub Base_Resize (Width As Double, Height As Double)
  
End Sub

Private Sub LoadPanelLayout
	pnlLayout.LoadLayout("clv.bal")
End Sub

Public Sub testCallback()
	objMapOfList.testCallback("getTestCallbackResponse")
End Sub

Public Sub LoadData()
	If clv1.IsInitialized = False Then
		Return
	End If
	clv1.Clear
	objMapOfList.ClearAll
	objMapOfList.FillTheMap2("getLoadDataResponse")
End Sub

Public Sub AddSingleData()
	If objMapOfList.IsInitialized = False Then
		Return
	End If
	' Dim p As B4XView = xui.CreatePanel("")
	pnlInput.SetLayoutAnimated(0, 0, 0, 250dip, 300dip) 'set the content size
	pnlInput.LoadLayout("InputBox.bal")
	sprHead.DropdownBackgroundColor = Colors.White
	sprHead.DropdownTextColor = Colors.Black
	sprHead.TextColor = Colors.Black
	edtHead.Visible = False
	Dim lstChoice As List = objMapOfList.HeaderList
	lstChoice.InsertAt(0, "choose...")
	lstChoice.Add("new head...")
	sprHead.AddAll(lstChoice)
	sprHead.SelectedIndex = 0
	Dim rs As ResumableSub = Dialog.ShowCustom(pnlInput, "Ok", "", "Cancel")
	Wait For (rs) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		If sprHead.SelectedIndex = 0 Then
			'choose...
			Return
		End If
		If edtItem.Text = "" Or IsNumber(edtQty.Text) = False Then
			Return
		End If
		If sprHead.SelectedIndex = sprHead.Size -1 And edtHead.Text <> "" Then
			'add new head
			objMapOfList.AddItem( _
				CreateMap( _
					"head": CreateMap("text": edtHead.Text), _
					"line": CreateMap("item": edtItem.Text, "qty": edtQty.Text) _
				) _
			)
		End If
		If sprHead.SelectedIndex <> sprHead.Size -1 Then
			'add to existing head
			objMapOfList.AddItem( _
				CreateMap( _
					"head": CreateMap("text": sprHead.SelectedItem), _
					"line": CreateMap("item": edtItem.Text, "qty": edtQty.Text) _
				) _
			)
		End If
	End If
End Sub

#Region EventHandlers
' Event handler of data loading
Sub getLoadDataResponse(mapRes As Map) 'ignore
	FillListView
End Sub

Sub getHeadAddedResponse(mapRes As Map) 'ignore
	Dim headid As Int = -1
	Dim lineid As Int = -1
	If mapRes.ContainsKey("headid") Then
		headid = mapRes.Get("headid")
	End If
	If mapRes.ContainsKey("lineid") Then
		lineid = mapRes.Get("lineid")
	End If
	If headid = -1 Or lineid = -1 Then
		Return
	End If
	Dim pnlHead As B4XView = xui.CreatePanel("")
	pnlHead.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 45dip)
	pnlHead.Tag = "Header"
	clv1.Add(pnlHead, "H_" & headid)
	Dim pnlLine As B4XView = xui.CreatePanel("")
	pnlLine.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 40dip)
	pnlLine.Tag = "Line"
	clv1.Add(pnlLine, $"L_${headid}_${lineid}"$)
	Dim pnlFoot As B4XView = xui.CreatePanel("")
	pnlFoot.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 45dip)
	pnlFoot.SetBitmap(bmFooter)
	pnlFoot.Tag = "Footer"
	clv1.Add(pnlFoot, "F_" & headid)
	timer.Enabled = True
	Wait For timer_tick
	timer.Enabled = False
	clv1.JumpToItem(clv1.Size-1)
End Sub

Sub getLineAddedResponse(mapRes As Map) 'ignore
	Dim headid As Int = -1
	Dim lineid As Int = -1
	If mapRes.ContainsKey("headid") Then
		headid = mapRes.Get("headid")
	End If
	If mapRes.ContainsKey("lineid") Then
		lineid = mapRes.Get("lineid")
	End If
	If headid = -1 Or lineid = -1 Then
		Return
	End If
	Dim pnlLine_1 As B4XView = xui.CreatePanel("")
	pnlLine_1.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 40dip)
	pnlLine_1.Tag = "Line"
	Dim pnlFoot_1 As B4XView = xui.CreatePanel("")
	pnlFoot_1.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 45dip)
	pnlFoot_1.Tag = "Footer"
	Dim currFootid As Int = FindCurrFootIndex(headid)
	If currFootid = -1 Then
		' impossible for block without footer
		Return
	End If
	LogIfIndexOutOfBound(195, currFootid)
	clv1.InsertAt(currFootid, pnlLine_1, $"L_${headid}_${lineid}"$)
	clv1.ReplaceAt(currFootid+1, pnlFoot_1, 45dip, "F_" & headid)
	timer.Enabled = True
	Wait For timer_tick
	timer.Enabled = False
	clv1.JumpToItem(currFootid)
	clv1.Refresh
End Sub

' Event handler of header get collapsed
Sub getCollapsedResponse(mapRes As Map) 'ignore
	Dim uiindex As Int = -1
	Dim count As Int = -1
	Dim headid As Int = -1
	If mapRes.ContainsKey("uiindex") Then
		uiindex = mapRes.Get("uiindex")
	End If
	If mapRes.ContainsKey("count") Then
		count = mapRes.Get("count")
	End If
	If mapRes.ContainsKey("headid") Then
		headid = mapRes.Get("headid")
	End If
	' hide the foot
	clv1.ResizeItem(uiindex + count + 1, 0dip)
	' hide lines
	Dim i As Int = 0
	For i = 0 To count -1
		clv1.ResizeItem(uiindex+i+1, 0dip)
	Next
	'refresh the head
	Dim pnlHead_1 As B4XView = xui.CreatePanel("")
	pnlHead_1.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 45dip)
	pnlHead_1.Tag = "Header"
	clv1.ReplaceAt(uiindex, pnlHead_1, 45dip, "H_" & headid)
	clv1.Refresh
End Sub
' Event handler of header get expanded
Sub getExpandedResponse(mapRes As Map) 'ignore
	Dim uiindex As Int = -1
	Dim count As Int = -1
	Dim headid As Int = -1	
	If mapRes.ContainsKey("uiindex") Then
		uiindex = mapRes.Get("uiindex")
	End If
	If mapRes.ContainsKey("count") Then
		count = mapRes.Get("count")
	End If
	If mapRes.ContainsKey("headid") Then
		headid = mapRes.Get("headid")
	End If	
	' show the foot
	clv1.ResizeItem(uiindex + count + 1, 45dip)
	' show lines
	Dim j As Int = 0
	For j = 0 To count -1
		clv1.ResizeItem(uiindex + j + 1, 40dip)
	Next
	'refresh the head
	Dim pnlHead_2 As B4XView = xui.CreatePanel("")
	pnlHead_2.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 45dip)
	pnlHead_2.Tag = "Header"
	clv1.ReplaceAt(uiindex, pnlHead_2, 45dip, "H_" & headid)
	clv1.Refresh
End Sub

Sub getHeadEditedResponse(mapRes As Map)
	Dim uiindex As Int = -1
	Dim headid As Int = -1
	If mapRes.ContainsKey("uiindex") Then
		uiindex = mapRes.Get("uiindex")
	End If
	If mapRes.ContainsKey("headid") Then
		headid = mapRes.Get("headid")
	End If
	Dim pnlHead As B4XView = xui.CreatePanel("")
	pnlHead.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 45dip)
	pnlHead.Tag = "Header"
	clv1.ReplaceAt(uiindex, pnlHead, 45dip, "H_" & headid)
	clv1.Refresh
End Sub

Sub getLineEditedResponse(mapRes As Map)
	Dim uiindex As Int = -1
	Dim headid As Int = -1
	Dim lineid As Int = -1
	If mapRes.ContainsKey("uiindex") Then
		uiindex = mapRes.Get("uiindex")
	End If
	If mapRes.ContainsKey("headid") Then
		headid = mapRes.Get("headid")
	End If
	If mapRes.ContainsKey("lineid") Then
		lineid = mapRes.Get("lineid")
	End If
	Dim pnlLine_2 As B4XView = xui.CreatePanel("")
	pnlLine_2.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 40dip)
	pnlLine_2.Tag = "Line"
	clv1.ReplaceAt(uiindex, pnlLine_2, 40dip, $"L_${headid}_${lineid}"$)
	Dim footidx_1 As Int = FindCurrFootIndex(headid)
	If footidx_1 = -1 Then
		Return
	End If
	Dim pnlFoot_2 As B4XView = xui.CreatePanel("")
	pnlFoot_2.SetLayoutAnimated(0,0,0,clv1.AsView.Width, 45dip)
	pnlFoot_2.Tag = "Footer"
	clv1.ReplaceAt(footidx_1, pnlFoot_2, 45dip, "F_" & headid)
	clv1.Refresh
End Sub

Sub getHeadDeletedResponse(mapRes As Map)
	Dim uiindex As Int = -1
	Dim count As Int = -1
	If mapRes.ContainsKey("uiindex") Then
		uiindex = mapRes.Get("uiindex")
	End If
	If mapRes.ContainsKey("count") Then
		count = mapRes.Get("count")
	End If
	' First, delete the footer
	clv1.RemoveAt(uiindex + count + 1)
	' Second, delete all children
	Dim j As Int = 0
	For j = count -1 To 0 Step -1
		Dim temp As String = clv1.GetValue(uiindex + j + 1)
		LogColor(temp, Colors.Blue)
		clv1.RemoveAt(uiindex + j + 1)
	Next
	' Third, delete the header
	LogIfIndexOutOfBound(325, uiindex)
	clv1.RemoveAt(uiindex)
	clv1.Refresh
End Sub

Sub getLineDeletedResponse(mapRes As Map)
	Dim uiindex As Int = -1
	Dim headid As Int = -1
	If mapRes.ContainsKey("uiindex") Then
		uiindex = mapRes.Get("uiindex")
	End If
	If mapRes.ContainsKey("headid") Then
		headid = mapRes.Get("headid")
	End If
	LogColor(clv1.GetValue(uiindex), Colors.Blue)
	Dim pnlFoot As B4XView = xui.CreatePanel("")
	pnlFoot.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 45dip)
	pnlFoot.Tag = "Footer"
	Dim footidx As Int = FindCurrFootIndex(headid)
	If footidx = -1 Then ' impossible for block without footer
		Return
	End If
	clv1.ReplaceAt(footidx, pnlFoot, 45dip, "F_" & headid)
	LogIfIndexOutOfBound(348, uiindex)
	clv1.RemoveAt(uiindex)
	clv1.Refresh
End Sub

Sub getLineExchangedResponse(mapRes As Map)
	Dim headid As Int = -1
	If mapRes.ContainsKey("headid") Then
		headid = mapRes.Get("headid")
	End If
	Dim oheadid As Int = -1
	If mapRes.ContainsKey("oheadid") Then
		oheadid = mapRes.Get("oheadid")
	End If
	Dim uiindex As Int = -1
	If mapRes.ContainsKey("uiindex") Then
		uiindex = mapRes.Get("uiindex")
	End If
	Try
		Select mapRes.Get("status")
			Case 0 ' Transfer in, Transfer out
				Dim pnlLine As B4XView = xui.CreatePanel("")
				pnlLine.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 40dip)
				pnlLine.Tag = "Line"
				'the lineid of value is kept and transfered
				Dim originalLineid As Int = UiindexToLineid(uiindex)
				If originalLineid = -1 Then
					Return
				End If
				Dim pnlFoot As B4XView = xui.CreatePanel("")
				pnlFoot.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 45dip)
				pnlFoot.Tag = "Footer"
				Dim pnlOFoot As B4XView = xui.CreatePanel("")
				pnlOFoot.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 45dip)
				pnlOFoot.Tag = "Footer"
				Dim value As String = $"L_${headid}_${originalLineid}"$
				Dim prevFootId As Int = FindCurrFootIndex(oheadid)
				Dim currFootid As Int = FindCurrFootIndex(headid)
				If currFootid = -1 Then
					Return
				End If
				If currFootid < uiindex Then
					' The larger index do first	i.e. uiindex do first
					LogIfIndexOutOfBound(391, uiindex)
					clv1.ReplaceAt(prevFootId, pnlOFoot, 45dip, "F_" & oheadid)
					clv1.RemoveAt(uiindex)
					LogIfIndexOutOfBound(394, currFootid)
					clv1.ReplaceAt(currFootid, pnlFoot, 45dip, "F_" & headid)
					clv1.InsertAt(currFootid, pnlLine, value)
				Else
					' The larger index do first	i.e. currFootid do first
					LogIfIndexOutOfBound(399, currFootid)
					clv1.ReplaceAt(currFootid, pnlFoot, 45dip, "F_" & headid)
					clv1.InsertAt(currFootid, pnlLine, value)
					LogIfIndexOutOfBound(402, uiindex)
					clv1.ReplaceAt(prevFootId, pnlOFoot, 45dip, "F_" & oheadid)
					clv1.RemoveAt(uiindex)
				End If
				clv1.Refresh
				timer.Enabled = True
				Wait For timer_tick
				timer.Enabled = False
				If currFootid > clv1.Size -1 Then
					currFootid = clv1.Size -1
				End If
				clv1.JumpToItem(currFootid)
			Case 1 ' Transfer in, delete
				Dim pnlLine_1 As B4XView = xui.CreatePanel("")
				pnlLine_1.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 40dip)
				pnlLine_1.Tag = "Line"
				'the lineid of value is kept and transfered
				Dim OLineid_1 As Int = UiindexToLineid(uiindex)
				If OLineid_1 = -1 Then
					Return
				End If
					
				Dim pnlFoot_1 As B4XView = xui.CreatePanel("")
				pnlFoot_1.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 45dip)
				pnlFoot_1.Tag = "Footer"
				Dim value_1 As String =  $"L_${headid}_${OLineid_1}"$
				Dim currFootid_1 As Int = FindCurrFootIndex(headid)
				If currFootid_1 = -1 Then
					Return
				End If
				If currFootid_1 < uiindex Then
					' The larger index do first i.e. uiindex do first
					LogIfIndexOutOfBound(434, uiindex+1)
					clv1.RemoveAt(uiindex+1) ' remove foot
					LogIfIndexOutOfBound(436, uiindex)
					clv1.RemoveAt(uiindex) 	 ' remove line
					LogIfIndexOutOfBound(438, uiindex-1)
					clv1.RemoveAt(uiindex-1) ' remove head
					LogIfIndexOutOfBound(440, currFootid_1)
					clv1.ReplaceAt(currFootid_1, pnlFoot_1, 45dip, "F_" & headid)
					clv1.InsertAt(currFootid_1, pnlLine_1, value_1)
				Else
					' The larger index do first i.e. currFootid do first
					clv1.ReplaceAt(currFootid_1, pnlFoot_1, 45dip, "F_" & headid)
					LogIfIndexOutOfBound(446, currFootid_1)
					clv1.InsertAt(currFootid_1, pnlLine_1, value_1)
					LogIfIndexOutOfBound(448, uiindex+1)
					clv1.RemoveAt(uiindex+1) ' remove foot
					LogIfIndexOutOfBound(450, uiindex)
					clv1.RemoveAt(uiindex) 	 ' remove line
					LogIfIndexOutOfBound(452, uiindex-1)
					clv1.RemoveAt(uiindex-1) ' remove head
				End If
				clv1.Refresh
				timer.Enabled = True
				Wait For timer_tick
				timer.Enabled = False
				If currFootid_1 > clv1.Size -1 Then
					currFootid_1 = clv1.Size -1
				End If
				clv1.JumpToItem(currFootid_1)
			Case 2 ' insert, transfer out
				Dim pnlHead_2 As B4XView = xui.CreatePanel("")
				pnlHead_2.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 45dip)
				pnlHead_2.SetBitmap(bmHeader)
				pnlHead_2.Tag = "Header"
				Dim pnlLine_2 As B4XView = xui.CreatePanel("")
				pnlLine_2.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 40dip)
				pnlLine_2.Tag = "Line"
				Dim pnlFoot_2 As B4XView = xui.CreatePanel("")
				pnlFoot_2.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 45dip)
				pnlFoot_2.SetBitmap(bmFooter)
				pnlFoot_2.Tag = "Footer"
				Dim pnlOFoot_2 As B4XView = xui.CreatePanel("")
				pnlOFoot_2.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 45dip)
				pnlOFoot_2.SetBitmap(bmFooter)
				pnlOFoot_2.Tag = "Footer"
				'the lineid of value is kept and transfered
				Dim OLineid_2 As Int = UiindexToLineid(uiindex)
				If OLineid_2 = -1 Then
					Return
				End If
				' Must add before delete
				Dim value_2 As String = $"L_${headid}_${OLineid_2}"$
				Dim prevFootId_2 As Int = FindCurrFootIndex(oheadid)
				clv1.Add(pnlHead_2, "H_" & headid)
				clv1.Add(pnlLine_2, value_2)
				clv1.Add(pnlFoot_2, "F_" & headid)
				LogIfIndexOutOfBound(490, uiindex)
				clv1.ReplaceAt(prevFootId_2, pnlOFoot_2, 45dip, "F_" & oheadid)
				clv1.RemoveAt(uiindex) 	 ' remove line
				timer.Enabled = True
				Wait For timer_tick
				timer.Enabled = False
				clv1.JumpToItem(clv1.Size-1)
			Case 3 ' insert, delete
				Dim pnlHead_3 As B4XView = xui.CreatePanel("")
				pnlHead_3.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 45dip)
				pnlHead_3.SetBitmap(bmHeader)
				pnlHead_3.Tag = "Header"
				Dim pnlLine_3 As B4XView = xui.CreatePanel("")
				pnlLine_3.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 40dip)
				pnlLine_3.Tag = "Line"
				Dim pnlFoot_3 As B4XView = xui.CreatePanel("")
				pnlFoot_3.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 45dip)
				pnlFoot_3.SetBitmap(bmFooter)
				pnlFoot_3.Tag = "Footer"
				'the lineid of value is kept and transfered
				Dim OLineid_3 As Int = UiindexToLineid(uiindex)
				If OLineid_3 = -1 Then
					Return
				End If
				' Must add before delete
				Dim value_3 As String = $"L_${headid}_${OLineid_3}"$
				clv1.Add(pnlHead_3, "H_" & headid)
				clv1.Add(pnlLine_3, value_3)
				clv1.Add(pnlFoot_3, "F_" & headid)
				LogIfIndexOutOfBound(519, uiindex+1)
				clv1.RemoveAt(uiindex+1) ' remove foot
				LogIfIndexOutOfBound(521, uiindex)
				clv1.RemoveAt(uiindex) 	 ' remove line
				LogIfIndexOutOfBound(523, uiindex-1)
				clv1.RemoveAt(uiindex-1) ' remove head
				timer.Enabled = True
				Wait For timer_tick
				timer.Enabled = False
				clv1.JumpToItem(clv1.Size-1)
			Case Else
				Return
		End Select
	Catch
		Dim errmsg As String = "ExchangedHandler: " & LastException.Message
		LogColor(errmsg, Colors.red)
		ToastMessageShow(errmsg, True)
	End Try
End Sub

#End Region

Private Sub clv1_VisibleRangeChanged (FirstIndex As Int, LastIndex As Int)
	Dim ExtraSize As Int = 18 'Extra Size MUST cover the whole screen + extra 2 rows in case of head add or exchange
	
	For i = 0 To clv1.Size - 1
		Dim pnl_1 As B4XView = clv1.GetPanel(i)
		If i > FirstIndex - ExtraSize And i < LastIndex + ExtraSize Then
			'Visible +
			If pnl_1.NumberOfViews = 0 Then
				Dim value() As String = Regex.Split("\_", clv1.GetValue(i))
				Dim valOne As Int = value(1)
				Select value(0)
					Case "H"
						If objMapOfList.mapHeader.ContainsKey(valOne) Then
							Dim mapEntry1 As Map = objMapOfList.mapHeader.Get(valOne)
							Dim myTitle As String = mapEntry1.Get("text")
							Dim isExpanded As Boolean = False
							If objMapOfList.IsInitialized Then
								isExpanded = objMapOfList.isHeadExpanded(valOne)
							End If
							EquipHeaderPanel(pnl_1, "HEADER #" & valOne & " " & myTitle, isExpanded)
							If isExpanded Then
								' Refresh the Footer when expanded
								Dim itsfootid As Int = FindCurrFootIndex(valOne)
								Dim pnl_footer As B4XView = clv1.GetPanel(itsfootid)
								Dim summary As String = $"Count: ${objMapOfList.mapCount.get(valOne)}; Sum: ${objMapOfList.mapSum.get(valOne)}"$
								EquipFooterPanel(pnl_footer, "FOOTER #" & valOne & "; " & summary)
							End If
						End If
					Case "L"
						Dim valTwo As Int = value(2)
						If objMapOfList.mapLine.ContainsKey(valTwo) Then
							Dim mapEntry2 As Map = objMapOfList.mapLine.Get(valTwo)
							Dim myQty As Int = mapEntry2.Get("qty")
							Dim myItem As String = mapEntry2.Get("item")
							EquipItemPanel(pnl_1, "LINE #" & valTwo & " " & myItem, myQty, 40dip)
						End If
					Case "F"
						If objMapOfList.mapHeader.ContainsKey(valOne) Then
							Dim summary_1 As String = $"Count: ${objMapOfList.mapCount.get(valOne)}; Sum: ${objMapOfList.mapSum.get(valOne)}"$
							EquipFooterPanel(pnl_1, "FOOTER #" & valOne & "; " & summary_1)
						End If
					Case Else
						Continue
				End Select
			End If
		End If
	Next
End Sub

Private Sub clv1_ItemClick (Index As Int, Value As Object)
	Log("Value: " & Value)
	If objMapOfList.IsInitialized = False Then
		Return
	End If
	Dim arrVal() As String = Regex.Split("\_", Value)
	
	Select arrVal(0)
		Case "H"
			Dim head_id As Int = arrVal(1)
			If objMapOfList.isHeadExpanded(head_id) Then
				objMapOfList.collapseHead(head_id, Index, "getCollapsedResponse")
			Else
				objMapOfList.expandHead(head_id, Index, "getExpandedResponse")
			End If
		Case "F"
			' Nothing to do
		Case "L"
			Dim str As String = objMapOfList.getContent(Value)
			Dim arr() As String = Regex.Split("\^", str)
			If arr.Length = 2 Then
				Dim msg1 As String = $"Index: ${Index}${CRLF}Value: ${Value}${CRLF}Item: ${arrVal(0)}${CRLF}Qty: ${arr(1)}"$
				Log("ItemClick (Line) - " & CRLF & msg1.Replace(CRLF, "; "))
				Msgbox2Async(msg1, "Line Info", "OK", "", "", Null, True)
			End If
	End Select
End Sub

Private Sub clv1_ItemLongClick (Index As Int, Value As Object)
	'Type conversion
	Dim strTemp As String = Value
	Dim arrTemp() As String = Regex.Split("\_", strTemp)
	Dim tagtype As String = arrTemp(0)
	If tagtype <> "H" And tagtype <> "L" Then
		Return
	End If
	'Type conversion
	Dim head_id As Int = arrTemp(1)
	Dim lstMenu As List
	If tagtype = "H" Then ' e.g. H_1
		lstMenu.Initialize2(Array As String("headinfo", "edit", "delete", "cancel"))
	End If
	If tagtype = "L" Then ' e.g. L_2_3
		lstMenu.Initialize2(Array As String("edit", "delete", "exchange", "cancel"))
	End If
	
	Select modCommon.popupMenu2(lstMenu)
		Case "headinfo"
			Dim str As String = objMapOfList.getContent(Value)
			Dim msg As String = $"Index: ${Index}${CRLF}Value: ${Value}${CRLF}Text: ${str}"$
			Log("ItemClick (Head) - " & CRLF & msg.Replace(CRLF, "; "))
			Msgbox2Async(msg, "Head Info", "OK", "", "", Null, True)
		Case "edit"
			If tagtype = "H" Then
				editHead(Index, arrTemp(1))
				Return
			End If
			If tagtype = "L" Then
				editLine(Index, arrTemp(1), arrTemp(2))
				Return
			End If
		Case "delete"
			If tagtype = "H" Then
				objMapOfList.setUIIndex(Index)
				'arrTemp(1) is header id
				objMapOfList.DeleteHeader(arrTemp(1))
				Return
			End If
			If tagtype = "L" Then
				objMapOfList.setUIIndex(Index)
				'arrTemp(1) is item's header id
				'arrTemp(2) is item id
				objMapOfList.DeleteItem(arrTemp(1), arrTemp(2))
				Return
			End If
		Case "exchange"
			exchangeLine(Index, head_id, arrTemp(2))
		Case "cancel"
			Return
		Case Else
			Return
	End Select
End Sub

Private Sub clv1_ReachEnd
	
End Sub

Private Sub clv1_ScrollChanged (Offset As Int)
	
End Sub

Sub FillListView()
	If objMapOfList.IsInitialized = False Then
		Return
	End If
	For Each key_1 As Int In objMapOfList.mapOne.Keys
		Dim lstTmp As List = objMapOfList.mapOne.Get(key_1)
		If lstTmp.IsInitialized = False Then
			Continue
		End If
		Dim pnlHead As B4XView = xui.CreatePanel("")
		pnlHead.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 45dip)
		pnlHead.Tag = "Header"
		clv1.Add(pnlHead, "H_" & key_1)
		For Each entry_1 As Int In lstTmp
			Dim pnlLine As B4XView = xui.CreatePanel("")
			pnlLine.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 40dip)
			pnlLine.Tag = "Line"
			clv1.Add(pnlLine, $"L_${key_1}_${entry_1}"$)
		Next
		Dim pnlFoot As B4XView = xui.CreatePanel("")
		pnlFoot.SetLayoutAnimated(0, 0, 0, clv1.AsView.Width, 45dip)
		pnlFoot.Tag = "Footer"
		clv1.Add(pnlFoot, "F_" & key_1)
	Next
End Sub

' Pass panel as Reference
Sub EquipItemPanel(pItem As Panel, Text As String, Text2 As String, Height As Int)
	
	Dim lbl As Label
	lbl.Initialize("")
	lbl.Gravity = Bit.Or(Gravity.CENTER_VERTICAL, Gravity.LEFT)
	lbl.Text = Text
	lbl.TextSize = 16
	lbl.TextColor = Colors.Black
	Dim lbl2 As Label
	lbl2.Initialize("")
	lbl2.Gravity = Bit.Or(Gravity.CENTER_VERTICAL, Gravity.LEFT)
	lbl2.TextSize = 16
	lbl2.TextColor = Colors.Black
	lbl2.Text = Text2
	pItem.AddView(lbl, 15dip, 2dip, 150dip, Height - 4dip) 'view #0
	pItem.AddView(lbl2, 280dip, 2dip, 50dip, Height - 4dip) 'view #2
End Sub
' Pass panel as Reference
Sub EquipHeaderPanel(pHeader As B4XView, Text As String, isExpanded As Boolean)
	
	pHeader.Color = Colors.DarkGray

	Dim lbl As Label : lbl.Initialize("")
	lbl.Gravity = Bit.Or(Gravity.CENTER_VERTICAL, Gravity.CENTER_HORIZONTAL)
	lbl.Text = Text
	lbl.TextSize = 16
	lbl.Typeface = Typeface.DEFAULT_BOLD
	lbl.TextColor = Colors.White
	Dim lbl1 As Label : lbl1.Initialize("")
	lbl1.Gravity = Bit.Or(Gravity.CENTER_VERTICAL, Gravity.RIGHT)
	If isExpanded Then
		lbl1.Text = modCommon.UTS(0x1F53A) ' ^
		pHeader.SetBitmap(bmHeader)
	Else
		lbl1.Text = modCommon.UTS(0x1F53B) ' v
		pHeader.SetBitmap(bmCollapsed)
	End If
	pHeader.AddView(lbl, 5dip, 2dip, 320dip, 45dip)
	pHeader.AddView(lbl1, 280dip, 2dip, 20dip, 45dip)
End Sub
' Pass panel as Reference
Sub EquipFooterPanel(pFooter As B4XView, Text As String)
	
	pFooter.Color = Colors.Gray
	pFooter.SetBitmap(bmFooter)
	Dim lbl As Label : lbl.Initialize("")
	lbl.Gravity = Bit.Or(Gravity.TOP, Gravity.CENTER_HORIZONTAL)
	lbl.Text = Text
	lbl.TextSize = 16
	lbl.Typeface = Typeface.DEFAULT_BOLD
	lbl.TextColor = Colors.White
	Dim lbl1 As Label : lbl1.Initialize("")
	lbl1.Gravity = Bit.Or(Gravity.CENTER_VERTICAL, Gravity.RIGHT)
	pFooter.RemoveAllViews
	pFooter.AddView(lbl, 5dip, 2dip, 320dip, 45dip)
	pFooter.AddView(lbl1, 280dip, 2dip, 20dip, 45dip)
End Sub

' return index of current block's footer by giving headid
Private Sub FindCurrFootIndex(headid As Int) As Int
	Dim idx_1 As Int = -1
	Dim i As Int = 0
	For i = 0 To clv1.Size-1
		If clv1.GetValue(i) = "H_" & headid Then
			idx_1 = i
			Exit
		End If
	Next
	If idx_1 = -1 Then
		Return -1
	End If
	Dim idx_2 As Int = -1
	Dim j As Int = 0
	For j = idx_1 + 1 To clv1.Size -1
		Dim tempvalue As String = clv1.GetValue(j)
		If tempvalue.SubString2(0, 1) = "F" Then
			idx_2 = j
			Exit
		End If
	Next
	Return idx_2
End Sub

Private Sub editHead(idx As Int, headid As Int)
	If objMapOfList.IsInitialized = False Then
		Return
	End If
	Dim text As String = objMapOfList.getTextByHeadId(headid)
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, 250dip, 90dip) 'set the content size
	p.LoadLayout("EditHead.bal")
	edtOHead.Visible = False
	edtOHead.Text = text
	edtHead.Visible = True
	edtHead.Text = text
	timer.Enabled = True
	Wait For timer_Tick
	timer.Enabled = False
	edtHead.RequestFocus
	edtHead.SelectAll
	Dim rs As ResumableSub = Dialog.ShowCustom(p, "Ok", "", "Cancel")
	Wait For (rs) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		If edtOHead.Text = edtHead.Text Then
			' No Change
			Return
		End If
		If edtHead.Text = "" Then
			Return
		End If
		objMapOfList.setUIIndex(idx)
		objMapOfList.EditHead( _
			CreateMap( _
				"head": CreateMap("headid": headid, "otext": edtOHead.Text, "text": edtHead.Text) _
			) _
		)		
	End If
End Sub

Private Sub editLine(idx As Int, headid As Int, lineid As Int)
	If objMapOfList.IsInitialized = False Then
		Return
	End If
	Dim text_1 As String = objMapOfList.getTextByHeadId(headid)
	Dim item_1 As String = objMapOfList.getItemByLineId(lineid)
	Dim qty_1 As Int = objMapOfList.getQtyByLineId(lineid)
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, 250dip, 220dip) 'set the content size
	p.LoadLayout("EditLine.bal")
	'edtHead.Text = text_1
	'edtHead.Enabled = False
	lblHead.Text = text_1
	edtOItem.Text = item_1
	edtItem.Text = item_1
	edtOQty.Text = qty_1
	edtQty.Text = qty_1
	timer.Enabled = True
	Wait For timer_Tick
	timer.Enabled = False
	edtItem.RequestFocus
	edtItem.SelectAll
	Dim rs As ResumableSub = Dialog.ShowCustom(p, "Ok", "", "Cancel")
	Wait For (rs) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		If edtOItem.Text = edtItem.Text And edtOQty.Text = edtQty.Text Then
			'No Change
			Return
		End If
		If edtItem.Text = "" Or IsNumber(edtQty.Text) = False Then
			Return
		End If
		objMapOfList.setUIIndex(idx)
		objMapOfList.EditLine( _
			CreateMap( _
				"line": CreateMap("headid": headid, "lineid": lineid, "oitem": edtOItem.Text, "item": edtItem.Text, _
					"oqty": edtOQty.Text, "qty": edtQty.Text) _
			) _
		)
	End If
End Sub

Private Sub exchangeLine(idx As Int, headid As Int, lineid As Int)
	If objMapOfList.IsInitialized = False Then
		Return
	End If
	Dim text_1 As String = objMapOfList.getTextByHeadId(headid)
	Dim p As B4XView = xui.CreatePanel("")
	p.SetLayoutAnimated(0, 0, 0, 250dip, 300dip) 'set the content size
	p.LoadLayout("ExchangeLine.bal")
	sprHead.DropdownBackgroundColor = Colors.White
	sprHead.DropdownTextColor = Colors.Black
	sprHead.TextColor = Colors.Black
	edtHead.Visible = False
	Dim lstChoice As List = objMapOfList.HeaderList
	Dim foundidx As Int = lstChoice.IndexOf(text_1)
	If foundidx > -1 Then
		lstChoice.RemoveAt(foundidx)
	End If
	lstChoice.InsertAt(0, "choose...")
	lstChoice.Add("new head...")
	sprHead.AddAll(lstChoice)
	sprHead.SelectedIndex = 0
	lblHead.Text = text_1
	Dim rs As ResumableSub = Dialog.ShowCustom(p, "Ok", "", "Cancel")
	Wait For (rs) Complete (Result As Int)
	If Result = xui.DialogResponse_Positive Then
		If sprHead.SelectedIndex = 0 Then
			Return
		End If
		If sprHead.SelectedIndex = sprHead.Size -1 And edtHead.Text = "" Then
			Return
		End If
		If sprHead.SelectedIndex = sprHead.Size -1 Then
			objMapOfList.exchangeLine(headid, edtHead.Text, lineid, idx)
		Else
			objMapOfList.exchangeLine(headid, sprHead.SelectedItem, lineid, idx)
		End If
	End If
End Sub

Private Sub UiindexToLineid(uiindex As Int) As Int
	Dim value As String = clv1.GetValue(uiindex)
	Dim arr() As String = Regex.Split("\_", value)
	If arr.Length <> 3 Then
		Return -1
	End If
	Return arr(2)
End Sub

Private Sub sprHead_ItemClick (Position As Int, Value As Object)	
	If Position = sprHead.Size - 1 Then 'new item
		edtHead.Visible = True
	Else
		edtHead.Visible = False
	End If
	timer.Enabled = True
	Wait For timer_Tick
	timer.Enabled = False
	edtHead.Text = ""
	edtHead.RequestFocus
	edtHead.SelectAll
End Sub

Private Sub LogIfIndexOutOfBound(whichline As Int, idx As Int)
	If clv1.IsInitialized = False Then
		Return
	End If
	If idx >= clv1.Size Then
		Dim err As String = "Which line: " & whichline & CRLF & _
			"Index: " & idx & CRLF & _
			"clv1 size: " & clv1.Size
		LogColor(err, Colors.Red)
		Msgbox2Async(err, "IndexOutOfBound", "OK", "", "", Null, True)
	End If
End Sub