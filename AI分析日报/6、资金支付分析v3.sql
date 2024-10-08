select 
    vbillcode, --订单号
    supname, --供应商
    denddate, --生效日期
    ppmny,  --待支付金额
    bumen, --采购部门
    caigouyuan,  --采购员
    reason --未发起原因
from (
select 
aa.pk_order, 
aa.vbillcode, 
aa.supname, 
aa.suppliergrade, 
aa.dbilldate,
aa.btname, 
aa.cgzuzhi, 
aa.cgcode, 
aa.qygs, 
aa.bumen, 
aa.caigouyuan, 
nvl(rz.invoicemny, 0) as invoicemny,
aa.ntotalorigmny,  
case when abs(aa.ntotalorigmny - nvl(rz.invoicemny, 0)) > 10 then '否' else '是' end as sameflag,
aa.sumfkmny, 
aa.sumfkmny/aa.ntotalorigmny as zfbl,
substr(pp.denddate, 0, 10) denddate,
pp.nmny ppmny,
v_kxlx.kxlx || round(pp.nrate, 2) || '%' as kxlx,
case when sysdate > to_date(pp.denddate, 'yyyy-mm-dd hh24:mi:ss') and app.billno is null
     then 
      (case when (v_kxlx.fkxz <> 2 or (v_kxlx.fkxz = 2 and v_kxlx.kxlx in ('入场款', '进度款'))) and htsmj.nnum is null then '未上传合同扫描件'
           when aa.bumen not in /*('设备采购部','辅料采购部','沁和供应部','生产物资部','行政物资部','汽配物资部','设备物资部','辅料物资部','工程物资部', '工程市场合同部')*/ 
            (select name from bd_defdoc where dr = 0 and enablestate = 2
            and pk_defdoclist = '1001AZ10000000Y6ETNV' )then '部门错误'
           when supbank.pk_bankaccsub is null then '银行账户空'
           --when dzrq = 'nofenpei' then '未分配供应商'
           when dzrq = '9999-12-31' then '未分配供应商'
           when (dzrq is null or SYSDATE-to_date(dzrq, 'yyyy-MM-dd HH24:MI:SS') >= 365) and v_kxlx.kxlx = '验收款' then '未对账'
           when (v_kxlx.fkxz = 2 and v_kxlx.kxlx not in ('入场款', '进度款') and pp.nmny > nvl(yingfuamount, 0)) then '应付账款不足'
           when (v_kxlx.kxlx in ('质保金', '验收款') and paying.billno is not null) then '有在途付款单'
           when paying2.src_billid is not null then '有在途付款单'
           when length(aa.vmemo) > 220 then '订单中采购说明超过220字'
           else '其他原因'
      end)  
  else null end as reason,
  
case when pp.denddate is null 
     then '未触发'
     when sysdate > to_date(pp.denddate, 'yyyy-mm-dd hh24:mi:ss') and app.billno is null
     then '已到期'
     when sysdate < to_date(pp.denddate, 'yyyy-mm-dd hh24:mi:ss')
     then '未到期'
     when sysdate > to_date(pp.denddate, 'yyyy-mm-dd hh24:mi:ss') and app.approvestatus <> 1
     then  '已发起'
     else null
end zt,dzrq
   
from (
select pk_order, vbillcode, vmemo, pk_supplier, supname, suppliergrade, dbilldate, ntotalorigmny, btname, 
cgzuzhi, cgcode, qygs, bumen, caigouyuan, yfmny+sum(nvl(fkmny, 0)) sumfkmny,dzrq, yingfuamount
from (
select distinct p.pk_order,
       p.vbillcode, 
       p.vmemo,
       sup.pk_supplier,
       sup.name supname,
       supdj.suppliergrade,
       substr(p.dbilldate, 0, 10) dbilldate,
       p.ntotalorigmny,
       case
         when bt.name = '电子银行承兑汇票' then
          '银行承兑'
         when bt.name = '电子商业承兑汇票' then
          '商业承兑'
         else
          bt.name
       end btname, 
       cgorg.name cgzuzhi, 
       qygs.name qygs,
       cgorg.code cgcode,
       --dept.name bumen,
       case when dept.name = '设备采购部' then '设备物资部' 
            when dept.name = '辅料采购部' then '工程物资部'
            when dept.name = '辅料物资部' then '工程物资部'
            else dept.name end  bumen,
       psn.name caigouyuan,
       
       ap.billno apbillno,
       nvl(yjpay.yfmny, 0) yfmny,
       case when 
       api.def7 = '~' or api.def7 is null
       then 
         (case when api.def6 = '~' or api.def6 is null
             then api.money_de
          else to_number(replace(api.def6, ',', ''))
          end
         )
     else
       to_number(replace(api.def7, ',', ''))
end fkmny,
    --dzjzrqb.dzjzrq, --对账截止日期
    --hzqxcb.hzqxc, --合作期限从
    --nvl(nvl(dzjzrqb.dzjzrq,hzqxcb.hzqxc),substr(sup.creationtime,0,10)) dzrq --对账日期 
    case when supstock.def1 is null then '9999-12-31'--'未分配'
      when supstock.def1 = '~' then hzqxc.cong 
      else supstock.def1 end as dzrq, --对账日期 
    yingfu.yingfuamount
  from po_order p
  left join (select distinct pk_order from po_order_payment where dr = 0 and pk_payperiod <> '1001AZ10000000G193B3') popay
    on p.pk_order = popay.pk_order
  left join (                 
           select pk_order, max(yfmny) yfmny from (
              select pk_order, feffdatetype, sum(naccumpayorgmny) yfmny from (
              select pk_order, feffdatetype, naccumpayorgmny from po_order_payplan where dr = 0 /*and pk_order = '1001XA100000006OSO1K'*/ and feffdatetype = '~'
              union all
              select pk_order, feffdatetype, norigmny from po_order_payplan where dr = 0 /*and pk_order = '1001XA100000006OSO1K'*/ and feffdatetype = '1001AZ10000000G193B3'
              ) group by pk_order, feffdatetype
            ) group by pk_order
    ) yjpay
    on p.pk_order = yjpay.pk_order
  left join org_purchaseorg cgorg
    on p.pk_org = cgorg.pk_purchaseorg 
  left join bd_supplier sup
    on p.pk_supplier = sup.pk_supplier
/*  left join (select pk_supplier,dzjzrq
              from (
                select  pk_supplier,substr(def1,0,10) dzjzrq, row_number() over (partition by pk_supplier order by def1) as rn
                from bd_supstock where def1 !='~'
              )
              where rn = 1) dzjzrqb --对账截止日期表
    on sup.pk_supplier = dzjzrqb.pk_supplier
  left join (select gyszj,hzqxc
            from (
              select  gyszj,substr(cong,0,10) hzqxc, row_number() over (partition by gyszj order by cong) as rn
              from gyscgxx_02 where cong !='~'
            )
            where rn = 1) hzqxcb --合作期限从表
    on sup.pk_supplier = hzqxcb.gyszj*/
    
  left join gyscgxx_02 hzqxc on (p.pk_supplier = hzqxc.gyszj and p.pk_org = hzqxc.zzzj)
  left join bd_supstock supstock on (hzqxc.gyszj = supstock.pk_supplier and hzqxc.zzzj = supstock.pk_org and supstock.dr = 0)
  left join V_wuziyingfuview_wh yingfu on (p.pk_org = yingfu.org and p.pk_supplier = yingfu.sup)  
  left join srmsm_supplierext_h suph
    on sup.pk_supplier = suph.csupplierid
  left join bd_supplier_grade supdj
    on suph.csupgrade = supdj.pk_grade_info
  left join bd_balatype bt
    on p.pk_balatype = bt.pk_balatype
  left join org_dept dept
    on p.pk_dept = dept.pk_dept
  left join bd_psndoc psn
    on p.cemployeeid = psn.pk_psndoc
  left join org_orgs org
    on p.pk_org = org.pk_org 
  left join bd_defdoc qygs
    on qygs.pk_defdoc = org.def6
  left join ap_paybill ap
    on (p.vbillcode = ap.def26 and ap.dr = 0 and ap.approvestatus = 1 and ap.pk_tradetypeid = '1001B3100000000DZJ99')
  left join (select * from ap_payitem api 
        left join po_order_payplan pp on api.top_itemid = pp.pk_order_payplan and pp.dr = 0
        where api.dr = 0 and pp.feffdatetype not in ('1001AZ10000000G193B3', '~')
        ) api
    on (ap.pk_paybill = api.pk_paybill)
  where p.dr = 0 
  and p.bislatest = 'Y'
  and p.forderstatus = 3
  and p.bfinalclose = 'N'
  and sup.supprop <> '1'
  and popay.pk_order is not null
  --and p.vbillcode = 'CD2022012800050417'
  --and substr(p.dbilldate, 0, 10) > '2019-01-01'
  and dept.name in (select name from bd_defdoc where dr = 0 and enablestate = 2
and pk_defdoclist = '1001AZ10000000Y6ETNV' )--物资供应报表部门集
  /*and substr(p.dbilldate, 0, 10)  between parameter('starttime') and parameter('endtime') 
  and cgorg.pk_purchaseorg in (parameter('cgzz'))
  and psn.pk_psndoc in (parameter('psndoc'))
  and p.pk_supplier in (parameter('pk_supplier'))
  and org.def6 in (parameter('ssqy'))*/
  )
  group by 
  pk_order, vbillcode,vmemo, pk_supplier, supname, suppliergrade, dbilldate, ntotalorigmny, btname, 
  cgzuzhi, cgcode, qygs, bumen, caigouyuan, yfmny,dzrq, yingfuamount
  having ntotalorigmny > yfmny+sum(nvl(fkmny, 0)) 
) aa 
left join po_order_payplan pp
  on aa.pk_order = pp.pk_order and pp.dr = 0 and pp.feffdatetype <> '~' and pp.feffdatetype <> '1001AZ10000000G193B3'
left join v_kxlx on pp.feffdatetype = v_kxlx.pk_payperiod
left join V_htsmj_wh htsmj on pp.pk_order = htsmj.pk_order
left join v_supbank supbank on aa.pk_supplier = supbank.pk_supplier
left join V_PAY_NOGL_VOUCHER paying on (pp.pk_financeorg = paying.pk_org and aa.pk_supplier = paying.sup)
left join (select distinct b.src_billid
  from ap_paybill h
 inner join ap_payitem b
    on h.pk_paybill = b.pk_paybill
 where h.dr = 0
   and b.dr = 0
   and h.approvestatus <> 1
   ) paying2 on pp.pk_order = paying2.src_billid
left join (
     select api.top_itemid, ap.billno, ap.approvestatus, api.def7
     from ap_payitem api 
     left join ap_paybill ap on api.pk_paybill = ap.pk_paybill 
     where api.dr = 0 
     and ap.dr = 0
     --and ap.billno = 'D32022123003028'
     --and ap.approvestatus = 1  
     and ap.pk_tradetypeid = '1001B3100000000DZJ99'
) app on pp.pk_order_payplan = app.top_itemid
left join V_GXH_PO_INVOICEMNY_WH rz on aa.vbillcode = rz.vbillcode
where app.billno is null or app.approvestatus <> 1
) where zt in ('已到期')
  and cgcode!='9182'
  and bumen not in ('采购科','工程市场合同部','工程市场部')
