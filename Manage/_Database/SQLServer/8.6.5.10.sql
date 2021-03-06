truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.6.5.10');
go

ALTER procedure [dbo].[spContent_RemoveContentItem]
	@ContentItemGuid uniqueidentifier
AS
	DECLARE @ContentDataGuid uniqueidentifier;
	
	SET		@ContentDataGuid = (SELECT ContentData_Guid FROM Content_Item WHERE ContentItem_Guid = @ContentItemGuid);

	DELETE	Content_Item_Placeholder
	WHERE	ContentItemGuid = @ContentItemGuid;
	
	DELETE	Content_Item
	WHERE	ContentItem_Guid = @ContentItemGuid;

	DELETE	Xtf_ContentLibrary_Dependency
	WHERE	Content_Object_Guid = @ContentItemGuid;
	
	DELETE	ContentData_Binary
	WHERE	ContentData_Guid = @ContentDataGuid;
	
	DELETE	ContentData_Binary_Version
	WHERE	ContentData_Guid = @ContentDataGuid;

	DELETE	ContentData_Text
	WHERE	ContentData_Guid = @ContentDataGuid;
	
	DELETE	ContentData_Text_Version
	WHERE	ContentData_Guid = @ContentDataGuid;

GO

DELETE FROM Xtf_ContentLibrary_Dependency
  WHERE Xtf_ContentLibrary_Dependency.Content_Object_Guid
  NOT IN (SELECT Content_Item.ContentItem_Guid FROM Content_Item)

GO
