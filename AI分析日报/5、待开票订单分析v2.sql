select gys,--供应商名称
       vbillcode, --订单号
       zuihou, --入库时间
       ordermny, --订单金额
       purinmny, --入库金额
       invoicemny, --入帐金额
       case when zt > 0 then '未提交' else '审批中' end fpzt, --发票状态
       psnname --采购员
       /*sumnotinvoicemny, --累计待开票金额
       case when deptname = '设备采购部' then '设备物资部' 
            when deptname = '辅料采购部' then '工程物资部'
            when deptname = '辅料物资部' then '工程物资部'
            else deptname end  deptname, --部门
       orgname, --采购组织
       parvdate, --预计到货日期
       sfjcxh, --是否寄存销售
       aname,--付款方式
       cglx, --采购类型
       notinvoicemny --待开票金额*/
       /*fkje,
       case when fkje > purinmny then '是' else '否' end fkjebigpurinmny*/
       from (
select a.gys,
       a.sumnotinvoicemny ,
       a.deptname,
       a.psnname,
       a.orgname,
       a.parvdate,
       a.sfjcxh,
       a.vbillcode,
       a.aname,
       a.cglx,
       a.zuihou,
       sum(a.invoicemny) invoicemny,
       sum(a.ordermny) ordermny,
       sum(a.purinmny) purinmny,
       sum(a.notinvoicemny)notinvoicemny,
       /*sum(a.fkje - a.money_cr) as fkje*/
       sum(zt) zt
    /*   a.pk_reqstoorg*/
  from(
  
  select detailnotinvoicemny.gys,
         detailnotinvoicemny.sfjcxh,
       sumnotinvoicemny.notinvoicemny sumnotinvoicemny,
       detailnotinvoicemny.deptname,
       detailnotinvoicemny.psnname,
       detailnotinvoicemny.vbillcode,
       detailnotinvoicemny.orgname,
       detailnotinvoicemny.parvdate,
       detailnotinvoicemny.aname,
       detailnotinvoicemny.cglx,
       shijian.zuihou,
       detailnotinvoicemny.invoicemny,
       detailnotinvoicemny.ordermny,
       detailnotinvoicemny.purinmny,
       detailnotinvoicemny.notinvoicemny,
       detailnotinvoicemny.zt
       /*bbb.fkje, 
       nvl(ccc.money_cr, 0) money_cr*/

  from (select gys, deptname, psnname, sfjcxh,
vbillcode, orgname, parvdate, jcvbillcode, aname,cglx,
invoicemny,
ordermny,
case when invoicemum = purinum then invoicemny else purinmny end purinmny,
(case when invoicemum = purinum then invoicemny else purinmny end) -  invoicemny as  notinvoicemny,
zt
from (
SELECT gy.name     gys,
               dept.name   deptname,
               psn.name    psnname,
               '否' sfjcxh,
               h.vbillcode,
               org.name orgname,
               substr(h.vdef7, 0, 10) parvdate,       /*预计到货日期*/
               h.vbillcode as jcvbillcode,
               fk.name aname,
               meta.billtypename cglx,
               sum(nvl(pooa.nnum, 0)) invoicemum, 
               sum(nvl(pooa.norigtaxmny, 0))  invoicemny,
               sum(b.norigtaxmny) ordermny,
               
               sum(case when h.brefwhenreturn = 'Y' then b.naccumstorenum
                 else NVL(b.naccumstorenum, 0) - nvl(b.nbackstorenum, 0)
               end) purinum,
               
               case
                 when h.brefwhenreturn = 'Y' then
                  sum(NVL(b.naccumstorenum, 0) * b.nqttaxprice)
                 else
                  sum((NVL(b.naccumstorenum, 0) - nvl(b.nbackstorenum, 0)) * b.nqttaxprice)
               end purinmny,
               
               case
                 when h.brefwhenreturn = 'Y' then
                  sum(NVL(b.naccumstorenum, 0) * b.nqttaxprice) -
                  sum(nvl(b.naccuminvoicemny, 0))
                 else
                  sum((NVL(b.naccumstorenum, 0) - nvl(b.nbackstorenum, 0)) *
                      b.nqttaxprice) - sum(nvl(b.naccuminvoicemny, 0))
               end notinvoicemny,
               /*b.pk_reqstoorg*/
             sum(nvl(pooa.zt, 1)) zt
          FROM po_order_b b
          LEFT outer JOIN po_order h
            ON b.pk_order = h.pk_order
          left join org_purchaseorg org 
            on h.pk_org = org.pk_purchaseorg 
          -- ++++++++++++++++++++++++++++++++++++
         /* left join po_arriveorder_b poa        \*到货单明细表--采购订单明细*\  
           on  b.pk_order_b = poa.csourcebid 
          left join ic_purchasein_b icp      \*采购入库单表体--到货单明细表*\
           on icp.csourcebillbid   = poa.pk_arriveorder_b 
           left join po_invoice_b  pob
           on pob.csourcebid = icp.cgeneralbid 
                      left join po_invoice pooa
           on pooa.pk_invoice = pob.pk_invoice */
           left outer join (select cfirstbid, h.fbillstatus, sum(decode(h.fbillstatus, 3, nnum, 0)) nnum,
                                                   sum(decode(h.fbillstatus, 3, norigtaxmny, 0)) norigtaxmny,
                                                   sum(decode(h.fbillstatus, 0, 1, 0)) zt
                                              from po_invoice_b b
                                              left outer join po_invoice h
                                                on b.pk_invoice = h.pk_invoice
                                             where b.dr = 0 
                                             /*王锴9.9提需求变更*/
                                             /*and h.fbillstatus = 3*/
                                             group by cfirstbid, h.fbillstatus) pooa
                             on b.pk_order_b = pooa.cfirstbid               

           -- ++++++++++++++++++++++++++++++++++++++++++++++++++
          LEFT outer JOIN bd_psndoc psn
            ON h.cemployeeid = psn.pk_psndoc
          left outer join org_dept dept
            on h.pk_dept = dept.pk_dept
          LEFT outer JOIN bd_material_v bd_material_v
            ON b.pk_srcmaterial = bd_material_v.pk_material
          left outer join bd_supplier gy
            on b.pk_supplier = gy.pk_supplier
          LEFT outer JOIN bd_billtype meta
            ON h.ctrantypeid = meta.pk_billtypeid
          left outer join bd_balatype bdb
            on h.pk_balatype = bdb.pk_balatype
          left outer join bd_defdoc fk
            on h.vdef5 = fk.pk_defdoc
          
         WHERE h.dr = 0
           AND (gy.supprop <> 1 or gy.code = '9150' )
           AND (bd_material_v.code like 'W%' or bd_material_v.code like 'S%' or
               bd_material_v.code like 'X%' or bd_material_v.code like 'Q%')
           AND b.dr = 0
           /*and h.nhtaxrate <> '0'*/
           and h.bislatest = 'Y'
           /*and pooa.fbillstatus  = 3*/
           /*and (h.vdef20 is null or h.vdef20 = '~')*/ --收货部门为空的条件
           AND meta.pk_billtypecode in ('21-Cxx-09', '21-Cxx-12')
           and SUBSTR(h.dbilldate, 0, 10) between to_char(sysdate-7,'yyyy-MM-dd') and to_char(sysdate,'yyyy-MM-dd')            
              /* and SUBSTR(h.dbilldate, 0, 10) >='2020-06-26'
              AND SUBSTR(h.dbilldate, 0, 10) <='2020-07-25'*/
           and h.forderstatus = '3'
           /*and (b.naccumstorenum >= b.nastnum  or b.bstockclose = 'Y')*/ /*新加条件*/
           and (b.bstockclose = 'N' or
               (b.bstockclose = 'Y' and nvl(b.naccumstorenum, 0) <> 0))
           
          /* -----------------新增条件---------------*/
          
           and not(b.nbackarrvnum is not null and b.naccumstorenum = 0)
           /* -----------------新增条件---------------*/
          
           /*and substr(h.vdef7, 0, 10) < substr(to_char(SYSDATE, 'yyyy-MM-dd hh24:mi:ss'), 0, 10)*/    /*预计到货日期在今天之前*/
           
           and dept.name in (select name from bd_defdoc where dr = 0 and enablestate = 2 
           and pk_defdoclist = '1001AZ10000000Y6ETNV') --物资供应报表部门集
           and org.code !='9182'
           
           and h.vbillcode not like 'CD2019080500007153'
           and h.vbillcode not like 'CD2019100500006225'
           and h.vbillcode not like 'CD2019122300007258'
           and h.vbillcode not like 'CD2019111400005140'
           and h.vbillcode not like 'CD2020102900018943'
           and h.vbillcode not like 'CD2019102000006181'
           and h.vbillcode not like 'CD2019081500013217'
           and h.vbillcode not like 'CD2020070900014985'
           and h.vbillcode not like 'CD2020081100016232'
           and h.vbillcode not like 'CD2020051300012776'
           and h.vbillcode not like 'CD2019111000004901'
           and h.vbillcode not like 'CD2020011300008285'
           and h.vbillcode not like 'CD2019122500007293'
           and h.vbillcode not like 'CD2020052400013218'
           and h.vbillcode not like 'CD2020050800012526'
           and h.vbillcode not like 'CD2020010500007884'
           and h.vbillcode not like 'CD2019111000006801'
           and h.vbillcode not like 'CD2021120500045515'
           and h.vbillcode not like 'CD2021101100040844'  /*任径通联系宋部长之后通知王锴让过滤*/
           and h.vbillcode not like 'CD2020080700016067'
           and h.vbillcode not like 'CD2020022500009160'
           and h.vbillcode not like 'CD2020030900013712'
           and h.vbillcode not like 'CD2021120500045521'
         group by dept.name,
                   org.name,
                   h.vdef7,
                  psn.name,
                  gy.name,
                  h.vbillcode,
                  fk.name,
                  meta.billtypename,
                  h.brefwhenreturn,
                  meta.billtypename
                  )
                  
                  
        union all
        
        
        SELECT gy.name gys,
               dept.name deptname,
               psn.name psnname,
               '否' sfjcxh,
               h.vbillcode,
               org.name orgname,
               substr(h.vdef7, 0, 10) parvdate,       /*预计到货日期*/
               h.vbillcode as jcvbillcode,
               fk.name aname,
               meta.billtypename cglx,
              /* icpa.modifiedtime zuihou,*/
               nvl(sum(pob.norigtaxmny),0) invoicemny,
               sum(b.norigtaxmny) ordermny,
               sum(b.naccuminvoicemny) purinmny,
               /*sum(b.naccuminvoicemny) - sum(b.naccuminvoicemny) notpurinmny*/
               sum(b.naccuminvoicemny) - nvl(sum(pob.norigtaxmny), 0) notinvoicemny,
               /*b.pk_reqstoorg*/
               sum(nvl(pob.zt, 1)) zt
          FROM po_order_b b
          LEFT outer JOIN po_order h
            ON b.pk_order = h.pk_order
          left join org_purchaseorg org 
            on h.pk_org = org.pk_purchaseorg 
          --+++++++++++++++++++++++++++++++++
          /*left outer join 
                  (select poab.csrcbid,poab.pk_acceptance_b, poab.num  from pu_acceptance_check_b poab 
                  left join pu_acceptance_check poaa on poaa.pk_acceptance = poab.pk_acceptance
                  where poab.dr = 0 and poaa.dr  = 0 and poaa.approvestatus <> 1
                  ) poab
                  on poab.csrcbid = b.pk_order_b */
          
          left join (select /*pob.pk_invoice_b, */pob.cfirstbid, sum(decode(poi.fbillstatus, 3, pob.norigtaxmny, 0)) norigtaxmny,
                    sum(decode(poi.fbillstatus, 0, 1, 0)) zt
                from po_invoice_b pob 
               left join po_invoice poi on poi.pk_invoice = pob.pk_invoice
               where pob.dr = 0 and poi.dr = 0 
               /*王锴9.9提需求变更*/
               /*and poi.fbillstatus  = 3*/
               group by /*pob.pk_invoice_b, */pob.cfirstbid
          ) pob 
          /*on poab.csrcbid = pob.pk_invoice_b */
          on b.pk_order_b = pob.cfirstbid    
         --+++++++++++++++++++++++++++++++++
          LEFT outer JOIN bd_psndoc psn
            ON h.cemployeeid = psn.pk_psndoc
          left outer join org_dept dept
            on h.pk_dept = dept.pk_dept
          LEFT outer JOIN bd_material_v bd_material_v
            ON b.pk_srcmaterial = bd_material_v.pk_material
          LEFT outer JOIN bd_billtype meta
            ON h.ctrantypeid = meta.pk_billtypeid
          left outer join bd_supplier gy
            on b.pk_supplier = gy.pk_supplier
          left outer join bd_balatype bdb
            on h.pk_balatype = bdb.pk_balatype
          left outer join bd_defdoc fk
            on h.vdef5 = fk.pk_defdoc
         WHERE h.dr = 0
           AND (bd_material_v.code like 'W%' or bd_material_v.code like 'S%' or
               bd_material_v.code like 'X%' or bd_material_v.code like 'Q%')
           AND b.dr = 0
           and h.bislatest = 'Y'
           AND (gy.supprop <> 1 or gy.code = '9150' )
           /*and h.nhtaxrate <> '0'*/
           AND meta.pk_billtypecode in ('21-Cxx-11')
           and SUBSTR(h.dbilldate, 0, 10) between to_char(sysdate-7,'yyyy-MM-dd') and to_char(sysdate,'yyyy-MM-dd')
              /*and SUBSTR(h.dbilldate, 0, 10) >='2020-01-26'
              AND SUBSTR(h.dbilldate, 0, 10) <='2020-12-25'*/
           and h.forderstatus = '3'
           /*and (b.naccuminvoicenum  >= b.nastnum  or b.bstockclose = 'Y') */   /*新加条件*/
           and (b.bstockclose = 'N' or
               (b.bstockclose = 'Y' and nvl(b.naccumstorenum, 0) <> 0))
           /*and substr(h.vdef7, 0, 10) < substr(to_char(SYSDATE, 'yyyy-MM-dd hh24:mi:ss'), 0, 10) */   /*预计到货日期在今天之前*/
           and h.vbillcode not like 'CD2019080500007153' /*因为这个单据被用另外一个补的订单挂账了，这个没办法挂账了。报表显示有问题。*/
           and h.vbillcode not like 'CD2019100500006225'
           and h.vbillcode not like 'CD2019122300007258'
           and h.vbillcode not like 'CD2019111400005140'
           and h.vbillcode not like 'CD2020102900018943'
           and h.vbillcode not like 'CD2019102000006181'
           and h.vbillcode not like 'CD2019081500013217'
           and h.vbillcode not like 'CD2020070900014985'
           and h.vbillcode not like 'CD2020081100016232'
           and h.vbillcode not like 'CD2020051300012776'
           and h.vbillcode not like 'CD2019111000004901'
           and h.vbillcode not like 'CD2020011300008285'
           and h.vbillcode not like 'CD2019122500007293'
           and h.vbillcode not like 'CD2019111000006801'
           and h.vbillcode not like 'CD2020052400013218'
           and h.vbillcode not like 'CD2020050800012526'
           and h.vbillcode not like 'CD2020010500007884'
           /* -----------------新增条件---------------*/
          
           and not(b.nbackarrvnum is not null and b.naccumstorenum = 0)
           /* -----------------新增条件---------------*/
           
           and dept.name in (select name from bd_defdoc where dr = 0 and enablestate = 2 
           and pk_defdoclist = '1001AZ10000000Y6ETNV') --物资供应报表部门集
           and org.code !='9182'
         group by dept.name, psn.name, org.name,
                   h.vdef7, gy.name, h.vbillcode, fk.name,meta.billtypename/*,icpa.modifiedtime*//*,b.pk_reqstoorg*/
         
         
        union all
        
        
select gys, deptname, psnname, sfjcxh,
vbillcode, orgname, parvdate, jcvbillcode, aname,cglx,
invoicemny,
ordermny,
case when purinum = nnum then invoicemny else purinmny end purinmny,
(case when purinum = nnum then invoicemny else purinmny end) -  invoicemny as  notinvoicemny,
zt
from (
 SELECT gy.name gys,
               dept.name deptname,
               psn.name psnname,
               '否' sfjcxh,
               h.vbillcode,
               org.name orgname,
               substr(h.vdef7, 0, 10) parvdate,       /*预计到货日期*/
               h.vbillcode as jcvbillcode,
               fk.name aname,
               meta.billtypename cglx,
               sum(pob.nnum) nnum,
               nvl(sum(pob.norigtaxmny), 0) invoicemny,
               sum(b.norigtaxmny) ordermny,
               /*h.ntotalorigmny  ordermny,*/
               
               sum(case when poab.pk_acceptance_b is null then nvl(bb.nmaxhandlenum, 0) 
                         else (case when poab.approvestatus = 1 then poab.num else 0 end)
                       end) purinum,
               
               sum(case when poab.pk_acceptance_b is null then nvl(bb.nmaxhandlenum, 0)*b.norigtaxprice 
                         else (case when poab.approvestatus = 1 then poab.money else 0 end)
                       end) purinmny,


               sum(case when poab.pk_acceptance_b is null then nvl(bb.nmaxhandlenum, 0)*b.norigtaxprice 
                         else (case when poab.approvestatus = 1 then poab.money  else 0 end)
                       end) - nvl(sum(pob.norigtaxmny), 0) as notinvoicemny,
                       sum(nvl(pob.zt, 1)) zt
                  /*b.pk_reqstoorg*/
          FROM po_order_b b
          LEFT outer JOIN po_order h
            ON b.pk_order = h.pk_order
            left join org_purchaseorg org 
            on h.pk_org = org.pk_purchaseorg 
          --+++++++++++++++++++++++++++++++++
          /*left outer join  pu_acceptance_check_b poab
          on poab.csrcbid = b.pk_order_b 
          left outer join  pu_acceptance_check poaa
          on poaa.pk_acceptance = poab.pk_acceptance*/
         left outer join 
                  (select poab.csrcbid,poab.pk_acceptance_b, poab.money, poaa.approvestatus, poab.num  from pu_acceptance_check_b poab 
                  left join pu_acceptance_check poaa on poaa.pk_acceptance = poab.pk_acceptance
                  where poab.dr = 0 and poaa.dr  = 0 /*and poaa.approvestatus <> -1*/ and poaa.transtypepk <> '1001AZ10000000ATEBLG'
                  ) poab
                  on poab.csrcbid = b.pk_order_b
                  
          left join (select /*pob.pk_invoice_b,*/ pob.cfirstbid, sum(decode(poi.fbillstatus, 3, pob.norigtaxmny, 0)) norigtaxmny, 
               sum(decode(poi.fbillstatus, 3, pob.nnum, 0)) nnum, sum(decode(poi.fbillstatus, 0, 1, 0)) zt from po_invoice_b pob 
               left join po_invoice poi on poi.pk_invoice = pob.pk_invoice
               where  pob.dr = 0 and poi.dr = 0
                /*王锴9.9提需求变更*/
               /*and poi.fbillstatus = 3*/
               group by /*pob.pk_invoice_b, */pob.cfirstbid
          ) pob 
          /*on poab.csrcbid = pob.pk_invoice_b*/
          on b.pk_order_b = pob.cfirstbid   
         --+++++++++++++++++++++++++++++++++
          LEFT outer JOIN bd_psndoc psn
            ON h.cemployeeid = psn.pk_psndoc
          left outer join org_dept dept
            on h.pk_dept = dept.pk_dept
          LEFT outer JOIN bd_material_v bd_material_v
            ON b.pk_srcmaterial = bd_material_v.pk_material
          LEFT outer JOIN bd_billtype meta
            ON h.ctrantypeid = meta.pk_billtypeid
          left outer join bd_supplier gy
            on b.pk_supplier = gy.pk_supplier
          left outer join bd_balatype bdb
            on h.pk_balatype = bdb.pk_balatype
          left outer join bd_defdoc fk
            on h.vdef5 = fk.pk_defdoc
          left outer join po_order_bb bb
            on (bb.pk_order_b = b.pk_order_b and bb.fonwaystatus = '2'and bb.isoperated = 'Y')
         WHERE h.dr = 0
           AND (gy.supprop <> 1 or gy.code = '9150' )
           AND (bd_material_v.code like 'W%' or bd_material_v.code like 'S%' or
               bd_material_v.code like 'X%' or bd_material_v.code like 'Q%')
           AND b.dr = 0
           and h.bislatest = 'Y'
           /*and h.nhtaxrate <> '0'*/
           AND meta.pk_billtypecode in ('21-Cxx-13')
           /*and ((bb.fonwaystatus = '2' and bb.isoperated = 'Y')  or b.bstockclose = 'Y')*/    /*新加条件*/
           and SUBSTR(h.dbilldate, 0, 10) between to_char(sysdate-7,'yyyy-MM-dd') and to_char(sysdate,'yyyy-MM-dd')
              /*and SUBSTR(h.dbilldate, 0, 10) >='2020-01-26'
              AND SUBSTR(h.dbilldate, 0, 10) <='2020-12-25'*/
              
           /*and bb.fonwaystatus = '2'*/
              /*and bb.vbillcode in (h.vbillcode)*/
           and (b.bstockclose = 'N' or
               (b.bstockclose = 'Y' and nvl(b.naccumstorenum, 0) <> 0))
           and org.code !='9182'    
           and dept.name in (select name from bd_defdoc where dr = 0 and enablestate = 2 
           and pk_defdoclist = '1001AZ10000000Y6ETNV') --物资供应报表部门集
          /* and substr(h.vdef7, 0, 10) < substr(to_char(SYSDATE, 'yyyy-MM-dd hh24:mi:ss'), 0, 10)*/    /*预计到货日期在今天之前*/
           and h.vbillcode not like 'CD2019080500007153' /*因为这个单据被用另外一个补的订单挂账了，这个没办法挂账了。报表显示有问题。*/
           and h.vbillcode not like 'CD2019100500006225'
           and h.vbillcode not like 'CD2019122300007258'
           and h.vbillcode not like 'CD2019111400005140'
           and h.vbillcode not like 'CD2020102900018943'
           and h.vbillcode not like 'CD2019102000006181'
           and h.vbillcode not like 'CD2019081500013217'
           and h.vbillcode not like 'CD2020070900014985'
           and h.vbillcode not like 'CD2020081100016232'
           and h.vbillcode not like 'CD2020051300012776'
           and h.vbillcode not like 'CD2019111000004901'
           and h.vbillcode not like 'CD2020011300008285'
           and h.vbillcode not like 'CD2019122500007293'
           and h.vbillcode not like 'CD2019111000006801'
           and h.vbillcode not like 'CD2020052400013218'
           and h.vbillcode not like 'CD2020050800012526'
           and h.vbillcode not like 'CD2020010500007884'
           /* -----------------新增条件---------------*/
          
          and not(b.nbackarrvnum is not null and b.naccumstorenum = 0)
           /* -----------------新增条件---------------*/
         group by dept.name, psn.name, org.name,
                   h.vdef7,gy.name, h.vbillcode, fk.name,meta.billtypename/*,icpa.modifiedtime*//*,b.pk_reqstoorg*/
                   )

        
        union all
        
        /*寄存销售消耗汇总金额*/
        
        select supplier.name gys,
               pob.deptname,
               pob.psnname,
               '是' sfjcxh,
               ics.vbillcode as vbillcode,
               '' as orgname,
               '' as parvdate,
               pob.vbillcode as jcvbillcode,
               pob.aname,
               pob.cglx,
               /*ics.modifiedtime zuihou,*/
               /*sum(nvl(pb.norigtaxmny, 0)) as invoicemny,
               sum(ics.nnumsum * pob.nqttaxprice) as ordermny,
               sum(ics.nnumsum * pob.nqttaxprice) as purinmny,
               sum(ics.nnumsum * pob.nqttaxprice) -
               sum(nvl(pb.norigtaxmny, 0)) as notinvoicemny*/
               sum(nvl(pb.norigtaxmny, 0)) as invoicemny,
               ics.nnumsum * nvl(pb.norigtaxprice, jmb.nastorigtaxprice) as ordermny,
               ics.nnumsum * nvl(pb.norigtaxprice, jmb.nastorigtaxprice) as purinmny,
               ics.nnumsum * nvl(pb.norigtaxprice, jmb.nastorigtaxprice) -
               sum(nvl(pb.norigtaxmny, 0)) as notinvoicemny,
               sum(nvl(pb.zt, 1)) zt
              /* pob.pk_reqstoorg*/
          from ic_vmi_sum ics
          left join bd_defdoc def on ics.cwarehouseid = def.code
          left join gysjmb_cgdd jmb ON ics.cvendorid = jmb.allz and ics.cmaterialoid = jmb.pk_source
          left join (select pk_srcmaterial,
                            vbillcode,
                            deptname,
                            psnname,
                            aname,
                            cglx,
                            norigtaxprice,
                            nqttaxprice,
                            pk_reqstoorg,
                            cgzzbm
                       from (select b.pk_srcmaterial,
                                    h.vbillcode,
                                    dept.name deptname,
                                    psn.name psnname,
                                    fk.name aname,
                                    meta.billtypename cglx,
                                    b.norigtaxprice,
                                    b.nqttaxprice,
                                    ROW_NUMBER() over(partition by b.pk_srcmaterial order by h.dbilldate desc) as ids,
                                    b.pk_reqstoorg,
                                    purchaseorg.code cgzzbm --采购组织编码
                               from po_order_b b
                               LEFT outer JOIN po_order h
                                 ON b.pk_order = h.pk_order
                               LEFT outer JOIN bd_billtype meta
                                 ON h.ctrantypeid = meta.pk_billtypeid
                               left outer join org_dept dept
                                 on h.pk_dept = dept.pk_dept
                               LEFT outer JOIN bd_material_v bd_material_v
                                 ON b.pk_srcmaterial =
                                    bd_material_v.pk_material
                               LEFT outer JOIN bd_psndoc psn
                                 ON h.cemployeeid = psn.pk_psndoc
                               left outer join bd_balatype bdb
                                 on h.pk_balatype = bdb.pk_balatype
                               left outer join bd_defdoc fk
                                 on h.vdef5 = fk.pk_defdoc
                               left join org_purchaseorg purchaseorg
                                 on b.pk_org = purchaseorg.pk_purchaseorg
                              where h.dr = 0
                                AND b.dr = 0
                                and h.forderstatus = '3'
                                and h.bislatest = 'Y'
                                AND meta.pk_billtypecode in ('21-03','21-Cxx-23') /*单据类型为供应商寄存采购*/
                                and dept.name in (select name from bd_defdoc where dr = 0 and enablestate = 2 
                                and pk_defdoclist = '1001AZ10000000Y6ETNV') --物资供应报表部门集
                                and (b.bstockclose = 'N' or
                                    (b.bstockclose = 'Y' and
                                    nvl(b.naccumstorenum, 0) <> 0))
                                   /* and b.pk_reqstoorg in (parameter('reqstoorg'))*/ )
                      where ids = 1 ) pob
            on ics.cmaterialoid = pob.pk_srcmaterial
          LEFT JOIN bd_supplier supplier
            ON ics.cvendorid = supplier.PK_SUPPLIER
         /* left join po_invoice_b pb
            on ics.cvmihid = pb.cfirstbid*/
            
         left join (select pob.pk_invoice_b, pob.cfirstbid, pob.norigtaxprice, sum(decode(poi.fbillstatus, 3, pob.norigtaxmny, 0)) norigtaxmny, 
         sum(decode(poi.fbillstatus, 3, pob.nnum, 0)) nnum,
         sum(decode(poi.fbillstatus, 0, 1, 0)) zt
          from po_invoice_b pob 
               left join po_invoice poi on poi.pk_invoice = pob.pk_invoice
               where  pob.dr = 0 and poi.dr = 0
               /*王锴9.9提需求变更*/
               /*poi.fbillstatus = 3*/
               group by pob.pk_invoice_b, pob.cfirstbid, pob.norigtaxprice
          ) pb on ics.cvmihid = pb.cfirstbid  
            
         where ics.dr = 0
           and ics.fbillflag = 4
           and pb.nnum <> ics.nnumsum
           AND (supplier.supprop <> 1 or supplier.code = '9150' )
           and pob.cgzzbm !='9182'
           and SUBSTR(ics.dmakedate, 0, 10) between to_char(sysdate-7,'yyyy-MM-dd') and to_char(sysdate,'yyyy-MM-dd')
        /*and SUBSTR(ics.dmakedate, 0, 10) >= '2021-09-01'
        AND SUBSTR(ics.dmakedate, 0, 10) <= '2021-10-22'*/
         group by ics.nnumsum, pb.norigtaxprice, jmb.nastorigtaxprice, supplier.name, pob.deptname, pob.psnname, pob.aname,pob.cglx, pob.vbillcode/*,ics.modifiedtime*/, ics.vbillcode/* ,pob.pk_reqstoorg*/
        
        ) detailnotinvoicemny
  left outer join (SELECT gy.name gys,
                          sum(NVL(b.naccumstorenum, 0) * b.nqttaxprice) -
                          sum(nvl(b.naccuminvoicemny, 0)) notinvoicemny
                     FROM po_order_b b
                     LEFT outer JOIN po_order h
                       ON b.pk_order = h.pk_order
                     LEFT outer JOIN bd_material_v bd_material_v
                       ON b.pk_srcmaterial = bd_material_v.pk_material
                     left outer join bd_supplier gy
                       on b.pk_supplier = gy.pk_supplier
                     LEFT outer JOIN bd_billtype meta
                       ON h.ctrantypeid = meta.pk_billtypeid
                    WHERE h.dr = 0
                      AND (bd_material_v.code like 'W%' or
                          bd_material_v.code like 'S%' or
                          bd_material_v.code like 'X%' or bd_material_v.code like 'Q%')
                      AND b.dr = 0
                      and h.bislatest = 'Y'
                      /*and (h.vdef20 is null or h.vdef20 = '~')*/ --收货部门为空的条件
                         /*AND meta.pk_billtypecode in ('21-Cxx-09', '21-Cxx-12','21-Cxx-11','21-Cxx-13')*/
                      and SUBSTR(h.dbilldate, 0, 10) between to_char(sysdate-7,'yyyy-MM-dd') and to_char(sysdate,'yyyy-MM-dd')
                      and h.forderstatus = '3'
                      AND (gy.supprop <> 1 or gy.code = '9150' )
                      /*and h.nhtaxrate <> '0'*/
                      and (b.bstockclose = 'N' or
                          (b.bstockclose = 'Y' and
                          nvl(b.naccumstorenum, 0) <> 0))
                      and h.vbillcode not like 'CD2019080500007153'
                      and h.vbillcode not like 'CD2019100500006225'
                      and h.vbillcode not like 'CD2019122300007258'
                      and h.vbillcode not like 'CD2019111400005140'
                      and h.vbillcode not like 'CD2020102900018943'
                      and h.vbillcode not like 'CD2019102000006181'
                      and h.vbillcode not like 'CD2019081500013217'
                      and h.vbillcode not like 'CD2020070900014985'
                      and h.vbillcode not like 'CD2020081100016232'
                      and h.vbillcode not like 'CD2020051300012776'
                      and h.vbillcode not like 'CD2019111000004901'
                      and h.vbillcode not like 'CD2020011300008285'
                      and h.vbillcode not like 'CD2019122500007293'
                      and h.vbillcode not like 'CD2019111000006801'
                      and h.vbillcode not like 'CD2020052400013218'
                      and h.vbillcode not like 'CD2020050800012526'
                      and h.vbillcode not like 'CD2020010500007884'
                      /* -----------------新增条件---------------*/
          
                      and not(b.nbackarrvnum is not null and b.naccumstorenum = 0)
                      /* -----------------新增条件---------------*/
                    group by gy.name) sumnotinvoicemny
    on detailnotinvoicemny.gys = sumnotinvoicemny.gys
    left join (
               select vbillcode,modifiedtime zuihou
         from(
         select 
               h.vbillcode,
               substr(icpa.modifiedtime,0,10) modifiedtime,
               row_number() over(partition by h.vbillcode order by icpa.modifiedtime desc)rn
         FROM po_order_b b
          LEFT outer JOIN po_order h
            ON b.pk_order = h.pk_order
          LEFT outer JOIN bd_billtype meta
            ON h.ctrantypeid = meta.pk_billtypeid
          left join po_arriveorder_b poa        /*到货单明细表--采购订单明细*/  
           on  b.pk_order_b = poa.csourcebid 
          left join ic_purchasein_b icp      /*采购入库单表体--到货单明细表*/
           on icp.csourcebillbid   = poa.pk_arriveorder_b 
          left join ic_purchasein_h icpa     /*采购入库单表头--表体*/
           on icp.cgeneralhid   = icpa.cgeneralhid 
         WHERE h.dr = 0
        /*   AND (bd_material_v.code like 'W%' or bd_material_v.code like 'S%' or
               bd_material_v.code like 'X%')*/
           AND b.dr = 0
           and h.bislatest = 'Y'
           AND meta.pk_billtypecode in ('21-Cxx-09', '21-Cxx-12')
           /*and h.nhtaxrate <> '0'*/
           and icpa.modifiedtime is not null
           /*and SUBSTR(h.dbilldate, 0, 10) >= parameter('sdate')
           AND SUBSTR(h.dbilldate, 0, 10) <= parameter('edate')*/
           )
           where rn = 1
           
           union all
           
         select vbillcode,modifiedtime
         from(
         select 
               h.vbillcode,
               substr(nvl(nvl(poab.creationtime, bb.ts), pob.dbilldate) ,0,10) modifiedtime,
               row_number() over(partition by h.vbillcode order by nvl(nvl(poab.creationtime, bb.ts), pob.dbilldate) desc) rn
         FROM po_order_b b
          LEFT outer JOIN po_order h
            ON b.pk_order = h.pk_order
          LEFT outer JOIN bd_billtype meta
            ON h.ctrantypeid = meta.pk_billtypeid
         left outer join 
                  (select poab.csrcbid,poab.pk_acceptance_b, poaa.creationtime  from pu_acceptance_check_b poab 
                  left join pu_acceptance_check poaa on poaa.pk_acceptance = poab.pk_acceptance
                  where poab.dr = 0 and poaa.dr  = 0 and poaa.approvestatus <> -1 and poaa.transtypepk <> '1001AZ10000000ATEBLG'
                  ) poab
                  on poab.csrcbid = b.pk_order_b
                  
          left join (select pob.pk_invoice_b, pob.cfirstbid, poi.dbilldate  from po_invoice_b pob 
               left join po_invoice poi on poi.pk_invoice = pob.pk_invoice
               where  pob.dr = 0 and poi.dr = 0
                /*王锴9.9提需求变更*/
               and poi.fbillstatus = 3
          ) pob 
          on b.pk_order_b = pob.cfirstbid
          left outer join po_order_bb bb
            on (bb.pk_order_b = b.pk_order_b and bb.fonwaystatus = '2'and bb.isoperated = 'Y' and nvl(bb.nmaxhandlenum, 0) <> 0)        
         WHERE h.dr = 0
           AND b.dr = 0
           and h.bislatest = 'Y'
           AND meta.pk_billtypecode in ('21-Cxx-11','21-Cxx-13')

           )
           where rn = 1
          
           union all
           
           select vbillcode,modifiedtime
           from(
           select vbillcode,
                  substr(modifiedtime,0,10) modifiedtime ,
                  row_number() over(partition by vbillcode order by modifiedtime desc)rn
           from ic_vmi_sum 
           where modifiedtime is not null 
                 /*and SUBSTR(creationtime, 0, 10) >= parameter('sdate')
                 AND SUBSTR(creationtime, 0, 10) <= parameter('edate')*/
           )where rn = 1

    )shijian on (shijian.vbillcode = detailnotinvoicemny.vbillcode )
    

       
       )a
       
       --where substr(a.zuihou,0,10) between parameter('begindate') and  parameter('enddate')
       group by a.gys,
       a.sfjcxh,
       a.sumnotinvoicemny ,
       a.deptname,
       a.psnname,
       a.vbillcode,
       a.aname,
       a.cglx,
       a.zuihou,
       a.orgname,
       a.parvdate
      /* a.pk_reqstoorg*/
      ) where  /*fkje - purinmny > 1 OR (ordermny >= purinmny and (abs(notinvoicemny) >= 1 \*or detailnotinvoicemny.notinvoicemny <= -1*\
    or (notinvoicemny = 0 and
       vbillcode = '寄存销售')))*/
       /*ordermny >= purinmny and*/ (abs(notinvoicemny) > 1.5 /*or detailnotinvoicemny.notinvoicemny <= -1*/
    or (notinvoicemny = 0 and
       vbillcode = '寄存销售'))
