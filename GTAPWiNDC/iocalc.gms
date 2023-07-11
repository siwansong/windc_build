$title	Canonical Template GTAP-WINDC Model (MGE format)

$set gtapwindc_datafile %system.fp%datasets\gtapwindc\43.gdx

*	Read the data:

$if not set ds $set ds 43

$include gtapwindc_data

singleton set	re(r)			Region to evaluate /usa/;

set	iag(i)			Agricultural sectors/ pdr, wht, gro, v_f, osd, c_b, pfb, ocr, ctl, oap, rmk, wol/,
	is(i,s)			Content to evaluate,
	samesector(i,s,i,s)	Sector identifier;

alias (s,ss);

parameter	valueadded(i,r,s)	Sectoral value-added;

valueadded(i,re(r),s) = rto(i,r)*vom(i,r,s)+sum(f,vfm(f,i,r,s)*(1+rtf0(f,i,r)));


variable	OBJ		Objective;

variables	v_P(i,j,s)	"Value-added content of Y(j,ss) in P(i)",
		v_PD(i,s,j,ss)	"Value-added content of Y(j,ss) in PD(i,s)",
		v_PZ(i,s,j,ss)	"Value-added content of Y(j,ss) in PZ(i,s)",
		v_PY(i,s,j,ss)	"Value-added content of Y(j,ss) in PY(i,s)";

equations	objdef, content_Y, content_Z, content_X;

*	Objective function: among all content definitions which are feasible, find the one which
*	most closely approximates the content in the national market.

objdef..	OBJ =e= sum((i,s,re(r),is)$xd0(i,r,s), xd0(i,r,s)*sqr(v_PD(i,s,is)-v_P(i,is)));

content_Y(i,re(r),s,is)$y_(i,r,s)..

		vom(i,r,s)*v_PY(i,s,is) =e= sum(j, vafm(j,i,r,s)*v_PZ(j,s,is)) + valueadded(i,r,s)$samesector(i,s,is);

content_Z(i,re(r),s,is)$z_(i,r,s)..
		a0(i,r,s)*v_PZ(i,s,is) =e= xd0(i,r,s)*v_PD(i,s,is) + nd0(i,r,s)*v_P(i,is);

content_X(i,re(r),s,is)$x_(i,r,s)..
		xn0(i,r,s)*v_P(i,is) + xd0(i,r,s)*v_PD(i,S,is) =E= vom(i,r,s)*v_PY(i,s,is);

model content /objdef, content_Y, content_Z, content_X/;

option qcp=cplex;


is(i,s) = no;
loop(iag,
	loop(re,
	  is(iag,s) = yes$valueadded(iag,re,s));
	samesector(i,s,i,s) = yes$is(i,s);
	solve content using qcp minimizing OBJ;
	is(iag,s) = no;
);

parameter	atm(*,iag,s)	Export content;
atm(i,iag,s)$iag(i) = v_P.L(i,iag,s);
atm("total",iag,s) = sum(i$iag(i), (sum(rr,vxmd(i,re,rr))+vst(i,re)) * v_P.L(i,iag,s)) /
		     sum(i$iag(i), (sum(rr,vxmd(i,re,rr))+vst(i,re)));

atm("vashare",iag,s) = valueadded(iag,re,s)/sum(s.local,valueadded(iag,re,s));

execute_unload 'atm.gdx',atm;
