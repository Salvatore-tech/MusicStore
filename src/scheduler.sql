BEGIN
    DBMS_SCHEDULER.create_program(
        program_name => 'P_ADDETTO_DEL_MESE',
        program_action => 'NOMINA_ADDETTO_DEL_MESE',
        program_type => 'STORED_PROCEDURE',
        number_of_arguments => 0,
        comments => 'Choosing best seller of the month using a stored procedure',
        enabled => TRUE);
END;

BEGIN
    DBMS_SCHEDULER.CREATE_SCHEDULE (
        repeat_interval  => 'FREQ=MONTHLY;BYDAY=1MON',
        start_date => TO_TIMESTAMP_TZ('2020-10-01 12:00:00.000000000 EUROPE/BERLIN','YYYY-MM-DD HH24:MI:SS.FF TZR'),
        comments => 'Runs every 1st monday',
        schedule_name  => 'EVERY_MONTH');
END;

BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
            job_name => 'JOB_ADDETTO_DEL_MESE',
            program_name => 'P_ADDETTO_DEL_MESE',
            schedule_name => 'EVERY_MONTH',
            enabled => TRUE,
            auto_drop => FALSE,
            comments => 'Job based on p_addetto_del_mese that runs every_month');
END;

-- Running job manually (for testing porpouse)
BEGIN
  DBMS_SCHEDULER.run_job (job_name => 'job_addetto_del_mese', use_current_session => TRUE);
END;
