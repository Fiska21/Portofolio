CREATE PROCEDURE [dbo].[dobelkontakmori]         
-- author: Fiska Hendiya /24 Nov 2021
-- Buat penggalian taskcript BMTPS_DBL_PRE
     
AS         

SELECT distinct 
		a.dttglawalstatus, 
       a.txtkontakid, 
       d.txtkontakid as txtpicid, 
       a.txtprodukid, 
       a.txtstatuspelangganid, 
       d.txtcabangid, 
       a.txtsubmissionid, 
       a.intsubmissionidx,
	   txtdetailmediadummy
into #sup2-- select * from #sup2
from dstatuspenggunaan a with(nolock)
  inner join dkontak c with(nolock) on a.txtkontakid= c.txtkontakid and (c.boldeletedmerge is null or c.boldeletedmerge =0)
  inner join dkontak d with(nolock) on d.txtkontakid= isnull(c.txtpicid, c.txtkontakid)and (d.boldeletedmerge is null or d.boldeletedmerge =0)
  inner join dmediakontak b with(nolock) on d.txtkontakid = b.txtkontakid 
			and lttxtMediaID ='0001'
			and lttxtStatusAktif='aktif'
			and (a.bolDeletedMerge='0' or a.bolDeletedMerge is null)
   where cast(dtTglAwalStatus as date) >= dateadd(day, -30,dtTglAwalStatus)

	and txtStatusPelangganID IN('PRE NC', 'PROSPEK')
	and a.txtProdukID in ('MIF-BMT-PLAT','MIF-BMT-SOY','MIF-CHK-PLAT','MIF-CHK-SOY','MIF-CHM-PLAT','MIF-CHM-SOY','MIF-CHS-PLAT','MIF-CHS-SOY')
	and bolStatusAkhir =1
---------------------------------------------------------
Select distinct  a.txtdetailmediadummy ---4 menit    
  into #Phone2 ---select * from #Phone2   
  from dmediakontak a with (nolock)    
  inner join #sup2 b on a.txtdetailmediadummy = b.txtdetailmediadummy    
  where 1=1    
  --and txtdetailmediadummy in ('02122222','081908706163','082158016158','081908634863')    
  and (boldeletedmerge is null or boldeletedmerge =0)    
  and lttxtstatusaktif ='Aktif'    
  and lttxtmediaid in ('0001')    
  group by a.txtdetailmediadummy   
  having count (distinct a.txtkontakid) >=2    

--------------------------------------------------------

DELETE FROM reporting..DobelKontakMori

insert into reporting..DobelKontakMori --SELECT * from reporting..DobelKontakMori
SELECT DISTINCT 'BMTPSOY_DOBEL' AS txtTaskScriptID, 
       a.dttglawalstatus, 
       a.txtkontakid, 
       a.txtpicid, 
       a.txtprodukid, 
       a.txtstatuspelangganid, 
       a.txtcabangid, 
       a.txtsubmissionid, 
       a.intsubmissionidx 
--into reporting..DobelKontakMori--> select * from [CRM_2_REPORTING].[Reporting].dbo.DobelKontakMori -- 
from #sup2 a ---select * from #sup2
inner join 
(select x.txtDetailMediaDummy, sum(JumlahPIC) JlhPIC, sum (BolMember) JlhMember from 
(
select distinct c.txtDetailMediaDummy,count(distinct txtpicid) as JumlahPIC,
	 case when txtMemberID is null then 0
	   ELSE 1 END AS BolMember
	   from #sup2 a
inner join (select distinct txtkontakid, txtdetailmediadummy from 
			dmediakontak
			where (boldeletedmerge is null or boldeletedmerge =0)    
			  and lttxtstatusaktif ='Aktif'    
			  and lttxtmediaid in ('0001')   
			  ) c on a.txtDetailMediaDummy = c.txtDetailMediaDummy
left join dmembership b on c.txtkontakid = b.txtkontakid
where c.txtdetailmediadummy in (select txtdetailmediadummy from #Phone2)
--and c.txtDetailMediaDummy ='0218507454'
group by case when txtMemberID is null then 0
	   ELSE 1 END, c.txtDetailMediaDummy) x
group by txtDetailMediaDummy) X1
on x1.txtDetailMediaDummy = a.txtDetailMediaDummy
where jlhPIC <> JlhMember