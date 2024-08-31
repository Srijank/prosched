DROP TABLE IF EXISTS "public"."users";
-- This script only contains the table creation statements and does not fully represent the table in the database. Do not use it as a backup.

-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS users_id_seq;

-- Table Definition
CREATE TABLE "public"."users" (
    "id" int4 NOT NULL DEFAULT nextval('users_id_seq'::regclass),
    "name" varchar(50) NOT NULL,
    "email" varchar(250) NOT NULL,
    "password" varchar(10000) NOT NULL,
    "usertype" varchar(20) DEFAULT 'normal'::character varying,
    "role" varchar(100),
    PRIMARY KEY ("id")
);



DROP TABLE IF EXISTS "public"."tasks";
-- This script only contains the table creation statements and does not fully represent the table in the database. Do not use it as a backup.

-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS tasks_task_id_seq;

-- Table Definition
CREATE TABLE "public"."tasks" (
    "task_id" int4 NOT NULL DEFAULT nextval('tasks_task_id_seq'::regclass),
    "user_id" int4,
    "task_name" varchar(250),
    "task_description" varchar(250),
    "priority" varchar(2),
    "status" varchar(20),
    "deleted" int4 DEFAULT 0,
    "updatedon" timestamptz,
    "createdon" timestamptz,
    "parenttask" int4,
    "deadline" date,
    "impact" varchar NOT NULL,
    "reward" varchar,
    CONSTRAINT "fk_user" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id"),
    PRIMARY KEY ("task_id")
);


CREATE OR REPLACE FUNCTION public.gettask(userid integer, useremail character varying, taskid integer, taskname character varying, taskdescription character varying, priorities character varying, parent_task integer, startingdate date, deadlinedate date, statustask character varying, deletedtask integer, impactoftask character varying, rewardoftask character varying)
 RETURNS TABLE(t_user_id integer, t_user_email character varying, t_task_id integer, t_task_name character varying, t_task_description character varying, t_priority character varying, t_deadline date, t_parent_task integer, t_status character varying, t_deleted integer, t_updatedon timestamp with time zone, t_createdon timestamp with time zone, t_impactoftask character varying, t_rewardoftask character varying)
 LANGUAGE plpgsql
AS $function$
    BEGIN
		IF userid IS NULL THEN  
		  RAISE EXCEPTION  'User_id cannot be null';
        END IF ;
		RETURN QUERY 
			SELECT user_id,u.email,task_id,task_name,task_description,priority,deadline ,parenttask,status,deleted,updatedon,createdon,impact,reward from tasks t,
			users u 
			WHERE deleted = deletedtask
			AND user_id IN (userid)
			and t.user_id = u.id
			AND u.email = useremail
			AND (taskid = 0 OR task_id IN (taskid))
			AND (taskname IS NULL OR task_name IN (taskname))
			AND (taskdescription IS NULL OR task_description IN (taskdescription))
			AND (priorities IS NULL OR priority IN (priorities))
			AND (parent_task IS NULL OR parenttask = (parent_task))
			AND ( deadlinedate is NULL or (deadline  between startingdate  and deadlinedate))
			AND ((status!='Done'  and statustask IS NULL )OR  status IN (statustask))
			ORDER BY createdon asc;
        

    END;
$function$
;



CREATE OR REPLACE PROCEDURE public.upserttask(IN userid integer, IN taskid integer, IN taskname character varying, IN taskdescription character varying, IN priorities character varying, IN parent_task integer, IN deadlinedate date, IN statustask character varying, IN deletedtask integer, IN impactoftask character varying, IN rewardoftask character varying, INOUT upsertstatus integer)
 LANGUAGE plpgsql
AS $procedure$
	DECLARE 
	  t_user_id integer :=userid;
      t_task_id integer := taskid;
      t_task_name VARCHAR(250) := taskname;
      t_task_description VARCHAR(250) := taskdescription;
      t_priority VARCHAR(250) := priorities;
      t_deadline date:= deadlinedate;
      t_parent_task INTeger :=parent_task;
      t_status VARCHAR(250) := statusTask ;
      t_deleted INTeger:= deletedTask ;
      t_impactoftask VARCHAR(250) := impactoftask;
      t_rewardoftask VARCHAR(250) := rewardoftask;
    BEGIN
		IF userid IS NULL THEN  
		  RAISE EXCEPTION  'User_id cannot be null';
        END IF ;
        IF taskname IS NULL THEN  
		  RAISE EXCEPTION  'Task name cannot be null';
        END IF ;
        IF taskname IS NULL THEN  
		  RAISE EXCEPTION  'Task name cannot be null';
        END IF ;
        IF priorities IS NULL THEN  
		  RAISE EXCEPTION  'Priority cannot be null';
        END IF ;
		upsertStatus := 0;
     IF t_task_id in (SELECT task_id from tasks where user_id= t_user_id) THEN 
		UPDATE  tasks SET task_name = t_task_name ,
		                       task_description= t_task_description,
		                       priority = t_priority,
		                       deadline = t_deadline,
		                       parenttask = t_parent_task,
		                       status = t_status ,
		                       deleted = t_deleted,
		                       impact = t_impactoftask,
		                       reward = t_rewardoftask,
		                       updatedon = now()
		WHERE task_id = t_task_id;
        upsertStatus := 1;
    ELSE 
		INSERT INTO tasks (user_id,task_name,task_description,priority,deadline,parenttask,status,deleted,createdon,updatedon,impact,reward)
		VALUES(t_user_id,t_task_name,t_task_description,t_priority,t_deadline,t_parent_task,t_status,t_deleted,now(),now(),t_impactoftask,t_rewardoftask);
        upsertStatus := 1;
    END IF;

    END;
    
$procedure$
;


INSERT INTO "public"."users" ("id", "name", "email", "password", "usertype", "role") VALUES
(9, 'Srijan K', 'srijanhosamane@gmail.com', '$2b$10$cHeHPUT1t/bez14ur5cTUe3Sb9czem..kdaMiqY.YXBgysyHljCQK', 'normal', 'Developer');
INSERT INTO "public"."users" ("id", "name", "email", "password", "usertype", "role") VALUES
(10, 'Sahana', 'sanachann1810@gmail.com', '$2b$10$yJ3qS55JCTzBn0v3w3ZsMOA69vBcsgKY21osjhONhvln0WmLWWkzy', 'normal', 'Designer');

INSERT INTO "public"."tasks" ("task_id", "user_id", "task_name", "task_description", "priority", "status", "deleted", "updatedon", "createdon", "parenttask", "deadline", "impact", "reward") VALUES
(141, 9, 'Creating this site', 'No', 'P1', 'To do', 1, '2024-06-30 13:33:10.209792+05:30', '2024-06-30 13:33:10.209792+05:30', 0, '2024-07-06', '6 months can be covered', 'Momos');
INSERT INTO "public"."tasks" ("task_id", "user_id", "task_name", "task_description", "priority", "status", "deleted", "updatedon", "createdon", "parenttask", "deadline", "impact", "reward") VALUES
(146, 9, 'Creating this site', 'No', 'P1', 'To do', 1, '2024-06-30 21:03:42.503985+05:30', '2024-06-30 21:03:42.503985+05:30', 0, '2024-07-06', '6 months can be covered', 'Momos');
INSERT INTO "public"."tasks" ("task_id", "user_id", "task_name", "task_description", "priority", "status", "deleted", "updatedon", "createdon", "parenttask", "deadline", "impact", "reward") VALUES
(142, 9, 'Creating this site', 'No', 'P2', 'In review', 1, '2024-06-30 20:52:23.068201+05:30', '2024-06-30 20:52:23.068201+05:30', 0, '2024-06-30', '6 months can be covered', 'Momos');
INSERT INTO "public"."tasks" ("task_id", "user_id", "task_name", "task_description", "priority", "status", "deleted", "updatedon", "createdon", "parenttask", "deadline", "impact", "reward") VALUES
(143, 9, 'Hellow', 'No', 'P1', 'To do', 1, '2024-06-30 21:03:12.529544+05:30', '2024-06-30 21:03:12.529544+05:30', 0, '2024-07-06', '6 months can be covered', 'Momos'),
(144, 9, 'Hellow', 'dsad', 'P1', 'To do', 1, '2024-06-30 21:03:22.86026+05:30', '2024-06-30 21:03:22.86026+05:30', 0, '2024-07-06', '6 months can be covered', 'Momos'),
(145, 9, 'Creating this site', 'No', 'P1', 'To do', 1, '2024-06-30 21:03:33.985911+05:30', '2024-06-30 21:03:33.985911+05:30', 0, '2024-07-06', '6 months can be covered', 'Momos'),
(147, 9, 'Finishing PM Course 5 (Module 2)', '2 hours needed', 'P2', 'Done', 0, '2024-07-21 02:21:31.560301+05:30', '2024-06-30 21:55:47.955635+05:30', 0, '2024-07-22', 'Understand Agile and learn its methodology', 'Course completion certificate'),
(148, 9, 'React Episode 1', 'Learn 1 hour', 'P1', 'Done', 0, '2024-07-21 02:21:38.972799+05:30', '2024-06-30 21:59:50.108904+05:30', 0, '2024-07-27', 'To build a user friendly application', '10 pushups'),
(149, 9, 'Learn Github and Git', 'Must to be learnt', 'P3', 'Done', 0, '2024-07-21 02:21:49.895499+05:30', '2024-06-30 22:01:39.480414+05:30', 0, '2024-07-27', 'Useful in every perspective', '5 Bicycle crunches'),
(150, 9, 'Going Gym', 'Workout', 'P1', 'Done', 0, '2024-07-21 02:21:58.385795+05:30', '2024-06-30 22:02:55.746834+05:30', 0, '2024-07-23', 'Better body, better Mind', 'Health'),
(151, 9, 'Adding Week /Day tasks', 'Toggle buttons to add', 'P2', 'Done', 0, '2024-07-21 02:22:06.555356+05:30', '2024-06-30 22:08:04.487858+05:30', 0, '2024-07-27', 'Differentiate between Week and daily schedule', 'Night walk'),
(152, 9, 'Creating this site', 'No', 'P1', 'To do', 1, '2024-07-21 12:54:01.823093+05:30', '2024-07-21 12:54:01.823093+05:30', 0, '2024-07-25', '6 months can be covered', 'Momos'),
(153, 9, 'Learning React ', '', 'P1', 'To do', 0, '2024-07-24 00:54:04.143476+05:30', '2024-07-24 00:54:04.143476+05:30', 0, '2024-07-28', 'React developer', 'Night walk '),
(154, 9, 'Creating this site', 'No', 'P1', 'To do', 0, '2024-08-22 12:37:14.767213+05:30', '2024-08-22 12:37:14.767213+05:30', 0, '2024-08-24', '6 months can be covered', '5 Bicycle crunches'),
(155, 9, 'Creating this site', 'No', 'P2', 'In progress', 1, '2024-08-22 13:22:05.596203+05:30', '2024-08-22 13:22:00.04671+05:30', 0, '2024-08-24', '6 months can be covered', 'Night walk');




