﻿<%
Class YT_Table
	Function List()
		Dim aryFileList
		Dim t(),j,i,s
		aryFileList=LoadIncludeFiles("ZB_USERS/THEME/"&ZC_BLOG_THEME&"/DATA/")
		If IsArray(aryFileList) Then
			If UBound(aryFileList) >= 2 Then
				Redim t(-1)
				j=UBound(t)+1
				ReDim Preserve t(j)
				t(j)="blog_Category.xml"
				j=UBound(t)+1
				ReDim Preserve t(j)
				t(j)="blog_Article.xml"
			End If
			For i = 1 to UBound(aryFileList)
				s = aryFileList(i)
				If Right(s,3)="xml" Then
					If s <> "blog_Category.xml" And s <> "blog_Article.xml" Then
						j=UBound(t)+1
						ReDim Preserve t(j)
						t(j)=aryFileList(i)
					End If
				End If
			Next
		End If
		List = t
	End Function
	Function Import(t)
		Dim x,d,b:b = false
			d=BlogPath&"ZB_USERS/THEME/"&ZC_BLOG_THEME&"/DATA/"&t
		Set x=CreateObject("Microsoft.XMLDOM")
			x.async=False
			x.ValidateOnParse=False
			x.load(d)
			If x.readyState=4 Then
				If x.parseError.errorCode=0 Then
					Dim n,s,r,j,k,w,l,a,e
					Dim Field(),Value()
					Dim sql,sql2,sql3,T4(),T2(),T5()
						t = Left(t,InStrRev(t,".")-1)
						If Exist(t) Then
							Redim T4(-1):Redim T5(-1):a = 0
							objConn.Execute("DELETE FROM "&t)
							For Each n In x.selectNodes("//"&t)
								Redim T2(-1)
								sql = "INSERT INTO [@TABLE](@FIELDS) VALUES (@VALUE)"
								Set r = objConn.Execute("SELECT TOP 1 * FROM "&t)
									For Each k In r.Fields
										w = UBound(T2)+1
										ReDim Preserve T2(w)
										T2(w)="{name:'"&k.name&"',type:"&k.type&",auto:"&LCase(k.properties("ISAUTOINCREMENT"))&"}"
									Next
								Set r = Nothing
								Redim Field(-1)
								Redim Value(-1)
								For s = 0 To n.childNodes.length-1
									If s > Ubound(T2) Then Exit For
									Dim obj:Set obj=YT.eval(T2(s))
									If obj.auto Then
										If UBound(T4) = -1 Then
											If t = "blog_Category" Or t = "blog_Article" Then
												sql2 = "ALTER TABLE ["&t&"] ALTER COLUMN ["&obj.name&"] COUNTER (1, 1)"
												objConn.Execute(sql2)
											End If
										End If
										l = UBound(T4)+1
										ReDim Preserve T4(l)
										T4(l) = Array(n.childNodes(s).Text,a+1)
									End If
									If obj.auto = false Then
										If n.getElementsByTagName(obj.name).length > 0 Then
											j = UBound(Field)+1
											ReDim Preserve Field(j)
											ReDim Preserve Value(j)
											If obj.name = "cate_ParentID" Then
												If Int(T4(l)(1)) <> Int(T4(l)(0)) Then 
													e = UBound(T5)+1
													ReDim Preserve T5(e)
													T5(e) = "UPDATE ["&t&"] SET [cate_ParentID] = "&T4(l)(1)&" WHERE [cate_ParentID] = "&T4(l)(0)
												End If
											End If
											Field(j) = "["&n.childNodes(s).nodeName&"]"
											Value(j) = "'"&n.childNodes(s).Text&"'"
											If obj.type = 7 Then
												Value(j) = Replace(Value(j),"T"," ")
												If Not isDate(Replace(Value(j),CHR(39),Empty)) Then Value(j) = Now()
											End If
										End If
									End If
								Next
								sql=Replace(sql,"@TABLE",t)
								sql=Replace(sql,"@FIELDS",Join(Field,","))
								sql=Replace(sql,"@VALUE",Join(Value,","))
								objConn.Execute(sql)
								a = a + 1
							Next
							If UBound(T5) <> -1 Then
								For Each sql3 In T5
									objConn.Execute(sql3)
								Next
							End If
							If UBound(T4) <> -1 Then
								Dim sl,sl2,sb
								If t = "blog_Category" Then
									'更新DATA目录下XML中的log_CateID
									For Each sl In List
										If sl <> "blog_Category.xml" Then
											sl2 = LoadFromFile(BlogPath&"ZB_USERS/THEME/"&ZC_BLOG_THEME&"/DATA/"&sl,"utf-8")
											For Each sb In T4
												sl2 = Replace(sl2,"<log_CateID>"&sb(0)&"</log_CateID>","<log_CateID>"&sb(1)&"</log_CateID>")
											Next
											Call SaveToFile(BlogPath&"ZB_USERS/THEME/"&ZC_BLOG_THEME&"/DATA/"&sl,sl2,"utf-8",False)
										End If
									Next
								Else
									'更新DATA目录下XML中的log_ID
									For Each sl In List
										If sl <> "blog_Article.xml" Then
											sl2 = LoadFromFile(BlogPath&"ZB_USERS/THEME/"&ZC_BLOG_THEME&"/DATA/"&sl,"utf-8")
											For Each sb In T4
												sl2 = Replace(sl2,"<log_ID>"&sb(0)&"</log_ID>","<log_ID>"&sb(1)&"</log_ID>")
											Next
											Call SaveToFile(BlogPath&"ZB_USERS/THEME/"&ZC_BLOG_THEME&"/DATA/"&sl,sl2,"utf-8",False)
										End If
									Next
								End If
							End If
						End If
					b = true
				End If
			End If
		Set x=Nothing
		Import = b
'		If b Then
'			Dim fso,XmlFile
'			Set fso = CreateObject("Scripting.FileSystemObject")
'				Set XmlFile = fso.GetFile(d)
'					XmlFile.Delete
'				Set XmlFile = Nothing
'			Set fso = Nothing
'		End If
	End Function 
	Function Exist(TableName)
		On Error Resume Next
		Dim Rs
		Set Rs=objConn.Execute("SELECT TOP 1 * FROM ["&TableName&"]")
		Set Rs=Nothing
		If Err.Number=0 Then
			Exist=True
		Else
			Err.Clear
			Exist=False
		End If	
	End Function
	Sub Delete(Node)
		Dim Sql
		Sql = "DROP TABLE ["&Node.selectSingleNode("Table/Name").Text&"]"
		objConn.Execute(Sql)
	End Sub
	Sub Create(Node)
		Dim Field,Sql
		Sql = "CREATE TABLE ["&Node.selectSingleNode("Table/Name").Text&"] ("
		For Each Field In Node.selectNodes("Field")
			Sql = Sql & "["&Field.selectSingleNode("Name").Text&"] "
			Sql = Sql & Field.selectSingleNode("Property").Text
			Sql = Sql & ","
		Next
		If ZC_MSSQL_ENABLE Then
			Sql=Replace(Sql,"COUNTER(1,1)","INT IDENTITY(1,1) NOT NULL")
			Sql=Replace(Sql,"VARCHAR","VARCHAR(500)")
		End If
		If Right(Sql,1)="," Then
			Sql = Left(Sql,Len(Sql)-1)
		End If
		If Node.selectSingleNode("Table/Bind").Text <> "" Then
			Sql = Sql & ",[log_ID] INT"
		End If
		Sql = Sql & ")"
		objConn.Execute(Sql)
	End Sub
	Function GetFields(TableName)
		Dim Rs,fs(),n,i
		Set Rs = objConn.Execute("SELECT TOP 1 * FROM "&TableName)
			ReDim fs(Rs.Fields.Count-1)
			i = 0
			For Each n In Rs.Fields
				fs(i) = n.Name
				i = i + 1
			Next
		Set Rs = Nothing
		GetFields=fs
	End Function
	Function FieldExist(Fields,Field)
		Dim n
		For Each n In Fields
			If n=Field Then
				FieldExist=True
				Exit Function
			End If
		Next
		FieldExist=False
	End Function
End Class
Class YT_Article
	'单篇文章
	Function GetArticleModel(ID)
		ID = Split(ID,",")
		If isArray(ID) Then
			Dim Rs
			Set Rs = objConn.Execute("select [log_ID] from blog_Article WHERE [log_ID] IN ("&Join(ID,",")&")")
				If Not (Rs.EOF and Rs.BOF) Then GetArticleModel = Rs.GetRows
			Set Rs = Nothing
		End If
	End Function
	'最新文章
	Function GetArticleRandomSortNew(Rows)
		If IsNumeric(Rows) Then
			Dim Rs
			Set Rs = objConn.Execute("select top " & CStr(Rows) & " [log_ID] from blog_Article WHERE [log_Type]=0 AND [log_ID]>0 AND [log_Level]>2 order by log_ID desc")
				If Not (Rs.EOF and Rs.BOF) Then GetArticleRandomSortNew = Rs.GetRows(Rows)
			Set Rs = Nothing
		End If
	End Function
	
	'随机文章
	Function GetArticleRandomSortRand(Rows)
		If IsNumeric(Rows) Then
			Dim Rs,sql
			If ZC_MSSQL_ENABLE Then
				sql="select top "& CStr(Rows) &" [log_ID] from blog_Article WHERE [log_Type]=0 AND [log_Level]>2 order by newid()"
			Else
				Randomize
				sql="select top "& CStr(Rows) &" [log_ID] from blog_Article WHERE [log_Type]=0 AND [log_Level]>2 order by rnd("& (-1 * (Int(1000 * Rnd) + 1)) &" * log_ID)"
			End If
			Set Rs = objConn.Execute(sql)
				If Not (Rs.EOF and Rs.BOF) Then GetArticleRandomSortRand = Rs.GetRows(Rows)
			Set Rs = Nothing
		End If
	End Function
	
	'本月评论排行
	Function GetArticleRandomSortComMonth(Rows)
		If IsNumeric(Rows) Then
			Dim Rs,sql
			If ZC_MSSQL_ENABLE Then
				sql="select top " & CStr(Rows) & " [log_ID] from blog_Article WHERE [log_Type]=0 AND [log_Level]>2 AND log_ID>0 AND DATEDIFF(MONTH,GETDATE(),log_PostTime)=0 ORDER BY log_CommNums DESC"
			Else
				sql="select top " & CStr(Rows) & " [log_ID] from blog_Article WHERE [log_Type]=0 AND [log_Level]>2 AND log_ID>0 AND (log_PostTime>Now()-90) ORDER BY log_CommNums DESC"
			End If
			Set Rs = objConn.Execute(sql)
				If Not (Rs.EOF and Rs.BOF) Then GetArticleRandomSortComMonth = Rs.GetRows(Rows)
			Set Rs = Nothing
		End If
	End Function
	
	'本年评论排行
	Function GetArticleRandomSortComYear(Rows)
		If IsNumeric(Rows) Then
			Dim Rs,sql
			If ZC_MSSQL_ENABLE Then
				sql="select top " & CStr(Rows) & " [log_ID] from blog_Article WHERE [log_Type]=0 AND [log_Level]>2 AND log_ID>0 AND DATEDIFF(YEAR,GETDATE(),log_PostTime)=0 ORDER BY log_CommNums DESC"
			Else
				sql="select top " & CStr(Rows) & " [log_ID] from blog_Article WHERE [log_Type]=0 AND [log_Level]>2 AND log_ID>0 AND  (log_PostTime>Now()-365) ORDER BY log_CommNums DESC "
			End If
			Set Rs = objConn.Execute(sql)
				If Not (Rs.EOF and Rs.BOF) Then GetArticleRandomSortComYear = Rs.GetRows(Rows)
			Set Rs = Nothing
		End If
	End Function
	
	'本月排行
	Function GetArticleRandomSortTopMonth(Rows)
		If IsNumeric(Rows) Then
			Dim Rs,sql
			If ZC_MSSQL_ENABLE Then
				sql="select top " & CStr(Rows) & " [log_ID] from blog_Article WHERE [log_Type]=0 AND [log_Level]>2 AND log_ID>0 AND  DATEDIFF(MONTH,GETDATE(),log_PostTime)=0 ORDER BY log_ViewNums DESC "
			Else
				sql="select top " & CStr(Rows) & " [log_ID] from blog_Article WHERE [log_Type]=0 AND [log_Level]>2 AND log_ID>0 AND  (log_PostTime>Now()-30) ORDER BY log_ViewNums DESC "
			End If
			Set Rs = objConn.Execute(sql)
				If Not (Rs.EOF and Rs.BOF) Then GetArticleRandomSortTopMonth = Rs.GetRows(Rows)
			Set Rs = Nothing
		End If
	End Function
	
	'本年排行
	Function GetArticleRandomSortTopYear(Rows)
		If IsNumeric(Rows) Then
			Dim Rs,sql
			If ZC_MSSQL_ENABLE Then
				sql="select top " & CStr(Rows) & " [log_ID] from blog_Article WHERE [log_Type]=0 AND [log_Level]>2 AND log_ID>0 AND  DATEDIFF(YEAR,GETDATE(),log_PostTime)=0 ORDER BY log_ViewNums DESC "
			Else
				sql="select top " & CStr(Rows) & " [log_ID] from blog_Article WHERE [log_Type]=0 AND [log_Level]>2 AND log_ID>0 AND  (log_PostTime>Now()-365) ORDER BY log_ViewNums DESC "
			End If
			Set Rs = objConn.Execute(sql)
				If Not (Rs.EOF and Rs.BOF) Then GetArticleRandomSortTopYear = Rs.GetRows(Rows)
			Set Rs = Nothing
		End If
	End Function
	
	'热文排行
	Function GetArticleRandomSortTopHot(Rows)	
		If IsNumeric(Rows) Then
			Dim Rs,sql
			If ZC_MSSQL_ENABLE Then
				sql="select top " & CStr(Rows) & " [log_ID] from blog_Article WHERE [log_Type]=0 AND [log_Level]>2 AND log_ID>0 ORDER BY log_CommNums*100 + log_TrackBackNums*200 + SQRT(log_ViewNums)*10 - DATEDIFF(DAY,GETDATE(),Log_PostTime)*DATEDIFF(DAY,GETDATE(),Log_PostTime) DESC"
			Else
				sql="select top " & CStr(Rows) & " [log_ID] from blog_Article WHERE [log_Type]=0 AND [log_Level]>2 AND log_ID>0 ORDER BY log_CommNums*100 + log_TrackBackNums*200 + sqr(log_ViewNums)*10 - (date()-Log_PostTime)*(date()-Log_PostTime) DESC "
			End If
			Set Rs = objConn.Execute(sql)
				If Not (Rs.EOF and Rs.BOF) Then GetArticleRandomSortTopHot = Rs.GetRows(Rows)
			Set Rs = Nothing
		End If
	End Function
		
	'分类文章列表
	Function GetArticleCategorys(Rows,CategoryID)
		If IsNumeric(Rows) Then
			Dim Rs
			Set Rs = objConn.Execute("SELECT top "& CStr(Rows) &" [log_ID] FROM [blog_Article] WHERE [log_Type]=0 AND [log_ID]>0 AND [log_Level]>1 AND ([log_CateID] IN ("& CStr(CategoryID) &")) ORDER BY [log_PostTime] DESC")
				If Not (Rs.EOF and Rs.BOF) Then GetArticleCategorys = Rs.GetRows(Rows)
			Set Rs = Nothing
		End If
	End Function
	
	'全站Limit(by:流年)
	
	Function GetArticleLimit(Rows,Index)
		If IsNumeric(Rows) And IsNumeric(Index) Then
			Dim Rs,sql
			sql="SELECT top "& CStr(Rows) &" [log_ID] FROM [blog_Article] WHERE [log_Type]=0 AND [log_Level]>2 AND log_ID>0 AND ([log_Istop]=0) AND [log_ID] NOT IN (SELECT top "& CStr(Index) &" [log_ID] FROM [blog_Article] WHERE [log_Type]=0 AND [log_Level]>2 AND log_ID>0 AND [log_Istop]=0 ORDER BY [log_PostTime] DESC) ORDER BY [log_PostTime] DESC"
			If Not ZC_MSSQL_ENABLE Then sql=Replace(sql,"[log_Istop]=0","[log_Istop]=FALSE")
			Set Rs = objConn.Execute(sql)
				If Not (Rs.EOF and Rs.BOF) Then GetArticleLimit = Rs.GetRows(Rows)
			Set Rs = Nothing
		End If
	End Function
	
	'分类Limit(by:流年)
	Function GetArticleCategorysLimit(Rows,Index,CategoryID)
		If IsNumeric(Rows) And IsNumeric(Index) Then
			Dim Rs,sql
			sql="SELECT top "& CStr(Rows) &" [log_ID] FROM [blog_Article] WHERE [log_Type]=0 AND [log_Level]>2 AND log_ID>0 AND [log_Istop]=0 AND [log_CateID] IN ("& CStr(CategoryID) &") AND [log_ID] NOT IN (SELECT top "& CStr(Index) &" [log_ID] FROM [blog_Article] WHERE [log_Type]=0 AND [log_Level]>2 AND log_ID>0 AND [log_Istop]=0 AND [log_CateID] IN ("& CStr(CategoryID) &") ORDER BY [log_PostTime] DESC) ORDER BY [log_PostTime] DESC"
			If Not ZC_MSSQL_ENABLE Then sql=Replace(sql,"[log_Istop]=0","[log_Istop]=FALSE")
			Set Rs = objConn.Execute(sql)
				If Not (Rs.EOF and Rs.BOF) Then GetArticleCategorysLimit = Rs.GetRows(Rows)
			Set Rs = Nothing
		End If
	End Function
	
	'分类随机文章
	Function GetArticleCategorysRandomSortRand(Rows,CategoryID)
		If IsNumeric(Rows) Then
			Dim Rs,sql
			If ZC_MSSQL_ENABLE Then
				sql="select top "& CStr(Rows) &" [log_ID] from blog_Article WHERE [log_Type]=0 AND [log_Level]>2 AND [log_CateID] IN ("&CStr(CategoryID)&") order by newid()"
			Else
				Randomize
				sql="select top "& CStr(Rows) &" [log_ID] from blog_Article WHERE [log_Type]=0 AND [log_Level]>2 AND [log_CateID] IN ("&CStr(CategoryID)&") order by rnd("& (-1 * (Int(1000 * Rnd) + 1)) &" * log_ID)"
			End If
			Set Rs = objConn.Execute(sql)
				If Not (Rs.EOF and Rs.BOF) Then GetArticleCategorysRandomSortRand = Rs.GetRows(Rows)
			Set Rs = Nothing
		End If
	End Function
	
	'分类热门文章列表
	Function GetArticleCategorysTophot(Rows,CategoryID)
		If IsNumeric(Rows) Then
			Dim Rs,sql
			If ZC_MSSQL_ENABLE Then
				sql="select top " & CStr(Rows) & " [log_ID] from blog_Article WHERE [log_Type]=0 AND [log_Level]>2 AND log_ID>0 AND ([log_CateID] IN ("&CStr(CategoryID)&")) ORDER BY log_CommNums*100 + log_TrackBackNums*200 + SQRT(log_ViewNums)*10 - DATEDIFF(DAY,GETDATE(),Log_PostTime)*DATEDIFF(DAY,GETDATE(),Log_PostTime) DESC"
			Else
				sql="select top " & CStr(Rows) & " [log_ID] from blog_Article WHERE [log_Type]=0 AND [log_Level]>2 AND log_ID>0 AND ([log_CateID] IN ("&CStr(CategoryID)&")) ORDER BY log_CommNums*100 + log_TrackBackNums*200 + sqr(log_ViewNums)*10 - (date()-Log_PostTime)*(date()-Log_PostTime) DESC"
			End If
			Set Rs = objConn.Execute(sql)
				If Not (Rs.EOF and Rs.BOF) Then GetArticleCategorysTophot = Rs.GetRows(Rows)
			Set Rs = Nothing
		End If
	End Function
	
	'Tag文章列表
	Function GetArticleTag(Rows,TagID)
		If IsNumeric(Rows) And IsNumeric(TagID) Then
			Dim Rs
			Set Rs = objConn.Execute("select top " & CStr(Rows) & " [log_ID] from blog_Article WHERE [log_Type]=0 AND [log_Level]>2 AND log_ID>0 And log_Tag LIKE '%{"&CStr(TagID)&"}%' ORDER BY Log_PostTime DESC")
				If Not (Rs.EOF and Rs.BOF) Then GetArticleTag = Rs.GetRows(Rows)
			Set Rs = Nothing
		End If
	End Function
	
	'分类Tag文章列表
	Function GetArticleCategoryTag(Rows,TagID,CategoryID)
		If IsNumeric(Rows) And IsNumeric(TagID) Then
			Dim Rs
			Set Rs = objConn.Execute("select top " & CStr(Rows) & " [log_ID] from blog_Article WHERE [log_Type]=0 AND [log_Level]>2 AND log_ID>0 AND ([log_CateID] IN ("&CStr(CategoryID)&")) And log_Tag LIKE '%{"&CStr(TagID)&"}%' ORDER BY Log_PostTime DESC")
				If Not (Rs.EOF and Rs.BOF) Then GetArticleCategoryTag = Rs.GetRows(Rows)
			Set Rs = Nothing
		End If
	End Function
	
	'置顶文章列表
	Function GetArticleTop(Rows)
		If IsNumeric(Rows) Then
			Dim Rs,sql
			sql="SELECT top " & CStr(Rows) & " [log_ID] FROM [blog_Article] WHERE [log_Type]=0 AND [log_Level]>2 AND log_ID>0 AND [log_Istop]=1 ORDER BY [log_PostTime] DESC"
			If Not ZC_MSSQL_ENABLE Then sql=Replace(sql,"[log_Istop]=1","[log_Istop]=TRUE")
			Set Rs = objConn.Execute(sql)
				If Not (Rs.EOF and Rs.BOF) Then GetArticleTop = Rs.GetRows(Rows)
			Set Rs = Nothing
		End If
	End Function
	
	'分类置顶文章列表
	Function GetArticleCategoryTop(Rows,CategoryID)
		If IsNumeric(Rows) Then
			Dim Rs,sql
			sql="SELECT top " & CStr(Rows) & " [log_ID] FROM [blog_Article] WHERE [log_Type]=0 AND [log_Level]>2 AND log_ID>0 AND [log_Istop]=1 AND ([log_CateID] IN ("&CStr(CategoryID)&")) ORDER BY [log_PostTime] DESC"
			If Not ZC_MSSQL_ENABLE Then sql=Replace(sql,"[log_Istop]=1","[log_Istop]=TRUE")
			Set Rs = objConn.Execute(sql)
				If Not (Rs.EOF and Rs.BOF) Then GetArticleCategoryTop = Rs.GetRows(Rows)
			Set Rs = Nothing
		End If
	End Function
	
End Class

Class YT_Comment
	'最新回复列表
	Function GetCommentComments(Rows)
		If IsNumeric(Rows) Then
			Dim Rs
			Set Rs = objConn.Execute("SELECT top "& CStr(Rows) &" [comm_ID] FROM [blog_Comment] WHERE   comm_ParentID = 0 ORDER BY [comm_PostTime] DESC,[comm_ID] DESC")
				If Not (Rs.EOF and Rs.BOF) Then GetCommentComments = Rs.GetRows(Rows)
			Set Rs = Nothing
		End If
	End Function
	
	'分类最新回复列表
	Function GetCommentCategorysComments(Rows,CategoryID)
		If IsNumeric(Rows) Then
			Dim Rs
			Set Rs = objConn.Execute("SELECT top "& CStr(Rows) &" [comm_ID] FROM [blog_Article],[blog_Comment] WHERE blog_Article.log_CateID<>0 AND blog_Article.log_ID>0 AND  comm_ParentID = 0 AND  ([log_CateID] IN ("& CStr(CategoryID) &")) and blog_Comment.log_ID=blog_Article.log_ID ORDER BY [comm_PostTime] DESC,[comm_ID] DESC")
				If Not (Rs.EOF and Rs.BOF) Then GetCommentCategorysComments = Rs.GetRows(Rows)
			Set Rs = Nothing
		End If
	End Function
	'文章评论列表
	Function GetCommentArticleComments(Rows,ID)
		If IsNumeric(Rows) Then
			Dim Rs
			Set Rs = objConn.Execute("SELECT top "& CStr(Rows) &" [comm_ID] FROM [blog_Comment] WHERE comm_ParentID = 0 AND log_ID IN ("& CStr(ID) &") ORDER BY [comm_PostTime] DESC,[comm_ID] DESC")
				If Not (Rs.EOF and Rs.BOF) Then GetCommentArticleComments = Rs.GetRows(Rows)
			Set Rs = Nothing
		End If
	End Function
End Class

Class YT_Tag
	' 标签列表
	Function GetTagLists(Rows)
		If IsNumeric(Rows) Then
			Dim Rs
			Set Rs = objConn.Execute("SELECT top " & CStr(Rows) & " [tag_ID] FROM [blog_Tag] ORDER BY [tag_Order] DESC,[tag_Count] DESC,[tag_ID] ASC")
				If Not (Rs.EOF and Rs.BOF) Then GetTagLists = Rs.GetRows(Rows)
			Set Rs = Nothing
		End If
	End Function
	'随机标签
	Function GetTagListsRandomSortRand(Rows)
		If IsNumeric(Rows) Then
			Dim Rs,sql
			If ZC_MSSQL_ENABLE Then
				sql="SELECT top " & CStr(Rows) & " [tag_ID] FROM [blog_Tag] order by newid()"
			Else
				Randomize
				sql="select top "& CStr(Rows) &" [tag_ID] from [blog_Tag] order by rnd("& (-1 * (Int(1000 * Rnd) + 1)) &" * tag_ID)"
			End If
			Set Rs = objConn.Execute(sql)
				If Not (Rs.EOF and Rs.BOF) Then GetTagListsRandomSortRand = Rs.GetRows(Rows)
			Set Rs = Nothing
		End If
	End Function
End Class
%>