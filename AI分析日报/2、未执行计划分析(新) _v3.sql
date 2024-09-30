select 
    name wlmc, --物料名称
    materialspec ggxh, --规格型号
    measdocname jldw, --计量单位 
    wrksl sl, --数量
    pk_stockorgname sbdw, --申报单位 
    round(case when jhzxzq = 0 then null
         when to_date(dbilldate, 'yyyy-MM-dd hh24:mi:ss')+jhzxzq >= sysdate then null
         else sysdate - (to_date(dbilldate, 'yyyy-MM-dd hh24:mi:ss')+jhzxzq)
    end,2) yqts, --逾期天数 
    deptname, --采购部门
    psnname, --采购员
    case when (kjht='是' and jgspd='是') then 1 else 0 end yyjgwzd, --已有价格未制单 1是 0否
    case when wwcdd > 0 then 1 else 0  end yzdwspwc, --已制单未审批完成 1是 0否
    case when jhzxzq = 0 then 0
         when to_date(dbilldate, 'yyyy-MM-dd hh24:mi:ss')+jhzxzq >= sysdate then 0
         else 1
    end sfyq,--是否逾期 1是 0否 
    case when regexp_like(cgts,'^-?\d+(\.\d+)?$') then to_number(cgts) else 0 end cgts,--采购天数
    substr(dmakedate,0,10) zdrq --制单日期
from (
SELECT p.pk_praybill_b,
       p.deptname,
       psnname,
       p.code,
       p.name,
       p.materialspec,
       p.measdocname,
       p.def19,
       p.graphid,
       p.vbillcode,
       p.cannum - p.returnnum - p.ALREADYNUM wzxs,
       p.wrksl,
       p.sqbm,
       p.sqr,
       lxfs,
       p.ycj,
       p.cgzz,
       p.wlflmc, --物料分类名称
       p.wlflzj,--物料分类主键
       KJHT,--是否框架合同
       jgspd,--是否有价格审批单
       supname, --历史厂家
       case
         when p.cannum = 0 then
          0
         else
          p.ALREADYNUM / (p.cannum - p.returnnum)
       end zxl,
       p.dbilldate,
       p.dmakedate,
       p.pk_stockorgname,
       p.vbmemo,
       orderb.vbillcode orderbillcode,
       orderb.forderstatus forderstatus,
       orderb.soid,
       orderb.vmcode,
       case when p.pk_stockorgname = '东风特种汽车有限公司'
       then 
           case when jhzq.sborg = '0001AZ100000004DDM1B' then jhzq.jhzxzq
                when jhzq2.sborg = '0001AZ100000004DDM1B' then jhzq2.jhzxzq
           else nvl(gysjmb.jhzxzq, '15')
           end
       else 
         nvl(coalesce(jhzq.jhzxzq, jhzq2.jhzxzq, null), 0) 
       end as jhzxzq,
       cgddsl, --采购订单物资数量
       qgdsl, --请购单物资数量   
       is_send_yuncai,  --是否传云采 
       wwcdd,
       cgts
  from (
        select pk_praybill_b,
                pk_employee,
                pk_stockorgname,
                psnname,
                case when deptname = '辅料采购部' then '工程物资部' 
                     when deptname = '设备采购部' then '设备物资部'
                     when deptname = '辅料物资部' then '工程物资部'  
                 else deptname end deptname,
                   pk_marbasclass,
                pk_srcmaterial,
                code,
                name,
                materialspec,
                def19,
                graphid,
                measdocname,
                vbdef1,
                vbillcode,
                dbilldate,
                dmakedate,
                vbmemo,
                sqbm,
                sqr,
                lxfs,
                ycj,
                cgzz,
                wlflmc, --物料分类名称
                wlflzj,--物料分类主键
                supname, --历史厂家
                case when KJHT is null then '否' else '是' end KJHT,--是否框架合同
                case when jgspd is null then '否' else '是' end jgspd,--是否有价格审批单
                COUNT(pk_praybill_b) plannum,
                SUM(CASE
                      WHEN nastnum > 0 THEN
                       1
                      ELSE
                       0
                    END) cannum,
                SUM(CASE
                      WHEN nastnum = 0 THEN
                       1
                      ELSE
                       0
                    END) returnnum,
                sum(
                 CASE
                      WHEN  pk_order_b is not null and forderstatus = 3  and nastnum > 0  THEN
                       1
                      ELSE
                       0
                    END
                 )ALREADYNUM,
                sum(nastnum) wrksl,
                cgddsl, --采购订单物资数量
                qgdsl, --请购单物资数量
                is_send_yuncai,  --是否传云采
                --jhzxzq, --计划执行周期
                cgts
          from (SELECT distinct b.pk_praybill_b pk_praybill_b,
                                 case
                                   when b.pk_employee = '~' then
                                    '无'
                                   else
                                    b.pk_employee
                                 end as pk_employee,
                                 org_stockorg_v.name pk_stockorgname,
                                 case
                                   when b.pk_employee = '~' then
                                    '无'
                                   else
                                    psn.name
                                 end as psnname,
                                 case
                                   when b.pk_employee = '~' then
                                    '无'
                                   else
                                    dept.name
                                 end as deptname,
                                 b.pk_srcmaterial,
                                 bd_material_v.pk_marbasclass pk_marbasclass,
                                 bd_material_v.code code,
                                 bd_material_v.name name,
                                 bd_material_v.materialspec materialspec,
                                 bd_material_v.def19 def19,
                                 bd_material_v.def8 ycj, --原厂家
                                 bd_material_v.graphid graphid,
                                 bd_material_v.def6 cgts, --采购天数
                                 bd_marbasclass.name wlflmc, --物料分类名称
                                 bd_material_v.pk_marbasclass wlflzj,--物料分类主键
                                 case when regexp_like(bd_material_v.def6,'^-?\d+(\.\d+)?$') then to_number(bd_material_v.def6) else 0 end as jhzxzq, --计划执行周期_新
                                 bd_measdoc.name measdocname,
                                 b.nastnum,
                                 orderb.pk_order_b,
                                 orderb.forderstatus,
                                 orderb.cgddsl, --采购订单物资数量
                                 b.naccumulatenum qgdsl, --请购单物资数量
                                 b.vbdef1,
                                 h.vbillcode,
                                 h.dbilldate,
                                 h.dmakedate,
                                 b.vbmemo,
                                 org_purchaseorg_v.name cgzz, --采购组织
                                 sqdept.name sqbm,--毛需求申请部门
                                 nvl(bd_psndoc.name,cusr.user_name) sqr,--毛需求申请人
                                 nvl(bd_psndoc.mobile,bd_psndoc2.mobile) lxfs,  --毛需求申请人联系方式
                                 purp_priceaudit_material_user.bs KJHT, --是否框架合同
                                 purp_priceaudit_material_jgspd.bs jgspd, --是否有价格审批单
                                 supplierprice.supname supname, --历史厂家
                                 case when b.VBDEF2='是' then '是' else '否' end is_send_yuncai  --是否传云采
                   FROM po_praybill_b b
                   left outer join po_praybill h
                     on b.pk_praybill = h.pk_praybill
                   left join po_storereq_b psb_jxq--物资需求申请单子表(净需求)
                     on b.pk_praybill_b = psb_jxq.csourcebid2
                   left join po_storereq_b psb_mxq --物资需求申请单子表(毛需求)
                     on psb_jxq.pk_storereq_b = psb_mxq.csourcebid2
                   left join po_storereq psh_mxq ----物资需求申请单主表(毛需求)
                     on psb_mxq.pk_storereq = psh_mxq.pk_storereq
                   left join org_dept sqdept --毛需求申请部门
                     on psh_mxq.pk_appdepth_v = sqdept.pk_vid
                   left join bd_psndoc --毛需求申请人
                     on psh_mxq.pk_apppsnh = bd_psndoc.pk_psndoc
                   left join sm_user cusr --请购单制单人
                     on h.billmaker = cusr.cuserid
                   left join bd_psndoc bd_psndoc2 --请购单制单人联系方式
                     on cusr.pk_psndoc = bd_psndoc2.pk_psndoc
                   left outer join bd_material bd_material_v
                     on b.pk_srcmaterial = bd_material_v.pk_material
                   left join bd_marbasclass --物料基本分类
                     on bd_material_v.pk_marbasclass = bd_marbasclass.pk_marbasclass
                   left join org_purchaseorg_v
                     on b.pk_purchaseorg_v = org_purchaseorg_v.pk_vid
                   left join purp_priceaudit_material_user --是否框架合同
                     on b.pk_material = purp_priceaudit_material_user.BPK_MATERIAL
                   left join purp_priceaudit_material_jgspd --是否有价格审批单
                     on b.pk_material = purp_priceaudit_material_jgspd.BPK_MATERIAL
                   left join (select pk_material,supname from (
                      select row_number() over(partition by pk_material order by dvaliddate desc) rn,
                             dvaliddate,
                             pk_material,
                             purp_supplierprice.pk_supplier,
                             bd_supplier.name supname
                      from purp_supplierprice
                      left join bd_supplier
                      on purp_supplierprice.pk_supplier = bd_supplier.pk_supplier)
                      where rn =1) supplierprice
                     on b.pk_material = supplierprice.pk_material
    left outer join (select 
                  csourcebid,
                  pk_order,
                  pk_order_b,
                  vbillcode,
                  forderstatus,
                  dealdate,
                  cgddsl from           
                  (select  
                  ROW_NUMBER() OVER(PARTITION BY csourcebid ORDER BY dealdate desc) rnnum,
                  csourcebid,
                  pk_order,
                  pk_order_b,
                  vbillcode,
                  forderstatus,
                  dealdate,
                  cgddsl --采购订单数量
                  from (
                  select po_order_b.csourcebid,
                         po_order_b.pk_order,
                         po_order_b.pk_order_b,
                         po_order.vbillcode,
                         po_order.forderstatus,
                         max(dealdate) dealdate,
                         po_order_b.nastnum cgddsl --采购订单数量
                    from po_order_b
                    left outer join po_order
                      on po_order_b.pk_order = po_order.pk_order
                    left join pub_workflownote pw
                      on pw.billno = po_order.vbillcode
                   where po_order_b.dr = 0
                     AND po_order.bislatest = 'Y'

                     and po_order.bislatest = 'Y'
                   group by po_order_b.csourcebid,
                            po_order_b.pk_order,
                            po_order_b.pk_order_b,
                            po_order.vbillcode,
                            po_order.forderstatus,
                            po_order_b.nastnum
                  )) where rnnum= 1) orderb
                     on b.pk_praybill_b = orderb.csourcebid
                   left outer join bd_psndoc psn
                     on b.pk_employee = psn.pk_psndoc
                   left outer join (select pk_psndoc, pk_dept
                            from (select distinct job.pk_psndoc,
                                                  job.pk_dept,
                                                  ROW_NUMBER() OVER(PARTITION BY job.pk_psndoc ORDER BY job.begindate desc) RN
                                    from hi_psnjob job where job.ismainjob ='Y' 
                                    )
                           where rn = 1) psnjob
                     on psn.pk_psndoc = psnjob.pk_psndoc
                   left outer join org_dept dept
                     on psnjob.pk_dept = dept.pk_dept
                   left join bd_billtype bilty--单据类型
                  on h.ctrantypeid = bilty.pk_billtypeid
                   left outer join bd_measdoc bd_measdoc
                     on b.cunitid = bd_measdoc.pk_measdoc
                   left outer join org_stockorg org_stockorg_v
                     on b.vbdef1 = org_stockorg_v.pk_stockorg
                  WHERE b.dr = 0
              and h.dr = 0
              and (h.vbillcode!='QG2022031600010457' and bd_material_v.code!='W130102010594')--23年8.28号王锴联系王鸿辉需求
              and not (b.browclose = 'Y' and b.naccumulatenum = 0) --不统计行关闭数据且累计数量为0
              and h.bislatest = 'Y'
              and (bd_material_v.code  like 'W%' OR bd_material_v.code  like 'S%'OR bd_material_v.code  like 'X%' OR bd_material_v.code  like 'Q%')
              and bilty.billtypename = '物资请购'
              and dept.name in ('工程物资部','汽配物资部','设备物资部','生产物资部','行政物资部')--物资供应报表部门集
              )
         GROUP BY pk_praybill_b,
                   pk_employee,
                   pk_stockorgname,
                   psnname,
                   case when deptname = '辅料采购部' then '工程物资部' 
                        when deptname = '设备采购部' then '设备物资部'
                        when deptname = '辅料物资部' then '工程物资部'  
                        else deptname end ,
                   pk_marbasclass,
                   pk_srcmaterial,
                   code,
                   name,
                   materialspec,
                   def19,
                   graphid,
                   measdocname,
                   vbdef1,
                   vbillcode,
                   dbilldate,
                   dmakedate,
                   vbmemo,
                   sqbm,
                   sqr,
                   lxfs,
                   ycj,
                   cgzz,
                   wlflmc,
                   wlflzj,
                   KJHT,
                   jgspd,
                   supname,
                   cgddsl, --采购订单物资数量
                   qgdsl, --请购单物资数量
                   is_send_yuncai,  --是否传云采
                   cgts
                   ) p
  left outer join (select a.vbillcode,
                          case
                            when a.forderstatus = '0' then
                             '自由'
                            when a.forderstatus = '1' then
                             '提交'
                            when a.forderstatus = '2' then
                             '正在审批'
                            when a.forderstatus = '3' then
                             '审批通过'
                            when a.forderstatus = '4' then
                             '审批不通过'
                            when a.forderstatus = '5' then
                             '输出'
                            else
                             '无记录'
                          end forderstatus,
                          a.vdef4 soid,
                          a.vdef5 vmcode,
                          a.csourcebid
                     from (ybr_twq) a
                   ) orderb
    on p.pk_praybill_b = orderb.csourcebid
  left join (SELECT pk_defdoc, def1 as sborg, def4 wlfl, 
       def3 wlbm, def6 jhzxzq
       FROM bd_defdoc
       WHERE pk_defdoclist = '1001AZ10000000PS4Z1T'
       and dr = 0
       and enablestate = 2
       and def6 <> '~'
       and def3 <> '~'
) jhzq on p.pk_srcmaterial = jhzq.wlbm
left join ( select pk_defdoc,sborg, wlfl, jhzxzq from V_gxh_jhzq2_WH
) jhzq2 on p.pk_marbasclass = jhzq2.wlfl
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
on p.pk_srcmaterial = gysjmb.pk_material
left join 
(
  select csourcebid,
  count(1) wwcdd --未完成订单条数
   from po_order_b pob
  left join po_order poh
  on poh.pk_order = pob.pk_order
  where poh.forderstatus in (0,2) --自由、审批中
  and pob.dr = 0
  and poh.dr = 0
  and poh.bislatest ='Y'
  and csourcebid !='~'
  group by csourcebid
) pob_2    
 on p.pk_praybill_b = pob_2.csourcebid
 where p.cannum - p.ALREADYNUM > 0
)