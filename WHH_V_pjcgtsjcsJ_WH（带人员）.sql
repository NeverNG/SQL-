create materialized view WHH_V_pjcgtsjcsJ_WH
build deferred
refresh force on demand
start with to_date('25-09-2024 23:59:29', 'dd-mm-yyyy hh24:mi:ss') next ADD_MONTHS(SYSDATE, 1) 
as
with pjcgtsjcsJ as( --平均采购天数基础数据
select
pjcgts.nd,
pjcgts.yearmth,
pjcgts.deptname,
pjcgts.psnname,
wlxx.part1,
wlxx.part2,
wlxx.part3,
wlxx.part4,
wlxx.part5,
wlxx.wlbm,
wlxx.wlmc,
nvl(pjcgts.pjcgts,0) pjcgts
from
(
select pk_material,
       nd,
       yearmth,
       deptname,
       psnname,
       avg(jhzxxhsj)pjcgts
from(
select
   --prb.pk_praybill_b,
   prb.pk_material,
   to_date(nvl(orderb.dealdate,to_char(sysdate,'yyyy-MM-dd HH24:MI:SS')),'yyyy-MM-dd HH24:MI:SS') -to_date(prh.dmakedate,'yyyy-MM-dd HH24:MI:SS') jhzxxhsj, --计划执行消耗时间(天)
   --row_number() over(partition by prb.pk_material order by prh.dmakedate desc) rn,
   substr(bd_accperiodmonth.yearmth,0,4) nd,
   bd_accperiodmonth.yearmth,
   psn.name psnname,
   dept.name deptname
from po_praybill_b prb
left join po_praybill prh
     on prb.pk_praybill = prh.pk_praybill
left join bd_material bdm
     on prb.pk_material = bdm.pk_material
left join bd_billtype bilty
     on prh.ctrantypeid = bilty.pk_billtypeid
left join bd_psndoc psn
     on prb.pk_employee = psn.pk_psndoc
left join (select pk_psndoc, pk_dept
    from (select distinct job.pk_psndoc,
                          job.pk_dept,
                          ROW_NUMBER() OVER(PARTITION BY job.pk_psndoc ORDER BY job.begindate desc) RN
            from hi_psnjob job where ismainjob='Y'
          )
   where rn = 1) psnjob
   on psn.pk_psndoc = psnjob.pk_psndoc
left join org_dept dept
     on psnjob.pk_dept = dept.pk_dept
left join (select
    distinct csourcebid,
    pk_order,
    pk_order_b,
    vbillcode,
    forderstatus,
    dealdate from
    (select
    ROW_NUMBER() OVER(PARTITION BY csourcebid ORDER BY dealdate desc) rnnum,
    csourcebid,
    pk_order,
    pk_order_b,
    vbillcode,
    forderstatus,
    dealdate
    from (
    select po_order_b.csourcebid,
           po_order_b.pk_order,
           po_order_b.pk_order_b,
           po_order.vbillcode,
           po_order.forderstatus,
           max(dealdate) dealdate
      from po_order_b
      left outer join po_order
        on po_order_b.pk_order = po_order.pk_order
      left join pub_workflownote pw
        on pw.billno = po_order.vbillcode
     where po_order_b.dr = 0
       AND po_order.bislatest = 'Y'
          /*and po_order.forderstatus = '3'*/
       and po_order.bislatest = 'Y'
    /*and po_order.bfinalclose = 'N'*/
    /*and po_order_b.bstockclose <> 'Y'*/
     group by po_order_b.csourcebid,
              po_order_b.pk_order,
              po_order_b.pk_order_b,
              po_order.vbillcode,
              po_order.forderstatus
    )) where rnnum= 1) orderb
    on prb.pk_praybill_b = orderb.csourcebid
left join org_purchaseorg purchaseorg
on prb.pk_purchaseorg = purchaseorg.pk_purchaseorg
left join bd_accperiodmonth bd_accperiodmonth
on substr(prh.creationtime, 0, 10) between
(substr(bd_accperiodmonth.BEGINDATE, 0, 10)) and
(substr(bd_accperiodmonth.ENDDATE, 0, 10))
where prb.dr = 0
  and prh.dr = 0
  and prb.nastnum !=0
  and prh.bislatest = 'Y'
  --and not((prh.fbillstatus = 5 or prb.browclose ='Y') and nvl(prb.naccumulatenum,0) =0)
  and not(prb.browclose ='Y' and prb.naccumulatenum = 0)
  and (bdm.code like 'W%' OR bdm.code  like 'S%' OR bdm.code  like 'X%' OR bdm.code  like 'Q%')
  and prb.vbdef1 != '~'
  --and prb.vbdef1 in (parameter('reqstoorg'))
  and bilty.billtypename='物资请购'
  and dept.name in (select name from bd_defdoc where dr = 0 and enablestate = 2
  and pk_defdoclist = '1001AZ10000000Y6ETNV' )
  --and substr(prh.creationtime, 0, 10) between '2024-08-26' and '2024-09-25'
  --and (SUBSTR(prh.dmakedate, 0, 10)  between parameter('starttime') and parameter('endtime'))
)
--where rn<=10
group by pk_material,
       nd,
       yearmth,
       deptname,
       psnname
) pjcgts
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
on pjcgts.pk_material = wlxx.pk_material
where nvl(pjcgts.pjcgts,0) !=0
),

cgzqmxb as (
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
coalesce(nullif(pjcgts,0),nullif(fifth_cgtsavg,0),nullif(fourth_cgtsavg,0),nullif(third_cgtsavg,0),nullif(second_cgtsavg,0),nullif(first_cgtsavg,0),0) pjcgts
 from
(
select
wlcgzqsjb.nd,
wlcgzqsjb.yearmth,
wlcgzqsjb.deptname,
wlcgzqsjb.psnname,
wlcgzqsjb.part1,
wlcgzqsjb.part2,
wlcgzqsjb.part3,
wlcgzqsjb.part4,
wlcgzqsjb.part5,
wlcgzqsjb.wlbm,
wlcgzqsjb.wlmc,
wlcgzqsjb.pjcgts,
nvl(first_cgzqsjb.cgtsavg,0) first_cgtsavg,
nvl(second_cgzqsjb.cgtsavg,0) second_cgtsavg,
nvl(third_cgzqsjb.cgtsavg,0) third_cgtsavg,
nvl(fourth_cgzqsjb.cgtsavg,0) fourth_cgtsavg,
nvl(fifth_cgzqsjb.cgtsavg,0) fifth_cgtsavg
from
(select nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5,wlbm,wlmc,pjcgts
  from pjcgtsjcsJ) wlcgzqsjb
left join
(select nd,yearmth,deptname,psnname,part1,
avg(pjcgts) cgtsavg
from pjcgtsjcsJ
where pjcgts != 0
group by nd,yearmth,deptname,psnname,part1) first_cgzqsjb
on wlcgzqsjb.nd = first_cgzqsjb.nd
and wlcgzqsjb.yearmth = first_cgzqsjb.yearmth
and wlcgzqsjb.deptname = first_cgzqsjb.deptname
and wlcgzqsjb.psnname = first_cgzqsjb.psnname
and wlcgzqsjb.part1 = first_cgzqsjb.part1
left join
(select nd,yearmth,deptname,psnname,part2,
avg(pjcgts) cgtsavg
from pjcgtsjcsJ
where pjcgts != 0
group by nd,yearmth,deptname,psnname,part2) second_cgzqsjb
on wlcgzqsjb.nd = second_cgzqsjb.nd
and wlcgzqsjb.yearmth = second_cgzqsjb.yearmth
and wlcgzqsjb.deptname = second_cgzqsjb.deptname
and wlcgzqsjb.psnname = second_cgzqsjb.psnname
and wlcgzqsjb.part2 = second_cgzqsjb.part2
left join
(select nd,yearmth,deptname,psnname,part3,
avg(pjcgts) cgtsavg
from pjcgtsjcsJ
where pjcgts != 0
group by nd,yearmth,deptname,psnname,part3) third_cgzqsjb
on wlcgzqsjb.nd = third_cgzqsjb.nd
and wlcgzqsjb.yearmth = third_cgzqsjb.yearmth
and wlcgzqsjb.deptname = third_cgzqsjb.deptname
and wlcgzqsjb.psnname = third_cgzqsjb.psnname
and wlcgzqsjb.part3 = third_cgzqsjb.part3
left join
(select nd,yearmth,deptname,psnname,part4,
avg(pjcgts) cgtsavg
from pjcgtsjcsJ
where pjcgts != 0
group by nd,yearmth,deptname,psnname,part4)fourth_cgzqsjb
on wlcgzqsjb.nd = fourth_cgzqsjb.nd
and wlcgzqsjb.yearmth = fourth_cgzqsjb.yearmth
and wlcgzqsjb.deptname = fourth_cgzqsjb.deptname
and wlcgzqsjb.psnname = fourth_cgzqsjb.psnname
and wlcgzqsjb.part4 = fourth_cgzqsjb.part4
left join
(select nd,yearmth,deptname,psnname,part5,
avg(pjcgts) cgtsavg
from pjcgtsjcsJ
where pjcgts != 0
group by nd,yearmth,deptname,psnname,part5) fifth_cgzqsjb
on wlcgzqsjb.nd = fifth_cgzqsjb.nd
and wlcgzqsjb.yearmth = fifth_cgzqsjb.yearmth
and wlcgzqsjb.deptname = fifth_cgzqsjb.deptname
and wlcgzqsjb.psnname = fifth_cgzqsjb.psnname
and wlcgzqsjb.part5 = fifth_cgzqsjb.part5
)
)

--查询
select nd,
yearmth,
deptname,
psnname,
avg(pjcgts) pjcgts from
(select
nd,
yearmth,
deptname,
psnname,
part2,
avg(pjcgts) pjcgts
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
coalesce(nullif(pjcgts_5,0),nullif(pjcgts_4,0),nullif(pjcgts_3,0),nullif(pjcgts_2,0),nullif(pjcgts_1,0),0) pjcgts
from(
select
first_cgzqsjb.nd,
first_cgzqsjb.yearmth,
first_cgzqsjb.deptname,
first_cgzqsjb.psnname,
first_cgzqsjb.part1,
second_cgzqsjb.part2,
third_cgzqsjb.part3,
fourth_cgzqsjb.part4,
fifth_cgzqsjb.part5,
nvl(first_cgzqsjb.pjcgts_1,0) pjcgts_1, --一级分类平均采购天数
nvl(second_cgzqsjb.pjcgts_2,0) pjcgts_2,--二级分类平均采购天数
nvl(third_cgzqsjb.pjcgts_3,0) pjcgts_3,--三级分类平均采购天数
nvl(fourth_cgzqsjb.pjcgts_4,0) pjcgts_4,--四级分类平均采购天数
nvl(fifth_cgzqsjb.pjcgts_5,0) pjcgts_5 --五级分类平均采购天数
from
(select nd,yearmth,deptname,psnname,part1,
avg(pjcgts_2) pjcgts_1
from (select nd,yearmth,deptname,psnname,part1,part2,
avg(pjcgts_3) pjcgts_2
from (select nd,yearmth,deptname,psnname,part1,part2,part3,
avg(pjcgts_4) pjcgts_3
from (select nd,yearmth,deptname,psnname,part1,part2,part3,part4,
avg(pjcgts_5) pjcgts_4
from (select nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5,
avg(pjcgts) pjcgts_5
from cgzqmxb
group by nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5)
group by nd,yearmth,deptname,psnname,part1,part2,part3,part4)
group by nd,yearmth,deptname,psnname,part1,part2,part3)
group by nd,yearmth,deptname,psnname,part1,part2)
group by nd,yearmth,deptname,psnname,part1) first_cgzqsjb
left join
(select nd,yearmth,deptname,psnname,part1,part2,
avg(pjcgts_3) pjcgts_2
from (select nd,yearmth,deptname,psnname,part1,part2,part3,
avg(pjcgts_4) pjcgts_3
from (select nd,yearmth,deptname,psnname,part1,part2,part3,part4,
avg(pjcgts_5) pjcgts_4
from (select nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5,
avg(pjcgts) pjcgts_5
from cgzqmxb
group by nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5)
group by nd,yearmth,deptname,psnname,part1,part2,part3,part4)
group by nd,yearmth,deptname,psnname,part1,part2,part3)
group by nd,yearmth,deptname,psnname,part1,part2) second_cgzqsjb
on first_cgzqsjb.nd = second_cgzqsjb.nd
and first_cgzqsjb.yearmth = second_cgzqsjb.yearmth
and first_cgzqsjb.deptname = second_cgzqsjb.deptname
and first_cgzqsjb.psnname = second_cgzqsjb.psnname
and first_cgzqsjb.part1 = second_cgzqsjb.part1
--and first_cgzqsjb.part2 = second_cgzqsjb.part2
left join
(select nd,yearmth,deptname,psnname,part1,part2,part3,
avg(pjcgts_4) pjcgts_3
from (select nd,yearmth,deptname,psnname,part1,part2,part3,part4,
avg(pjcgts_5) pjcgts_4
from (select nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5,
avg(pjcgts) pjcgts_5
from cgzqmxb
group by nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5)
group by nd,yearmth,deptname,psnname,part1,part2,part3,part4)
group by nd,yearmth,deptname,psnname,part1,part2,part3) third_cgzqsjb
on second_cgzqsjb.nd = third_cgzqsjb.nd
and second_cgzqsjb.yearmth = third_cgzqsjb.yearmth
and second_cgzqsjb.deptname = third_cgzqsjb.deptname
and second_cgzqsjb.psnname = third_cgzqsjb.psnname
and second_cgzqsjb.part1 = third_cgzqsjb.part1
and second_cgzqsjb.part2 = third_cgzqsjb.part2
--and second_cgzqsjb.part3 = third_cgzqsjb.part3
left join
(select nd,yearmth,deptname,psnname,part1,part2,part3,part4,
avg(pjcgts_5) pjcgts_4
from (select nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5,
avg(pjcgts) pjcgts_5
from cgzqmxb
group by nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5)
group by nd,yearmth,deptname,psnname,part1,part2,part3,part4) fourth_cgzqsjb
on third_cgzqsjb.nd = fourth_cgzqsjb.nd
and third_cgzqsjb.yearmth = fourth_cgzqsjb.yearmth
and third_cgzqsjb.deptname = fourth_cgzqsjb.deptname
and third_cgzqsjb.psnname = fourth_cgzqsjb.psnname
and third_cgzqsjb.part1 = fourth_cgzqsjb.part1
and third_cgzqsjb.part2 = fourth_cgzqsjb.part2
and third_cgzqsjb.part3 = fourth_cgzqsjb.part3
--and first_cgzqsjb.part4 = fourth_cgzqsjb.part4
left join
(select nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5,
avg(pjcgts) pjcgts_5
from cgzqmxb
group by nd,yearmth,deptname,psnname,part1,part2,part3,part4,part5) fifth_cgzqsjb
on fourth_cgzqsjb.nd = fifth_cgzqsjb.nd
and fourth_cgzqsjb.yearmth = fifth_cgzqsjb.yearmth
and fourth_cgzqsjb.deptname = fifth_cgzqsjb.deptname
and fourth_cgzqsjb.psnname = fifth_cgzqsjb.psnname
and fourth_cgzqsjb.part1 = fifth_cgzqsjb.part1
and fourth_cgzqsjb.part2 = fifth_cgzqsjb.part2
and fourth_cgzqsjb.part3 = fifth_cgzqsjb.part3
and fourth_cgzqsjb.part4 = fifth_cgzqsjb.part4
--and first_cgzqsjb.part5 = fifth_cgzqsjb.part5
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
psnname
