truncate table dbversion;
go
insert into dbversion(dbversion) values ('8.7.1.18');
go
CREATE PROCEDURE [dbo].[spUser_AddToPasswordHistory]
	@UserId int,
	@PwdHash varchar(1000)
AS
BEGIN
	DECLARE @HistoryLimit integer
	DECLARE @BusinessUnitGuid uniqueidentifier
	DECLARE @UserGuid uniqueidentifier

	SELECT	@BusinessUnitGuid = Business_Unit_GUID,
			@UserGuid = User_Guid
	FROM	Intelledox_User
	WHERE	User_ID = @UserId;

	SET @HistoryLimit = (SELECT Global_Options.OptionValue 
						FROM Global_Options 
						WHERE  Global_Options.BusinessUnitGuid = @BusinessUnitGuid
							AND Global_Options.OptionCode = 'PASSWORD_HISTORY_COUNT')

	IF (@HistoryLimit > 0)
	BEGIN
		INSERT INTO [Password_History] (User_Guid, pwdhash)
		VALUES (@UserGuid, @PwdHash)

		DELETE FROM Password_History
		WHERE id NOT IN (SELECT TOP (@HistoryLimit) id 
						FROM Password_History 
						WHERE User_Guid = @UserGuid
						ORDER BY DateCreatedUtc DESC)
			AND User_Guid = @UserGuid;
	END
END
GO
ALTER PROCEDURE [dbo].[spUser_IsLockedOut]
	@Username nvarchar(256)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT COUNT(*)
	FROM Intelledox_User
	WHERE Intelledox_User.Username = @Username AND
		Intelledox_User.Locked_Until_Utc IS NOT NULL AND
		Intelledox_User.Locked_Until_Utc > GETUTCDATE()
END
GO
ALTER PROCEDURE [dbo].[spUser_InvalidLogonAttempt]
	@Username nvarchar(256)
AS
BEGIN
	UPDATE Intelledox_User
	SET [Invalid_Logon_Attempts] = [Invalid_Logon_Attempts] + 1
	WHERE Username = @Username
END
GO
ALTER PROCEDURE [dbo].[spUser_ClearInvalidLogonAttempts]
	@Username nvarchar(256)
AS
BEGIN
	UPDATE Intelledox_User
	SET [Invalid_Logon_Attempts] = 0
	WHERE Username = @Username
END
GO
