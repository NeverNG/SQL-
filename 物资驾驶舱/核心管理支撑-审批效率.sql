--平均审批时长
select round(avg(PINJUN),2) pinjun,
       to_char(sysdate,'yyyy-MM-dd') gxrq --更新日期
from (
select 
paixu,
paixus,
case when pub_workflownote.BDNAME=''  then '合计' else pub_workflownote.BDNAME end BDNAME, --采购类型
case when pub_workflownote.CGBM is null then '合计' else pub_workflownote.CGBM end CGBM, --采购部门 
pub_workflownote.SHULIANG SHULIANG,--订单数量
pub_workflownote.PINJUN PINJUN --审批时长(小时)
from 
(select paixu, paixus, bdname, 
case when cgbm = '设备采购部' then '设备物资部' 
     when cgbm = '辅料采购部' then '工程物资部'
     when cgbm = '辅料物资部' then '工程物资部'
     else cgbm end cgbm,
shuliang, pinjun 
from (
SELECT case when bd_defdoc.name ='标准合同' then 1 
            when bd_defdoc.name ='特殊合同' then 2 
            when bd_defdoc.name ='框架订单' then 3
            when bd_defdoc.name ='无合同订单' then 4
            else 5
       end paixu,
       bd_defdoc.name bdname, 
  case when dept.name is null then 1
         else 0
       end paixus,
       dept.name cgbm,
       COUNT(DISTINCT billno) shuliang,
       NVL(SUM(CEIL((TO_DATE(dealdate, 'YYYY-MM-DD HH24-MI-SS') -
                    TO_DATE(senddate, 'YYYY-MM-DD HH24-MI-SS')) * 24 * 60 * 60)),
           0) / 60 / 60 / COUNT(DISTINCT billno) pinjun
  FROM pub_workflownote
  LEFT JOIN sm_user sm_user
    ON sm_user.cuserid = pub_workflownote.checkman
    left join bd_psndoc bp 
    on (sm_user.pk_psndoc = bp.pk_psndoc)
  left join po_order po_order
    on billno = po_order.vbillcode
  left join bd_defdoc bd_defdoc
    on bd_defdoc.pk_defdoc = po_order.vdef3
  LEFT OUTER JOIN org_dept dept
    ON po_order.pk_dept = dept.pk_dept
 WHERE NVL(pub_workflownote.dr, 0) = '0'
   AND approvestatus <> 4
   --and bp.pk_org in (parameter('pk_org'))
   --and po_order.pk_org in (parameter('pk_org'))
   AND BILLNO IN
       (SELECT VBILLCODE
          FROM po_order
          left join bd_accperiodmonth accmonth
              on to_char(sysdate, 'yyyy-MM-dd') between
              (substr(accmonth.BEGINDATE, 0, 10)) and
              (substr(accmonth.ENDDATE, 0, 10))
         WHERE po_order.forderstatus = '3'
           AND NVL(po_order.dr, 0) = 0
           /*AND SUBSTR(dbilldate, 0, 10) >= parameter('sendq')
           AND SUBSTR(dbilldate, 0, 10) <= parameter('sendz')*/
         AND SUBSTR(dbilldate, 0, 10) >= accmonth.BEGINDATE
         AND SUBSTR(dbilldate, 0, 10) <= accmonth.ENDDATE
       )
/*                      AND SUBSTR(dbilldate, 0, 10) >= '2021-06-01'
           AND SUBSTR(dbilldate, 0, 10) <= '2021-07-30')*/
   and bd_defdoc.name is not null
/*GROUP BY rollup (bd_defdoc.name, dept.name)*/
 group by GROUPING SETS ((bd_defdoc.name,dept.name),(bd_defdoc.name),(dept.name),(NUlL))
 ) order by paixu
) pub_workflownote
) where BDNAME is null and cgbm !='合计'