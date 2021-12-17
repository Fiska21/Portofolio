alter procedure CleanDummyMP1    
    
----author : Fiska hendiya    
-----Create date : 2021-08-24    
---- Description : Update kontakid Dummy dengan unik ( 1 Phone hanya 1 PIC ID) dari data Marketplace    
---sp_helptext CleanDummyMP1    
--------------------------------------------------------------------------------------------------------------------    
as    
    
Begin    
    
set nocount on;    
------------------------------------------------ 1 menitan    
 select distinct cust_code, rsrv_no, case when left(cust_phone,5)='62620' then '0'+SUBSTRING(cust_phone,6,30)  
 when left(cust_phone,4)='6262' then  '0'+SUBSTRING(cust_phone,5,30)    
 when left(cust_phone,5)='62+62' then '0'+SUBSTRING(cust_phone,6,30)    
 when left(cust_phone,3)='620' then  '0'+SUBSTRING(cust_phone,4,30)  
  when left(cust_phone,3)='625' then '08'+SUBSTRING(cust_phone,4,30)  
 when left(cust_phone,2)='62' then '0'+SUBSTRING(cust_phone,3,30)    
 when left(cust_phone,1)='8' then '0'+ cust_phone     
 when left(cust_phone,4)='0628' then  '08'+SUBSTRING(cust_phone,4,30)     
 when left(cust_phone,4)='0808' then '0'+SUBSTRING(cust_phone,5,30)     
 else cust_phone end as Telp     
 into #TrxComp --- select * from #TrxComp     
 from mtl_reservation_transaction_headers a with(nolock)    
 inner join mtl_reservation_transaction_status c on a.intSO_HeaderID = c.intSO_HeaderID     
 and intstatusID ='103' and bitactive=1    
 inner join CRM_4_NHD.NationalCRMDB.dbo.dkontak b with(nolock) on a.cust_code =b.txtkontakid and bolkontakdummy='1' and txtalamat='marketplace'    
------------------------------------------------     
  Select distinct txtdetailmediadummy ---4 menit    
  into #Phone1 ---select * from #Phone1    
  from CRM_4_NHD.NationalCRMDB.dbo.dmediakontak a with (nolock)    
  inner join #TrxComp b on a.txtdetailmediadummy = b.Telp    
  where 1=1    
  --and txtdetailmediadummy in ('02122222','081908706163','082158016158','081908634863')    
  and (boldeletedmerge is null or boldeletedmerge =0)    
  and lttxtstatusaktif ='Aktif'    
  and lttxtmediaid in ('0001')    
  group by txtdetailmediadummy    
  having count (distinct txtkontakid) =1    
 ----------------------------------------------- 4 menit    
  select a.*, c.TXTKONTAKID as KontakID_Seharusnya      
  into #cleansing --select * from #cleansing    
  from #TrxComp a    
  inner join #Phone1 b on a.Telp = b.txtdetailmediadummy    
  inner join CRM_4_NHD.NationalCRMDB.dbo.dmediakontak c with (nolock) on b.txtdetailmediadummy = c.txtdetailmediadummy    
  and (boldeletedmerge is null or boldeletedmerge =0)    
  and lttxtstatusaktif ='Aktif'    
  and lttxtmediaid in ('0001')    
----------------------------------------------------    
update a --- 0.5 menit    
set a.cust_code = b.KontakID_Seharusnya        
from mtl_reservation_transaction_headers a        
inner join #cleansing b on a.rsrv_no = b.rsrv_no    
where a.rsrv_no in (select distinct rsrv_no from #cleansing)      
------------------------------------------------------------------------     
update a ---2 detik     
set a.cust_code = b.KontakID_Seharusnya        
from mtl_reservation_transaction_md_headers a        
inner join #cleansing b on a.rsrv_no = b.rsrv_no    
where a.rsrv_no in (select distinct rsrv_no from #cleansing)          
-------------------------------------------------------------------------    
 update a ---2 menitan         
 set a.txtkontakid = b.KontakID_Seharusnya      
 from mtl_transaction_poin a         
 inner join #cleansing b on a.txtNoSO = b.rsrv_no    
 where a.txtNoSO in (select distinct rsrv_no from #cleansing)    
-----------------------------------------------------------------------------     
 update a ------1 menit    
 set  a.intperiod_membershipid=d.intperiodeid,a.txtperiodepoint=d.txtperiodepoint       
 from mtl_transaction_poin a         
 inner join CRM_4_NHD.NationalCRMDB.dbo.dmembership c with(nolock) on c.txtkontakid=a.txtkontakid    
 inner join CRM_4_NHD.NationalCRMDB.dbo.dmembershipperiode d with(nolock) on c.txtkontakid=d.txtkontakid    
where a.txtNoSO in (select distinct rsrv_no from #cleansing)    
 and (a.intPeriod_MembershipID <> d.intperiodeid)    
 and a.txtPeriodePoint <> d.txtPeriodePoint     
 and d.dttglawal<=cast(a.dtcreateddate as date)     
 and d.dttglakhir>=cast(a.dtcreateddate as date)    
 --(a.txtPeriodePoint is null or a.txtPeriodePoint='')    
 and a.txtreservationno is null    
 and a.intbasepoin<>0    
 and a.txtstatus ='COMPLETED'    
    
 update a -------    
 set  a.intperiod_membershipid=d.intperiodeid,a.txtperiodepoint=d.txtperiodepoint       
 from mtl_transaction_poin a         
 inner join CRM_4_NHD.NationalCRMDB.dbo.dmembership c with(nolock) on c.txtkontakid=a.txtkontakid    
 inner join CRM_4_NHD.NationalCRMDB.dbo.dmembershipperiode d with(nolock) on c.txtkontakid=d.txtkontakid    
 where a.txtNoSO in (select distinct rsrv_no from #cleansing)    
 and (a.intPeriod_MembershipID <> d.intperiodeid)    
 --and a.txtPeriodePoint <> d.txtPeriodePoint     
 and d.dttglawal<=cast(a.dtcreateddate as date)     
 and d.dttglakhir>=cast(a.dtcreateddate as date)    
 and (a.txtPeriodePoint is null or a.txtPeriodePoint='')    
 and a.txtreservationno is null    
 and a.intbasepoin<>0    
 and a.txtstatus ='COMPLETED'    
    
------------------------------------------------------------------------------------------    
    
 drop table #TrxComp     
 drop table #Phone1    
 drop table #cleansing      
         
end 