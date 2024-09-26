/*create materialized view WHH_V_pjdhtsjcsJ_WH
build deferred
refresh force on demand
start with to_date('25-09-2024 23:59:29', 'dd-mm-yyyy hh24:mi:ss') next ADD_MONTHS(SYSDATE, 1) 
as*/
with pjdhtsjcsJ as( --平均到货天数基础数据
select
pjdhts.nd,
pjdhts.yearmth,
pjdhts.deptname,
pjdhts.psnname,
wlxx.part1,
wlxx.part2,
wlxx.part3,
wlxx.part4,
wlxx.part5,
wlxx.wlbm,
wlxx.wlmc,
/*wlxx.cgyzj,--采购员主键
wlxx.cgy, --物料分类采购员
wlxx.deptname, --采购部门*/
nvl(pjdhts.pjdhts,0) pjdhts
 from
(
select 
  nd,
  yearmth,
  deptname,
  psnname,
  pk_material,
  avg(dhsc) pjdhts
from
(
select 
nd,
yearmth,
deptname,
psnname,
pk_material,
case when dhsc>180 then 180 else dhsc end dhsc
--row_number() over(partition by pk_material order by dhtime desc) rn,
from(
select
pob.pk_material,
case when rkqk.rkqk in('已入库','未全部入库')
  then to_date(substr(icpb.zzqzrq,0,10),'yyyy-MM-dd') - to_date(substr(poh.taudittime,0,10),'yyyy-MM-dd')
  else sysdate - to_date(substr(poh.taudittime,0,10),'yyyy-MM-dd') end dhsc,
substr(bd_accperiodmonth.yearmth,0,4) nd,
bd_accperiodmonth.yearmth,
psn.name psnname,
dept.name deptname
from po_order_b pob
left join po_order poh
on pob.pk_order = poh.pk_order
left outer join bd_material m
on pob.pk_material = m.pk_material
left outer join bd_billtype meta
on poh.ctrantypeid = meta.pk_billtypeid
left join org_dept dept
on poh.pk_dept = dept.pk_dept
left join whh_v_cgddrkqk rkqk
on pob.pk_order_b = rkqk.pk_order_b
left join bd_accperiodmonth bd_accperiodmonth
on substr(poh.creationtime, 0, 10) between
(substr(bd_accperiodmonth.BEGINDATE, 0, 10)) and
(substr(bd_accperiodmonth.ENDDATE, 0, 10))
left join
(select
  cfirstbillbid,
  taudittime zzqzrq
from
(
select ic_purchasein_b.cfirstbillbid,
       ic_purchasein_h.taudittime,
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
and meta.pk_billtypecode in ('21-Cxx-09','21-Cxx-12','21-Cxx-24','21-Cxx-23')
and rkqk.rkqk in('已入库','未全部入库','未入库')
and dept.name in (select name from bd_defdoc where dr = 0 and enablestate = 2
    and pk_defdoclist = '1001AZ10000000Y6ETNV')
and substr(poh.creationtime, 0, 10) between '2024-08-26' and '2024-09-12'

union all
select
pob.pk_material,
case when rkqk.rkqk in('已入库','未全部入库')
  then to_date(substr(nvl(flow.dealdate,pobb.dbilldate),0,10),'yyyy-MM-dd') - to_date(substr(poh.taudittime,0,10),'yyyy-MM-dd')
  else sysdate - to_date(substr(poh.taudittime,0,10),'yyyy-MM-dd') end dhsc,
substr(bd_accperiodmonth.yearmth,0,4) nd,
bd_accperiodmonth.yearmth,
psn.name psnname,
dept.name deptname
from po_order_b pob
left join po_order poh
on pob.pk_order = poh.pk_order
left outer join bd_material m
on pob.pk_material = m.pk_material
left outer join bd_billtype meta
on poh.ctrantypeid = meta.pk_billtypeid
left join org_dept dept
on poh.pk_dept = dept.pk_dept
left join whh_v_cgddrkqk rkqk
on pob.pk_order_b = rkqk.pk_order_b
left join bd_accperiodmonth bd_accperiodmonth
on substr(poh.creationtime, 0, 10) between
(substr(bd_accperiodmonth.BEGINDATE, 0, 10)) and
(substr(bd_accperiodmonth.ENDDATE, 0, 10))
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
and pobb.fonwaystatus  = 2
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
and rkqk.rkqk in('已入库','未全部入库','未入库')
and dept.name in (select name from bd_defdoc where dr = 0 and enablestate = 2
    and pk_defdoclist = '1001AZ10000000Y6ETNV')
and substr(poh.creationtime, 0, 10) between '2024-08-26' and '2024-09-12'

union all
select
pob.pk_material,
case when rkqk.rkqk in('已入库','未全部入库')
  then to_date(substr(pov.zzfpsj,0,10),'yyyy-MM-dd') - to_date(substr(poh.taudittime,0,10),'yyyy-MM-dd')
  else sysdate - to_date(substr(poh.taudittime,0,10),'yyyy-MM-dd') end dhsc,
substr(bd_accperiodmonth.yearmth,0,4) nd,
bd_accperiodmonth.yearmth,
psn.name psnname,
dept.name deptname
from po_order_b pob
left join po_order poh
on pob.pk_order = poh.pk_order
left outer join bd_material m
on pob.pk_material = m.pk_material
left outer join bd_billtype meta
on poh.ctrantypeid = meta.pk_billtypeid
left join org_dept dept
on poh.pk_dept = dept.pk_dept
left join whh_v_cgddrkqk rkqk
on pob.pk_order_b = rkqk.pk_order_b
left join bd_accperiodmonth bd_accperiodmonth
on substr(poh.creationtime, 0, 10) between
(substr(bd_accperiodmonth.BEGINDATE, 0, 10)) and
(substr(bd_accperiodmonth.ENDDATE, 0, 10))
left join
(select pk_order_b,
taudittime zzfpsj
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
and rkqk.rkqk in('已入库','未全部入库','未入库')
and dept.name in (select name from bd_defdoc where dr = 0 and enablestate = 2
    and pk_defdoclist = '1001AZ10000000Y6ETNV')
and substr(poh.creationtime, 0, 10) between '2024-08-26' and '2024-09-12'
)
)
--where rn<=10
group by 
  nd,
  yearmth,
  deptname,
  psnname,
  pk_material
) pjdhts
left join 
(
select
distinct bdm.code wlbm,
bdm.name wlmc,
bdm.pk_material,
bdm.pk_marbasclass,
mar.part1,
mar.part2,
mar.part3,
mar.part4,
mar.part5
/*po_position_view.cemployeeid cgyzj, --采购员主键
psn.name cgy, --物料分类采购员
dept.name deptname --采购部门*/
from bd_material bdm
left join
(
select
    code,
    level,
    regexp_substr(sys_connect_by_path(code, '->'), '[^->]+', 1, 1) as part1,
    regexp_substr(sys_connect_by_path(code, '->'), '[^->]+', 1, 2) as part2,
    regexp_substr(sys_connect_by_path(code, '->'), '[^->]+', 1, 3) as part3,
    regexp_substr(sys_connect_by_path(code, '->'), '[^->]+', 1, 4) as part4,
    regexp_substr(sys_connect_by_path(code, '->'), '[^->]+', 1, 5) as part5,
    pk_marbasclass
from
    bd_marbasclass
start with
    code in ('W','S','X','Q')
connect by
    prior pk_marbasclass = pk_parent
)mar
on bdm.pk_marbasclass = mar.pk_marbasclass
where bdm.dr = 0
and bdm.enablestate = 2
and (bdm.code like 'W%' or bdm.code like 'S%' or bdm.code like 'X%' or bdm.code like 'Q%')
) wlxx
on pjdhts.pk_material = wlxx.pk_material
where nvl(pjdhts.pjdhts,0) !=0
),

dhzqmxb as (
select
distinct
nd,
yearmth,
deptname,
psnname,
part1,
part2,
part3,
part4,
part5,
wlbm,
wlmc,
coalesce(nullif(pjdhts,0),nullif(fifth_cgtsavg,0),nullif(fourth_cgtsavg,0),nullif(third_cgtsavg,0),nullif(second_cgtsavg,0),nullif(first_cgtsavg,0),0) pjdhts
 from
(
select
wldhzqsjb.nd,
wldhzqsjb.yearmth,
wldhzqsjb.deptname,
wldhzqsjb.psnname,
wldhzqsjb.part1,
wldhzqsjb.part2,
wldhzqsjb.part3,
wldhzqsjb.part4,
wldhzqsjb.part5,
wldhzqsjb.wlbm,
wldhzqsjb.wlmc,
wldhzqsjb.pjdhts,
nvl(first_dhzqsjb.cgtsavg,0) first_cgtsavg,
nvl(second_dhzqsjb.cgtsavg,0) second_cgtsavg,
nvl(third_dhzqsjb.cgtsavg,0) third_cgtsavg,
nvl(fourth_dhzqsjb.cgtsavg,0) fourth_cgtsavg,
nvl(fifth_dhzqsjb.cgtsavg,0) fifth_cgtsavg
from
(select nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5,wlbm,wlmc,pjdhts
  from pjdhtsjcsJ) wldhzqsjb
left join
(select nd,yearmth,deptname,psnname,part1,
avg(pjdhts) cgtsavg
from pjdhtsjcsJ
where pjdhts != 0
group by nd,yearmth,deptname,psnname,part1) first_dhzqsjb
on wldhzqsjb.nd = first_dhzqsjb.nd
and wldhzqsjb.yearmth = first_dhzqsjb.yearmth
and wldhzqsjb.deptname = first_dhzqsjb.deptname
and wldhzqsjb.psnname = first_dhzqsjb.psnname
and wldhzqsjb.part1 = first_dhzqsjb.part1
left join
(select nd,yearmth,deptname,psnname,part2,
avg(pjdhts) cgtsavg
from pjdhtsjcsJ
where pjdhts != 0
group by nd,yearmth,deptname,psnname,part2) second_dhzqsjb
on wldhzqsjb.nd = second_dhzqsjb.nd
and wldhzqsjb.yearmth = second_dhzqsjb.yearmth
and wldhzqsjb.deptname = second_dhzqsjb.deptname
and wldhzqsjb.psnname = second_dhzqsjb.psnname
and wldhzqsjb.part2 = second_dhzqsjb.part2
left join
(select nd,yearmth,deptname,psnname,part3,
avg(pjdhts) cgtsavg
from pjdhtsjcsJ
where pjdhts != 0
group by nd,yearmth,deptname,psnname,part3) third_dhzqsjb
on wldhzqsjb.nd = third_dhzqsjb.nd
and wldhzqsjb.yearmth = third_dhzqsjb.yearmth
and wldhzqsjb.deptname = third_dhzqsjb.deptname
and wldhzqsjb.psnname = third_dhzqsjb.psnname
and wldhzqsjb.part3 = third_dhzqsjb.part3
left join
(select nd,yearmth,deptname,psnname,part4,
avg(pjdhts) cgtsavg
from pjdhtsjcsJ
where pjdhts != 0
group by nd,yearmth,deptname,psnname,part4)fourth_dhzqsjb
on wldhzqsjb.nd = fourth_dhzqsjb.nd
and wldhzqsjb.yearmth = fourth_dhzqsjb.yearmth
and wldhzqsjb.deptname = fourth_dhzqsjb.deptname
and wldhzqsjb.psnname = fourth_dhzqsjb.psnname
and wldhzqsjb.part4 = fourth_dhzqsjb.part4
left join
(select nd,yearmth,deptname,psnname,part5,
avg(pjdhts) cgtsavg
from pjdhtsjcsJ
where pjdhts != 0
group by nd,yearmth,deptname,psnname,part5) fifth_dhzqsjb
on wldhzqsjb.nd = fifth_dhzqsjb.nd
and wldhzqsjb.yearmth = fifth_dhzqsjb.yearmth
and wldhzqsjb.deptname = fifth_dhzqsjb.deptname
and wldhzqsjb.psnname = fifth_dhzqsjb.psnname
and wldhzqsjb.part5 = fifth_dhzqsjb.part5
)
)

--查询
select nd,
yearmth,
deptname,
psnname,
avg(pjdhts) pjdhts from
(select
nd,
yearmth,
deptname,
psnname,
part2,
avg(pjdhts) pjdhts
from(
select
nd,
yearmth,
deptname,
psnname,
part1,
decode(part2,part1,null,part2) part2,
decode(part3,part2,null,part3) part3,
decode(part4,part3,null,part4) part4,
decode(part5,part4,null,part5) part5,
coalesce(nullif(pjdhts_5,0),nullif(pjdhts_4,0),nullif(pjdhts_3,0),nullif(pjdhts_2,0),nullif(pjdhts_1,0),0) pjdhts
from(
select
first_dhzqsjb.nd,
first_dhzqsjb.yearmth,
first_dhzqsjb.deptname,
first_dhzqsjb.psnname,
first_dhzqsjb.part1,
second_dhzqsjb.part2,
third_dhzqsjb.part3,
fourth_dhzqsjb.part4,
fifth_dhzqsjb.part5,
nvl(first_dhzqsjb.pjdhts_1,0) pjdhts_1, --一级分类平均采购天数
nvl(second_dhzqsjb.pjdhts_2,0) pjdhts_2,--二级分类平均采购天数
nvl(third_dhzqsjb.pjdhts_3,0) pjdhts_3,--三级分类平均采购天数
nvl(fourth_dhzqsjb.pjdhts_4,0) pjdhts_4,--四级分类平均采购天数
nvl(fifth_dhzqsjb.pjdhts_5,0) pjdhts_5 --五级分类平均采购天数
from
(select nd,yearmth,deptname,psnname,part1,
avg(pjdhts_2) pjdhts_1
from (select nd,yearmth,deptname,psnname,part1,part2,
avg(pjdhts_3) pjdhts_2
from (select nd,yearmth,deptname,psnname,part1,part2,part3,
avg(pjdhts_4) pjdhts_3
from (select nd,yearmth,deptname,psnname,part1,part2,part3,part4,
avg(pjdhts_5) pjdhts_4
from (select nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5,
avg(pjdhts) pjdhts_5
from dhzqmxb
group by nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5)
group by nd,yearmth,deptname,psnname,part1,part2,part3,part4)
group by nd,yearmth,deptname,psnname,part1,part2,part3)
group by nd,yearmth,deptname,psnname,part1,part2)
group by nd,yearmth,deptname,psnname,part1) first_dhzqsjb
left join
(select nd,yearmth,deptname,psnname,part1,part2,
avg(pjdhts_3) pjdhts_2
from (select nd,yearmth,deptname,psnname,part1,part2,part3,
avg(pjdhts_4) pjdhts_3
from (select nd,yearmth,deptname,psnname,part1,part2,part3,part4,
avg(pjdhts_5) pjdhts_4
from (select nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5,
avg(pjdhts) pjdhts_5
from dhzqmxb
group by nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5)
group by nd,yearmth,deptname,psnname,part1,part2,part3,part4)
group by nd,yearmth,deptname,psnname,part1,part2,part3)
group by nd,yearmth,deptname,psnname,part1,part2) second_dhzqsjb
on first_dhzqsjb.nd = second_dhzqsjb.nd
and first_dhzqsjb.yearmth = second_dhzqsjb.yearmth
and first_dhzqsjb.deptname = second_dhzqsjb.deptname
and first_dhzqsjb.psnname = second_dhzqsjb.psnname
and first_dhzqsjb.part1 = second_dhzqsjb.part1
--and first_dhzqsjb.part2 = second_dhzqsjb.part2
left join
(select nd,yearmth,deptname,psnname,part1,part2,part3,
avg(pjdhts_4) pjdhts_3
from (select nd,yearmth,deptname,psnname,part1,part2,part3,part4,
avg(pjdhts_5) pjdhts_4
from (select nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5,
avg(pjdhts) pjdhts_5
from dhzqmxb
group by nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5)
group by nd,yearmth,deptname,psnname,part1,part2,part3,part4)
group by nd,yearmth,deptname,psnname,part1,part2,part3) third_dhzqsjb
on second_dhzqsjb.nd = third_dhzqsjb.nd
and second_dhzqsjb.yearmth = third_dhzqsjb.yearmth
and second_dhzqsjb.deptname = third_dhzqsjb.deptname
and second_dhzqsjb.psnname = third_dhzqsjb.psnname
and second_dhzqsjb.part1 = third_dhzqsjb.part1
and second_dhzqsjb.part2 = third_dhzqsjb.part2
--and second_dhzqsjb.part3 = third_dhzqsjb.part3
left join
(select nd,yearmth,deptname,psnname,part1,part2,part3,part4,
avg(pjdhts_5) pjdhts_4
from (select nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5,
avg(pjdhts) pjdhts_5
from dhzqmxb
group by nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5)
group by nd,yearmth,deptname,psnname,part1,part2,part3,part4) fourth_dhzqsjb
on third_dhzqsjb.nd = fourth_dhzqsjb.nd
and third_dhzqsjb.yearmth = fourth_dhzqsjb.yearmth
and third_dhzqsjb.deptname = fourth_dhzqsjb.deptname
and third_dhzqsjb.psnname = fourth_dhzqsjb.psnname
and third_dhzqsjb.part1 = fourth_dhzqsjb.part1
and third_dhzqsjb.part2 = fourth_dhzqsjb.part2
and third_dhzqsjb.part3 = fourth_dhzqsjb.part3
--and first_dhzqsjb.part4 = fourth_dhzqsjb.part4
left join
(select nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5,
avg(pjdhts) pjdhts_5
from dhzqmxb
group by nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5) fifth_dhzqsjb
on fourth_dhzqsjb.nd = fifth_dhzqsjb.nd
and fourth_dhzqsjb.yearmth = fifth_dhzqsjb.yearmth
and fourth_dhzqsjb.deptname = fifth_dhzqsjb.deptname
and fourth_dhzqsjb.psnname = fifth_dhzqsjb.psnname
and fourth_dhzqsjb.part1 = fifth_dhzqsjb.part1
and fourth_dhzqsjb.part2 = fifth_dhzqsjb.part2
and fourth_dhzqsjb.part3 = fifth_dhzqsjb.part3
and fourth_dhzqsjb.part4 = fifth_dhzqsjb.part4
--and first_dhzqsjb.part5 = fifth_dhzqsjb.part5
)
)
group by nd,
yearmth,
deptname,
psnname,
part2
)
group by
nd,
yearmth,
deptname,
psnname;
