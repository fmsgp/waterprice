
global data "D:\Dropbox\water"   	

*Figure 1
use "${data}\data.dta", clear
keep if ext!=1
keep pcat year month wat time

bysort pcat year month: egen mwat=mean(wat)
bysort pcat year month: gen seq_type=_n

sort time
twoway (lfitci wat time if treatment==1 & announce==0, color("white%80"))  (lfitci wat time if treatment==1 & announce==1, color("white%80")) (lfit wat time if treatment==1 & announce==0, lc(gray))  (lfit wat time if treatment==1 & announce==1, lc(gray))  (scatter wat time if treatment==1 & announce==0, mc(gray))(scatter wat time if treatment==1 & announce==1, mc(gray)) , ytitle("Mean monthly water consumption") xtitle("") ylabel(12(2)20) xline(685.5) legend(off) xlabel(660 "2015m1" 672 "2016m1" 684 "2017m1" 696 "2018m1")
graph save "Graph" figure1a, replace

twoway  (lfitci wat time if treatment==0 & announce==0, color("white%80"))  (lfitci wat time if treatment==0 & announce==1, color("white%80")) (lfit wat time if treatment==0 & announce==0, lc(gray))  (lfit wat time if treatment==0 & announce==1, lc(gray))  (scatter wat time if treatment==0 & announce==0, mc(gray))(scatter wat time if treatment==0& announce==1, mc(gray)) , ytitle("Mean monthly water consumption") xtitle("") ylabel(12(2)20) xline(685.5) legend(off) xlabel(660 "2015m1" 672 "2016m1" 684 "2017m1" 696 "2018m1")
graph save "Graph" figure1b.gph, replace

graph use figure1a
gr_edit .b1title.text = {`"(a) HDB flats"'}
graph save figure1a, replace

graph use figure1b
gr_edit .b1title.text = {`"(b) Private apartments"'}
graph save figure1b, replace

graph combine figure1a figure1b, row(2) xsize(3.45) ysize(5) graphregion(color(white)) ycommon
graph save "Graph" Figure1.gph, replace
graph export Figure1.pdf, replace

*Figure 2
import excel "${data}\SourceData_Fig2.xlsx", sheet("Figure2a") firstrow clear 
split Date, p("-")
destring Date1, gen(year)
destring Date2, gen(month)
gen ym=ym(year, month)
format ym %tm
twoway (line WaterPrice ym) (line Usave ym), scheme(plottig) legend(row(1) pos(6)) xlabel(612(12)720)  xtitle("") title("(a) Water price and U-save", pos(6)) xlin(685) xline(690) xline(702) xline(625) xline(630) xline(697) xline(708)
graph save figure2a, replace

import excel "${data}\SourceData_Fig2.xlsx", sheet("Figure2b") firstrow clear 
split Month, p("-")
destring Month1, gen(year)
destring Month2, gen(month)
gen ym=ym(year, month)
format ym %tm
twoway (line GSTvouchercash ym) (line Usave ym), scheme(plottig) legend(row(1) pos(6)) xlabel(612(12)720) xtitle("") title("(b)	GST Voucher Cash and U-save", pos(6)) xlin(685, lc(black)) xline(690, lc(black)) xline(625, lc(black)) xline(630, lc(black)) xline(697, lc(black)) xline(708, lc(black))
graph save figure2b, replace

graph combine figure2a figure2b, row(2) xsize(3.45) ysize(6) graphregion(color(white)) ycommon
graph save "Graph" Figure2.gph, replace
graph export Figure2.pdf, replace


*Figure 3

use "${data}\data.dta", clear
keep if ext!=1
keep if time>=660 & time<708

cap drop announce
gen announce=1 if time>685 
replace announce=0 if announce==.

cap drop chg1
gen chg1=1 if time>690
replace chg1=0 if chg1==.

cap drop chg2 
gen chg2=(time>702)

gen treatment=(nptype<6)
gen post=(time>685)

cap drop trend
gen trend=time
replace trend=0 if trend<=661

replace trend=0 if treatment==0


*by ptype
reghdfe ln_wat 1.announce#ib6.nptype 1.chg1#ib6.nptype 1.chg2#ib6.nptype trend, absorb(i.premiseno i.time) cluster(pcode time) compact poolsize(4)
eststo het2
estimates save figure3_2,replace

coefplot het2, keep(1.announce#*) scheme(plottig) mc(black) ciopts(lcolor(black) recast(rcap)) offset(0) legend(off) vertical ytitle("Change in monthly water consumption (log)") ///
ysize(2.6) xsize(3.575) ylabel(-0.15(0.05)0.05,format(%5.2f)) yline(0) omitted ///
xlabel(1 "HDB 1/2-room" 2 "HDB 3-room" 3 "HDB 4-room" 4 "HDB 5-room" 5 "HDB Executive") title("(d) Announcement effect by housing type", pos(6)) 
graph save "Graph" figure3d, replace

coefplot het2, keep(1.chg1#*) scheme(plottig) mc(black) ciopts(lcolor(black) recast(rcap)) offset(0) legend(off) vertical ytitle("Change in monthly water consumption (log)") ///
ysize(2.6) xsize(3.575) ylabel(-0.15(0.05)0.05,format(%5.2f)) yline(0) omitted ///
xlabel(1 "HDB 1/2-room" 2 "HDB 3-room" 3 "HDB 4-room" 4 "HDB 5-room" 5 "HDB Executive") title("(e) Effect of first price change by housing type", pos(6)) 
graph save "Graph" figure3e, replace

coefplot het2, keep(1.chg2#*) scheme(plottig) format(%9.2g) ciopts(lcolor(black) recast(rcap)) offset(0) legend(off) vertical ytitle("Change in monthly water consumption (log)") ///
ysize(2.6) xsize(3.575) ylabel(-0.15(0.05)0.05,format(%5.2f)) yline(0) omitted ///
xlabel(1 "HDB 1/2-room" 2 "HDB 3-room" 3 "HDB 4-room" 4 "HDB 5-room" 5 "HDB Executive") title("(f) Effect of second price change by housing type", pos(6)) 
graph save "Graph" figure3f, replace

*by water demand 

cap drop m_wat
bysort premiseno: egen m_wat=mean(wat)
cap drop cn
bysort premiseno (time): gen cn=_n
replace m_wat=. if cn!=1
cap drop ptile
egen ptile=xtile(m_wat), by(cn) nq(4)
cap drop cut
bysort premiseno: egen cut=mean(ptile)

gen DD_ann=announce*treatment
gen DD=chg1*treatment
gen DD2=chg2*treatment

cap drop trend
gen trend=time
replace trend=0 if trend<=661

reghdfe ln_wat i.cut#1.DD_ann i.cut#1.DD i.cut#1.DD2 i.treatment#c.trend i.cut#c.trend, absorb(i.premiseno i.time) cluster(pcode time) compact poolsize(4)
eststo het1
estimates save figure3_1,replace

coefplot het1, keep(*#1.DD_ann) scheme(plottig)  mc(black) ciopts(lcolor(black) recast(rcap)) offset(0) legend(off) vertical ytitle("Change in monthly water consumption (log)") ///
ysize(2.6) xsize(3.575) ylabel(-0.15(0.05)0.05,format(%5.2f)) yline(0) omitted baselevels ///
xlabel(1 "Q1(0,8.65])" 2 "Q2(8.65,14.16]" 3 "Q3(14.16,21.31]" 4 "Q4(21.31,80]") title("(a) Announcement effect by water demand", pos(6))
graph save "Graph" figure3a,replace

coefplot het1, keep(*#1.DD) scheme(plottig)  mc(black) ciopts(lcolor(black) recast(rcap)) offset(0) legend(off) vertical ytitle("Change in monthly water consumption (log)") ///
ysize(2.6) xsize(3.575) ylabel(-0.15(0.05)0.05,format(%5.2f)) yline(0) omitted baselevels ///
xlabel(1 "Q1(0,8.65])" 2 "Q2(8.65,14.16]" 3 "Q3(14.16,21.31]" 4 "Q4(21.31,80]") title("(b) Effect of first price change by water demand", pos(6))
graph save "Graph" figure3b,replace

coefplot het1, keep(*#1.DD2) scheme(plottig)  mc(black) ciopts(lcolor(black) recast(rcap)) offset(0) legend(off) vertical ytitle("Change in monthly water consumption (log)") ///
ysize(2.6) xsize(3.575) ylabel(-0.15(0.05)0.05,format(%5.2f)) yline(0) omitted baselevels ///
xlabel(1 "Q1(0,8.65])" 2 "Q2(8.65,14.16]" 3 "Q3(14.16,21.31]" 4 "Q4(21.31,80]") title("(c) Effect of second price change by water demand", pos(6)) name(figure3c)
graph save figure3c, replace

foreach v in a b c d e f{
	graph use figure3`v'
}

graph combine figure3a figure3b figure3c figure3d figure3e figure3f , row(2) xsize(7) ysize(2.6) graphregion(color(white)) ycommon
graph save "Graph" Figure3.gph, replace
graph export Figure3.pdf, replace

*Figure 4
import excel "${data}\SourceData_Fig4.xlsx", clear sheet("Figure") firstrow
drop sd
drop M N O P Q R
drop if ptype==""
encode change, gen(cat)
encode ptype, gen(nptype)
cap drop id
gen id=cat if nptype==1
replace id=cat+4 if nptype==2
replace id=cat+8 if nptype==3
replace id=cat+12 if nptype==4
replace id=cat+16 if nptype==5
sort id

tw (scatter mean_pinc id if cat==1) (scatter mean_pinc id if cat==2)(rcap high_pinc low_pinc id if cat==1, lcolor(black) ) (rcap high_pinc low_pinc id if cat==2, lcolor(blue) ) , scheme(plottig) ysize(2.6) xsize(3.575) legend(pos(6) row(2)  lab(1 "After first price increase") lab(2 "After both price increase")) ytitle("Bill change as percentage of income (%)") xtitle("") xlabel(2 "1-/2-room" 6 "3-room" 10 "4-room" 14 "4-room" 18 "Executive") 
graph save figure4a, replace

tw (scatter mean id if cat==1, mlabel(mean) mlabf(%9.3f)) (scatter mean id if cat==2, mlabel(mean) mlabposition(11) mlabf(%9.3f)) (scatter mean id if cat==3, mlabel(mean) mlabposition(12)  mlabf(%9.3f)) (rcap high low id if cat==1) (rcap high low id if cat==2) , scheme(plottig) ysize(2.6) xsize(3.575) legend(pos(6) row(1) lab(1 "Bill change after first price increase") lab(2 "Bill change after both price increase") lab(3 "Rebate change")) ytitle("Monthly amount in SGD") xtitle("") xlabel(2 "1-/2-room" 6 "3-room" 10 "4-room" 14 "4-room" 18 "Executive") ylabel(0(2)12)
graph save figure4b, replace


tw (scatter mean_netpinc id if cat==1, mlabel(mean_netpinc) mlabposition(5) mlabc(black) mlabf(%9.3f)) (scatter mean_netpinc id if cat==2, mlabel(mean_netpinc) mlabposition(5) mlabc(black) mlabf(%9.3f)) (rcap high_netpinc low_netpinc id if cat==1, lcolor(black)) (rcap high_netpinc low_netpinc id if cat==2) , scheme(plottig) ysize(2.6) xsize(3.575) legend(pos(6) row(2)  lab(1 "After first price increase") lab(2 "After both price increase") lab(3 "95% confidence interval") lab(4 "") lab(5 "")) ytitle("Net cost change as percentage of income (%)") xtitle("") xlabel(2 "1-/2-room" 6 "3-room" 10 "4-room" 14 "4-room" 18 "Executive") ylabel(,format(%9.1fc)) name(figure4c, replace)
graph save figure4c, replace

foreach v in a b c {
	graph use figure4`v'
}

graph combine figure4a figure4b figure4c, row(3) xsize(4) ysize(7) graphregion(color(white))
graph save "Graph" Figure4.gph, replace
graph export Figure4.pdf, replace

*Figure 5
clear
use "${data}\data.dta", clear
keep if ext!=1 & time<=647
keep time nptype ln_wat premiseno pcode ln_psi ln_rain ln_temp year month wat
gen treatment=(nptype<6)
gen rebate=(time>630)
gen announce=(time>625)

cap drop trend
gen trend=time
*replace trend=0 if treatment==0

cap drop m_wat
bysort premiseno: egen m_wat=mean(wat)
cap drop cn
bysort premiseno (time): gen cn=_n
replace m_wat=. if cn!=1
cap drop ptile
egen ptile=xtile(m_wat), by(cn) nq(4)
cap drop cut
bysort premiseno: egen cut=mean(ptile)

gen DD_ann=announce*treatment
gen DD=rebate*treatment

bysort cut: summ m_wat

gen pre=1 if time>=621 & time<=625
replace pre=0 if pre==.
gen DD_pre=pre*treatment

reghdfe ln_wat 1.pre#ib6.nptype 1.announce#ib6.nptype 1.rebate#ib6.nptype 1.treatment#c.trend, absorb(i.premiseno i.time) cluster(pcode time) compact poolsize(4)
eststo r1_het1
estimates save r1_het1,replace

coefplot r1_het1, keep(1.announce#*) mlabel format(%9.3f) scheme(plottig) mc(black) ciopts(lcolor(black) recast(rcap)) offset(0) legend(off) vertical ytitle("Change in monthly water consumption (log)") ///
ysize(2.6) xsize(3.575) ylabel(-0.10(0.05)0.10,format(%5.2f)) yline(0) omitted ///
xlabel(1 "HDB 1/2-room" 2 "HDB 3-room" 3 "HDB 4-room" 4 "HDB 5-room" 5 "HDB Executive") title("(a) Announcement effect by HDB flat type", pos(6)) 
graph save "Graph" figure5a, replace
coefplot r1_het1, keep(1.rebate#*) mlabel format(%9.3f) scheme(plottig) mc(black) ciopts(lcolor(black) recast(rcap)) offset(0) legend(off) vertical ytitle("Change in monthly water consumption (log)") ///
ysize(2.6) xsize(3.575) ylabel(-0.10(0.05)0.10,format(%5.2f)) yline(0) omitted ///
xlabel(1 "HDB 1/2-room" 2 "HDB 3-room" 3 "HDB 4-room" 4 "HDB 5-room" 5 "HDB Executive") title("(b) Effect of rebate change by HDB flat type", pos(6)) 
graph save "Graph" figure5b, replace
cap drop trend
gen trend=time
replace trend=0 if treatment==0

reghdfe ln_wat i.cut#1.DD_ann i.cut#1.DD i.cut#c.trend if time>612, absorb(i.premiseno i.time) cluster(pcode time) compact poolsize(4)
eststo r1_het2
estimates save r1_het2,replace
coefplot r1_het2, keep(*#1.DD_ann) mlabel format(%9.3f) scheme(plottig) mc(black) ciopts(lcolor(black) recast(rcap)) offset(0) legend(off) vertical ytitle("Change in monthly water consumption (log)") ///
ysize(2.6) xsize(3.575) ylabel(-0.15(0.05)0.05,format(%5.2f)) yline(0) omitted baselevels xlabel(1 "Q1(0,9.45])" 2 "Q2(9.45,15.20]" 3 "Q3(15.20,22.58]" 4 "Q4(21.58,88.65]") ///
title("(c) Announcement effect by water demand", pos(6))
graph save "Graph" figure5c.gph, replace

coefplot r1_het2, keep(*#1.DD) scheme(plottig) mlabel format(%9.3f) mc(black) ciopts(lcolor(black) recast(rcap)) offset(0) legend(off) vertical ytitle("Change in monthly water consumption (log)") ///
ysize(2.6) xsize(3.575) ylabel(-0.15(0.05)0.05,format(%5.2f)) yline(0) omitted baselevels xlabel(1 "Q1(0,9.45])" 2 "Q2(9.45,15.20]" 3 "Q3(15.20,22.58]" 4 "Q4(21.58,88.65]") ///
title("(d) Effect of rebate change by water demand", pos(6))
graph save "Graph" figure5d.gph, replace

foreach v in a b c d {
	graph use figure5`v'
}

graph combine figure5a figure5b figure5c figure5d, row(2) xsize(7) ysize(4) graphregion(color(white)) ycommon
graph save "Graph" Figure5.gph, replace
graph export Figure5.pdf, replace



*Table 1
**column (1)-(2)
use "${data}\data.dta", clear
keep if ext!=1
keep if time>=660 & time<708
gen pre=1 if time<=685 & time>673
replace pre=0 if pre==.
cap drop announce
gen announce=1 if time>685 
replace announce=0 if announce==.
cap drop chg1
gen chg1=1 if time>690
replace chg1=0 if chg1==.
cap drop chg2 
gen chg2=(time>702)
gen treatment=(nptype<6)
gen post=(time>685)

reghdfe ln_wat 1.pre#1.treatment  1.post#1.treatment trend, absorb(i.premiseno i.time) cluster(pcode time) 
reghdfe ln_wat 1.pre#1.treatment  1.announce#1.treatment 1.chg1#1.treatment 1.chg2#1.treatment trend, absorb(i.premiseno i.time) cluster(pcode time)

**column (3)-(4)
use "${data}\data.dta", clear
gen treatment=(nptype<6)
keep if ext!=1 & time<=647
gen rebate=(time>630)
gen announce=(time>625)
gen pre=1 if time>=621 & time<=625
replace pre=0 if pre==.
gen post=ann

reghdfe ln_wat 1.pre#1.treatment 1.post#1.treatment trend if time<=647, absorb(i.premiseno i.time) cluster(pcode time) 
reghdfe ln_wat 1.pre#1.treatment 1.announce#1.treatment 1.rebate#1.treatment trend if time<=647, absorb(i.premiseno i.time) cluster(pcode time) 
