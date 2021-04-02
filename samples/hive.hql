set hive.execution.engine=tez;


-- これはサンプルクエリです！
create external table t_tomoabe.test {
    abe string,
    bbe int,
    cbe double
}
row format delimited
fields terminated by ','
lines terminated by '\n'
stored as orc
location '/user/t_tomoabe/warehouse/test'
;

with tmp as (
    select
        abe
        ,bbe
        ,cbe
    from
        t_tomoabe.before
    where 1=1
        and a > 20
        and b between '20210301' and '20200331'
    limit
        10
)
insert table t_tomoabe.test
select
    abe
    ,SUM(cast(bbe as int)) as bbe_str
    ,ROW_NUMBER() OVER (ORDER BY cbe)
from
    tmp
group by
    abe
;



