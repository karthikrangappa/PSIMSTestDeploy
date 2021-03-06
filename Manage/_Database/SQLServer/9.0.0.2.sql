truncate table dbversion;
go
insert into dbversion(dbversion) values ('9.0.0.2');
go

ALTER PROCEDURE [dbo].[spProjectGroup_UpdateFeatureFlags]
	@ProjectGroupGuid uniqueidentifier = null,
	@ProjectGuid uniqueidentifier = null
AS
	DECLARE @ProjectGroupsAffected TABLE 
	(
		Template_Group_Guid uniqueidentifier,
		Content_Guid uniqueidentifier,
		Layout_Guid uniqueidentifier
	)

	IF (@ProjectGuid is NULL)
	BEGIN
		-- Update a single group
		INSERT INTO @ProjectGroupsAffected(Template_Group_Guid, Content_Guid, Layout_Guid)
		SELECT @ProjectGroupGuid, Template_Guid, Layout_Guid
		FROM	Template_Group
		WHERE	Template_Group_Guid = @ProjectGroupGuid;
	END
	ELSE
	BEGIN
		-- Update groups using a project
		WITH ParentFragments (Template_Guid)
		AS
		(
			-- Anchor member definition
			SELECT	t.Template_Guid
			FROM	Xtf_Fragment_Dependency t
			WHERE	t.Fragment_Guid = @ProjectGuid
			UNION ALL
			-- Recursive member definition
			SELECT t.Template_Guid
			FROM Xtf_Fragment_Dependency t
				INNER JOIN ParentFragments AS p ON t.Fragment_Guid = p.Template_Guid
		)
		INSERT INTO @ProjectGroupsAffected(Template_Group_Guid, Content_Guid, Layout_Guid)
		SELECT DISTINCT Template_Group.Template_Group_Guid, Template_Group.Template_Guid as Content_Guid, Template_Group.Layout_Guid
		FROM ParentFragments
			INNER JOIN Template_Group ON ParentFragments.Template_Guid = Template_Group.Template_Guid
				OR ParentFragments.Template_Guid = Template_Group.Layout_Guid

		--Select parent content project guid
		INSERT INTO @ProjectGroupsAffected(Template_Group_Guid, Content_Guid, Layout_Guid)
		SELECT Template_Group_Guid, Template_Guid, Layout_Guid
		FROM	Template_Group
		WHERE	(Template_Guid = @ProjectGuid OR Layout_Guid = @ProjectGuid) AND
				Template_Group_Guid NOT IN (SELECT Template_Group_Guid FROM @ProjectGroupsAffected);

	END

	DECLARE @FeatureFlag int;
	DECLARE @Content_Guid uniqueidentifier
	DECLARE @Layout_Guid uniqueidentifier
	DECLARE @Project_Version nvarchar(10)
	DECLARE PgCursor CURSOR
		FOR	SELECT	Template_Group_Guid, Content_Guid, Layout_Guid
			FROM	@ProjectGroupsAffected;

	OPEN PgCursor;
	FETCH NEXT FROM PgCursor INTO @ProjectGroupGuid, @Content_Guid, @Layout_Guid;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Content
		SET @FeatureFlag = (SELECT	Template.FeatureFlags
					FROM	Template_Group
							INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid 
									AND (Template_Group.Template_Version IS NULL
										OR Template_Group.Template_Version = Template.Template_Version)
					WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid
					UNION ALL
					SELECT	Template_Version.FeatureFlags
					FROM	Template_Group
							INNER JOIN Template_Version ON (Template_Group.Template_Guid = Template_Version.Template_Guid 
									AND Template_Group.Template_Version = Template_Version.Template_Version)
					WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid)

		SET @Project_Version = (SELECT	Template.Template_Version
					FROM	Template_Group
							INNER JOIN Template ON Template_Group.Template_Guid = Template.Template_Guid 
									AND (Template_Group.Template_Version IS NULL
										OR Template_Group.Template_Version = Template.Template_Version)
					WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid
					UNION ALL
					SELECT	Template_Version.Template_Version
					FROM	Template_Group
							INNER JOIN Template_Version ON (Template_Group.Template_Guid = Template_Version.Template_Guid 
									AND Template_Group.Template_Version = Template_Version.Template_Version)
					WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid)

		-- Content Project Fragments
		DECLARE FragCursor CURSOR
			FOR	WITH ChildFragments (Template_Guid)
				AS
				(
					-- Anchor member definition
					SELECT	t.Fragment_Guid
					FROM	Xtf_Fragment_Dependency t
					WHERE	t.Template_Guid = @Content_Guid AND
							t.Template_Version = @Project_Version
					UNION ALL
					-- Recursive member definition
					SELECT t.Fragment_Guid
					FROM Xtf_Fragment_Dependency t
						INNER JOIN ChildFragments AS p ON t.Template_Guid = p.Template_Guid
						INNER JOIN Template ON t.Template_Version = Template.Template_Version AND t.Template_Guid = Template.Template_Guid
				)
				SELECT Template_Guid
				FROM ChildFragments;

		OPEN FragCursor;
		FETCH NEXT FROM FragCursor INTO @ProjectGuid;
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @FeatureFlag = @FeatureFlag | ISNULL((SELECT FeatureFlags
				FROM Template
				WHERE Template_Guid = @ProjectGuid), 0);

			FETCH NEXT FROM FragCursor INTO @ProjectGuid;
		END
		
		CLOSE FragCursor;
		DEALLOCATE FragCursor;

		-- Layout
		IF @Layout_Guid IS NOT NULL
		BEGIN
			SET @FeatureFlag = @FeatureFlag | ISNULL((SELECT Template.FeatureFlags
					FROM	Template_Group
							INNER JOIN Template ON Template_Group.Layout_Guid = Template.Template_Guid
									AND (Template_Group.Layout_Version IS NULL
										OR Template_Group.Layout_Version = Template.Template_Version)
					WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid
					UNION ALL
					SELECT	Template_Version.FeatureFlags
					FROM	Template_Group
							INNER JOIN Template_Version ON Template_Group.Layout_Guid = Template_Version.Template_Guid
									AND Template_Group.Layout_Version = Template_Version.Template_Version
					WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid), 0)

			SET @Project_Version =(SELECT Template.Template_Version
					FROM	Template_Group
							INNER JOIN Template ON Template_Group.Layout_Guid = Template.Template_Guid
									AND (Template_Group.Layout_Version IS NULL
										OR Template_Group.Layout_Version = Template.Template_Version)
					WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid
					UNION ALL
					SELECT	Template_Version.Template_Version
					FROM	Template_Group
							INNER JOIN Template_Version ON Template_Group.Layout_Guid = Template_Version.Template_Guid
									AND Template_Group.Layout_Version = Template_Version.Template_Version
					WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid)

			-- Layout Project fragments
			DECLARE LayoutFragCursor CURSOR
				FOR	WITH ChildFragments (Template_Guid)
					AS
					(
						-- Anchor member definition
						SELECT	t.Fragment_Guid
						FROM	Xtf_Fragment_Dependency t
						WHERE	t.Template_Guid = @Layout_Guid AND
							    t.Template_Version = @Project_Version
						UNION ALL
						-- Recursive member definition
						SELECT t.Fragment_Guid
						FROM Xtf_Fragment_Dependency t
							INNER JOIN ChildFragments AS p ON t.Template_Guid = p.Template_Guid
							INNER JOIN Template ON t.Template_Version = Template.Template_Version AND t.Template_Guid = Template.Template_Guid
					)
					SELECT Template_Guid
					FROM ChildFragments;

			OPEN LayoutFragCursor;
			FETCH NEXT FROM LayoutFragCursor INTO @ProjectGuid;
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @FeatureFlag = @FeatureFlag | ISNULL((SELECT FeatureFlags
					FROM Template
					WHERE Template_Guid = @ProjectGuid), 0);

				FETCH NEXT FROM LayoutFragCursor INTO @ProjectGuid;
			END
		
			CLOSE LayoutFragCursor;
			DEALLOCATE LayoutFragCursor;
		END

		UPDATE	Template_Group
		SET		Template_Group.FeatureFlags = @FeatureFlag
		WHERE	Template_Group.Template_Group_Guid = @ProjectGroupGuid;
		
		FETCH NEXT FROM PgCursor INTO @ProjectGroupGuid, @Content_Guid, @Layout_Guid;
	END

	CLOSE PgCursor;
	DEALLOCATE PgCursor;

GO
ALTER PROCEDURE [dbo].[spProject_UpdateDefinition] (
	@Xtf xml,
	@TemplateGuid uniqueidentifier,
	@EncryptedXtf varbinary(MAX)
)
AS
	SET ARITHABORT ON

	DECLARE @FeatureFlags int;
	DECLARE @DataObjectGuid uniqueidentifier;
	DECLARE @XtfVersion nvarchar(10)

	BEGIN TRAN
		-- Feature detection --
		SET @FeatureFlags = 0
		SELECT @XtfVersion = Template.Template_Version FROM Template WHERE Template.Template_Guid = @TemplateGuid

		-- Workflow
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/Workflow/State/Transition)') as ProjectXML(P))
		BEGIN
			--Looking for a specified transition from the start state
			IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/Workflow/State)') as StateXML(S)
					  CROSS APPLY S.nodes('(Transition)') as TransitionXML(T)
					  WHERE S.value('@ID', 'uniqueidentifier') = cast('11111111-1111-1111-1111-111111111111' as uniqueidentifier)
					  AND (T.value('@SendToType', 'int') = 0 or T.value('@SendToType', 'int') IS NULL))
			BEGIN
				SET @FeatureFlags = @FeatureFlags | 256;
			END
			ELSE
			BEGIN
				SET @FeatureFlags = @FeatureFlags | 1;
			END
		END

		-- Data source
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 2		-- Data field
						OR Q.value('@TypeId', 'int') = 9	-- Data table
						OR Q.value('@TypeId', 'int') = 12	-- Data list
						OR Q.value('@TypeId', 'int') = 14)	-- Data source
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 2;

			INSERT INTO Xtf_Datasource_Dependency(Template_Guid, Template_Version, Data_Object_Guid)
			SELECT DISTINCT @TemplateGuid,
					@XtfVersion,
					Q.value('@DataObjectGuid', 'uniqueidentifier')
			FROM 
				@Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question)') as QuestionXML(Q)
			WHERE Q.value('@DataObjectGuid', 'uniqueidentifier') is not null
				AND Q.value('@DataServiceGuid', 'uniqueidentifier') <> '6a4af944-0563-4c95-aba1-ddf2da4337b1'
				AND (SELECT  COUNT(*)
				FROM    Xtf_Datasource_Dependency 
				WHERE   Template_Guid = @TemplateGuid
				AND     Template_Version = @XtfVersion 
				AND		Data_Object_Guid = Q.value('@DataObjectGuid', 'uniqueidentifier')) = 0
			
		END

		-- Content library
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 11
						AND Q.value('@DisplayType', 'int') = 8) -- Existing content item
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 4;
		END
		
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 11
						AND Q.value('@DisplayType', 'int') = 4) -- Search
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 8;
		END

		BEGIN
			DELETE FROM Xtf_ContentLibrary_Dependency
			WHERE	Xtf_ContentLibrary_Dependency.Template_Guid = @TemplateGuid AND
					Xtf_ContentLibrary_Dependency.Template_Version = @XtfVersion;

			INSERT INTO Xtf_ContentLibrary_Dependency(Template_Guid, Template_Version, Content_Object_Guid)
			SELECT DISTINCT @TemplateGuid, @XtfVersion, Content_Object_Guid
			FROM (
				SELECT C.value('@Id', 'uniqueidentifier') as Content_Object_Guid
				FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question/Answer/ContentItem)') as ContentItemXML(C)
				UNION
				SELECT Q.value('@ContentItemGuid', 'uniqueidentifier')
				FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Question)') as QuestionXML(Q)
				WHERE Q.value('@ContentItemGuid', 'uniqueidentifier') is not null) Content
		END

		-- Address
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 1)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 16;
		END

		-- Rich text
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 19)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 64;
		END
			
		-- Custom Question
		IF EXISTS(SELECT 1 FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as ProjectXML(P)
						CROSS APPLY P.nodes('(Question)') as QuestionXML(Q)
				WHERE	Q.value('@TypeId', 'int') = 22)
		BEGIN
			SET @FeatureFlags = @FeatureFlags | 128;
		END

		-- Fragments
		BEGIN
			DELETE FROM Xtf_Fragment_Dependency
			WHERE	Xtf_Fragment_Dependency.Template_Guid = @TemplateGuid AND
					Xtf_Fragment_Dependency.Template_Version = @XtfVersion;

			INSERT INTO Xtf_Fragment_Dependency(Template_Guid, Template_Version, Fragment_Guid)
			SELECT DISTINCT @TemplateGuid, @XtfVersion, Fragment_Guid
			FROM (
				SELECT fp.value('@ProjectGuid', 'uniqueidentifier') as Fragment_Guid
				FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup)') as PageFragmentXML(fp)
				WHERE fp.value('@ProjectGuid', 'uniqueidentifier') IS NOT NULL
				UNION
				SELECT fn.value('@ProjectGuid', 'uniqueidentifier')
				FROM @Xtf.nodes('(/Intelledox_TemplateFile/WizardInfo/BookmarkGroup/Layout//Fragment)') as NodeFragmentXML(fn)
				WHERE fn.value('@ProjectGuid', 'uniqueidentifier') IS NOT NULL) Fragments

			IF EXISTS(SELECT 1 FROM Xtf_Fragment_Dependency WHERE Template_Guid = @TemplateGuid AND Template_Version = @XtfVersion)
			BEGIN
				SET @FeatureFlags = @FeatureFlags | 512;
			END
		END
					
		IF @EncryptedXtf IS NULL
		BEGIN
			UPDATE	Template 
			SET		Project_Definition = @XTF,
					FeatureFlags = @FeatureFlags,
					EncryptedProjectDefinition = NULL
			WHERE	Template_Guid = @TemplateGuid;
		END
		ELSE
		BEGIN
			UPDATE	Template 
			SET		EncryptedProjectDefinition = @EncryptedXtf,
					FeatureFlags = @FeatureFlags,
					Project_Definition = NULL
			WHERE	Template_Guid = @TemplateGuid;
		END

		EXEC spProjectGroup_UpdateFeatureFlags @ProjectGuid=@TemplateGuid;
	COMMIT
GO
