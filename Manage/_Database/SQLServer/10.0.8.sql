truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.0.8');
go

CREATE PROC [dbo].[spProject_GetProjectsUsingFragment]
	@ProjectGuid uniqueidentifier

AS

BEGIN
	SELECT	DISTINCT project.Name, project.Template_Guid, project.Template_Type_ID, project.FolderGuid
	FROM	Xtf_Fragment_Dependency dependency
		INNER JOIN Template project ON dependency.Template_Guid = project.Template_Guid
	WHERE	dependency.Fragment_Guid = @ProjectGuid;
END
GO

ALTER PROCEDURE [dbo].[spTenant_CreateAdminUser] (
	   @NewBusinessUnit uniqueidentifier,
	   @AdminUserGuid uniqueidentifier,
       @FirstName nvarchar(50),
       @LastName nvarchar(50),
       @UserName nvarchar(256),
       @UserPasswordHash varchar(1000),
       @UserPwdSalt nvarchar(128),
       @UserPwdFormat int,
       @Email nvarchar(256)
)
AS
		
	DECLARE @GlobalAdminRoleGuid uniqueidentifier

	--User address for admin user
    INSERT INTO Address_Book (Full_Name, First_Name, Last_Name, Email_Address)
    VALUES (@FirstName + ' ' + @LastName, @FirstName, @LastName, @Email)

    --Admin
    INSERT INTO Intelledox_User(Username, Pwdhash, PwdSalt, PwdFormat, ChangePassword, WinNT_User, Business_Unit_Guid, User_Guid, Address_ID, IsGuest)
    VALUES (@UserName, @UserPasswordHash, @UserPwdSalt, @UserPwdFormat, 1, 0, @NewBusinessUnit, @AdminUserGuid, @@IDENTITY, 0)

	IF NOT EXISTS(SELECT 1 
					FROM Administrator_Level 
					WHERE AdminLevel_Description = 'Global Administrator' 
						AND Business_Unit_Guid = @NewBusinessUnit)
	BEGIN
		SET @GlobalAdminRoleGuid = NewId() -- We need this later
		INSERT INTO Administrator_Level(AdminLevel_Description, RoleGuid, Business_Unit_Guid)
		VALUES ('Global Administrator', @GlobalAdminRoleGuid, @NewBusinessUnit)
		
		INSERT INTO Role_Permission(PermissionGuid, RoleGuid)
		SELECT Permission.PermissionGuid, @GlobalAdminRoleGuid
		FROM Permission
	END
	ELSE
	BEGIN
		SELECT @GlobalAdminRoleGuid = RoleGuid  
		FROM Administrator_Level 
		WHERE AdminLevel_Description = 'Global Administrator' 
			AND Business_Unit_Guid = @NewBusinessUnit
	END
	
    --Make admin user a global admin (that we previously defined)
	INSERT INTO User_Role(UserGuid, RoleGuid)
	VALUES(@AdminUserGuid, @GlobalAdminRoleGuid)

	--Group assignment for the admin user
    INSERT INTO User_Group_Subscription(UserGuid, IsDefaultGroup, GroupGuid)
    SELECT @AdminUserGuid, 1, Group_Guid 
    FROM User_Group
    WHERE SystemGroup = 1 
    AND Business_Unit_Guid = @NewBusinessUnit
GO


ALTER VIEW [dbo].[vwUserAI]
AS
	SELECT u.Business_Unit_GUID as BusinessUnitGuid,
			u.User_Guid as UserGuid,
			u.IsGuest,
			u.IsAnonymousUser,
			u.[Disabled],
			u.Username COLLATE Latin1_General_CI_AI as Username,
			ud.First_Name COLLATE Latin1_General_CI_AI as FirstName,
			ud.Last_Name COLLATE Latin1_General_CI_AI as LastName
	FROM Intelledox_User u
		LEFT JOIN Address_Book ud ON u.Address_ID = ud.Address_ID;
GO

INSERT INTO Group_Output(GroupGuid, FormatTypeId, LockOutput, EmbedFullFonts, CreateOutline)
SELECT	GroupGuid, 11, LockOutput, 0, 0
FROM	Group_Output
WHERE	FormatTypeID = 9
		AND GroupGuid NOT IN (
			SELECT	GroupGuid
			FROM	Group_Output
			WHERE	FormatTypeId = 1 OR FormatTypeId = 3 OR FormatTypeId = 11
		);

DELETE FROM	Group_Output
WHERE	FormatTypeID = 9;
GO

ALTER PROCEDURE [dbo].[spProject_ProjectByName]
	@ProjectName nvarchar(100),
	@BusinessUnitGuid uniqueidentifier,
	@PublishableOnly bit = 0
AS
		SELECT 	a.template_id, a.[name] as project_name, a.template_type_id, 
				a.template_guid, a.template_version, a.import_date, 
				a.Business_Unit_GUID, a.Supplier_Guid, a.Modified_Date, Intelledox_User.Username,
				a.Modified_By, lockedByUser.Username AS LockedBy,
				a.FeatureFlags, a.FolderGuid
		FROM	Template a
			LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = a.Modified_By
			LEFT JOIN Intelledox_User lockedByUser ON lockedByUser.User_Guid = a.LockedByUserGuid
		WHERE	a.Business_Unit_GUID = @BusinessUnitGuid
			AND a.Name = @ProjectName
			AND (
				(@PublishableOnly = 1 AND Template_Type_ID IN (1,3))
				OR @PublishableOnly = 0
			)
GO

sp_rename 'License_Key','zzLicenseKey';
GO
ALTER procedure [dbo].[spProject_GetProjectsByContentItem]
	@ContentGuid varchar(40),
	@BusinessUnitGuid uniqueidentifier
as
	SET ARITHABORT ON 

	SELECT 	Template.template_id, 
			Template.[name] as project_name, 
			Template.template_type_id, 
			Template.template_guid, 
			Template.template_version, 
			Template.import_date,
			Template.Business_Unit_GUID, 
			Template.Supplier_Guid,
			Template.Modified_Date,
			Intelledox_User.Username,
			Template.Modified_By,
			Template.FeatureFlags,
			Template.FolderGuid
	FROM	Template
		LEFT JOIN Intelledox_User ON Intelledox_User.User_Guid = Template.Modified_By
		INNER JOIN Xtf_ContentLibrary_Dependency on Xtf_ContentLibrary_Dependency.Template_Guid = Template.Template_Guid  AND
													Xtf_ContentLibrary_Dependency.Template_Version = Template.Template_Version
	WHERE	Template.Business_Unit_GUID = @BusinessUnitGuid
		AND Xtf_ContentLibrary_Dependency.Content_Object_Guid = @ContentGuid 
	ORDER BY Template.[name];

GO
