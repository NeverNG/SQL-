select 
5 mb, --Ŀ��
round(case when sum(ordernum - closenum) = 0 then 0 else sum(yqdhnum)/sum(ordernum - closenum)*100 end,2) yqbl,--���ڱ���
case when (case when sum(ordernum - closenum) = 0 then 0 else sum(yqdhnum)/sum(ordernum - closenum)*100 end) = 0 then 100 
  else round(5/(case when sum(ordernum - closenum) = 0 then 0 else sum(yqdhnum)/sum(ordernum - closenum)*100 end)*100,2) end dcl, --�����
to_char(sysdate,'yyyy-MM-dd') gxrq --��������
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
                     WHEN (case
                       /*when b.bstockclose = 'Y' and (b.naccumstorenum is null or b.naccumstorenum=0) */
                       when nvl(b.naccumstorenum,0)=0
                         then
                         0
                         else 
                         case when icb.dbizdate is null then sysdate -  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss') 
                              else (to_date(icb.dbizdate, 'yyyy-MM-dd hh24:mi:ss')-  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss')) 
                         end 
                  end)<= case when m.def15 ='~' then 999 end THEN
                      1
                     ELSE
                      0
                   END) jsdhnum,
               sum(CASE
                     WHEN (case
                       /*when b.bstockclose = 'Y' and (b.naccumstorenum is null or b.naccumstorenum=0) */
                       when nvl(b.naccumstorenum,0)=0
                         then
                         0
                         else 
                         case when icb.dbizdate is null then sysdate -  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss') 
                              else (to_date(icb.dbizdate, 'yyyy-MM-dd hh24:mi:ss')-  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss')) 
                         end 
                  end) > case when m.def15 ='~' then 999 end THEN
                      1
                     ELSE
                      0
                   END) yqdhnum  --���ڵ�������
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
                   and purinb.csourcetype = '21' /*��Դ�����ǲɹ�����*/
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
                   and purinb.csourcetype = '23' /*��Դ�����ǵ�����*/
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
          left join org_purchaseorg purchaseorg
            on b.pk_org = purchaseorg.pk_purchaseorg
         where (m.code like 'W%' or m.code like 'S%'  or m.code like 'X%' or m.code like 'Q%')
           and h.bislatest = 'Y'
           and (h.vdef20 is null or h.vdef20 = '~')
           and b.dr = 0
           and bd_supplier.supprop <> 1
           and meta.pk_billtypecode in ('21-Cxx-09','21-Cxx-12','21-Cxx-23','21-Cxx-24')
           and substr(h.vdef7, 0, 10) >= to_char(sysdate-7,'yyyy-MM-dd')
           and substr(h.vdef7, 0, 10) <= to_char(sysdate,'yyyy-MM-dd')
           and dept.name in (select name from bd_defdoc where dr = 0 and enablestate = 2 
           and pk_defdoclist = '1001AZ10000000Y6ETNV') --���ʹ�Ӧ�����ż�
           AND (b.bstockclose = 'N' OR
                                 (b.bstockclose = 'Y' AND nvl(b.naccumstorenum, 0) <> 0)  OR
                                 (b.bstockclose = 'Y' AND b.naccumstorenum=0))
           AND h.forderstatus = '3'
           and purchaseorg.code !='9182' --���˲ɹ���֯��9182������
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
                     WHEN (case 
                 /*when b.bstockclose = 'Y'*/
                 when bb.fonwaystatus = '2' and bb.isoperated = 'Y'
                 then 
                   case when bb.dbilldate is null then sysdate -  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss') 
                        else (to_date(bb.dbilldate, 'yyyy-MM-dd hh24:mi:ss')-  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss')) 
                   end 
                 else 
                   0
                 end) <=case when m.def15 ='~' then 999 end THEN
                      1
                     ELSE
                      0
                   END) jsdhnum,
               sum(CASE
                     WHEN (case 
                 /*when b.bstockclose = 'Y'*/
                 when bb.fonwaystatus = '2' and bb.isoperated = 'Y'
                 then 
                   case when bb.dbilldate is null then sysdate -  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss') 
                        else (to_date(bb.dbilldate, 'yyyy-MM-dd hh24:mi:ss')-  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss')) 
                   end 
                 else 
                   0
                 end) >case when m.def15 ='~' then 999 end THEN
                      1
                     ELSE
                      0
                   END) yqdhnum  --���ڵ�������
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
          left join org_purchaseorg purchaseorg
            on b.pk_org = purchaseorg.pk_purchaseorg
         where (m.code like 'W%' or m.code like 'S%' or m.code like 'X%' or m.code like 'Q%')
           and h.bislatest = 'Y'
           and bd_supplier.supprop <> 1
           and (h.vdef20 is null or h.vdef20 = '~')
           and b.dr = 0
           and meta.pk_billtypecode in ('21-Cxx-13')
           and substr(h.vdef7, 0, 10) >= to_char(sysdate-7,'yyyy-MM-dd')
           and substr(h.vdef7, 0, 10) <= to_char(sysdate,'yyyy-MM-dd')
           /*and substr(h.vdef7, 0, 10) >= '2020-01-26'
              and substr(h.vdef7, 0, 10) <= '2020-08-26'*/
           and dept.name in (select name from bd_defdoc where dr = 0 and enablestate = 2 
           and pk_defdoclist = '1001AZ10000000Y6ETNV') --���ʹ�Ӧ�����ż�
           AND h.forderstatus = '3'
           AND (b.bstockclose = 'N' OR
                       (b.bstockclose = 'Y' AND nvl(b.naccumstorenum, 0) <> 0)  OR
                       (b.bstockclose = 'Y' AND b.naccumstorenum=0))
           and purchaseorg.code !='9182' --���˲ɹ���֯��9182������
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
                     when nvl(b.naccuminvoicenum,0)=0 then      /*��Ϊ�ۼƿ�Ʊ������*/
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
                     WHEN (case 
                 /*when b.bstockclose = 'Y' */
                 when nvl(b.naccuminvoicenum,0)=0
                 then 0 
                 else
                   case when pob.dbilldate is null then sysdate -  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss') 
                        else (to_date(pob.dbilldate, 'yyyy-MM-dd hh24:mi:ss')-  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss')) 
                   end
               end
               ) <=case when m.def15 ='~' then 999 end THEN
                      1
                     ELSE
                      0
                   END) jsdhnum,
               sum(CASE
                     WHEN (case 
                 /*when b.bstockclose = 'Y' */
                 when nvl(b.naccuminvoicenum,0)=0
                 then 0 
                 else
                   case when pob.dbilldate is null then sysdate -  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss') 
                        else (to_date(pob.dbilldate, 'yyyy-MM-dd hh24:mi:ss')-  to_date(h.taudittime,'yyyy-MM-dd hh24:mi:ss')) 
                   end
               end
               ) >case when m.def15 ='~' then 999 end THEN
                      1
                     ELSE
                      0
                   END) yqdhnum  --���ڵ�������
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
          left join org_purchaseorg purchaseorg
            on b.pk_org = purchaseorg.pk_purchaseorg
         where (m.code like 'W%' or m.code like 'S%' or m.code like 'X%' or m.code like 'Q%')
           and h.bislatest = 'Y'
           and bd_supplier.supprop <> 1
           and (h.vdef20 is null or h.vdef20 = '~')
           and b.dr = 0
           and meta.pk_billtypecode in ('21-Cxx-11')
           and substr(h.vdef7, 0, 10) >= to_char(sysdate-7,'yyyy-MM-dd')
           and substr(h.vdef7, 0, 10) <= to_char(sysdate,'yyyy-MM-dd')
           /*and substr(h.vdef7, 0, 10) >= '2020-01-26'
              and substr(h.vdef7, 0, 10) <= '2020-08-26'*/
           and dept.name in (select name from bd_defdoc where dr = 0 and enablestate = 2 
           and pk_defdoclist = '1001AZ10000000Y6ETNV') --���ʹ�Ӧ�����ż�
           AND h.forderstatus = '3'
           AND (b.bstockclose = 'N' OR
                       (b.bstockclose = 'Y' AND nvl(b.naccumstorenum, 0) <> 0)  OR
                       (b.bstockclose = 'Y' AND b.naccumstorenum=0))
           and purchaseorg.code !='9182' --���˲ɹ���֯��9182������
         group by bd_accperiodmonth.YEARMTH,
                  bd_accperiodmonth.ACCPERIODMTH,
                  dept.name
                  )
  where deptname not in ('�ɹ���','�����г���ͬ��','�����г���')
