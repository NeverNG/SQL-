--供应商管理
select count(1) gsyzs, --供应商总数
       sum(case when bdg.suppliergrade ='战略供应商' then 1 else 0 end) zlgyssl, --战略供应商数量
       sum(case when  bdd3.name !='不寄存' then 1 else 0 end) jcgyssl, --寄存供应商数量
       to_char(sysdate,'yyyy-MM-dd') gxrq --更新日期
  from bd_supplier bds
  left join srmsm_supplierext_h sh
    on bds.pk_supplier = sh.csupplierid
  left join bd_supplier_grade bdg
    on bdg.pk_grade_info = sh.csupgrade
  left join bd_defdoc bdd
    on bdd.pk_defdoc = bds.def2
  left join bd_defdoc bdd1
    on bdd1.pk_defdoc = bds.def14
  left join org_dept bdd2
    on bdd2.pk_dept = bds.def21
  left join org_orgs
    on bds.pk_org = org_orgs.pk_org
  left join bd_defdoc bdd3
    on bdd3.pk_defdoc = bds.def13
 where bds.dr = 0
 and bds.enablestate = 2
 and bdd2.name in ('行政物资部','工程物资部','生产物资部','汽配物资部','设备物资部')
 and org_orgs.code ='01'
 and bdd1.name ='供应链管理中心'
 and bdg.suppliergrade not in ('黑名单供应商','禁入供应商')