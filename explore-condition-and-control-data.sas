options compress=yes;

/*******************************************/
/**EXPLORE CONDITION_1 and CONTROL_1 TABLE**/
/*******************************************/
%macro explore_data(lib=, table=, value=);
	ods noproctitle;
	title "EXPLORE &table. TABLE";

	proc print data=&lib..&table. (obs=10);
	run;

	/*** Analyze categorical variables ***/
	title "Frequencies for Date Variable";

	proc freq data=&lib..&table.;
		tables date / plots=(freqplot);
	run;

	/*** Analyze numeric variables ***/
	title "Descriptive Statistics for Activity Variable";

	proc means data=&lib..&table. n nmiss mean std min q1 median q3 max skew;
		var &value.;
	run;

	title;

	proc univariate data=&lib..&table. noprint;
		histogram &value.;
	run;
%mend explore_data;

%explore_data(lib=CASUSER, table=condition_1, value=activity)
%explore_data(lib=CASUSER, table=control_1, value=activity)

/*********************************************/
/**TRANSFORM CONDITION_1 and CONTROL_1 TABLE**/
/*********************************************/
*It can be seen that there is a high level of skewness, so we can take the log or square root of activity;
%macro transform_data(lib=, table=);
	ods noproctitle;
	title "TRANSFORM ACTIVITY VALUE FOR &table. TABLE";

	data work.&table.;
		set &lib..&table.;
		log_activity=log(activity + 1);
		sqrt_activity=sqrt(activity);
	run;

	proc means data=work.&table. n nmiss mean std min q1 median q3 max skew;
		var activity log_activity sqrt_activity;
	run;

	title;

	proc univariate data=work.&table. noprint;
		histogram log_activity sqrt_activity;
	run;
%mend transform_data();

%transform_data(lib=CASUSER, table=condition_1)
%transform_data(lib=CASUSER, table=control_1)

/****************************************************/
/**GROUPING CONDITION_1 and CONTROL_1 TABLE BY DATE**/
/****************************************************/
%macro grouping_by_date(table=);
	proc sql noprint;
		create table work.mean_act_by_date_&table. as 
			select date, mean(log_activity) as log_activity 'log_activity'
			from work.&table. group by date;
	quit;
%mend grouping_by_date();

%grouping_by_date(table=condition_1)
%grouping_by_date(table=control_1)
%explore_data(lib=WORK, table=mean_act_by_date_condition_1, value=log_activity)
%explore_data(lib=WORK, table=mean_act_by_date_control_1, value=log_activity)

/********************************************/
/**LISTING TABLE NAMES FROM CASUSER LIBRARY**/
/********************************************/
%macro list_lib_tables(lib=work, table_cat=);
	%global table_names;
	%let table_names=;
	proc sql;
		select catx('.', 'CASUSER', memname) into :table_names separated by ' '
		from dictionary.tables
		where libname eq "&lib." and memname like "&table_cat.%";
	quit;
	%put &=table_names;
%mend list_lib_tables;

/***********************************************/
/**COMBINE ALL OF CONTROL AND CONDITION TABLES**/
/***********************************************/
%macro combine_tables(lib=, table_cat=, name=);
	%list_lib_tables(lib=&lib., table_cat=&table_cat.);

	data &name.;
   		set &table_names. indsname=source;
		dsname = scan(source,2,'.');
	run;
%mend combine_tables;
%combine_tables(lib=CASUSER, table_cat=CONDITION, name=CONDITIONS)
%combine_tables(lib=CASUSER, table_cat=CONTROL, name=CONTROLS)
