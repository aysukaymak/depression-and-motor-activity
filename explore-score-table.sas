
/**********************/
/**EXPLORE SCORE FILE**/
/**********************/
proc print data=casuser.scores;
run;

*adding difference of scores ("after activity recording", "before activity recording");
data casuser.scores;
	set casuser.scores;
	deltaMadrs=madrs2-madrs1;
run;

*scores table includes condition and control group data. Control group have empty columns except for number (id), days, gender and age;
*therefore score table is splited between condition and control observations;
data casuser.sc_condition casuser.sc_control;
	set casuser.scores;
	if prxmatch('/condition/', number) then output casuser.sc_condition;
	else output casuser.sc_control;
run;

/****************************************/
/**CLEAN AND EXPLORE SC_CONDITION TABLE**/
/****************************************/

*defining a standard text for the missing values;
data casuser.sc_condition;
	set casuser.sc_condition;
	if edu=' ' then edu='.';
	if melanch='NA' then melanch='.';
run;
%load_tables(table=sc_condition ,lib=CASUSER, sess=impsess)

proc print data=casuser.sc_condition;
run;

proc freq data=casuser.sc_condition;
run;

*dropping null columns from the control file;
data casuser.sc_control;
	set casuser.sc_control;
	keep number days gender age;
run;
%load_tables(table=sc_control,lib=CASUSER, sess=impsess)

proc print data=casuser.sc_control;
run;

proc freq data=casuser.sc_control;
run;