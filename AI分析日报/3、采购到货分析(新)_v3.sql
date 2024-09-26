select 
  tt1.deptname, --采购部门
  tt1.shouldnum, --应到货项数
  tt1.icnum, --已到货项数
  tt1.dhl,--物资到货率
  tt1.yqdhnum,  --逾期到货项数
  tt1.yqbl,--逾期比例
  tt1.wdhnum, --未到货项数
  tt2.pjdhts avgarrdays --平均天数
 from (
select
  YEARMTH,
  deptname, --采购部门
  shouldnum, --应到货项数
  icnum, --已到货项数
  dhl,--物资到货率
  yqdhnum,  --逾期到货项数
  yqbl,--逾期比例
  wdhnum, --未到货项数
  avgarrdays --平均天数
from
(
select YEARMTH,
       --month|| '月份' month,
       case when deptname = '辅料采购部' then '工程物资部' 
            when deptname = '设备采购部' then '设备物资部'
            when deptname = '辅料物资部' then '工程物资部'  
             else deptname end deptname, --采购部门
       --sum(ordernum) ordernum, --订单项数
       --sum(closenum) closenum, --关闭项数
       sum(ordernum - closenum) shouldnum, --应到货项数
       sum(icnum) icnum, --已到货项数
       round(case when sum(ordernum - closenum) = 0 then 0 else sum(icnum)/sum(ordernum - closenum) end,2) dhl,--物资到货率
       sum(yqdhnum) yqdhnum,  --逾期到货项数 
       round(case when sum(ordernum - closenum) = 0 then 0 else sum(yqdhnum)/sum(ordernum - closenum) end,2) yqbl,--逾期比例
       sum(ordernum - closenum-icnum) wdhnum, --未到货项数
       --sum(jsdhnum) jsdhnum, --及时到货项数
       --sum(arrdays) arrdays,
       round(case when sum(icnum) = 0 then 0 else sum(arrdays) / sum(icnum) end,2) as avgarrdays --平均天数
       /*case
         when sum(ordernum - closenum) = 0 then
          0
         else
          sum(jsdhnum) / sum(ordernum - closenum)
       end jsdhl*/
  from (select bd_accperiodmonth.YEARMTH      YEARMTH,
               bd_accperiodmonth.ACCPERIODMTH month,
               dept.name                      deptname,
               count(b.pk_material) ordernum,
               sum(
                 case
                       /*when b.bstockclose = 'Y' and (b.naccumstorenum is null or b.naccumstorenum=0) */
                       when nvl(b.naccumstorenum,0)=0
                         then
                         0
                         else 
                         case when icb.dbizdate is null then sysdate -  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss') 
                              else (to_date(icb.dbizdate, 'yyyy-MM-dd hh24:mi:ss')-  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss')) 
                         end 
                  end
                ) as arrdays,
               sum(case
                     when nvl(b.naccumstorenum,0)=0 then
                      0
                     else
                      1
                   end) icnum,
               /*count(icb.cmaterialoid) icnum,*/
               sum(case
                     when b.bstockclose = 'Y' and (b.naccumstorenum is null or b.naccumstorenum=0) then
                      1
                     else
                      0
                   end) closenum,
               sum(CASE
                     WHEN ((
                 case
                       /*when b.bstockclose = 'Y' and (b.naccumstorenum is null or b.naccumstorenum=0) */
                       when nvl(b.naccumstorenum,0)=0
                         then
                         0
                         else 
                         case when icb.dbizdate is null then sysdate -  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss') 
                              else (to_date(icb.dbizdate, 'yyyy-MM-dd hh24:mi:ss')-  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss')) 
                         end 
                  end
                )<=(case when regexp_like(m.def15,'^-?\d+(\.\d+)?$') then to_number(m.def15) else 0 end)) THEN
                      1
                     ELSE
                      0
                   END) jsdhnum,
               sum(CASE
                     WHEN ((
                 case
                       /*when b.bstockclose = 'Y' and (b.naccumstorenum is null or b.naccumstorenum=0) */
                       when nvl(b.naccumstorenum,0)=0
                         then
                         0
                         else 
                         case when icb.dbizdate is null then sysdate -  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss') 
                              else (to_date(icb.dbizdate, 'yyyy-MM-dd hh24:mi:ss')-  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss')) 
                         end 
                  end
                )>(case when regexp_like(m.def15,'^-?\d+(\.\d+)?$') then to_number(m.def15) else 0 end)) THEN
                      1
                     ELSE
                      0
                   END) yqdhnum  --逾期到货项数
          from po_order_b b
          left outer join po_order h
            on b.pk_order = h.pk_order
          left outer join bd_psndoc psn
            on h.cemployeeid = psn.pk_psndoc
          left outer join org_dept dept
            on h.pk_dept = dept.pk_dept
         left outer join bd_supplier bd_supplier
            on h.pk_supplier = bd_supplier.pk_supplier
          LEFT OUTER JOIN 
          (select dbizdate, csourcebillbid, cmaterialoid
  from (select dbizdate,
               csourcebillbid,
               cmaterialoid,
               ROW_NUMBER() OVER(PARTITION BY csourcebillbid ORDER BY dbizdate asc) RN
          from (SELECT DISTINCT purinb.dbizdate,
                                purinb.csourcebillbid,
                                purinb.cmaterialoid
                /*ROW_NUMBER() OVER(PARTITION BY purinb.csourcebillbid ORDER BY purinb.csourcebillbid, purinb.dbizdate) RN*/
                  FROM ic_purchasein_b purinb
                  LEFT OUTER JOIN ic_purchasein_h purinh
                    ON purinb.cgeneralhid = purinh.cgeneralhid
                 WHERE purinb.dr = 0
                   and purinb.nnum <> 0
                   and purinb.csourcetype = '21' /*来源单据是采购订单*/
                union all
                SELECT DISTINCT purinb.dbizdate,
                                arriveb.csourcebid,
                                purinb.cmaterialoid
                /*ROW_NUMBER() OVER(PARTITION BY purinb.csourcebillbid ORDER BY purinb.csourcebillbid, purinb.dbizdate) RN*/
                  FROM ic_purchasein_b purinb
                  LEFT OUTER JOIN ic_purchasein_h purinh
                    ON purinb.cgeneralhid = purinh.cgeneralhid
                  left outer join po_arriveorder_b arriveb
                    on purinb.csourcebillbid = arriveb.pk_arriveorder_b
                 WHERE purinb.dr = 0
                   and purinb.nnum <> 0
                   and purinb.csourcetype = '23' /*来源单据是到货单*/
                ))
              where RN = 1) icb
          on (b.pk_order_b = icb.csourcebillbid)
          left outer join bd_material m
            on b.pk_material = m.pk_material
          LEFT outer JOIN bd_billtype meta
            ON h.ctrantypeid = meta.pk_billtypeid
          left join bd_accperiodmonth bd_accperiodmonth
            on substr(h.vdef7, 0, 10) between
               (substr(bd_accperiodmonth.BEGINDATE, 0, 10)) and
               (substr(bd_accperiodmonth.ENDDATE, 0, 10))
          left join bd_accperiodmonth acmonth_2
            on to_char(sysdate,'yyyy-MM-dd') between
               (substr(acmonth_2.BEGINDATE, 0, 10)) and
               (substr(acmonth_2.ENDDATE, 0, 10))
          left join org_purchaseorg purchaseorg
            on b.pk_org = purchaseorg.pk_purchaseorg
         where (m.code like 'W%' or m.code like 'S%'  or m.code like 'X%' or m.code like 'Q%')
           and h.bislatest = 'Y'
           and (h.vdef20 is null or h.vdef20 = '~')
           and b.dr = 0
           and bd_supplier.supprop <> 1
           and meta.pk_billtypecode in ('21-Cxx-09','21-Cxx-12','21-Cxx-23','21-Cxx-24')
           /*and substr(h.vdef7, 0, 10) >= to_char(sysdate-7,'yyyy-MM-dd')
           and substr(h.vdef7, 0, 10) <= to_char(sysdate,'yyyy-MM-dd')*/
           AND (SUBSTR(h.vdef7, 0, 10) between substr(acmonth_2.BEGINDATE,0,10) and substr(acmonth_2.ENDDATE,0,10))
           and dept.name in (select name from bd_defdoc where dr = 0 and enablestate = 2 
           and pk_defdoclist = '1001AZ10000000Y6ETNV') --物资供应报表部门集
           AND (b.bstockclose = 'N' OR
                                 (b.bstockclose = 'Y' AND nvl(b.naccumstorenum, 0) <> 0)  OR
                                 (b.bstockclose = 'Y' AND b.naccumstorenum=0))
           AND h.forderstatus = '3'
           and purchaseorg.code !='9182' --过滤采购组织是9182的数据
         group by bd_accperiodmonth.YEARMTH,
                  bd_accperiodmonth.ACCPERIODMTH,
                  dept.name
           union all
          select bd_accperiodmonth.YEARMTH      YEARMTH,
               bd_accperiodmonth.ACCPERIODMTH month,
               dept.name                      deptname,
               count(b.pk_material) ordernum,
               sum(
               case 
                 /*when b.bstockclose = 'Y'*/
                 when bb.fonwaystatus = '2' and bb.isoperated = 'Y'
                 then 
                   case when bb.dbilldate is null then sysdate -  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss') 
                        else (to_date(bb.dbilldate, 'yyyy-MM-dd hh24:mi:ss')-  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss')) 
                   end 
                 else 
                   0
                 end
               ) as arrdays,
               
               /*sum(case
                     when bb.fonwaystatus = '2' and bb.isoperated = 'Y' then
                      1
                     else
                      0
                   end) icnum,*/
               count(distinct poab.pk_acceptance_b )icnum,
               sum(case
                     when b.bstockclose = 'Y' then
                      1
                     else
                      0
                   end) closenum,
               sum(CASE
                     WHEN ((
               case 
                 /*when b.bstockclose = 'Y'*/
                 when bb.fonwaystatus = '2' and bb.isoperated = 'Y'
                 then 
                   case when bb.dbilldate is null then sysdate -  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss') 
                        else (to_date(bb.dbilldate, 'yyyy-MM-dd hh24:mi:ss')-  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss')) 
                   end 
                 else 
                   0
                 end
               )<=(case when regexp_like(m.def15,'^-?\d+(\.\d+)?$') then to_number(m.def15) else 0 end)) THEN
                      1
                     ELSE
                      0
                   END) jsdhnum,
               sum(CASE
                     WHEN ((
               case 
                 /*when b.bstockclose = 'Y'*/
                 when bb.fonwaystatus = '2' and bb.isoperated = 'Y'
                 then 
                   case when bb.dbilldate is null then sysdate -  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss') 
                        else (to_date(bb.dbilldate, 'yyyy-MM-dd hh24:mi:ss')-  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss')) 
                   end 
                 else 
                   0
                 end
               )>(case when regexp_like(m.def15,'^-?\d+(\.\d+)?$') then to_number(m.def15) else 0 end)) THEN
                      1
                     ELSE
                      0
                   END) yqdhnum  --逾期到货项数
         from po_order_b b
          left outer join po_order h
            on b.pk_order = h.pk_order
          -- ++++++++++++++++++++++++++++++++
          left outer join  pu_acceptance_check_b poab
            on poab.csrcbid = b.pk_order_b 
          left outer join  pu_acceptance_check poaa
            on (poaa.pk_acceptance = poab.pk_acceptance and poaa.approvestatus = 1)
            -- ++++++++++++++++++++++++++++++++++++++
          left outer join bd_psndoc psn
            on h.cemployeeid = psn.pk_psndoc
          left outer join org_dept dept
            on h.pk_dept = dept.pk_dept
          left outer join po_order_bb bb
            on b.pk_order_b = bb.pk_order_b
         left outer join bd_material m
            on b.pk_material = m.pk_material
          LEFT outer JOIN bd_billtype meta
            ON h.ctrantypeid = meta.pk_billtypeid
            left outer join bd_supplier bd_supplier
            on h.pk_supplier = bd_supplier.pk_supplier
          left join bd_accperiodmonth bd_accperiodmonth
            on substr(h.vdef7, 0, 10) between
               (substr(bd_accperiodmonth.BEGINDATE, 0, 10)) and
               (substr(bd_accperiodmonth.ENDDATE, 0, 10))
          left join bd_accperiodmonth acmonth_2
            on to_char(sysdate,'yyyy-MM-dd') between
               (substr(acmonth_2.BEGINDATE, 0, 10)) and
               (substr(acmonth_2.ENDDATE, 0, 10))
          left join org_purchaseorg purchaseorg
            on b.pk_org = purchaseorg.pk_purchaseorg
         where (m.code like 'W%' or m.code like 'S%' or m.code like 'X%' or m.code like 'Q%')
           and h.bislatest = 'Y'
           and bd_supplier.supprop <> 1
           and (h.vdef20 is null or h.vdef20 = '~')
           and b.dr = 0
           and meta.pk_billtypecode in ('21-Cxx-13')
           /*and substr(h.vdef7, 0, 10) >= to_char(sysdate-7,'yyyy-MM-dd')
           and substr(h.vdef7, 0, 10) <= to_char(sysdate,'yyyy-MM-dd')*/
           AND (SUBSTR(h.vdef7, 0, 10) between substr(acmonth_2.BEGINDATE,0,10) and substr(acmonth_2.ENDDATE,0,10))
           and dept.name in (select name from bd_defdoc where dr = 0 and enablestate = 2 
           and pk_defdoclist = '1001AZ10000000Y6ETNV') --物资供应报表部门集
           AND h.forderstatus = '3'
           AND (b.bstockclose = 'N' OR
                       (b.bstockclose = 'Y' AND nvl(b.naccumstorenum, 0) <> 0)  OR
                       (b.bstockclose = 'Y' AND b.naccumstorenum=0))
           and purchaseorg.code !='9182' --过滤采购组织是9182的数据
         group by bd_accperiodmonth.YEARMTH,
                  bd_accperiodmonth.ACCPERIODMTH,
                  dept.name      
       union all
                 select bd_accperiodmonth.YEARMTH      YEARMTH,
               bd_accperiodmonth.ACCPERIODMTH month,
               dept.name                      deptname,
               count(b.pk_material) ordernum, 
               sum(
               case 
                 /*when b.bstockclose = 'Y' */
                 when nvl(b.naccuminvoicenum,0)=0
                 then 0 
                 else
                   case when pob.dbilldate is null then sysdate -  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss') 
                        else (to_date(pob.dbilldate, 'yyyy-MM-dd hh24:mi:ss')-  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss')) 
                   end
               end
               ) as arrdays,

               sum(case
                     when nvl(b.naccuminvoicenum,0)=0 then      /*改为累计开票主数量*/
                      0
                     else
                      1
                   end) icnum,
               sum(case
                     when b.bstockclose = 'Y' then
                      1
                     else
                      0
                   end) closenum,
               sum(CASE
                     WHEN ((
               case 
                 /*when b.bstockclose = 'Y' */
                 when nvl(b.naccuminvoicenum,0)=0
                 then 0 
                 else
                   case when pob.dbilldate is null then sysdate -  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss') 
                        else (to_date(pob.dbilldate, 'yyyy-MM-dd hh24:mi:ss')-  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss')) 
                   end
               end
               )<=(case when regexp_like(m.def15,'^-?\d+(\.\d+)?$') then to_number(m.def15) else 0 end)) THEN
                      1
                     ELSE
                      0
                   END) jsdhnum,
               sum(CASE
                     WHEN ((
               case 
                 /*when b.bstockclose = 'Y' */
                 when nvl(b.naccuminvoicenum,0)=0
                 then 0 
                 else
                   case when pob.dbilldate is null then sysdate -  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss') 
                        else (to_date(pob.dbilldate, 'yyyy-MM-dd hh24:mi:ss')-  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss')) 
                   end
               end
               )>(case when regexp_like(m.def15,'^-?\d+(\.\d+)?$') then to_number(m.def15) else 0 end))THEN
                      1
                     ELSE
                      0
                   END) yqdhnum  --逾期到货项数
         from po_order_b b
          left outer join po_order h
            on b.pk_order = h.pk_order
          left outer join bd_psndoc psn
            on h.cemployeeid = psn.pk_psndoc
          left outer join org_dept dept
            on h.pk_dept = dept.pk_dept
          left join po_invoice_b pob 
            on b.pk_order_b = pob.cfirstbid
/*          left outer join po_order_bb bb
            on b.pk_order_b = bb.pk_order_b*/
         left outer join bd_material m
            on b.pk_material = m.pk_material
          LEFT outer JOIN bd_billtype meta
            ON h.ctrantypeid = meta.pk_billtypeid
            left outer join bd_supplier bd_supplier
            on h.pk_supplier = bd_supplier.pk_supplier
          left join bd_accperiodmonth bd_accperiodmonth
            on substr(h.vdef7, 0, 10) between
               (substr(bd_accperiodmonth.BEGINDATE, 0, 10)) and
               (substr(bd_accperiodmonth.ENDDATE, 0, 10))
           left join bd_accperiodmonth acmonth_2
            on to_char(sysdate,'yyyy-MM-dd') between
               (substr(acmonth_2.BEGINDATE, 0, 10)) and
               (substr(acmonth_2.ENDDATE, 0, 10))
          left join org_purchaseorg purchaseorg
            on b.pk_org = purchaseorg.pk_purchaseorg
         where (m.code like 'W%' or m.code like 'S%' or m.code like 'X%' or m.code like 'Q%')
           and h.bislatest = 'Y'
           and bd_supplier.supprop <> 1
           and (h.vdef20 is null or h.vdef20 = '~')
           and b.dr = 0
           and meta.pk_billtypecode in ('21-Cxx-11')
           /*and substr(h.vdef7, 0, 10) >= to_char(sysdate-7,'yyyy-MM-dd')
           and substr(h.vdef7, 0, 10) <= to_char(sysdate,'yyyy-MM-dd')*/
           AND (SUBSTR(h.vdef7, 0, 10) between substr(acmonth_2.BEGINDATE,0,10) and substr(acmonth_2.ENDDATE,0,10))
           and dept.name in (select name from bd_defdoc where dr = 0 and enablestate = 2 
           and pk_defdoclist = '1001AZ10000000Y6ETNV') --物资供应报表部门集
           AND h.forderstatus = '3'
           AND (b.bstockclose = 'N' OR
                       (b.bstockclose = 'Y' AND nvl(b.naccumstorenum, 0) <> 0)  OR
                       (b.bstockclose = 'Y' AND b.naccumstorenum=0))
           and purchaseorg.code !='9182' --过滤采购组织是9182的数据
         group by bd_accperiodmonth.YEARMTH,
                  bd_accperiodmonth.ACCPERIODMTH,
                  dept.name
                  )
 group by YEARMTH, --, month, 
 case when deptname = '辅料采购部' then '工程物资部' 
      when deptname = '设备采购部' then '设备物资部' 
      when deptname = '辅料物资部' then '工程物资部' 
      else deptname end
)
where deptname not in ('采购科','工程市场合同部','工程市场部','工程项目中心')
) tt1
left join WHH_V_PJDHTSJCSJ_WH tt2
on tt1.yearmth = tt2.yearmth
and tt1.deptname = tt2.deptname

select * from WHH_V_PJDHTSJCSJ_WH