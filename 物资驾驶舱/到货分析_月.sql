select
25 mbts,--Ŀ������ 
25/(sum(case when dhsc>180 then 180 else dhsc end)/count(pk_order_b))*100 dcl, --�����
sum(case when dhsc>180 then 180 else dhsc end)/count(pk_order_b) pjts,--���
to_char(sysdate,'yyyy-MM-dd') gxrq --��������
 from
(
select 
poh.pk_order,
pob.pk_order_b,
poh.taudittime, --��������ʱ��
rkqk.rkqk,
icpb.zzqzrq, --����ǩ������
dept.name BUMEN, --����
psn.name, --�ɹ�Ա
case when rkqk.rkqk in('�����','δȫ�����') 
  then to_date(substr(icpb.zzqzrq,0,10),'yyyy-MM-dd') - to_date(substr(poh.taudittime,0,10),'yyyy-MM-dd')
  else sysdate - to_date(substr(poh.taudittime,0,10),'yyyy-MM-dd') end dhsc--����ʱ��
from po_order_b pob
left join po_order poh
on pob.pk_order = poh.pk_order
left outer join bd_material m
on pob.pk_material = m.pk_material
left outer join bd_billtype meta
on poh.ctrantypeid = meta.pk_billtypeid
left join whh_v_cgddrkqk rkqk
on pob.pk_order_b = rkqk.pk_order_b
left join
(select 
  cfirstbillbid,
  taudittime zzqzrq --����ǩ������
from
(
select ic_purchasein_b.cfirstbillbid, --Դͷ���ݱ�������
       ic_purchasein_h.taudittime, --ǩ������ 
       row_number() over(partition by ic_purchasein_b.cfirstbillbid order by ic_purchasein_h.taudittime asc) rn
  from ic_purchasein_b
  left join ic_purchasein_h
    on ic_purchasein_b.cgeneralhid = ic_purchasein_h.cgeneralhid
 where ic_purchasein_h.dr = 0
   and ic_purchasein_b.dr = 0
   and ic_purchasein_h.fbillflag = 3
) where rn = 1) icpb
on icpb.cfirstbillbid = pob.pk_order_b
left join org_dept dept
on poh.pk_dept = dept.pk_dept
left join bd_psndoc psn
on poh.cemployeeid = psn.pk_psndoc
where pob.dr = 0
and poh.dr = 0
and poh.bislatest = 'Y'
and (poh.vdef20 is null or poh.vdef20='~')
and poh.forderstatus = 3
and (m.code like 'W%' or m.code like 'S%' or m.code like 'X%' or m.code like 'Q%')
and meta.pk_billtypecode in ('21-Cxx-09','21-Cxx-1','21-Cxx-24','21-Cxx-23')
and rkqk.rkqk in('�����','δȫ�����','δ���')
and dept.name in (select name from bd_defdoc where dr = 0 and enablestate = 2 
    and pk_defdoclist = '1001AZ10000000Y6ETNV') --���ʹ�Ӧ�����ż�
and substr(poh.dmakedate, 0, 10) between concat(to_char(add_months(sysdate, -1), 'yyyy-MM'), '-26') and to_char(sysdate, 'yyyy-MM-dd')
union all
select 
poh.pk_order,
pob.pk_order_b,
poh.taudittime, --��������ʱ��
rkqk.rkqk,
nvl(flow.dealdate,pobb.dbilldate), --����ǩ������
dept.name BUMEN, --����
psn.name, --�ɹ�Ա
case when rkqk.rkqk in('�����','δȫ�����') 
  then to_date(substr(nvl(flow.dealdate,pobb.dbilldate),0,10),'yyyy-MM-dd') - to_date(substr(poh.taudittime,0,10),'yyyy-MM-dd')
  else sysdate - to_date(substr(poh.taudittime,0,10),'yyyy-MM-dd') end dhsc --����ʱ��
from po_order_b pob
left join po_order poh
on pob.pk_order = poh.pk_order
left outer join bd_material m
on pob.pk_material = m.pk_material
left outer join bd_billtype meta
on poh.ctrantypeid = meta.pk_billtypeid
left join whh_v_cgddrkqk rkqk
on pob.pk_order_b = rkqk.pk_order_b
left join  pu_acceptance_check_b poab
  on poab.csrcbid = pob.pk_order_b 
left outer join  pu_acceptance_check poaa
  on poaa.pk_acceptance = poab.pk_acceptance
left join (
   select
    billid,
    dealdate
    from
    (select 
    billid,
    dealdate,
    row_number() over(partition by billid order by dealdate desc) rn
    from pub_workflownote
    where actiontype !='BIZ'
  and approvestatus = 1
    ) where rn = 1
)flow
on poab.pk_acceptance = flow.billid
left join po_order_bb pobb
on pob.pk_order_b = pobb.pk_order_b
and pobb.dr = 0
and pobb.fonwaystatus  = 2 --��;������ ȷ��
left join org_dept dept
on poh.pk_dept = dept.pk_dept
left join bd_psndoc psn
on poh.cemployeeid = psn.pk_psndoc
where pob.dr = 0
and poh.dr = 0
and poh.bislatest = 'Y'
and (poh.vdef20 is null or poh.vdef20='~')
and poh.forderstatus = 3
and (m.code like 'W%' or m.code like 'S%' or m.code like 'X%' or m.code like 'Q%')
and meta.pk_billtypecode in ('21-Cxx-13')
and rkqk.rkqk in('�����','δȫ�����','δ���')
and dept.name in (select name from bd_defdoc where dr = 0 and enablestate = 2 
    and pk_defdoclist = '1001AZ10000000Y6ETNV') --���ʹ�Ӧ�����ż�
and substr(poh.dmakedate, 0, 10) between concat(to_char(add_months(sysdate, -1), 'yyyy-MM'), '-26') and to_char(sysdate, 'yyyy-MM-dd')
union all
select 
poh.pk_order,
pob.pk_order_b,
poh.taudittime, --��������ʱ��
rkqk.rkqk,
pov.zzfpsj, --���緢Ʊʱ��
dept.name BUMEN, --����
psn.name, --�ɹ�Ա
case when rkqk.rkqk in('�����','δȫ�����') 
  then to_date(substr(pov.zzfpsj,0,10),'yyyy-MM-dd') - to_date(substr(poh.taudittime,0,10),'yyyy-MM-dd')
  else sysdate - to_date(substr(poh.taudittime,0,10),'yyyy-MM-dd') end dhsc--����ʱ��
from po_order_b pob
left join po_order poh
on pob.pk_order = poh.pk_order
left outer join bd_material m
on pob.pk_material = m.pk_material
left outer join bd_billtype meta
on poh.ctrantypeid = meta.pk_billtypeid
left join whh_v_cgddrkqk rkqk
on pob.pk_order_b = rkqk.pk_order_b
left join
(select pk_order_b,
taudittime zzfpsj --���緢Ʊʱ��
from(
select 
  povb.pk_order_b, 
  povh.taudittime,
  row_number() over(partition by povb.pk_order_b order by povh.taudittime asc) rn
  from po_invoice_b povb
  left join po_invoice povh
    on povb.pk_invoice = povh.pk_invoice
 where povb.dr = 0
   and povh.dr = 0
   and povh.fbillstatus = 3
) where rn = 1) pov
on pov.pk_order_b = pob.pk_order_b
left join org_dept dept
on poh.pk_dept = dept.pk_dept
left join bd_psndoc psn
on poh.cemployeeid = psn.pk_psndoc
where pob.dr = 0
and poh.dr = 0
and poh.bislatest = 'Y'
and (poh.vdef20 is null or poh.vdef20='~')
and poh.forderstatus = 3
and (m.code like 'W%' or m.code like 'S%' or m.code like 'X%' or m.code like 'Q%')
and meta.pk_billtypecode in ('21-Cxx-11')
and rkqk.rkqk in('�����','δȫ�����','δ���')
and dept.name in (select name from bd_defdoc where dr = 0 and enablestate = 2 
    and pk_defdoclist = '1001AZ10000000Y6ETNV') --���ʹ�Ӧ�����ż�
and substr(poh.dmakedate, 0, 10) between concat(to_char(add_months(sysdate, -1), 'yyyy-MM'), '-26') and to_char(sysdate, 'yyyy-MM-dd')
)
