truncate table dbversion;
go
insert into dbversion(dbversion) values ('10.0.19');
go

-- 10150
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'PK_Action_Log' AND object_id = OBJECT_ID('dbo.Action_Log'))
BEGIN

	CREATE TABLE dbo.Tmp_Action_Log
		(
		[ActionGuid] [uniqueidentifier] NOT NULL,
		[DateTimeUTC] [datetime] NOT NULL,
		[Log_Guid] [uniqueidentifier] NOT NULL,
		[User_Guid] [uniqueidentifier] NOT NULL,
		[ProcessingMS] [int] NOT NULL,
		[Result] [int] NOT NULL,
		[EncryptedChecksum] [varbinary](max) NULL,
		[BusinessUnitGuid] [uniqueidentifier] NOT NULL
		);

	CREATE CLUSTERED INDEX IX_Action_Log ON dbo.Tmp_Action_Log
		(
		[DateTimeUTC]
		);

	INSERT INTO dbo.Tmp_Action_Log ([ActionGuid], [DateTimeUTC], [Log_Guid], [User_Guid], [ProcessingMS], 
			[Result], [EncryptedChecksum], [BusinessUnitGuid])
	SELECT	[ActionGuid], [DateTimeUTC], [Log_Guid], [User_Guid], [ProcessingMS],
			[Result], [EncryptedChecksum], [BusinessUnitGuid]
	FROM	Action_Log;

	DROP TABLE dbo.Action_Log;
	EXECUTE sp_rename N'dbo.Tmp_Action_Log', N'Action_Log', 'OBJECT';
END
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'PK_Email_Log' AND object_id = OBJECT_ID('dbo.Email_Log'))
BEGIN

	CREATE TABLE dbo.Tmp_Email_Log
		(
			[EmailType] [nvarchar](100) NOT NULL,
			[DateTimeUTC] [datetime] NOT NULL,
			[Id] [uniqueidentifier] NOT NULL,
			[NumAddressees] [int] NOT NULL,
			[EncryptedChecksum] [varbinary](max) NULL,
			[BusinessUnitGuid] [uniqueidentifier] NOT NULL,
			[ProjectGuid] [uniqueidentifier] NULL
		);

	CREATE CLUSTERED INDEX IX_Email_Log ON dbo.Tmp_Email_Log
		(
		[DateTimeUTC]
		);

	INSERT INTO dbo.Tmp_Email_Log ([EmailType], [DateTimeUTC], [Id], [NumAddressees], [EncryptedChecksum], 
			[BusinessUnitGuid], [ProjectGuid])
	SELECT	[EmailType], [DateTimeUTC], [Id], [NumAddressees], [EncryptedChecksum],
			[BusinessUnitGuid], [ProjectGuid]
	FROM	Email_Log;

	DROP TABLE dbo.Email_Log;
	EXECUTE sp_rename N'dbo.Tmp_Email_Log', N'Email_Log', 'OBJECT';
END
GO

IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'PK_Escalation_Log' AND object_id = OBJECT_ID('dbo.Escalation_Log'))
BEGIN

	CREATE TABLE dbo.Tmp_Escalation_Log
		(
			[EscalationTypeId] [uniqueidentifier] NOT NULL,
			[DateTimeUTC] [datetime] NOT NULL,
			[CurrentStateGuid] [uniqueidentifier] NOT NULL,
			[ProcessingMS] [float] NOT NULL,
			[EncryptedChecksum] [varbinary](max) NULL,
			[BusinessUnitGuid] [uniqueidentifier] NOT NULL,
			[ProjectGuid] [uniqueidentifier] NULL
		);

	CREATE CLUSTERED INDEX IX_Escalation_Log ON dbo.Tmp_Escalation_Log
		(
		[DateTimeUTC]
		);

	INSERT INTO dbo.Tmp_Escalation_Log ([EscalationTypeId], [DateTimeUTC], [CurrentStateGuid], [ProcessingMS], [EncryptedChecksum], 
			[BusinessUnitGuid], [ProjectGuid])
	SELECT	[EscalationTypeId], [DateTimeUTC], [CurrentStateGuid], [ProcessingMS], [EncryptedChecksum],
			[BusinessUnitGuid], [ProjectGuid]
	FROM	Escalation_Log;

	DROP TABLE dbo.Escalation_Log;
	EXECUTE sp_rename N'dbo.Tmp_Escalation_Log', N'Escalation_Log', 'OBJECT';
END
GO
