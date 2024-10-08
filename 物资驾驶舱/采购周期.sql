select cg.nd, --年度 
cg.yearmth, --会计月份 
cg.deptname, --部门
round((nvl(cg.pjcgts,0) + nvl(dh.pjdhts,0)),2) cgzq, --采购周期
to_char(sysdate,'yyyy-MM-dd') gxrq --更新日期
from WHH_V_PJCGTSJCSJ_WH cg
left join WHH_V_PJDHTSJCSJ_WH dh
on cg.nd = dh.nd
and cg.yearmth = dh.yearmth
and cg.deptname = dh.deptname