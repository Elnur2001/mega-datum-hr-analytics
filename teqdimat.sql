



CREATE TABLE EMPLOYEE_DATA (
    EmployeeID VARCHAR2(20),
    FirstName VARCHAR2(50),
    LastName VARCHAR2(50),
    Gender VARCHAR2(20),
    Age NUMBER,
    BusinessTravel VARCHAR2(50),
    Department VARCHAR2(50),
    DistanceFromHome_KM NUMBER,
    State VARCHAR2(10),
    Ethnicity VARCHAR2(100),
    Education NUMBER,
    EducationField VARCHAR2(100),
    JobRole VARCHAR2(100),
    MaritalStatus VARCHAR2(20),
    Salary NUMBER,
    StockOptionLevel NUMBER,
    OverTime VARCHAR2(10),
    HireDate DATE,
    Attrition VARCHAR2(10),
    YearsAtCompany NUMBER,
    YearsInMostRecentRole NUMBER,
    YearsSinceLastPromotion NUMBER,
    YearsWithCurrManager NUMBER
);

create table education_data(EducationLevelID number,
                            EducationLevel varchar2(50)
                            )
                            
                            
select * from education_data for update

alter table education_data 
add constraint pk_education_level primary key (educationlevelid)


alter table employee_data 
add constraint pk_employee_id primary key (employeeid)

alter table employee_data 
add constraint fk_emp_education foreign key (education) 
references education_data(educationlevelid)

select * from employee_data

-- 1.Job Role-larda işçilərə görə ən çox 3 Job Role növünü təyin etmək. Job Role və Employee Count çıxmalı
select * from employee_data

select e.jobrole,
       count(e.employeeid) as employeecount
from employee_data e
group by e.jobrole
order by employeecount desc fetch first 3 rows only

--2.Şirkətdə ən uzun müddətli çalışan top 10 işçinin ad soyadı və
-- bu gündən etibarən neçə ildir burada çalışdığını tapmaq
select e.firstname,
       e.lastname,
       e.hiredate,
       floor(months_between(sysdate,e.hiredate)/12)
from employee_data e
order by e.hiredate asc fetch first 10 rows only


--3.Bütün işçilərin adının sonuna soyadındakı simvolların sayı qədər
--“*”- simvolunu əlavə etmək və DistanceFromHome sütunundakı məlumatın sonuna KM əlavə edərək ekrana çıxartmaq

select * from employee_data

select e.firstname || rpad('*',length(e.lastname),'*') as firstname,
       e.lastname,
       e.distancefromhome_km || ' km' as distance
from employee_data e

--4.Ən yüksək və ən az maaş alan işçilərin təhsil səviyələrini çıxaran sorğu yazın.

select e.firstname,
       e.lastname,
       ed.educationlevel,
       e.salary
from employee_data e
left join education_data ed 
on e.education = ed.educationlevelid
where e.salary = (select max(salary) from employee_data)
or e.salary = (select min(salary) from employee_data)

--5.Təhsil səviyəsi artan sıra ilə olmaqla hər işçinin bir əvvəlki işçi ilə maaş fərqini tapın.

select e.firstname,
       e.lastname,
       e.salary,
       lag(e.salary,1) over (order by e.education) as evvelkimaas,
       e.salary - lag(e.salary,1) over (order by e.education) as maasferqi
from employee_data e

--6. Əməkdaşların evdən iş yerinə ən uzaq məsafəni qət 
--edənlərini tapın və onlarla bağlı məlumatları göstərin.

select *
from employee_data e 
where e.distancefromhome_km = (select max(e.distancefromhome_km) from employee_data e)


--7. Orta yaş və orta maaşdan yuxarı olan əməkdaşları tapın.
select e.firstname,
       e.lastname,
       e.age,
       e.salary
from employee_data e 
where e.salary > (select avg(e.salary) from employee_data e)
and 
e.age > (select avg(e.age) from employee_data e)

--8. Təhsil Səviyyəsinə və Təhsil Sahəsinə Görə Cinsiyyətin Paylanması

select ed.educationlevel,
       e.educationfield,
       e.gender,
       count(e.gender),
       round(count(e.gender)/(select count(gender) from employee_data)*100,2) || '%' as faiz
from employee_data e
left join education_data ed
on e.education = ed.educationlevelid
group by ed.educationlevelid,ed.educationlevel,e.educationfield,e.gender
order by ed.educationlevelid,e.educationfield,e.gender



--9. Hər təhsil səviyyəsi üçün əməkdaşların illik maaş artımını və şirkətdəki ortalama iş müddətini tapın.
select 
     sub.jobrole,
     sub.hire_year,
     sub.salary,
     round(lag(avg(salary)) over(partition by sub.jobrole order by sub.hire_year),2) as evvelki_il,
     round(sub.salary-lag(avg(salary)) over(partition by sub.jobrole order by sub.hire_year),2) as ferq
from
(select e.jobrole,
       extract(year from e.hiredate) as hire_year,
       avg(e.salary) as salary
from employee_data e
group by e.jobrole,extract(year from e.hiredate)
) sub
group by sub.jobrole,sub.hire_year,sub.salary









--10. Hər bir departamentdə əməkdaşların şirkətdən çıxma nisbətini tapın (ATTRITION "Yes" olan əməkdaşlar).

select e.department,
       e.yes_say,
       a.umumi_say,
       round(e.yes_say/a.umumi_say*100,2)||'%'
from (select department,
             count(e.attrition)as yes_say
      from employee_data e
     where attrition = 'Yes'
     group by department ) e
     join
     (select department,
             count(e.attrition)as umumi_say
      from employee_data e
     group by department) a
     on e.department = a.department
     
     
select e.department,
       round(sum(case
       when e.attrition = 'Yes' then 1
         else 0
           end)/count(e.attrition)*100,2)||'%' as dep_bolumme
from employee_data e 
group by e.department



--11. Hər təhsil səviyyəsi üçün orta maaşı ötən əməkdaşların siyahısını əldə edin.

select e.educationlevel,
      e.firstname,
      e.lastname,
      e.salary,
      a.orta_maas
       
from 
(select educationlevel,
        firstname,
        lastname,
        salary
from employee_data 
join education_data  on education=educationlevelid) e

join

(select educationlevel,
       avg(salary) as orta_maas
from employee_data e
join education_data ed on education=educationlevelid
group by educationlevel) a
on e.educationlevel = a.educationlevel

where e.salary > a.orta_maas


--12. 3 ildən az təcrübəsi olan, amma şirkətdə orta maaşdan çox qazanan əməkdaşları göstərin.

select e.firstname,
       e.salary
from employee_data e
where e.salary > (select avg(e.salary) from employee_data e)
and e.yearsatcompany <3

--13. Hər bir təhsil səviyyəsi və iş roluna görə əməkhaqqına görə ən yüksək 5 əməkdaşı seçin.


select department,
       firstname,
       salary,
       row_number() over(
           partition by department
           order by salary desc
       ) as rn
from employee_data;





select 
a.firstname,
a.lastname,
a.educationlevel,
a.jobrole,
a.salary

from 

(select e.firstname,
        e.lastname,
       ed.educationlevel,
       e.jobrole,
       e.salary,
       row_number() over(partition by ed.educationlevel,e.jobrole order by e.salary desc) as rn
from employee_data e
join education_data ed
on e.education=ed.educationlevelid) a
where rn<=5
