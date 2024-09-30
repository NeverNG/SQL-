select 
  tt_1.vbillcode, --订单编号
  tt_1.gysmc, --供应商名称
  tt_1.wlmc, --物料名称
  tt_1.sl, --数量
  tt_1.jldw, --计量单位
  round(tt_1.overdays,2) overdays,/*逾期天数*/ 
  tt_1.cgbm, --采购部门
  tt_1.cgy, --采购员
  tt_1.ydhwrk, --已到货未入库
  round(tt_1.dhts,2) dhts, --到货天数
  tt_1.ddsprq, --订单审批日期
  CURRENT_TIMESTAMP sjc
from
(
select 
poh.vbillcode, --订单编号
sup.name gysmc, --供应商名称
bdm.name wlmc, --物料名称
round(pob.nastnum,2) sl, --数量
mea.name jldw, --计量单位
substr(poh.vdef7, 0, 10) jhdhrq,--计划到货日期
round(case when regexp_like(substr(poh.vdef7, 0, 10), '^\d{4}-\d{2}-\d{2}$') then
  sysdate - to_date(substr(poh.vdef7, 0, 10), 'yyyy-MM-dd')                             
else
   0
end,2) as overdays,/*逾期天数*/
/*sysdate-(to_date(poh.taudittime,'yyyy-MM-dd hh24:mi:ss')+(case when regexp_like(bdm.def15,'^-?\d+(\.\d+)?$') then to_number(bdm.def15) else 0 end)) as overdays,*//*逾期天数*/ 
dept.name cgbm, --采购部门
psn.name cgy, --采购员
case when (nvl(arr.dhdxs,0)>0 and icpb.rkdwqz is null) or(icpb.rkdwqz > 0) then 1 else 0 end ydhwrk, --已到货未入库
case when regexp_like(bdm.def15,'^-?\d+(\.\d+)?$') then to_number(bdm.def15) else 0 end dhts, --到货天数
substr(poh.taudittime,0,10) ddsprq --订单审批日期
from whh_v_cgddrkqk rkqk
left join po_order poh
on rkqk.pk_order = poh.pk_order
left join bd_supplier sup
on poh.pk_supplier = sup.pk_supplier
left join po_order_b pob
on rkqk.pk_order_b = pob.pk_order_b
left join bd_material bdm
on pob.pk_material = bdm.pk_material
left join bd_measdoc mea
on pob.castunitid = mea.pk_measdoc
left join org_dept dept
on poh.pk_dept = dept.pk_dept
left join bd_psndoc psn
on poh.cemployeeid = psn.pk_psndoc
left join
(select
  arb.pk_order_b,
  count(1) dhdxs 
  from 
  po_arriveorder_b arb
  left join po_arriveorder arh
  on arh.pk_arriveorder = arb.pk_arriveorder
  where arb.dr = 0
  and arh.dr = 0
  and arh.fbillstatus = 3
  group by arb.pk_order_b) arr --到货单
on rkqk.pk_order_b = arr.pk_order_b
left join
      (select ic_purchasein_b.cfirstbillbid,
             sum(case when ic_purchasein_h.fbillflag = 3 then 0 else 1 end) rkdwqz --入库单未签字
      from ic_purchasein_b
      left join ic_purchasein_h
           on ic_purchasein_b.cgeneralhid = ic_purchasein_h.cgeneralhid
      where ic_purchasein_b.dr = 0
      and ic_purchasein_h.fbillflag != 1
      group by ic_purchasein_b.cfirstbillbid) icpb --采购入库单
on rkqk.pk_order_b = icpb.cfirstbillbid
left join org_purchaseorg purchaseorg
on pob.pk_org = purchaseorg.pk_purchaseorg
where rkqk.rkqk in ('未入库','未全部入库')
and dept.name not in ('采购科','汽配物资部','工程市场合同部','工程市场部','工程项目中心')
and (bdm.code like 'W%' or bdm.code like 'S%' or bdm.code like 'X%' or bdm.code like 'Q%')
and purchaseorg.code !='9182' --过滤采购组织是9182的数据
) tt_1
--where tt_1.overdays > 0
order by tt_1.overdays desc,tt_1.gysmc desc,tt_1.vbillcode desc,tt_1.wlmc desc
-- 逾期天数→供应商名称→订单编号→物料名称 全部降序