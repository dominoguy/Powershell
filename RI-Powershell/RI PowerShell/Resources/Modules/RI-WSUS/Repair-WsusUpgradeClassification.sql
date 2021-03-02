declare @NotNeededFiles table (FileDigest binary(20) UNIQUE)
insert into @NotNeededFiles(FileDigest) (select FileDigest from tbFile where FileName like '%.esd%' except select FileDigest from tbFileForRevision)
delete from tbFileOnServer where FileDigest in (select FileDigest from @NotNeededFiles)
delete from tbFile where FileDigest in (select FileDigest from @NotNeededFiles)