select yearv,
       sum(yufuamount)  YUFUAMOUNT, --预付账款
       sum(yingfuamount) SUMYINGFUAMOUNT, --应付账款
       sysdate
from(
select custsupprop, pk_cust_sup,
       suppliername,
       pk_org,
       orgname,
       ssbm,
       zjm,
       yearv,
       sum(openamount) as openamount,
       sum(debitamount) as debitamount,
       sum(creditamount) as creditamount,  
       sum(balamount) as balamount,
       sum(yingfuqc) as yingfuqc,
       sum(yufuqc) as yufuqc,
       sum(zhibaomnyqc) as zhibaomnyqc,
       sum(yingfuamount) as yingfuamount,
       sum(yufuamount) as yufuamount,
       sum(zhibaomny) as zhibaomny,
       gysjbfl
from(

select custsupprop, pk_cust_sup,
       suppliername,
       pk_org,
       orgname,
       ssbm,
       zjm,
       sum(openamount) as openamount,
       sum(debitamount) as debitamount,
       sum(creditamount) as creditamount,  
       sum(balamount) as balamount,
       sum(yingfuqc) as yingfuqc,
       sum(yufuqc) as yufuqc,
       sum(zhibaomnyqc) as zhibaomnyqc,
       sum(yingfuamount) as yingfuamount,
       sum(yufuamount) as yufuamount,
       sum(zhibaomny) as zhibaomny,
       gysjbfl,
       yearv
       from (
select yearv,
       custsupprop,
       pk_cust_sup,
       suppliername,
       pk_org,
       orgname,
       ssbm,
       zjm,
/*       sum(openamount) openamount,
       sum(debitamount) debitamount,
       sum(creditamount) creditamount,  
       sum(balamount) - (-sum(openamount)) balamount,*/
       0 openamount,
       0 debitamount,
       0 creditamount,  
       0 balamount,
/*        case when yearv = '2022' and  then sum(gl_detail.localcreditamount - gl_detail.localdebitamount) - 119141525.90 else sum(gl_detail.localcreditamount - gl_detail.localdebitamount) end openamount,*/
       case
         when sum(openamount) >= 0 then
          sum(openamount) 
         else 0
       end yingfuqc,
       case
         when sum(openamount) < 0 then
          -sum(openamount) else 0
       end yufuqc,
       case
         when sum(zhibaomnys) >= 0 then
          sum(zhibaomnys) else 0
       end zhibaomnyqc,
       
       /*case
         when sum(balamount) + sum(openamount) >= 0 then
          sum(balamount) + sum(openamount) else 0
       end yingfuamount,
       case
         when sum(balamount) + sum(openamount) < 0 then
          - (sum(balamount) + sum(openamount)) else 0
       end yufuamount,

       case
         when sum(zhibaomnye) + sum(zhibaomnys) >= 0 then
          sum(zhibaomnye) + sum(zhibaomnys) else 0
       end zhibaomny*/
       
       case
         when sum(balamount) >= 0 then
              sum(balamount) 
           else 0
       end yingfuamount,
       case
         when sum(balamount) < 0 then
          -sum(balamount) else 0
       end yufuamount,
       case
         when sum(zhibaomnye) >= 0 then
          sum(zhibaomnye) else 0
       end zhibaomny,
       gysjbfl  
  from (select gl_detail.pk_accasoa,
               gl_detail.pk_accountingbook,
               gl_detail.yearv yearv,
               accmth.accperiodmth, 
               bd_cust_supplier.custsupprop,
               bd_cust_supplier.pk_cust_sup,
               bd_cust_supplier.name suppliername,
               org.pk_org,
               org.name orgname,
               bd.def21 ssbm,
               bdd.name zjm,
               sum(gl_detail.localdebitamount) opendebitamount,
               sum(gl_detail.localcreditamount) opencreditamount,
               sum(gl_detail.localcreditamount - gl_detail.localdebitamount) openamount,
               0 debitamount,
               0 creditamount,
               0 balamount,
               0 zhibaomnys,
               0 zhibaomnye,
               bdsc.name gysjbfl --供应商基本分类
          from gl_detail gl_detail
          left outer join gl_docfree1
            on gl_detail.assid = gl_docfree1.assid
          /*left join gl_voucher glv on gl_detail.pk_voucher = glv.pk_voucher*/
          left join bd_cust_supplier
            on gl_docfree1.F4 = bd_cust_supplier.pk_cust_sup
          left outer join bd_accasoa acc
            on gl_detail.pk_accasoa = acc.pk_accasoa
          left outer join bd_account chartacc
            on acc.pk_account = chartacc.pk_account
          left outer join org_accountingbook
            on gl_detail.pk_accountingbook = org_accountingbook.pk_accountingbook
          left outer join org_setofbook on org_accountingbook.pk_setofbook=org_setofbook.pk_setofbook
          left outer join org_orgs org
            on org_accountingbook.pk_relorg = org.pk_org
          /*left outer join bd_supplier bd
            on bd.name = bd_cust_supplier.name*/
          left outer join bd_supplier bd
            on bd.pk_supplier = bd_cust_supplier.pk_cust_sup
          left join bd_supplierclass bdsc --供应商基本分类
            on bd.pk_supplierclass = bdsc.pk_supplierclass
          left outer join bd_defdoc bdd
            on bdd.pk_defdoc = bd.def14
         left join bd_accperiodmonth accmonth_2
          on to_char(sysdate, 'yyyy-MM-dd') between
          (substr(accmonth_2.BEGINDATE, 0, 10)) and
          (substr(accmonth_2.ENDDATE, 0, 10))
          left join bd_accperiodmonth accmth
            on substr(accmonth_2.BEGINDATE, 0, 10) between substr(accmth.begindate, 0, 10) and substr(accmth.enddate, 0, 10)
         where 
           gl_detail.yearv = substr(accmth.yearmth, 1, 4)/*1=1*/
           and gl_detail.adjustperiod >= '00'
           and gl_detail.adjustperiod < accmth.accperiodmth 
/*           gl_detail.yearv = substr('2021-07-05', 1, 4)\*1=1*\
           and gl_detail.adjustperiod >= '00'
           and gl_detail.adjustperiod < substr('2021-07-05', 6, 2)*/
           and (chartacc.code like '2202%' or chartacc.code like '1123%')
           and chartacc.code not in('122103','224111')
           and gl_docfree1.F18 = '1001B31000000005L2Z1'
           and gl_detail.dr = 0
           and org_setofbook.code='0001'
           and gl_detail.voucherkindv <> 5
           and gl_detail.tempsaveflag <> 'Y'
           /*and org.name <> '孝义市大富房地产开发有限公司'*/
           /*and (glv.pk_system <>  'GL' and bd.code <> '0200379') */
         group by gl_detail.pk_accasoa,
                  gl_detail.pk_accountingbook,
                  bd_cust_supplier.custsupprop,
                  bd_cust_supplier.pk_cust_sup,
                  bd_cust_supplier.name,
                  gl_detail.yearv,
                  accmth.accperiodmth, 
                  org.name,
                  bd.def21,
                  bdd.name,
                  org.pk_org,
                  bdsc.name
         union all
         select gl_detail.pk_accasoa,
               gl_detail.pk_accountingbook,
               gl_detail.yearv yearv,
               accmth.accperiodmth, 
               bd_cust_supplier.custsupprop,
               bd_cust_supplier.pk_cust_sup,
               bd_cust_supplier.name suppliername,
               org.pk_org,
               org.name orgname,
               bd.def21 ssbm,
               bdd.name zjm, 
               /*9198-0001  山西平定古州卫东煤业有限公司-基准账簿 不去客商往来这个科目余额*/
               
               sum(case when org.code = '9198' and chartacc.code = '224111' then 0 else gl_detail.localdebitamount end ) opendebitamount,
               sum(case when org.code = '9198' and chartacc.code = '224111' then 0 else gl_detail.localcreditamount end ) opencreditamount,
               sum(case when org.code = '9198' and chartacc.code = '224111' then 0 else gl_detail.localcreditamount - gl_detail.localdebitamount end) openamount,
               0 debitamount,
               0 creditamount,
               0 balamount,
               0 zhibaomnys,
               0 zhibaomnye,
               bdsc.name gysjbfl --供应商基本分类
          from gl_detail gl_detail
          left outer join gl_docfree1
            on gl_detail.assid = gl_docfree1.assid
          /*left join gl_voucher glv on gl_detail.pk_voucher = glv.pk_voucher*/
          left join bd_cust_supplier
            on gl_docfree1.F4 = bd_cust_supplier.pk_cust_sup
          left outer join bd_accasoa acc
            on gl_detail.pk_accasoa = acc.pk_accasoa
          left outer join bd_account chartacc
            on acc.pk_account = chartacc.pk_account
          left outer join org_accountingbook
            on gl_detail.pk_accountingbook =
               org_accountingbook.pk_accountingbook
          left outer join org_setofbook on org_accountingbook.pk_setofbook=org_setofbook.pk_setofbook
          left outer join org_orgs org
            on org_accountingbook.pk_relorg = org.pk_org
/*          left outer join bd_supplier bd
            on bd.name = bd_cust_supplier.name*/
          left outer join bd_supplier bd
            on bd.pk_supplier = bd_cust_supplier.pk_cust_sup
          left join bd_supplierclass bdsc --供应商基本分类
            on bd.pk_supplierclass = bdsc.pk_supplierclass
          left outer join bd_defdoc bdd
            on bdd.pk_defdoc = bd.def14
          left join bd_accperiodmonth accmonth_2
            on to_char(sysdate, 'yyyy-MM-dd') between
            (substr(accmonth_2.BEGINDATE, 0, 10)) and
            (substr(accmonth_2.ENDDATE, 0, 10))
          left join bd_accperiodmonth accmth
            on substr(accmonth_2.BEGINDATE, 0, 10) between substr(accmth.begindate, 0, 10) and substr(accmth.enddate, 0, 10)
         where 
           gl_detail.yearv = substr(accmth.yearmth, 1, 4)/*1=1*/
           and gl_detail.adjustperiod >= '00'
           and gl_detail.adjustperiod < accmth.accperiodmth  
/*           gl_detail.yearv = substr('2021-07-05', 1, 4)\*1=1*\
           and gl_detail.adjustperiod >= '00'
           and gl_detail.adjustperiod < substr('2021-07-05', 6, 2)*/
           --and (chartacc.code in ('224103','224111'))     /*质保金和客商往来*/
           and (chartacc.code in ('224103'))     /*质保金*/
           and chartacc.code not in('122103','224111')
           and gl_detail.dr = 0
           and org_setofbook.code='0001'
           and gl_detail.voucherkindv <> 5
           and gl_detail.tempsaveflag <> 'Y'
           /*and org.name <> '孝义市大富房地产开发有限公司'*/
           /*and (glv.pk_system <>  'GL' and bd.code <> '0200379') */
         group by gl_detail.pk_accasoa,
                  gl_detail.pk_accountingbook,
                  bd_cust_supplier.custsupprop,
                  bd_cust_supplier.pk_cust_sup,
                  bd_cust_supplier.name,
                  gl_detail.yearv,
                  accmth.accperiodmth, 
                  org.name,
                  bd.def21,
                  bdd.name,
                  org.pk_org,
                  bdsc.name
       /*应付质保金*/
         union all
         select gl_detail.pk_accasoa,
               gl_detail.pk_accountingbook,
               gl_detail.yearv yearv,
               accmth.accperiodmth, 
               bd_cust_supplier.custsupprop,
               bd_cust_supplier.pk_cust_sup,
               bd_cust_supplier.name suppliername,
               org.pk_org,
               org.name orgname,
               bd.def21 ssbm,
               bdd.name zjm, 
               0 opendebitamount,
               0 opencreditamount,
               0 openamount,
               0 debitamount,
               0 creditamount,
               0 balamount,
               sum(gl_detail.localcreditamount - gl_detail.localdebitamount) zhibaomnys,
               0 zhibaomnye,
               bdsc.name gysjbfl
          from gl_detail gl_detail
          /*left join gl_voucher glv on gl_detail.pk_voucher = glv.pk_voucher*/
          left outer join gl_docfree1
            on gl_detail.assid = gl_docfree1.assid
          left join bd_cust_supplier
            on gl_docfree1.F4 = bd_cust_supplier.pk_cust_sup
          left outer join bd_accasoa acc
            on gl_detail.pk_accasoa = acc.pk_accasoa
          left outer join bd_account chartacc
            on acc.pk_account = chartacc.pk_account
          left outer join org_accountingbook
            on gl_detail.pk_accountingbook = org_accountingbook.pk_accountingbook
          left outer join org_setofbook 
            on org_accountingbook.pk_setofbook=org_setofbook.pk_setofbook
          left outer join org_orgs org
            on org_accountingbook.pk_relorg = org.pk_org
/*          left outer join bd_supplier bd
            on bd.name = bd_cust_supplier.name*/
          left outer join bd_supplier bd
            on bd.pk_supplier = bd_cust_supplier.pk_cust_sup
          left join bd_supplierclass bdsc --供应商基本分类
            on bd.pk_supplierclass = bdsc.pk_supplierclass
          left outer join bd_defdoc bdd
            on bdd.pk_defdoc = bd.def14
          left join bd_accperiodmonth accmonth_2
            on to_char(sysdate, 'yyyy-MM-dd') between
            (substr(accmonth_2.BEGINDATE, 0, 10)) and
            (substr(accmonth_2.ENDDATE, 0, 10))
          left join bd_accperiodmonth accmth
            on substr(accmonth_2.BEGINDATE, 0, 10) between substr(accmth.begindate, 0, 10) and substr(accmth.enddate, 0, 10)
         where 
           gl_detail.yearv = substr(accmth.yearmth, 1, 4)/*1=1*/
           and gl_detail.adjustperiod >= '00'
           and gl_detail.adjustperiod < accmth.accperiodmth
           
/*           gl_detail.yearv = substr('2021-07-05', 1, 4)\*1=1*\
           and gl_detail.adjustperiod >= '00'
           and gl_detail.adjustperiod < substr('2021-07-05', 6, 2)*/
           and chartacc.code = '224103'   /*质保金*/
           and gl_detail.dr = 0
           and org_setofbook.code='0001'
           and gl_detail.voucherkindv <> 5
           and gl_detail.tempsaveflag <> 'Y'
           /*and org.name <> '孝义市大富房地产开发有限公司'*/
           
           /*and (glv.pk_system <>  'GL' and bd.code <> '0200379')*/

         group by gl_detail.pk_accasoa,
                  gl_detail.pk_accountingbook,
                  bd_cust_supplier.custsupprop,
                  bd_cust_supplier.pk_cust_sup,
                  bd_cust_supplier.name,
                  gl_detail.yearv,
                  accmth.accperiodmth, 
                  org.name,
                  bd.def21,
                  bdd.name,
                  org.pk_org, 
                  bdsc.name
                  
        union all
        select gl_detail.pk_accasoa,
               gl_detail.pk_accountingbook,
               gl_detail.yearv yearv,
               accmths.accperiodmth, 
               bd_cust_supplier.custsupprop,
               bd_cust_supplier.pk_cust_sup,
               bd_cust_supplier.name suppliername,
               org.pk_org,
               org.name orgname,
               bd.def21 ssbm,
               bdd.name zjm,
               0 opendebitamount,
               0 opencreditamount,
               0 openamount,
               sum(gl_detail.localdebitamount) debitamount,
               sum(gl_detail.localcreditamount) creditamount,
               sum(gl_detail.localcreditamount - gl_detail.localdebitamount) balamount,
               0 zhibaomnys,
               0 zhibaomnye,
               bdsc.name gysjbfl
          from gl_detail gl_detail
          /*left join gl_voucher glv on gl_detail.pk_voucher = glv.pk_voucher*/
          left outer join gl_docfree1
            on gl_detail.assid = gl_docfree1.assid
          left join bd_cust_supplier
            on gl_docfree1.F4 = bd_cust_supplier.pk_cust_sup
          left outer join bd_accasoa acc
            on gl_detail.pk_accasoa = acc.pk_accasoa
          left outer join bd_account chartacc
            on acc.pk_account = chartacc.pk_account
          left outer join org_accountingbook
            on gl_detail.pk_accountingbook = org_accountingbook.pk_accountingbook
          left outer join org_setofbook 
            on org_accountingbook.pk_setofbook=org_setofbook.pk_setofbook
          left outer join org_orgs org
            on org_accountingbook.pk_relorg = org.pk_org
/*            left outer join bd_supplier bd
            on bd.name = bd_cust_supplier.name*/
          left outer join bd_supplier bd
            on bd.pk_supplier = bd_cust_supplier.pk_cust_sup
          left join bd_supplierclass bdsc --供应商基本分类
            on bd.pk_supplierclass = bdsc.pk_supplierclass
          left outer join bd_defdoc bdd
            on bdd.pk_defdoc = bd.def14
           /*left join bd_accperiodmonth accmth
            on parameter('sdate') between substr(accmth.begindate, 0, 10) and substr(accmth.enddate, 0, 10)*/
           left join bd_accperiodmonth accmths
            on to_char(sysdate,'yyyy-MM-dd') between substr(accmths.begindate, 0, 10) and substr(accmths.enddate, 0, 10)
         where 
           gl_detail.yearv = substr(accmths.yearmth, 1, 4)/*1=1*/
           /*and gl_detail.adjustperiod >= accmth.accperiodmth  */
           and gl_detail.adjustperiod >= '00'
           and gl_detail.adjustperiod <= accmths.accperiodmth 
           /*and gl_detail.adjustperiod <= (select accperiodmth  from bd_accperiodmonth where to_char(sysdate,'yyyy-MM-dd') between substr(begindate, 0, 10) and substr(enddate, 0, 10)) */   
            
           
/*           gl_detail.yearv >= substr('2021-08-05', 1, 4)
           and gl_detail.adjustperiod >= substr('2021-07-01', 6, 2)
           and gl_detail.adjustperiod <= substr('2021-07-21', 6, 2)*/
           
           and (chartacc.code like '2202%' or chartacc.code like '1123%')
           and chartacc.code not in('122103','224111')
           and gl_docfree1.F18 = '1001B31000000005L2Z1'
           and gl_detail.dr = 0
           and org_setofbook.code='0001'
           and gl_detail.voucherkindv <> 5
           and gl_detail.tempsaveflag <> 'Y'
           /*and org.name <> '孝义市大富房地产开发有限公司'*/
           
           /*and (glv.pk_system <>  'GL' and bd.code <> '0200379')*/

         group by gl_detail.pk_accasoa,
                  gl_detail.pk_accountingbook,
                  bd_cust_supplier.custsupprop,
                  bd_cust_supplier.pk_cust_sup,
                  bd_cust_supplier.name,
                  gl_detail.yearv,
                  accmths.accperiodmth, 
                  org.name,
                  bd.def21,
                  bdd.name,
                  org.pk_org,
                  bdsc.name
          union all
        select gl_detail.pk_accasoa,
               gl_detail.pk_accountingbook,
               gl_detail.yearv yearv,
               accmths.accperiodmth, 
               bd_cust_supplier.custsupprop,
               bd_cust_supplier.pk_cust_sup,
               bd_cust_supplier.name suppliername,
               org.pk_org,
               org.name orgname,
               bd.def21 ssbm,
               bdd.name zjm,
               0 opendebitamount,
               0 opencreditamount,
               0 openamount,
               sum(case when org.code = '9198' and chartacc.code = '224111' then 0 else gl_detail.localdebitamount end ) debitamount,
               sum(case when org.code = '9198' and chartacc.code = '224111' then 0 else gl_detail.localcreditamount end ) creditamount,
               sum(case when org.code = '9198' and chartacc.code = '224111' then 0 else gl_detail.localcreditamount - gl_detail.localdebitamount end) balamount,
               0 zhibaomnys,
               0 zhibaomnye,
               bdsc.name gysjbfl
          from gl_detail gl_detail
          /*left join gl_voucher glv on gl_detail.pk_voucher = glv.pk_voucher*/
          left outer join gl_docfree1
            on gl_detail.assid = gl_docfree1.assid
          left join bd_cust_supplier
            on gl_docfree1.F4 = bd_cust_supplier.pk_cust_sup
          left outer join bd_accasoa acc
            on gl_detail.pk_accasoa = acc.pk_accasoa
          left outer join bd_account chartacc
            on acc.pk_account = chartacc.pk_account
          left outer join org_accountingbook
            on gl_detail.pk_accountingbook = org_accountingbook.pk_accountingbook
          left outer join org_setofbook 
            on org_accountingbook.pk_setofbook=org_setofbook.pk_setofbook
          left outer join org_orgs org
            on org_accountingbook.pk_relorg = org.pk_org
/*            left outer join bd_supplier bd
            on bd.name = bd_cust_supplier.name*/
          left outer join bd_supplier bd
            on bd.pk_supplier = bd_cust_supplier.pk_cust_sup
          left join bd_supplierclass bdsc --供应商基本分类
            on bd.pk_supplierclass = bdsc.pk_supplierclass
          left outer join bd_defdoc bdd
            on bdd.pk_defdoc = bd.def14        
           /*left join bd_accperiodmonth accmth
            on parameter('sdate') between substr(accmth.begindate, 0, 10) and substr(accmth.enddate, 0, 10)*/
           left join bd_accperiodmonth accmths
            on to_char(sysdate,'yyyy-MM-dd') between substr(accmths.begindate, 0, 10) and substr(accmths.enddate, 0, 10)
         where 
           gl_detail.yearv = substr(accmths.yearmth, 1, 4)/*1=1*/
           /*and gl_detail.adjustperiod >= accmth.accperiodmth */
           and gl_detail.adjustperiod >= '00' 
           and gl_detail.adjustperiod <= accmths.accperiodmth 
           /*and gl_detail.adjustperiod <= (select accperiodmth  from bd_accperiodmonth where to_char(sysdate,'yyyy-MM-dd') between substr(begindate, 0, 10) and substr(enddate, 0, 10)) */  

/*           and gl_detail.yearv >= substr('2021-08-05', 1, 4)
           and gl_detail.adjustperiod >= substr('2021-07-01', 6, 2)
           and gl_detail.adjustperiod <= substr('2021-07-21', 6, 2)*/
           
           and (chartacc.code in ('224103'))
           and chartacc.code not in('122103','224111')
           and gl_detail.dr = 0
           and org_setofbook.code='0001'
           and gl_detail.voucherkindv <> 5
           and gl_detail.tempsaveflag <> 'Y'
           /*and org.name <> '孝义市大富房地产开发有限公司'*/
           
           /*and (glv.pk_system <>  'GL' and bd.code <> '0200379')*/

         group by gl_detail.pk_accasoa,
                  gl_detail.pk_accountingbook,
                  bd_cust_supplier.custsupprop,
                  bd_cust_supplier.pk_cust_sup,
                  bd_cust_supplier.name,
                  gl_detail.yearv,
                  accmths.accperiodmth, 
                  org.name,
                  bd.def21,
                  bdd.name,
                  org.pk_org,
                  bdsc.name
        /*应付质保金 */         
        union all
        select gl_detail.pk_accasoa,
               gl_detail.pk_accountingbook,
               gl_detail.yearv yearv,
               accmths.accperiodmth, 
               bd_cust_supplier.custsupprop,
               bd_cust_supplier.pk_cust_sup,
               bd_cust_supplier.name suppliername,
               org.pk_org,
               org.name orgname,
               bd.def21 ssbm,
               bdd.name zjm,
               0 opendebitamount,
               0 opencreditamount,
               0 openamount,
               0 debitamount,
               0 creditamount,
               0 balamount, 
               0 zhibaomnys,
               sum(gl_detail.localcreditamount - gl_detail.localdebitamount) zhibaomnye,
               bdsc.name gysjbfl
          from gl_detail gl_detail
          /*left join gl_voucher glv on gl_detail.pk_voucher = glv.pk_voucher*/
          left outer join gl_docfree1
            on gl_detail.assid = gl_docfree1.assid
          left join bd_cust_supplier
            on gl_docfree1.F4 = bd_cust_supplier.pk_cust_sup
          left outer join bd_accasoa acc
            on gl_detail.pk_accasoa = acc.pk_accasoa
          left outer join bd_account chartacc
            on acc.pk_account = chartacc.pk_account
          left outer join org_accountingbook
            on gl_detail.pk_accountingbook = org_accountingbook.pk_accountingbook
          left outer join org_setofbook 
            on org_accountingbook.pk_setofbook=org_setofbook.pk_setofbook
          left outer join org_orgs org
            on org_accountingbook.pk_relorg = org.pk_org
/*            left outer join bd_supplier bd
            on bd.name = bd_cust_supplier.name*/
          left outer join bd_supplier bd
            on bd.pk_supplier = bd_cust_supplier.pk_cust_sup
          left join bd_supplierclass bdsc --供应商基本分类
            on bd.pk_supplierclass = bdsc.pk_supplierclass
          left outer join bd_defdoc bdd
            on bdd.pk_defdoc = bd.def14
          /*left join bd_accperiodmonth accmth
            on parameter('sdate') between substr(accmth.begindate, 0, 10) and substr(accmth.enddate, 0, 10)*/
          left join bd_accperiodmonth accmths
            on to_char(sysdate,'yyyy-MM-dd') between substr(accmths.begindate, 0, 10) and substr(accmths.enddate, 0, 10)
         where 
           gl_detail.yearv >= substr(accmths.yearmth, 1, 4)/*1=1*/
           /*and gl_detail.adjustperiod >= accmth.accperiodmth*/
           and gl_detail.adjustperiod >= '00'  
           and gl_detail.adjustperiod <= accmths.accperiodmth
           /*and gl_detail.adjustperiod <= (select accperiodmth  from bd_accperiodmonth where to_char(sysdate,'yyyy-MM-dd') between substr(begindate, 0, 10) and substr(enddate, 0, 10))*/    

/*           and gl_detail.yearv >= substr('2021-08-05', 1, 4)
           and gl_detail.adjustperiod >= substr('2021-07-01', 6, 2)
           and gl_detail.adjustperiod <= substr('2021-07-21', 6, 2)*/
           
           and (chartacc.code in ('224103'))
           and gl_detail.dr = 0
           and org_setofbook.code='0001'
           and gl_detail.voucherkindv <> 5
           and gl_detail.tempsaveflag <> 'Y'
           /*and org.name <> '孝义市大富房地产开发有限公司'*/
           
           /*and (glv.pk_system <>  'GL' and bd.code <> '0200379')*/

         group by gl_detail.pk_accasoa,
                  gl_detail.pk_accountingbook,
                  bd_cust_supplier.custsupprop,
                  bd_cust_supplier.pk_cust_sup,
                  bd_cust_supplier.name,
                  gl_detail.yearv,
                  accmths.accperiodmth, 
                  org.name,
                  bd.def21,
                  bdd.name,
                  org.pk_org,
                  bdsc.name
                  
)
where 1=1 
/*and orgname not in ('孝义市大富房地产开发有限公司')*/
/*and orgname like '%平定金源国际酒店%'*/
/*and zhibaomnys <> 0*/
 group by yearv, custsupprop, pk_cust_sup, suppliername, pk_org, orgname,ssbm,zjm,gysjbfl
 ) group by custsupprop, pk_cust_sup, suppliername, pk_org, orgname,ssbm,zjm,gysjbfl,yearv
/*  left join bd_supplier bb
 on bb.pk_supplier = aa.pk_cust_sup
 left join bd_supplier bds12
 on bds12.pk_supplier = bb.def12*/) 
 where zjm ='供应链管理中心'
 and ssbm not in('第一大宗供应部','第二大宗供应部')
 group by custsupprop, pk_cust_sup, suppliername, pk_org, orgname,ssbm,zjm,gysjbfl,yearv
) group by yearv