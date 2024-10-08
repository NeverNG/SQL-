--物料编码
select 
sum(case when (code like 'W%' or code like 'S%' or code like 'X%' or code like 'Q%' or code like 'L%') then 1 else 0 end) as wlzs,--物料总数
  sum(case when code like 'L%' then 1 else 0 end) lswls, --临时物料数
  to_char(sysdate,'yyyy-MM-dd') gxrq --更新日期
  from bd_material
 where dr = 0
   and enablestate = 2;