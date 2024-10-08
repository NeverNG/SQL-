select  aa.YEARMTH, aa.month, aa.bmmc, aa.plannum, aa.cannum, aa.returnnum, aa.ALREADYNUM, aa.wzxs, aa.zxl, aa.sumnum, aa.zsj, 
case when aa.cannum = 0 then 0 else aa.zsj/aa.cannum end as pjcgts
/*,aa.pk_reqstoorg*/
from (

SELECT p.YEARMTH YEARMTH,
       p.month || '月份' month,
       p.bmmc,
       p.plannum,
       p.cannum,
       p.returnnum,
       p.ALREADYNUM,
       p.cannum - p.ALREADYNUM as wzxs,
       case
         when p.cannum = 0 then
          0
         else
          p.ALREADYNUM / p.cannum
       end zxl,
       p.zsj,
       p.sumnum
       /*p.pk_reqstoorg*/
  FROM (
  
  select YEARMTH,month,
  --bmmc,
  case when bmmc= '辅料采购部' then '工程物资部' 
       when bmmc = '设备采购部' then '设备物资部'
       when bmmc = '辅料物资部' then '工程物资部' 
       else bmmc end bmmc,
  sum(plannum)plannum,sum(cannum)cannum,sum(returnnum)returnnum,sum(ALREADYNUM)ALREADYNUM,sum(zsj)zsj,sum(sumnum)sumnum
  from(
  SELECT bd_accperiodmonth.YEARMTH YEARMTH,
               bd_accperiodmonth.ACCPERIODMTH month,
               dept.name bmmc, 
               COUNT(b.pk_praybill_b) plannum,
               count(distinct b.pk_praybill_b) sumnum,
               SUM(CASE 
                     WHEN b.nastnum > 0 
         THEN
                      1
                     ELSE
                      0
                   END)cannum,
               SUM(CASE
                     WHEN b.nastnum = 0 THEN
                      1
                     ELSE
                      0
                   END) returnnum,
               /*SUM(CASE
                     WHEN (orderb.pk_order_b is null or b.nastnum = 0 or orderb.pk_order = '1001AZ10000000BLAVIE' or orderb.pk_order = '1001AZ10000000BSTO27') THEN
                      0
                     ELSE
                      1
                   END) ALREADYNUM,*/
                 /*SUM(CASE
                      WHEN orderb.pk_order_b is null THEN
                       0
                      ELSE
                       1
                    END) ALREADYNUM,*/
                  sum(
                 CASE
                      WHEN b.nastnum > 0 and orderb.pk_order_b is not null and  orderb.forderstatus = 3 THEN
                       1
                      ELSE
                       0
                    END
                 
                 )ALREADYNUM,
                 sum(
               
               case when jxq.dealdate is not null
                 then (
                   case when orderb.pk_order is not null
                     then (
                       case when  b.nastnum = 0 then 0 
                         else (case when orderb.forderstatus = 3 
                                then TO_DATE(orderb.dealdate, 'YYYY-MM-DD HH24-MI-SS') - TO_DATE(jxq.dealdate, 'YYYY-MM-DD HH24-MI-SS')
                                else sysdate - TO_DATE(jxq.dealdate, 'YYYY-MM-DD HH24-MI-SS')
                                  end) 
                         end
                       )
                       
                      else 
                          ( case when h.fbillstatus = 5 or b.browclose = 'Y' or b.nastnum = 0 then 0 
                        else 
                        sysdate - TO_DATE(jxq.dealdate, 'YYYY-MM-DD HH24-MI-SS')
                        end )end
                     )
 
                   else (
                    case when orderb.pk_order is not null
                     then ( case when  b.nastnum = 0 then 0 
                         else (case when orderb.forderstatus = 3 
                                then TO_DATE(orderb.dealdate, 'YYYY-MM-DD HH24-MI-SS') - TO_DATE(h.creationtime, 'YYYY-MM-DD HH24-MI-SS')
                                else sysdate - TO_DATE(h.creationtime, 'YYYY-MM-DD HH24-MI-SS')
                                  end) 
                         end
                       )
                      else 
                       ( case when h.fbillstatus = 5 or b.browclose = 'Y' or b.nastnum = 0 then 0 
                        else 
                        sysdate - TO_DATE(h.creationtime, 'YYYY-MM-DD HH24-MI-SS')
                        end )end
                     )
                end
               )  as zsj
                  /* b.pk_reqstoorg */
          FROM po_praybill_b b
          left outer join po_praybill h
            on b.pk_praybill = h.pk_praybill
          left outer join bd_material m
             on b.pk_srcmaterial = m.pk_material       
          left outer join (select 
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
          on b.pk_praybill_b = orderb.csourcebid
left outer join bd_psndoc psn
            on b.pk_employee = psn.pk_psndoc
          left outer join (select pk_psndoc, pk_dept
                            from (select distinct job.pk_psndoc,
                                                  job.pk_dept,
                                                  ROW_NUMBER() OVER(PARTITION BY job.pk_psndoc ORDER BY job.begindate desc) RN
                                    from hi_psnjob job where job.ismainjob ='Y'
                                 /*  where pk_dept in
                                         (select pk_dept
                                            from org_dept
                                           where name in ('设备采购部',
                                                          '辅料采购部',
                                                          '备品备件部',
                                                          '汇能供应部',
                                                          '沁和供应部',  
                                                          '生产物资部',
                                                          '行政物资部',
                                                          '汽配物资部','设备物资部','辅料物资部'))*/)
                           where rn = 1) psnjob
            on psn.pk_psndoc = psnjob.pk_psndoc
          left outer join org_dept dept
            on psnjob.pk_dept = dept.pk_dept
          left join bd_accperiodmonth bd_accperiodmonth
            on substr(h.dmakedate, 0, 10) between
               (substr(bd_accperiodmonth.BEGINDATE, 0, 10)) and
               (substr(bd_accperiodmonth.ENDDATE, 0, 10))
          left join (
            select  b.CSOURCEBID2, max(pw.dealdate) dealdate from po_storereq_b b 
             left join po_storereq a on b.pk_storereq = a.pk_storereq 
             left join pub_workflownote pw on pw.billno = a.vbillcode
             group by b.CSOURCEBID2
          ) jxq
          on b.pk_praybill_b = jxq.CSOURCEBID2
    left join bd_billtype bilty--单据类型
          on h.ctrantypeid = bilty.pk_billtypeid
            WHERE b.dr = 0 
                and h.dr = 0

                and not(b.browclose = 'Y' and b.naccumulatenum = 0) --不统计行关闭数据且累计数量为0
                and (h.vbillcode!='QG2022031600010457' and m.code!='W130102010594')--23年8.28号王锴联系王鸿辉需求
                       /*and psnjob.LASTFLAG = 'Y'*/
                       /*and psnjob.dr = '0'*/
                and h.bislatest = 'Y'
                --and (bd_material_v.code not like 'w%' and bd_material_v.code not like 'L%'and bd_material_v.code not like 'K%' and bd_material_v.code not like 'J%')
                and (m.code  like 'W%' OR m.code  like 'S%'OR m.code  like 'X%' OR m.code  like 'Q%')
                --and SUBSTR(h.dbilldate, 0, 10) >= parameter('starttime')
                --AND SUBSTR(h.dbilldate, 0, 10) <= parameter('endtime')
                and (SUBSTR(h.dmakedate, 0, 10)  between parameter('starttime') and parameter('endtime'))
                and b.vbdef1 in (parameter('reqstoorg')) 
    and b.vbdef1 != '~' 
                and bilty.billtypename = '物资请购'
         GROUP BY bd_accperiodmonth.YEARMTH,
                  bd_accperiodmonth.ACCPERIODMTH,
                  dept.name
                  /*b.pk_reqstoorg*/ )
            group by YEARMTH,month,
            --bmmc
            case when bmmc= '辅料采购部' then '工程物资部' 
                 when bmmc = '设备采购部' then '设备物资部'
                 when bmmc = '辅料物资部' then '工程物资部' 
                 else bmmc end
            ) p
      ) aa 
     /* left join (
      
      
      
      )bb on (aa.YEARMTH = bb.YEARMTH and aa.month = bb.month and aa.bmmc = bb.bmmc \*and aa.pk_reqstoorg = bb.pk_reqstoorg*\)*/