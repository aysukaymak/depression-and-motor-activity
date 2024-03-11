options compress=yes;
options casdatalimit=all;

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
%macro transform_data(lib_from=, lib_to=, table=);
	ods noproctitle;
	title "TRANSFORM ACTIVITY VALUE FOR &table. TABLE";

	data &lib_to..&table.;
		set &lib_from..&table.;
		log_activity=log(activity + 1);
		sqrt_activity=sqrt(activity);
	run;

	proc means data=&lib_to..&table. n nmiss mean std min q1 median q3 max skew;
		var activity log_activity sqrt_activity;
	run;

	title;

	proc univariate data=&lib_to..&table. noprint;
		histogram log_activity sqrt_activity;
	run;
%mend transform_data();

%transform_data(lib_from=CASUSER, lib_to=WORK, table=condition_1)
%transform_data(lib_from=CASUSER, lib_to=WORK, table=control_1)

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

	data &lib..&name.;
   		set &table_names. indsname=source;
		dsname = scan(source,2,'.');
	run;
%mend combine_tables;
%combine_tables(lib=CASUSER, table_cat=CONDITION, name=CONDITIONS)
%combine_tables(lib=CASUSER, table_cat=CONTROL, name=CONTROLS)

%transform_data(lib_from=CASUSER, lib_to=CASUSER, table=conditions)
%transform_data(lib_from=CASUSER, lib_to=CASUSER, table=controls)

/*******************************************************/
/**GROUPING CONDITION and CONTROL ACTIVITIES BY HOURLY**/  
/*******************************************************/
%macro grouping_by_hour(lib=, table=);
	proc sql noprint;
		create table mean_act_by_hour_&table. as 
			select dsname, date, hour(timestamp) as hour, mean(log_activity) as mean_activity,
				   std(log_activity) as std_activity,
				   n(log_activity) as n_activity,
				   sum(log_activity=0) as zero_activity_proportion
			from &lib..&table. group by date, hour, dsname;
	quit;

	data &lib..mean_act_by_hour_&table.;
		set mean_act_by_hour_&table.;
	run;
%mend grouping_by_hour();

%grouping_by_hour(lib=CASUSER, table=CONDITIONS)
%grouping_by_hour(lib=CASUSER, table=CONTROLS)

/****************************************/
/**TIME SERIES ANALYSIS WITH LINE PLOTS**/  
/****************************************/
%macro line_plots(lib=, table=, color=);
	proc sort data=&lib..&table.;
    	by dsname;
	run;

	/* Initialize the SGPLOT */
	ods graphics on / width=20in;
 	ods graphics on / height=4in;
	ods listing;

	proc sgplot data=&lib..&table.;
    	by dsname;
    	series x=date y=mean_activity / group=dsname lineattrs=(color=&color.);
    	yaxis label='Mean activity' grid;
    	xaxis label='Date' fitpolicy=rotate;
    	title 'Mean activity for each condition group';
	run;

	ods graphics off;
%mend line_plots();

%line_plots(lib=CASUSER, table=mean_act_by_hour_CONDITIONS, color=red)
%line_plots(lib=CASUSER, table=mean_act_by_hour_CONTROLS, color=green)
