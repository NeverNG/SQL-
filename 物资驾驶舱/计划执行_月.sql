select
  3 mbts,--目标天数 
  round(sum(jhzxxhsj)/count(tt1.pk_praybill_b),2) pjcgts, --达成
  3/(sum(jhzxxhsj)/count(tt1.pk_praybill_b))*100 dcl,--达成率
  to_char(sysdate,'yyyy-MM-dd') gxrq --更新日期
from
(select
    distinct prb.pk_praybill_b,
    prb.nastnum nastnum,
    case when dept.name = '辅料采购部' then '工程物资部' 
      when dept.name = '设备采购部' then '设备物资部'
      when dept.name = '辅料物资部' then '工程物资部' 
      else dept.name end deptname, --部门
    case when prb.naccumulatenum > 0 and orderb.forderstatus=3 then 1 else 0 end sfycg, --是否已采购
    case when org.name = '东风特种汽车有限公司'
     then 
         case when jhzq.sborg = '0001AZ100000004DDM1B' then jhzq.jhzxzq
              when jhzq2.sborg = '0001AZ100000004DDM1B' then jhzq2.jhzxzq
         else nvl(gysjmb.jhzxzq, '15') 
         end
     else 
         nvl(coalesce(jhzq.jhzxzq, jhzq2.jhzxzq, null), 999) --如果没有计划执行周期，就无期限
     end as jhzxzq, --计划执行周期
   to_date(nvl(orderb.dealdate,to_char(sysdate,'yyyy-MM-dd HH24:MI:SS')),'yyyy-MM-dd HH24:MI:SS') -to_date(prh.dmakedate,'yyyy-MM-dd HH24:MI:SS') jhzxxhsj --计划执行消耗时间
from po_praybill_b prb
left join po_praybill prh
     on prb.pk_praybill = prh.pk_praybill
left join bd_material bdm
     on prb.pk_srcmaterial = bdm.pk_material
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
left join bd_billtype bilty--单据类型
     on prh.ctrantypeid = bilty.pk_billtypeid
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
left join (SELECT pk_defdoc, def1 as sborg, def4 wlfl, 
       def3 wlbm, def6 jhzxzq
       FROM bd_defdoc
       WHERE pk_defdoclist = '1001AZ10000000PS4Z1T'
       and dr = 0
       and enablestate = 2
       and def6 <> '~'
       and def3 <> '~'
) jhzq 
  on prb.pk_srcmaterial = jhzq.wlbm
left join (select pk_defdoc,sborg, wlfl, jhzxzq from V_gxh_jhzq2_WH
) jhzq2 
  on bdm.pk_marbasclass = jhzq2.wlfl
left join org_stockorg org
     on prb.vbdef1 = org.pk_stockorg
left join (
     select a.pk_org, a.pk_supplier, a.pk_material, bdm.code,  a.nastorigtaxprice ,a.dvaliddate , '3' as jhzxzq,
      row_number()over(partition by a.pk_supplier,bdm.code order by a.tcreatetime desc,a.dvaliddate desc)rn
      from purp_supplierprice a
      left join org_purchaseorg b
      on a.pk_org = b.pk_purchaseorg
      left join bd_supplier bds
      on bds.pk_supplier = a.pk_supplier
      left join bd_material bdm
      on bdm.pk_material = a.pk_material
      where a.dr = 0 
      and a.pk_org = '0001AZ100000004DDM1B'  /*东风特种汽车有限公司*/
      and to_char(sysdate,'yyyy-mm-dd hh24:mi:ss') between a.dvaliddate and a.dinvaliddate
) gysjmb 
on prb.pk_srcmaterial = gysjmb.pk_material
left join org_purchaseorg purchaseorg
on prb.pk_purchaseorg = purchaseorg.pk_purchaseorg
where prb.dr = 0
  and prh.dr = 0
  and prb.nastnum !=0 --数量不为0
  and prh.bislatest = 'Y'
  --and not((prh.fbillstatus = 5 or prb.browclose ='Y') and nvl(prb.naccumulatenum,0) =0)
  and not(prb.browclose ='Y' and prb.naccumulatenum = 0)
  and (prh.vbillcode!='QG2022031600010457' and bdm.code!='W130102010594')--23年8.28号王锴联系王鸿辉需求
  and (bdm.code  like 'W%' OR bdm.code  like 'S%'OR bdm.code  like 'X%' OR bdm.code like 'Q%')
  and (SUBSTR(prh.dmakedate, 0, 10) between concat(to_char(add_months(sysdate, -1), 'yyyy-MM'), '-26') and to_char(sysdate, 'yyyy-MM-dd'))
  and prb.vbdef1 != '~' 
  and bilty.billtypename='物资请购'
  and dept.name in (select name from bd_defdoc where dr = 0 and enablestate = 2
  and pk_defdoclist = '1001AZ10000000Y6ETNV' )--物资供应报表部门集
  and purchaseorg.code !='9182' --过滤采购组织是9182的数据
) tt1
where tt1.deptname not in('采购科','工程市场合同部','工程市场部')
