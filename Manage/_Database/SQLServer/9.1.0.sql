truncate table dbversion;
go
insert into dbversion(dbversion) values ('9.1.0');
go
ALTER PROCEDURE [dbo].[spDataSource_UpdateDataService]
	@DataServiceGuid uniqueidentifier,
	@Name nvarchar(100),
	@ConnectionString nvarchar(MAX),
	@CredentialMethod int,
	@AllowConnectionExport bit,
	@BusinessUnitGuid uniqueidentifier,
	@ProviderName nvarchar(100),
	@Username nvarchar(100),
	@PasswordHash varchar(1000)
as
	IF NOT EXISTS(SELECT * FROM Data_Service WHERE data_service_guid = @DataServiceGuid)
		INSERT INTO Data_Service ([name], connection_string, data_service_guid, 
				Credential_Method, Allow_Connection_Export, Business_Unit_Guid, Provider_Name, 
				Username, PasswordHash)
		VALUES (@Name, @ConnectionString, @DataServiceGuid, 
				@CredentialMethod, @AllowConnectionExport, @BusinessUnitGuid, @ProviderName, 
				@Username, @PasswordHash);
	ELSE
		UPDATE Data_Service
		SET [name] = @Name,
			connection_string = @ConnectionString,
			Credential_Method = @CredentialMethod,
			Allow_Connection_Export = @AllowConnectionExport,
			Business_Unit_Guid = @BusinessUnitGuid,
			Provider_Name = @ProviderName,
			Username = @Username,
			PasswordHash = @PasswordHash
		WHERE Data_Service_Guid = @DataServiceGuid;
GO
ALTER PROCEDURE [dbo].[spUsers_UserByUsernameOrEmail]
	@UsernameOrEmail nvarchar(256),
	@ErrorCode int = 0 output

AS

BEGIN

	SELECT Intelledox_User.*, Email_Address
	FROM Intelledox_User
	LEFT JOIN Address_Book ON Intelledox_User.Address_ID = Address_Book.Address_ID
	WHERE Email_Address = @UsernameOrEmail OR Username = @UsernameOrEmail
	AND Disabled = 0;

	SET @ErrorCode = @@ERROR;	
END
GO
ALTER PROCEDURE [dbo].[spUser_UpdatePassword]
	@UserGuid uniqueidentifier,
	@PasswordHash varchar(1000),
	@PasswordSalt nvarchar(128),
	@PasswordFormat int
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE Intelledox_User
	SET pwdhash = @PasswordHash,
		PwdFormat = @PasswordFormat,
		PwdSalt = @PasswordSalt
	WHERE User_Guid = @UserGuid;
END
GO
INSERT INTO Global_Options (BusinessUnitGuid, OptionCode, OptionDescription, OptionValue)
SELECT bu.Business_Unit_GUID, 'SYSTEM_NAME', 'System Name', 'Intelledox Infiniti'
FROM Business_Unit bu
GO

































