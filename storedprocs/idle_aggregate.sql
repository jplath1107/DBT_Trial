CREATE OR REPLACE PROCEDURE PROD_DIG.DBT_JPLATH1107.IDLE_AGGREGATE()
RETURNS VARCHAR(16777216)
LANGUAGE SQL
EXECUTE AS CALLER
AS 'begin
CALL PROD_DIG.DBT_JPLATH1107.IDLE_AGGREGATE();

DELETE FROM PROD_DIG.DBT_JPLATH1107.IDLE_AGGREGATE
WHERE Date >= current_date -10;

INSERT INTO PROD_DIG.DBT_JPLATH1107.IDLE_AGGREGATE


with Raw0 as (
SELECT
cid
,LTRIM(RTRIM(login)) as Login
,LTRIM(RTRIM(drivername)) as drivername
,vehicle_number
,A.strt_datime
,A.end_datime
,a.eng_time
,A.mov_time
,A.short_idle_time
,A.long_idle_time
,A.traveled_miles
,iff((A.long_idle_fuel/1000.0)/(DATEDIFF(SECOND,A.strt_datime,A.end_datime)+1/3600.00) between 0 and 20,a.long_idle_fuel/1000.0,0) as Long_Idle_Fuel
,iff((A.short_idle_fuel/1000.0)/(DATEDIFF(SECOND,A.strt_datime,A.end_datime)+1/3600.00) between 0 and 20,a.short_idle_fuel/1000.0,0) as Short_Idle_Fuel
,iff((A.gal_fuel/1000.0)/(DATEDIFF(SECOND,A.strt_datime,A.end_datime)+1/3600.00) between 0 and 20,A.gal_fuel/1000.0,0) as Gal_Fuel
,DATEDIFF(SECOND,A.strt_datime,A.end_datime)/3600.00 as Time

FROM peoplenet.performxbydriverdata as A --index(IX_strt_end_datime)

WHERE
A.strt_datime <= A.end_datime
and cast(A.strt_datime as date) >= cast(A.end_datime as date)-180
and cast(end_datime as date) >= current_date -10
and cast(strt_datime as date) > ''1900-01-01''
and DATEDIFF(SECOND,A.strt_datime,A.end_datime)/3600.00 < 200
)
,
Raw1 as (
SELECT
A.cid
,A.Login
,A.drivername
,A.vehicle_number
,D.UNMAKE
,D.UNYEAR
,A.strt_datime
,A.end_datime
,a.eng_time
,A.mov_time
,A.short_idle_time
,A.long_idle_time
,A.traveled_miles
,A.Long_Idle_Fuel
,A.Short_Idle_Fuel
,A.Gal_Fuel
,A.Time
,iff(trim(A.cid) = 2626,TRIM(B.SRVDR1),TRIM(C.SRVDR1)) as SRVDR1
,iff(trim(A.cid) = 2626,TRIM(B.SRVDR2),TRIM(C.SRVDR2)) as SRVDR2
,iff(trim(A.cid) = 2626,B.srvdiv,c.srvdiv) as SRVDIV
,iff(trim(A.cid) = 2626,TRIM(B.srvmgr),TRIM(c.srvmgr)) as SRVMGR


FROM Raw0 A 
LEFT JOIN (
    select b.date, a.*
    from cccfilec.UNITSRV a
    left join dbo.dim_date b on a.srvdat = b.juldate
) B on TRIM(A.Vehicle_Number) = trim(B.SRVUNT) and CAST(A.end_datime as date) = CAST(DATEADD(D,-1,B.date) as date)
LEFT JOIN (
    select b.date, a.*
    from cccfilet.UNITSRV a
    left join dbo.dim_date b on a.srvdat = b.juldate
) as C on TRIM(A.Vehicle_Number) = trim(C.SRVUNT) and CAST(A.end_datime as date) = CAST(DATEADD(D,-1,C.date) as date)
LEFT JOIN iesfilec.UNITS as D on TRIM(A.Vehicle_Number) = TRIM(D.UNUNIT)
)

SELECT
A.cid
,A.login
,A.drivername
,A.vehicle_number
,A.UNMAKE as vehicle_make
,A.UNYEAR as vehicle_model
,CAST(A.end_datime as date) as Date
,SUM(A.eng_time)/3600.00 as EngineHr
,SUM(A.mov_time)/3600.00 as MoveHr
,SUM(A.short_idle_time + A.long_idle_time)/3600.00 as IdleHr
,SUM(A.Time) as SegmentHr
,sum(A.Traveled_Miles) as TraveledMiles
,sum(A.long_idle_fuel + A.short_idle_fuel) as IdleFuel
,sum(A.gal_fuel) as GalFuel
,A.SRVDR1 as Driver1
,A.SRVDR2 as Driver2
,A.SRVDIV as Division
,A.SRVMGR as Fleet

FROM Raw1 as A

GROUP BY CAST(a.end_datime as date), A.cid, A.login, A.drivername, A.vehicle_number, A.UNMAKE, A.UNYEAR, A.SRVDR1, A.SRVDR2, A.SRVDIV, A.srvmgr

order by CAST(A.end_datime as date) asc;


     return ''done'';

end';