-- ============================================================
--  EduMetrics — Client Database (Week 0)  v2
--
--  4 classes: BTech CSE Year 1–4 (all running concurrently)
--  Each class covers 2 semesters per academic year:
--    Year 1  →  Sem 1 (odd) + Sem 2 (even)
--    Year 2  →  Sem 3 (odd) + Sem 4 (even)
--    Year 3  →  Sem 5 (odd) + Sem 6 (even)
--    Year 4  →  Sem 7 (odd) + Sem 8 (even)
--  40 students per class  (160 students total)
--  36 global weeks per academic year  (18 odd + 18 even)
--  Exam weeks: sem-week 8 (midterm) and sem-week 18 (endterm)
--              → global weeks 8, 18, 26, 36
--
--  Run against MySQL on the edumetrics_client schema.
-- ============================================================

CREATE DATABASE IF NOT EXISTS edumetrics_client
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE edumetrics_client;


-- ══════════════════════════════════════════════════════════════
--  1. CLASSES
--  Each row = one physical class section running the full year.
--  odd_sem / even_sem are the semester numbers for that class.
-- ══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS classes (
  class_id        VARCHAR(20)  PRIMARY KEY,
  name            VARCHAR(80)  NOT NULL,
  year_of_study   INT          NOT NULL,   -- 1–4
  odd_sem         INT          NOT NULL,   -- 1, 3, 5, or 7
  even_sem        INT          NOT NULL,   -- 2, 4, 6, or 8
  section         VARCHAR(5)   DEFAULT 'A',
  branch          VARCHAR(20)  DEFAULT 'CSE',
  batch_start_year INT,
  total_students  INT          DEFAULT 40
);

INSERT INTO classes VALUES
  ('CSE_Y1_A', 'BTech CSE Year 1 Section A', 1, 1, 2, 'A', 'CSE', 2024, 40),
  ('CSE_Y2_A', 'BTech CSE Year 2 Section A', 2, 3, 4, 'A', 'CSE', 2023, 40),
  ('CSE_Y3_A', 'BTech CSE Year 3 Section A', 3, 5, 6, 'A', 'CSE', 2022, 40),
  ('CSE_Y4_A', 'BTech CSE Year 4 Section A', 4, 7, 8, 'A', 'CSE', 2021, 40);


-- ══════════════════════════════════════════════════════════════
--  2. ADVISORS
-- ══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS advisors (
  advisor_id      VARCHAR(10)  PRIMARY KEY,
  name            VARCHAR(80)  NOT NULL,
  email           VARCHAR(100) UNIQUE NOT NULL,
  class_id        VARCHAR(20),
  FOREIGN KEY (class_id) REFERENCES classes(class_id)
);

INSERT INTO advisors VALUES
  ('ADV001', 'Dr. Priya Mehta',    'priya.mehta@college.edu',    'CSE_Y1_A'),
  ('ADV002', 'Dr. Rohan Sharma',   'rohan.sharma@college.edu',   'CSE_Y2_A'),
  ('ADV003', 'Dr. Sunita Nair',    'sunita.nair@college.edu',    'CSE_Y3_A'),
  ('ADV004', 'Dr. Vikram Pillai',  'vikram.pillai@college.edu',  'CSE_Y4_A');


-- ══════════════════════════════════════════════════════════════
--  3. STUDENTS
--  crisis_sem = semester number when their crisis hits (0 = none)
--  Dropout data lives in dropout_events; students table stays lean.
-- ══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS students (
  student_id      VARCHAR(10)  PRIMARY KEY,
  class_id        VARCHAR(20)  NOT NULL,
  advisor_id      VARCHAR(10),
  name            VARCHAR(80)  NOT NULL,
  roll_number     INT          NOT NULL,
  gender          CHAR(1),
  email           VARCHAR(100) UNIQUE,
  parent_email    VARCHAR(100),
  phone           VARCHAR(15),
  archetype       VARCHAR(30)  NOT NULL DEFAULT 'consistent_avg',
  crisis_sem      INT          NOT NULL DEFAULT 0,
  FOREIGN KEY (class_id)   REFERENCES classes(class_id),
  FOREIGN KEY (advisor_id) REFERENCES advisors(advisor_id)
);

-- ── Year 1 students (STU001–STU040) ──────────────────────────
INSERT INTO students
  (student_id,class_id,advisor_id,name,roll_number,gender,email,parent_email,archetype,crisis_sem)
VALUES
('STU001','CSE_Y1_A','ADV001','Aarav Kumar',       1,'M','aarav.kumar@college.edu',      'parent.aarav@gmail.com',      'consistent_avg',   0),
('STU002','CSE_Y1_A','ADV001','Vivaan Sharma',      2,'M','vivaan.sharma@college.edu',    'parent.vivaan@gmail.com',     'high_performer',   0),
('STU003','CSE_Y1_A','ADV001','Aditya Singh',       3,'M','aditya.singh@college.edu',     'parent.aditya@gmail.com',     'slow_fader',       0),
('STU004','CSE_Y1_A','ADV001','Ananya Patel',       4,'F','ananya.patel@college.edu',     'parent.ananya@gmail.com',     'consistent_avg',   0),
('STU005','CSE_Y1_A','ADV001','Diya Gupta',         5,'F','diya.gupta@college.edu',       'parent.diya@gmail.com',       'high_performer',   0),
('STU006','CSE_Y1_A','ADV001','Priya Joshi',        6,'F','priya.joshi@college.edu',      'parent.priya@gmail.com',      'crammer',          0),
('STU007','CSE_Y1_A','ADV001','Rahul Verma',        7,'M','rahul.verma@college.edu',      'parent.rahul@gmail.com',      'consistent_avg',   0),
('STU008','CSE_Y1_A','ADV001','Rohan Mishra',       8,'M','rohan.mishra@college.edu',     'parent.rohan@gmail.com',      'late_bloomer',     0),
('STU009','CSE_Y1_A','ADV001','Sneha Rao',          9,'F','sneha.rao@college.edu',        'parent.sneha@gmail.com',      'slow_fader',       0),
('STU010','CSE_Y1_A','ADV001','Kiran Reddy',       10,'M','kiran.reddy@college.edu',      'parent.kiran@gmail.com',      'consistent_avg',   0),
('STU011','CSE_Y1_A','ADV001','Meera Nair',        11,'F','meera.nair@college.edu',       'parent.meera@gmail.com',      'high_performer',   0),
('STU012','CSE_Y1_A','ADV001','Ishaan Pillai',     12,'M','ishaan.pillai@college.edu',    'parent.ishaan@gmail.com',     'crisis_student',   1),
('STU013','CSE_Y1_A','ADV001','Tanvi Shah',        13,'F','tanvi.shah@college.edu',       'parent.tanvi@gmail.com',      'consistent_avg',   0),
('STU014','CSE_Y1_A','ADV001','Yash Mehta',        14,'M','yash.mehta@college.edu',       'parent.yash@gmail.com',       'silent_disengager',0),
('STU015','CSE_Y1_A','ADV001','Sakshi Chopra',     15,'F','sakshi.chopra@college.edu',    'parent.sakshi@gmail.com',     'slow_fader',       0),
('STU016','CSE_Y1_A','ADV001','Dev Bose',          16,'M','dev.bose@college.edu',         'parent.dev@gmail.com',        'consistent_avg',   0),
('STU017','CSE_Y1_A','ADV001','Aryan Das',         17,'M','aryan.das@college.edu',        'parent.aryan@gmail.com',      'crammer',          0),
('STU018','CSE_Y1_A','ADV001','Kavya Iyer',        18,'F','kavya.iyer@college.edu',       'parent.kavya@gmail.com',      'high_performer',   0),
('STU019','CSE_Y1_A','ADV001','Simran Menon',      19,'F','simran.menon@college.edu',     'parent.simran@gmail.com',     'consistent_avg',   0),
('STU020','CSE_Y1_A','ADV001','Harsh Chandra',     20,'M','harsh.chandra@college.edu',    'parent.harsh@gmail.com',      'late_bloomer',     0),
('STU021','CSE_Y1_A','ADV001','Neha Kumar',        21,'F','neha.kumar@college.edu',       'parent.neha@gmail.com',       'crisis_student',   2),
('STU022','CSE_Y1_A','ADV001','Ritesh Sharma',     22,'M','ritesh.sharma@college.edu',    'parent.ritesh@gmail.com',     'consistent_avg',   0),
('STU023','CSE_Y1_A','ADV001','Divya Singh',       23,'F','divya.singh@college.edu',      'parent.divya@gmail.com',      'silent_disengager',0),
('STU024','CSE_Y1_A','ADV001','Nikhil Patel',      24,'M','nikhil.patel@college.edu',     'parent.nikhil@gmail.com',     'slow_fader',       0),
('STU025','CSE_Y1_A','ADV001','Shreya Gupta',      25,'F','shreya.gupta@college.edu',     'parent.shreya@gmail.com',     'high_performer',   0),
('STU026','CSE_Y1_A','ADV001','Amit Joshi',        26,'M','amit.joshi@college.edu',       'parent.amit@gmail.com',       'silent_disengager',0),
('STU027','CSE_Y1_A','ADV001','Kajal Verma',       27,'F','kajal.verma@college.edu',      'parent.kajal@gmail.com',      'crammer',          0),
('STU028','CSE_Y1_A','ADV001','Ravi Mishra',       28,'M','ravi.mishra@college.edu',      'parent.ravi@gmail.com',       'consistent_avg',   0),
('STU029','CSE_Y1_A','ADV001','Sunita Rao',        29,'F','sunita.rao@college.edu',       'parent.sunita@gmail.com',     'silent_disengager',0),
('STU030','CSE_Y1_A','ADV001','Manish Reddy',      30,'M','manish.reddy@college.edu',     'parent.manish@gmail.com',     'late_bloomer',     0),
('STU031','CSE_Y1_A','ADV001','Pallavi Nair',      31,'F','pallavi.nair@college.edu',     'parent.pallavi@gmail.com',    'slow_fader',       0),
('STU032','CSE_Y1_A','ADV001','Gaurav Pillai',     32,'M','gaurav.pillai@college.edu',    'parent.gaurav@gmail.com',     'crisis_student',   1),
('STU033','CSE_Y1_A','ADV001','Swati Shah',        33,'F','swati.shah@college.edu',       'parent.swati@gmail.com',      'high_performer',   0),
('STU034','CSE_Y1_A','ADV001','Deepak Mehta',      34,'M','deepak.mehta@college.edu',     'parent.deepak@gmail.com',     'consistent_avg',   0),
('STU035','CSE_Y1_A','ADV001','Rekha Chopra',      35,'F','rekha.chopra@college.edu',     'parent.rekha@gmail.com',      'silent_disengager',0),
('STU036','CSE_Y1_A','ADV001','Sanjay Bose',       36,'M','sanjay.bose@college.edu',      'parent.sanjay@gmail.com',     'crammer',          0),
('STU037','CSE_Y1_A','ADV001','Ankita Das',        37,'F','ankita.das@college.edu',       'parent.ankita@gmail.com',     'late_bloomer',     0),
('STU038','CSE_Y1_A','ADV001','Vikram Iyer',       38,'M','vikram.iyer@college.edu',      'parent.vikram@gmail.com',     'slow_fader',       0),
('STU039','CSE_Y1_A','ADV001','Preeti Menon',      39,'F','preeti.menon@college.edu',     'parent.preeti@gmail.com',     'consistent_avg',   0),
('STU040','CSE_Y1_A','ADV001','Rajesh Chandra',    40,'M','rajesh.chandra@college.edu',   'parent.rajesh@gmail.com',     'crisis_student',   2);

-- ── Year 2 students (STU041–STU080) ──────────────────────────
INSERT INTO students
  (student_id,class_id,advisor_id,name,roll_number,gender,email,parent_email,archetype,crisis_sem)
VALUES
('STU041','CSE_Y2_A','ADV002','Tarun Kumar',       1,'M','tarun.kumar@college.edu',      'parent.tarun@gmail.com',      'consistent_avg',   0),
('STU042','CSE_Y2_A','ADV002','Bhavna Sharma',     2,'F','bhavna.sharma@college.edu',    'parent.bhavna@gmail.com',     'high_performer',   0),
('STU043','CSE_Y2_A','ADV002','Suresh Singh',      3,'M','suresh.singh@college.edu',     'parent.suresh@gmail.com',     'slow_fader',       0),
('STU044','CSE_Y2_A','ADV002','Geeta Patel',       4,'F','geeta.patel@college.edu',      'parent.geeta@gmail.com',      'consistent_avg',   0),
('STU045','CSE_Y2_A','ADV002','Pankaj Gupta',      5,'M','pankaj.gupta@college.edu',     'parent.pankaj@gmail.com',     'silent_disengager',0),
('STU046','CSE_Y2_A','ADV002','Vandana Joshi',     6,'F','vandana.joshi@college.edu',    'parent.vandana@gmail.com',    'crammer',          0),
('STU047','CSE_Y2_A','ADV002','Mohan Verma',       7,'M','mohan.verma@college.edu',      'parent.mohan@gmail.com',      'consistent_avg',   0),
('STU048','CSE_Y2_A','ADV002','Lata Mishra',       8,'F','lata.mishra@college.edu',      'parent.lata@gmail.com',       'late_bloomer',     0),
('STU049','CSE_Y2_A','ADV002','Hemant Rao',        9,'M','hemant.rao@college.edu',       'parent.hemant@gmail.com',     'high_performer',   0),
('STU050','CSE_Y2_A','ADV002','Shweta Reddy',     10,'F','shweta.reddy@college.edu',     'parent.shweta@gmail.com',     'crisis_student',   3),
('STU051','CSE_Y2_A','ADV002','Kunal Nair',       11,'M','kunal.nair@college.edu',       'parent.kunal@gmail.com',      'consistent_avg',   0),
('STU052','CSE_Y2_A','ADV002','Pooja Pillai',     12,'F','pooja.pillai@college.edu',     'parent.pooja@gmail.com',      'slow_fader',       0),
('STU053','CSE_Y2_A','ADV002','Arjun Shah',       13,'M','arjun.shah@college.edu',       'parent.arjun@gmail.com',      'silent_disengager',0),
('STU054','CSE_Y2_A','ADV002','Riya Mehta',       14,'F','riya.mehta@college.edu',       'parent.riya@gmail.com',       'crammer',          0),
('STU055','CSE_Y2_A','ADV002','Sai Chopra',       15,'M','sai.chopra@college.edu',       'parent.sai@gmail.com',        'consistent_avg',   0),
('STU056','CSE_Y2_A','ADV002','Reyansh Bose',     16,'M','reyansh.bose@college.edu',     'parent.reyansh@gmail.com',    'consistent_avg',   0),
('STU057','CSE_Y2_A','ADV002','Ayaan Das',        17,'M','ayaan.das@college.edu',        'parent.ayaan@gmail.com',      'silent_disengager',0),
('STU058','CSE_Y2_A','ADV002','Nisha Iyer',       18,'F','nisha.iyer@college.edu',       'parent.nisha@gmail.com',      'late_bloomer',     0),
('STU059','CSE_Y2_A','ADV002','Vihaan Menon',     19,'M','vihaan.menon@college.edu',     'parent.vihaan@gmail.com',     'slow_fader',       0),
('STU060','CSE_Y2_A','ADV002','Smita Chandra',    20,'F','smita.chandra@college.edu',    'parent.smita@gmail.com',      'consistent_avg',   0),
('STU061','CSE_Y2_A','ADV002','Ritesh Kumar',     21,'M','ritesh2.kumar@college.edu',    'parent.ritesh2@gmail.com',    'crisis_student',   4),
('STU062','CSE_Y2_A','ADV002','Kavya Sharma',     22,'F','kavya.sharma@college.edu',     'parent.kavya2@gmail.com',     'high_performer',   0),
('STU063','CSE_Y2_A','ADV002','Harsh Singh',      23,'M','harsh.singh@college.edu',      'parent.harsh2@gmail.com',     'slow_fader',       0),
('STU064','CSE_Y2_A','ADV002','Divya Patel',      24,'F','divya.patel@college.edu',      'parent.divya2@gmail.com',     'crammer',          0),
('STU065','CSE_Y2_A','ADV002','Nikhil Gupta',     25,'M','nikhil.gupta@college.edu',     'parent.nikhil2@gmail.com',    'consistent_avg',   0),
('STU066','CSE_Y2_A','ADV002','Shreya Joshi',     26,'F','shreya.joshi@college.edu',     'parent.shreya2@gmail.com',    'silent_disengager',0),
('STU067','CSE_Y2_A','ADV002','Amit Verma',       27,'M','amit.verma@college.edu',       'parent.amit2@gmail.com',      'consistent_avg',   0),
('STU068','CSE_Y2_A','ADV002','Kajal Mishra',     28,'F','kajal.mishra@college.edu',     'parent.kajal2@gmail.com',     'late_bloomer',     0),
('STU069','CSE_Y2_A','ADV002','Ravi Rao',         29,'M','ravi.rao@college.edu',         'parent.ravi2@gmail.com',      'crisis_student',   3),
('STU070','CSE_Y2_A','ADV002','Sunita Reddy',     30,'F','sunita.reddy@college.edu',     'parent.sunita2@gmail.com',    'high_performer',   0),
('STU071','CSE_Y2_A','ADV002','Manish Nair',      31,'M','manish.nair@college.edu',      'parent.manish2@gmail.com',    'consistent_avg',   0),
('STU072','CSE_Y2_A','ADV002','Pallavi Pillai',   32,'F','pallavi.pillai@college.edu',   'parent.pallavi2@gmail.com',   'slow_fader',       0),
('STU073','CSE_Y2_A','ADV002','Gaurav Shah',      33,'M','gaurav.shah@college.edu',      'parent.gaurav2@gmail.com',    'silent_disengager',0),
('STU074','CSE_Y2_A','ADV002','Swati Mehta',      34,'F','swati.mehta@college.edu',      'parent.swati2@gmail.com',     'crammer',          0),
('STU075','CSE_Y2_A','ADV002','Deepak Chopra',    35,'M','deepak.chopra@college.edu',    'parent.deepak2@gmail.com',    'consistent_avg',   0),
('STU076','CSE_Y2_A','ADV002','Rekha Bose',       36,'F','rekha.bose@college.edu',       'parent.rekha2@gmail.com',     'late_bloomer',     0),
('STU077','CSE_Y2_A','ADV002','Sanjay Das',       37,'M','sanjay.das@college.edu',       'parent.sanjay2@gmail.com',    'crisis_student',   4),
('STU078','CSE_Y2_A','ADV002','Ankita Iyer',      38,'F','ankita.iyer@college.edu',      'parent.ankita2@gmail.com',    'high_performer',   0),
('STU079','CSE_Y2_A','ADV002','Vikram Menon',     39,'M','vikram.menon@college.edu',     'parent.vikram2@gmail.com',    'consistent_avg',   0),
('STU080','CSE_Y2_A','ADV002','Preeti Chandra',   40,'F','preeti.chandra@college.edu',   'parent.preeti2@gmail.com',    'slow_fader',       0);

-- ── Year 3 students (STU081–STU120) ──────────────────────────
INSERT INTO students
  (student_id,class_id,advisor_id,name,roll_number,gender,email,parent_email,archetype,crisis_sem)
VALUES
('STU081','CSE_Y3_A','ADV003','Aarav Sharma',     1,'M','aarav.sharma@college.edu',      'parent.aarav2@gmail.com',     'consistent_avg',   0),
('STU082','CSE_Y3_A','ADV003','Vivaan Singh',      2,'M','vivaan.singh@college.edu',      'parent.vivaan2@gmail.com',    'high_performer',   0),
('STU083','CSE_Y3_A','ADV003','Aditya Patel',      3,'M','aditya.patel@college.edu',      'parent.aditya2@gmail.com',    'slow_fader',       0),
('STU084','CSE_Y3_A','ADV003','Ananya Gupta',      4,'F','ananya.gupta@college.edu',      'parent.ananya2@gmail.com',    'consistent_avg',   0),
('STU085','CSE_Y3_A','ADV003','Diya Joshi',        5,'F','diya.joshi@college.edu',        'parent.diya2@gmail.com',      'silent_disengager',0),
('STU086','CSE_Y3_A','ADV003','Priya Verma',       6,'F','priya.verma@college.edu',       'parent.priya2@gmail.com',     'crammer',          0),
('STU087','CSE_Y3_A','ADV003','Rahul Mishra',      7,'M','rahul.mishra@college.edu',      'parent.rahul2@gmail.com',     'consistent_avg',   0),
('STU088','CSE_Y3_A','ADV003','Rohan Rao',         8,'M','rohan.rao@college.edu',         'parent.rohan2@gmail.com',     'late_bloomer',     0),
('STU089','CSE_Y3_A','ADV003','Sneha Reddy',       9,'F','sneha.reddy@college.edu',       'parent.sneha2@gmail.com',     'high_performer',   0),
('STU090','CSE_Y3_A','ADV003','Kiran Nair',       10,'F','kiran.nair@college.edu',        'parent.kiran2@gmail.com',     'crisis_student',   5),
('STU091','CSE_Y3_A','ADV003','Meera Pillai',     11,'F','meera.pillai@college.edu',      'parent.meera2@gmail.com',     'consistent_avg',   0),
('STU092','CSE_Y3_A','ADV003','Ishaan Shah',      12,'M','ishaan.shah@college.edu',       'parent.ishaan2@gmail.com',    'slow_fader',       0),
('STU093','CSE_Y3_A','ADV003','Tanvi Mehta',      13,'F','tanvi.mehta@college.edu',       'parent.tanvi2@gmail.com',     'silent_disengager',0),
('STU094','CSE_Y3_A','ADV003','Yash Chopra',      14,'M','yash.chopra@college.edu',       'parent.yash2@gmail.com',      'crammer',          0),
('STU095','CSE_Y3_A','ADV003','Sakshi Bose',      15,'F','sakshi.bose@college.edu',       'parent.sakshi2@gmail.com',    'high_performer',   0),
('STU096','CSE_Y3_A','ADV003','Dev Das',          16,'M','dev.das@college.edu',           'parent.dev2@gmail.com',       'consistent_avg',   0),
('STU097','CSE_Y3_A','ADV003','Aryan Iyer',       17,'M','aryan.iyer@college.edu',        'parent.aryan2@gmail.com',     'silent_disengager',0),
('STU098','CSE_Y3_A','ADV003','Kavya Menon',      18,'F','kavya.menon@college.edu',       'parent.kavya3@gmail.com',     'late_bloomer',     0),
('STU099','CSE_Y3_A','ADV003','Simran Chandra',   19,'F','simran.chandra@college.edu',    'parent.simran2@gmail.com',    'slow_fader',       0),
('STU100','CSE_Y3_A','ADV003','Harsh Kumar',      20,'M','harsh.kumar@college.edu',       'parent.harsh3@gmail.com',     'consistent_avg',   0),
('STU101','CSE_Y3_A','ADV003','Neha Sharma',      21,'F','neha.sharma@college.edu',       'parent.neha2@gmail.com',      'crisis_student',   6),
('STU102','CSE_Y3_A','ADV003','Ritesh Singh',     22,'M','ritesh.singh@college.edu',      'parent.ritesh3@gmail.com',    'high_performer',   0),
('STU103','CSE_Y3_A','ADV003','Divya Gupta',      23,'F','divya.gupta@college.edu',       'parent.divya3@gmail.com',     'consistent_avg',   0),
('STU104','CSE_Y3_A','ADV003','Nikhil Joshi',     24,'M','nikhil.joshi@college.edu',      'parent.nikhil3@gmail.com',    'crammer',          0),
('STU105','CSE_Y3_A','ADV003','Shreya Verma',     25,'F','shreya.verma@college.edu',      'parent.shreya3@gmail.com',    'slow_fader',       0),
('STU106','CSE_Y3_A','ADV003','Amit Mishra',      26,'M','amit.mishra@college.edu',       'parent.amit3@gmail.com',      'silent_disengager',0),
('STU107','CSE_Y3_A','ADV003','Kajal Rao',        27,'F','kajal.rao@college.edu',         'parent.kajal3@gmail.com',     'consistent_avg',   0),
('STU108','CSE_Y3_A','ADV003','Ravi Reddy',       28,'M','ravi.reddy@college.edu',        'parent.ravi3@gmail.com',      'late_bloomer',     0),
('STU109','CSE_Y3_A','ADV003','Sunita Nair',      29,'F','sunita.nair2@college.edu',      'parent.sunita3@gmail.com',    'crisis_student',   5),
('STU110','CSE_Y3_A','ADV003','Manish Pillai',    30,'M','manish.pillai@college.edu',     'parent.manish3@gmail.com',    'high_performer',   0),
('STU111','CSE_Y3_A','ADV003','Pallavi Shah',     31,'F','pallavi.shah@college.edu',      'parent.pallavi3@gmail.com',   'silent_disengager',0),
('STU112','CSE_Y3_A','ADV003','Gaurav Mehta',     32,'M','gaurav.mehta@college.edu',      'parent.gaurav3@gmail.com',    'consistent_avg',   0),
('STU113','CSE_Y3_A','ADV003','Swati Chopra',     33,'F','swati.chopra@college.edu',      'parent.swati3@gmail.com',     'slow_fader',       0),
('STU114','CSE_Y3_A','ADV003','Deepak Bose',      34,'M','deepak.bose@college.edu',       'parent.deepak3@gmail.com',    'crammer',          0),
('STU115','CSE_Y3_A','ADV003','Rekha Das',        35,'F','rekha.das@college.edu',         'parent.rekha3@gmail.com',     'consistent_avg',   0),
('STU116','CSE_Y3_A','ADV003','Sanjay Iyer',      36,'M','sanjay.iyer@college.edu',       'parent.sanjay3@gmail.com',    'late_bloomer',     0),
('STU117','CSE_Y3_A','ADV003','Ankita Menon',     37,'F','ankita.menon@college.edu',      'parent.ankita3@gmail.com',    'crisis_student',   6),
('STU118','CSE_Y3_A','ADV003','Vikram Chandra',   38,'M','vikram.chandra@college.edu',    'parent.vikram3@gmail.com',    'high_performer',   0),
('STU119','CSE_Y3_A','ADV003','Preeti Kumar',     39,'F','preeti.kumar@college.edu',      'parent.preeti3@gmail.com',    'consistent_avg',   0),
('STU120','CSE_Y3_A','ADV003','Rajesh Sharma',    40,'M','rajesh.sharma@college.edu',     'parent.rajesh2@gmail.com',    'slow_fader',       0);

-- ── Year 4 students (STU121–STU160) ──────────────────────────
INSERT INTO students
  (student_id,class_id,advisor_id,name,roll_number,gender,email,parent_email,archetype,crisis_sem)
VALUES
('STU121','CSE_Y4_A','ADV004','Varun Kumar',       1,'M','varun.kumar@college.edu',       'parent.varun@gmail.com',      'consistent_avg',   0),
('STU122','CSE_Y4_A','ADV004','Nandita Sharma',    2,'F','nandita.sharma@college.edu',    'parent.nandita@gmail.com',    'high_performer',   0),
('STU123','CSE_Y4_A','ADV004','Rohit Singh',       3,'M','rohit.singh@college.edu',       'parent.rohit@gmail.com',      'slow_fader',       0),
('STU124','CSE_Y4_A','ADV004','Prerna Patel',      4,'F','prerna.patel@college.edu',      'parent.prerna@gmail.com',     'consistent_avg',   0),
('STU125','CSE_Y4_A','ADV004','Shubham Gupta',     5,'M','shubham.gupta@college.edu',     'parent.shubham@gmail.com',    'silent_disengager',0),
('STU126','CSE_Y4_A','ADV004','Pooja Joshi',       6,'F','pooja.joshi@college.edu',       'parent.pooja2@gmail.com',     'crammer',          0),
('STU127','CSE_Y4_A','ADV004','Akash Verma',       7,'M','akash.verma@college.edu',       'parent.akash@gmail.com',      'consistent_avg',   0),
('STU128','CSE_Y4_A','ADV004','Komal Mishra',      8,'F','komal.mishra@college.edu',      'parent.komal@gmail.com',      'late_bloomer',     0),
('STU129','CSE_Y4_A','ADV004','Sumit Rao',         9,'M','sumit.rao@college.edu',         'parent.sumit@gmail.com',      'high_performer',   0),
('STU130','CSE_Y4_A','ADV004','Jyoti Reddy',      10,'F','jyoti.reddy@college.edu',       'parent.jyoti@gmail.com',      'crisis_student',   7),
('STU131','CSE_Y4_A','ADV004','Abhishek Nair',    11,'M','abhishek.nair@college.edu',     'parent.abhishek@gmail.com',   'consistent_avg',   0),
('STU132','CSE_Y4_A','ADV004','Monika Pillai',    12,'F','monika.pillai@college.edu',     'parent.monika@gmail.com',     'slow_fader',       0),
('STU133','CSE_Y4_A','ADV004','Rajiv Shah',       13,'M','rajiv.shah@college.edu',        'parent.rajiv@gmail.com',      'silent_disengager',0),
('STU134','CSE_Y4_A','ADV004','Sonal Mehta',      14,'F','sonal.mehta@college.edu',       'parent.sonal@gmail.com',      'crammer',          0),
('STU135','CSE_Y4_A','ADV004','Deepesh Chopra',   15,'M','deepesh.chopra@college.edu',    'parent.deepesh@gmail.com',    'consistent_avg',   0),
('STU136','CSE_Y4_A','ADV004','Tanya Bose',       16,'F','tanya.bose@college.edu',        'parent.tanya@gmail.com',      'consistent_avg',   0),
('STU137','CSE_Y4_A','ADV004','Kuber Das',        17,'M','kuber.das@college.edu',         'parent.kuber@gmail.com',      'silent_disengager',0),
('STU138','CSE_Y4_A','ADV004','Ritu Iyer',        18,'F','ritu.iyer@college.edu',         'parent.ritu@gmail.com',       'late_bloomer',     0),
('STU139','CSE_Y4_A','ADV004','Lalit Menon',      19,'M','lalit.menon@college.edu',       'parent.lalit@gmail.com',      'slow_fader',       0),
('STU140','CSE_Y4_A','ADV004','Seema Chandra',    20,'F','seema.chandra@college.edu',     'parent.seema@gmail.com',      'consistent_avg',   0),
('STU141','CSE_Y4_A','ADV004','Girish Kumar',     21,'M','girish.kumar@college.edu',      'parent.girish@gmail.com',     'crisis_student',   8),
('STU142','CSE_Y4_A','ADV004','Rashmi Sharma',    22,'F','rashmi.sharma@college.edu',     'parent.rashmi@gmail.com',     'high_performer',   0),
('STU143','CSE_Y4_A','ADV004','Tarun Singh',      23,'M','tarun.singh@college.edu',       'parent.tarun2@gmail.com',     'slow_fader',       0),
('STU144','CSE_Y4_A','ADV004','Kamla Patel',      24,'F','kamla.patel@college.edu',       'parent.kamla@gmail.com',      'crammer',          0),
('STU145','CSE_Y4_A','ADV004','Anand Gupta',      25,'M','anand.gupta@college.edu',       'parent.anand@gmail.com',      'consistent_avg',   0),
('STU146','CSE_Y4_A','ADV004','Laxmi Joshi',      26,'F','laxmi.joshi@college.edu',       'parent.laxmi@gmail.com',      'silent_disengager',0),
('STU147','CSE_Y4_A','ADV004','Arun Verma',       27,'M','arun.verma@college.edu',        'parent.arun@gmail.com',       'consistent_avg',   0),
('STU148','CSE_Y4_A','ADV004','Hema Mishra',      28,'F','hema.mishra@college.edu',       'parent.hema@gmail.com',       'late_bloomer',     0),
('STU149','CSE_Y4_A','ADV004','Sunil Rao',        29,'M','sunil.rao@college.edu',         'parent.sunil@gmail.com',      'crisis_student',   7),
('STU150','CSE_Y4_A','ADV004','Babita Reddy',     30,'F','babita.reddy@college.edu',      'parent.babita@gmail.com',     'high_performer',   0),
('STU151','CSE_Y4_A','ADV004','Narendra Nair',    31,'M','narendra.nair@college.edu',     'parent.narendra@gmail.com',   'consistent_avg',   0),
('STU152','CSE_Y4_A','ADV004','Urmila Pillai',    32,'F','urmila.pillai@college.edu',     'parent.urmila@gmail.com',     'slow_fader',       0),
('STU153','CSE_Y4_A','ADV004','Manoj Shah',       33,'M','manoj.shah@college.edu',        'parent.manoj@gmail.com',      'silent_disengager',0),
('STU154','CSE_Y4_A','ADV004','Sudha Mehta',      34,'F','sudha.mehta@college.edu',       'parent.sudha@gmail.com',      'crammer',          0),
('STU155','CSE_Y4_A','ADV004','Ramesh Chopra',    35,'M','ramesh.chopra@college.edu',     'parent.ramesh@gmail.com',     'consistent_avg',   0),
('STU156','CSE_Y4_A','ADV004','Kamini Bose',      36,'F','kamini.bose@college.edu',       'parent.kamini@gmail.com',     'late_bloomer',     0),
('STU157','CSE_Y4_A','ADV004','Vinod Das',        37,'M','vinod.das@college.edu',         'parent.vinod@gmail.com',      'crisis_student',   8),
('STU158','CSE_Y4_A','ADV004','Shashi Iyer',      38,'M','shashi.iyer@college.edu',       'parent.shashi@gmail.com',     'high_performer',   0),
('STU159','CSE_Y4_A','ADV004','Geeta Menon',      39,'F','geeta.menon@college.edu',       'parent.geeta2@gmail.com',     'consistent_avg',   0),
('STU160','CSE_Y4_A','ADV004','Prakash Chandra',  40,'M','prakash.chandra@college.edu',   'parent.prakash@gmail.com',    'slow_fader',       0);


-- ══════════════════════════════════════════════════════════════
--  4. DROPOUT EVENTS  (schema only — zero rows at week 0)
--  Populated by the simulator if a student drops out mid-semester.
-- ══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS dropout_events (
  dropout_id        BIGINT AUTO_INCREMENT PRIMARY KEY,
  student_id        VARCHAR(10)  NOT NULL UNIQUE,
  class_id          VARCHAR(20)  NOT NULL,
  dropout_semester  INT          NOT NULL,
  dropout_reason    VARCHAR(80),
  last_active_week  INT          NOT NULL,
  FOREIGN KEY (student_id) REFERENCES students(student_id),
  FOREIGN KEY (class_id)   REFERENCES classes(class_id)
);


-- ══════════════════════════════════════════════════════════════
--  5. SUBJECTS  (all 8 semesters)
-- ══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS subjects (
  subject_id      VARCHAR(15)  PRIMARY KEY,
  subject_name    VARCHAR(80)  NOT NULL,
  semester        INT          NOT NULL,   -- 1–8
  credits         INT          DEFAULT 4,
  difficulty      VARCHAR(10)  DEFAULT 'Medium',
  subject_type    VARCHAR(20)  DEFAULT 'Core'
);

INSERT INTO subjects VALUES
-- Semester 1
('S1_MATH1',  'Mathematics I',              1, 4, 'Hard',    'Core'),
('S1_PHY',    'Physics',                    1, 4, 'Medium',  'Core'),
('S1_PROG',   'Programming Fundamentals',   1, 4, 'Medium',  'Core'),
('S1_ENG',    'English Communication',      1, 2, 'Easy',    'Foundation'),
('S1_DRAW',   'Engineering Drawing',        1, 2, 'Medium',  'Core'),
-- Semester 2
('S2_MATH2',  'Mathematics II',             2, 4, 'Hard',    'Core'),
('S2_CHEM',   'Chemistry',                  2, 4, 'Medium',  'Core'),
('S2_DPROG',  'Data Structures',            2, 4, 'Medium',  'Core'),
('S2_ELEC',   'Basic Electronics',          2, 3, 'Medium',  'Core'),
('S2_EVS',    'Environmental Science',      2, 2, 'Easy',    'Foundation'),
-- Semester 3
('S3_DISC',   'Discrete Mathematics',       3, 4, 'Hard',    'Core'),
('S3_CO',     'Computer Organisation',      3, 4, 'Hard',    'Core'),
('S3_DBMS',   'Database Management',        3, 4, 'Medium',  'Core'),
('S3_OS',     'Operating Systems',          3, 4, 'Hard',    'Core'),
('S3_SE',     'Software Engineering',       3, 3, 'Medium',  'Core'),
-- Semester 4
('S4_TOC',    'Theory of Computation',      4, 4, 'Hard',    'Core'),
('S4_CN',     'Computer Networks',          4, 4, 'Hard',    'Core'),
('S4_DAA',    'Design & Analysis of Algo',  4, 4, 'Hard',    'Core'),
('S4_JAVA',   'Object Oriented Programming',4, 3, 'Medium',  'Core'),
('S4_STAT',   'Probability & Statistics',   4, 3, 'Medium',  'Core'),
-- Semester 5
('S5_CD',     'Compiler Design',            5, 4, 'Hard',    'Core'),
('S5_AI',     'Artificial Intelligence',    5, 4, 'Hard',    'Core'),
('S5_CC',     'Cloud Computing',            5, 3, 'Medium',  'Core'),
('S5_MD',     'Mobile Development',         5, 3, 'Medium',  'Core'),
('S5_ELEC1',  'Elective I',                 5, 3, 'Medium',  'Elective'),
-- Semester 6
('S6_ML',     'Machine Learning',           6, 4, 'Hard',    'Core'),
('S6_IS',     'Information Security',       6, 4, 'Hard',    'Core'),
('S6_DV',     'Data Visualisation',         6, 3, 'Medium',  'Core'),
('S6_ELEC2',  'Elective II',                6, 3, 'Medium',  'Elective'),
('S6_PROJ',   'Mini Project',               6, 2, 'Medium',  'Project'),
-- Semester 7
('S7_BDA',    'Big Data Analytics',         7, 4, 'Hard',    'Core'),
('S7_IOT',    'Internet of Things',         7, 3, 'Medium',  'Core'),
('S7_ELEC3',  'Elective III',               7, 3, 'Medium',  'Elective'),
('S7_ELEC4',  'Elective IV',                7, 3, 'Medium',  'Elective'),
('S7_PROJ2',  'Project Phase I',            7, 3, 'Hard',    'Project'),
-- Semester 8
('S8_PROJ3',  'Project Phase II',           8, 6, 'Hard',    'Project'),
('S8_ELEC5',  'Elective V',                 8, 3, 'Medium',  'Elective'),
('S8_ELEC6',  'Elective VI',                8, 3, 'Medium',  'Elective'),
('S8_INTERN', 'Internship / Training',      8, 4, 'Medium',  'Core'),
('S8_SEMINAR','Technical Seminar',          8, 2, 'Easy',    'Core');


-- ══════════════════════════════════════════════════════════════
--  6. CLASS_SUBJECTS  (which subjects each class studies)
-- ══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS class_subjects (
  class_id        VARCHAR(20)  NOT NULL,
  subject_id      VARCHAR(15)  NOT NULL,
  teacher_name    VARCHAR(80),
  PRIMARY KEY (class_id, subject_id),
  FOREIGN KEY (class_id)   REFERENCES classes(class_id),
  FOREIGN KEY (subject_id) REFERENCES subjects(subject_id)
);

INSERT INTO class_subjects VALUES
-- Year 1 — Sem 1 subjects
('CSE_Y1_A','S1_MATH1', 'Prof. Anil Kapoor'),
('CSE_Y1_A','S1_PHY',   'Prof. Meena Desai'),
('CSE_Y1_A','S1_PROG',  'Prof. Suresh Babu'),
('CSE_Y1_A','S1_ENG',   'Prof. Rita Sharma'),
('CSE_Y1_A','S1_DRAW',  'Prof. Kishore Rao'),
-- Year 1 — Sem 2 subjects
('CSE_Y1_A','S2_MATH2', 'Prof. Anil Kapoor'),
('CSE_Y1_A','S2_CHEM',  'Prof. Meena Desai'),
('CSE_Y1_A','S2_DPROG', 'Prof. Suresh Babu'),
('CSE_Y1_A','S2_ELEC',  'Prof. Kishore Rao'),
('CSE_Y1_A','S2_EVS',   'Prof. Rita Sharma'),
-- Year 2 — Sem 3 subjects
('CSE_Y2_A','S3_DISC',  'Prof. Anil Kapoor'),
('CSE_Y2_A','S3_CO',    'Prof. Venkat Rao'),
('CSE_Y2_A','S3_DBMS',  'Prof. Suresh Babu'),
('CSE_Y2_A','S3_OS',    'Prof. Pradeep Kumar'),
('CSE_Y2_A','S3_SE',    'Prof. Latha Nair'),
-- Year 2 — Sem 4 subjects
('CSE_Y2_A','S4_TOC',   'Prof. Anil Kapoor'),
('CSE_Y2_A','S4_CN',    'Prof. Venkat Rao'),
('CSE_Y2_A','S4_DAA',   'Prof. Pradeep Kumar'),
('CSE_Y2_A','S4_JAVA',  'Prof. Suresh Babu'),
('CSE_Y2_A','S4_STAT',  'Prof. Latha Nair'),
-- Year 3 — Sem 5 subjects
('CSE_Y3_A','S5_CD',    'Prof. Venkat Rao'),
('CSE_Y3_A','S5_AI',    'Prof. Deepa Menon'),
('CSE_Y3_A','S5_CC',    'Prof. Rajan Iyer'),
('CSE_Y3_A','S5_MD',    'Prof. Pradeep Kumar'),
('CSE_Y3_A','S5_ELEC1', 'Prof. Latha Nair'),
-- Year 3 — Sem 6 subjects
('CSE_Y3_A','S6_ML',    'Prof. Deepa Menon'),
('CSE_Y3_A','S6_IS',    'Prof. Venkat Rao'),
('CSE_Y3_A','S6_DV',    'Prof. Rajan Iyer'),
('CSE_Y3_A','S6_ELEC2', 'Prof. Latha Nair'),
('CSE_Y3_A','S6_PROJ',  'Prof. Pradeep Kumar'),
-- Year 4 — Sem 7 subjects
('CSE_Y4_A','S7_BDA',   'Prof. Deepa Menon'),
('CSE_Y4_A','S7_IOT',   'Prof. Rajan Iyer'),
('CSE_Y4_A','S7_ELEC3', 'Prof. Latha Nair'),
('CSE_Y4_A','S7_ELEC4', 'Prof. Venkat Rao'),
('CSE_Y4_A','S7_PROJ2', 'Prof. Pradeep Kumar'),
-- Year 4 — Sem 8 subjects
('CSE_Y4_A','S8_PROJ3',  'Prof. Pradeep Kumar'),
('CSE_Y4_A','S8_ELEC5',  'Prof. Deepa Menon'),
('CSE_Y4_A','S8_ELEC6',  'Prof. Venkat Rao'),
('CSE_Y4_A','S8_INTERN', 'Prof. Rajan Iyer'),
('CSE_Y4_A','S8_SEMINAR','Prof. Latha Nair');


-- ══════════════════════════════════════════════════════════════
--  7. EXAM SCHEDULE
--  Exam weeks are sem-week 8 (midterm) and sem-week 18 (endterm).
--  All dates computed from a sim_year=2024 base:
--    Odd sems  (1,3,5,7): start first Monday of August  2024
--    Even sems (2,4,6,8): start first Monday of January 2025
--  Sem-week 8 ≈ week 8 after sem start; sem-week 18 ≈ week 18.
--  schedule_id format: ES_<cls>_<subj>_<type>
--
--  semester column added (required by db_writer2 queries).
-- ══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS exam_schedule (
  schedule_id     VARCHAR(25)  PRIMARY KEY,
  class_id        VARCHAR(20)  NOT NULL,
  subject_id      VARCHAR(15)  NOT NULL,
  exam_type       VARCHAR(10)  NOT NULL,   -- 'midterm' or 'endterm'
  semester        INT          NOT NULL,
  scheduled_week  INT          NOT NULL,   -- within-semester week (8 or 18)
  exam_date       DATE,
  max_marks       INT          DEFAULT 50,
  duration_mins   INT          DEFAULT 120,
  FOREIGN KEY (class_id)   REFERENCES classes(class_id),
  FOREIGN KEY (subject_id) REFERENCES subjects(subject_id)
);

-- Year 1 / Sem 1 — odd sem, dates anchor on 2024-08-05 (first Mon Aug 2024)
INSERT INTO exam_schedule VALUES
('ES_Y1S1_MATH1_MID','CSE_Y1_A','S1_MATH1','midterm', 1, 8,'2024-09-23',50,120),
('ES_Y1S1_PHY_MID',  'CSE_Y1_A','S1_PHY',  'midterm', 1, 8,'2024-09-24',50,120),
('ES_Y1S1_PROG_MID', 'CSE_Y1_A','S1_PROG', 'midterm', 1, 8,'2024-09-25',50,120),
('ES_Y1S1_ENG_MID',  'CSE_Y1_A','S1_ENG',  'midterm', 1, 8,'2024-09-26',50, 90),
('ES_Y1S1_DRAW_MID', 'CSE_Y1_A','S1_DRAW', 'midterm', 1, 8,'2024-09-27',50,120),
('ES_Y1S1_MATH1_END','CSE_Y1_A','S1_MATH1','endterm', 1,18,'2024-12-02',50,180),
('ES_Y1S1_PHY_END',  'CSE_Y1_A','S1_PHY',  'endterm', 1,18,'2024-12-03',50,180),
('ES_Y1S1_PROG_END', 'CSE_Y1_A','S1_PROG', 'endterm', 1,18,'2024-12-04',50,180),
('ES_Y1S1_ENG_END',  'CSE_Y1_A','S1_ENG',  'endterm', 1,18,'2024-12-05',50,120),
('ES_Y1S1_DRAW_END', 'CSE_Y1_A','S1_DRAW', 'endterm', 1,18,'2024-12-06',50,120);

-- Year 1 / Sem 2 — even sem, dates anchor on 2025-01-06 (first Mon Jan 2025)
INSERT INTO exam_schedule VALUES
('ES_Y1S2_MATH2_MID','CSE_Y1_A','S2_MATH2','midterm', 2, 8,'2025-03-03',50,120),
('ES_Y1S2_CHEM_MID', 'CSE_Y1_A','S2_CHEM', 'midterm', 2, 8,'2025-03-04',50,120),
('ES_Y1S2_DPROG_MID','CSE_Y1_A','S2_DPROG','midterm', 2, 8,'2025-03-05',50,120),
('ES_Y1S2_ELEC_MID', 'CSE_Y1_A','S2_ELEC', 'midterm', 2, 8,'2025-03-06',50,120),
('ES_Y1S2_EVS_MID',  'CSE_Y1_A','S2_EVS',  'midterm', 2, 8,'2025-03-07',50, 90),
('ES_Y1S2_MATH2_END','CSE_Y1_A','S2_MATH2','endterm', 2,18,'2025-05-12',50,180),
('ES_Y1S2_CHEM_END', 'CSE_Y1_A','S2_CHEM', 'endterm', 2,18,'2025-05-13',50,180),
('ES_Y1S2_DPROG_END','CSE_Y1_A','S2_DPROG','endterm', 2,18,'2025-05-14',50,180),
('ES_Y1S2_ELEC_END', 'CSE_Y1_A','S2_ELEC', 'endterm', 2,18,'2025-05-15',50,180),
('ES_Y1S2_EVS_END',  'CSE_Y1_A','S2_EVS',  'endterm', 2,18,'2025-05-16',50,120);

-- Year 2 / Sem 3
INSERT INTO exam_schedule VALUES
('ES_Y2S3_DISC_MID', 'CSE_Y2_A','S3_DISC', 'midterm', 3, 8,'2024-09-23',50,120),
('ES_Y2S3_CO_MID',   'CSE_Y2_A','S3_CO',   'midterm', 3, 8,'2024-09-24',50,120),
('ES_Y2S3_DBMS_MID', 'CSE_Y2_A','S3_DBMS', 'midterm', 3, 8,'2024-09-25',50,120),
('ES_Y2S3_OS_MID',   'CSE_Y2_A','S3_OS',   'midterm', 3, 8,'2024-09-26',50,120),
('ES_Y2S3_SE_MID',   'CSE_Y2_A','S3_SE',   'midterm', 3, 8,'2024-09-27',50, 90),
('ES_Y2S3_DISC_END', 'CSE_Y2_A','S3_DISC', 'endterm', 3,18,'2024-12-02',50,180),
('ES_Y2S3_CO_END',   'CSE_Y2_A','S3_CO',   'endterm', 3,18,'2024-12-03',50,180),
('ES_Y2S3_DBMS_END', 'CSE_Y2_A','S3_DBMS', 'endterm', 3,18,'2024-12-04',50,180),
('ES_Y2S3_OS_END',   'CSE_Y2_A','S3_OS',   'endterm', 3,18,'2024-12-05',50,180),
('ES_Y2S3_SE_END',   'CSE_Y2_A','S3_SE',   'endterm', 3,18,'2024-12-06',50,120);

-- Year 2 / Sem 4
INSERT INTO exam_schedule VALUES
('ES_Y2S4_TOC_MID',  'CSE_Y2_A','S4_TOC',  'midterm', 4, 8,'2025-03-03',50,120),
('ES_Y2S4_CN_MID',   'CSE_Y2_A','S4_CN',   'midterm', 4, 8,'2025-03-04',50,120),
('ES_Y2S4_DAA_MID',  'CSE_Y2_A','S4_DAA',  'midterm', 4, 8,'2025-03-05',50,120),
('ES_Y2S4_JAVA_MID', 'CSE_Y2_A','S4_JAVA', 'midterm', 4, 8,'2025-03-06',50,120),
('ES_Y2S4_STAT_MID', 'CSE_Y2_A','S4_STAT', 'midterm', 4, 8,'2025-03-07',50,120),
('ES_Y2S4_TOC_END',  'CSE_Y2_A','S4_TOC',  'endterm', 4,18,'2025-05-12',50,180),
('ES_Y2S4_CN_END',   'CSE_Y2_A','S4_CN',   'endterm', 4,18,'2025-05-13',50,180),
('ES_Y2S4_DAA_END',  'CSE_Y2_A','S4_DAA',  'endterm', 4,18,'2025-05-14',50,180),
('ES_Y2S4_JAVA_END', 'CSE_Y2_A','S4_JAVA', 'endterm', 4,18,'2025-05-15',50,180),
('ES_Y2S4_STAT_END', 'CSE_Y2_A','S4_STAT', 'endterm', 4,18,'2025-05-16',50,180);

-- Year 3 / Sem 5
INSERT INTO exam_schedule VALUES
('ES_Y3S5_CD_MID',   'CSE_Y3_A','S5_CD',   'midterm', 5, 8,'2024-09-23',50,120),
('ES_Y3S5_AI_MID',   'CSE_Y3_A','S5_AI',   'midterm', 5, 8,'2024-09-24',50,120),
('ES_Y3S5_CC_MID',   'CSE_Y3_A','S5_CC',   'midterm', 5, 8,'2024-09-25',50,120),
('ES_Y3S5_MD_MID',   'CSE_Y3_A','S5_MD',   'midterm', 5, 8,'2024-09-26',50,120),
('ES_Y3S5_ELEC1_MID','CSE_Y3_A','S5_ELEC1','midterm', 5, 8,'2024-09-27',50,120),
('ES_Y3S5_CD_END',   'CSE_Y3_A','S5_CD',   'endterm', 5,18,'2024-12-02',50,180),
('ES_Y3S5_AI_END',   'CSE_Y3_A','S5_AI',   'endterm', 5,18,'2024-12-03',50,180),
('ES_Y3S5_CC_END',   'CSE_Y3_A','S5_CC',   'endterm', 5,18,'2024-12-04',50,180),
('ES_Y3S5_MD_END',   'CSE_Y3_A','S5_MD',   'endterm', 5,18,'2024-12-05',50,180),
('ES_Y3S5_ELEC1_END','CSE_Y3_A','S5_ELEC1','endterm', 5,18,'2024-12-06',50,180);

-- Year 3 / Sem 6
INSERT INTO exam_schedule VALUES
('ES_Y3S6_ML_MID',   'CSE_Y3_A','S6_ML',   'midterm', 6, 8,'2025-03-03',50,120),
('ES_Y3S6_IS_MID',   'CSE_Y3_A','S6_IS',   'midterm', 6, 8,'2025-03-04',50,120),
('ES_Y3S6_DV_MID',   'CSE_Y3_A','S6_DV',   'midterm', 6, 8,'2025-03-05',50,120),
('ES_Y3S6_ELEC2_MID','CSE_Y3_A','S6_ELEC2','midterm', 6, 8,'2025-03-06',50,120),
('ES_Y3S6_PROJ_MID', 'CSE_Y3_A','S6_PROJ', 'midterm', 6, 8,'2025-03-07',50, 90),
('ES_Y3S6_ML_END',   'CSE_Y3_A','S6_ML',   'endterm', 6,18,'2025-05-12',50,180),
('ES_Y3S6_IS_END',   'CSE_Y3_A','S6_IS',   'endterm', 6,18,'2025-05-13',50,180),
('ES_Y3S6_DV_END',   'CSE_Y3_A','S6_DV',   'endterm', 6,18,'2025-05-14',50,180),
('ES_Y3S6_ELEC2_END','CSE_Y3_A','S6_ELEC2','endterm', 6,18,'2025-05-15',50,180),
('ES_Y3S6_PROJ_END', 'CSE_Y3_A','S6_PROJ', 'endterm', 6,18,'2025-05-16',50,120);

-- Year 4 / Sem 7
INSERT INTO exam_schedule VALUES
('ES_Y4S7_BDA_MID',  'CSE_Y4_A','S7_BDA',  'midterm', 7, 8,'2024-09-23',50,120),
('ES_Y4S7_IOT_MID',  'CSE_Y4_A','S7_IOT',  'midterm', 7, 8,'2024-09-24',50,120),
('ES_Y4S7_E3_MID',   'CSE_Y4_A','S7_ELEC3','midterm', 7, 8,'2024-09-25',50,120),
('ES_Y4S7_E4_MID',   'CSE_Y4_A','S7_ELEC4','midterm', 7, 8,'2024-09-26',50,120),
('ES_Y4S7_P2_MID',   'CSE_Y4_A','S7_PROJ2','midterm', 7, 8,'2024-09-27',50,120),
('ES_Y4S7_BDA_END',  'CSE_Y4_A','S7_BDA',  'endterm', 7,18,'2024-12-02',50,180),
('ES_Y4S7_IOT_END',  'CSE_Y4_A','S7_IOT',  'endterm', 7,18,'2024-12-03',50,180),
('ES_Y4S7_E3_END',   'CSE_Y4_A','S7_ELEC3','endterm', 7,18,'2024-12-04',50,180),
('ES_Y4S7_E4_END',   'CSE_Y4_A','S7_ELEC4','endterm', 7,18,'2024-12-05',50,180),
('ES_Y4S7_P2_END',   'CSE_Y4_A','S7_PROJ2','endterm', 7,18,'2024-12-06',50,180);

-- Year 4 / Sem 8
INSERT INTO exam_schedule VALUES
('ES_Y4S8_P3_MID',   'CSE_Y4_A','S8_PROJ3', 'midterm', 8, 8,'2025-03-03',50,120),
('ES_Y4S8_E5_MID',   'CSE_Y4_A','S8_ELEC5', 'midterm', 8, 8,'2025-03-04',50,120),
('ES_Y4S8_E6_MID',   'CSE_Y4_A','S8_ELEC6', 'midterm', 8, 8,'2025-03-05',50,120),
('ES_Y4S8_INT_MID',  'CSE_Y4_A','S8_INTERN','midterm', 8, 8,'2025-03-06',50, 90),
('ES_Y4S8_SEM_MID',  'CSE_Y4_A','S8_SEMINAR','midterm',8, 8,'2025-03-07',50, 60),
('ES_Y4S8_P3_END',   'CSE_Y4_A','S8_PROJ3', 'endterm', 8,18,'2025-05-12',50,180),
('ES_Y4S8_E5_END',   'CSE_Y4_A','S8_ELEC5', 'endterm', 8,18,'2025-05-13',50,180),
('ES_Y4S8_E6_END',   'CSE_Y4_A','S8_ELEC6', 'endterm', 8,18,'2025-05-14',50,180),
('ES_Y4S8_INT_END',  'CSE_Y4_A','S8_INTERN','endterm', 8,18,'2025-05-15',50,120),
('ES_Y4S8_SEM_END',  'CSE_Y4_A','S8_SEMINAR','endterm',8,18,'2025-05-16',50, 60);


-- ══════════════════════════════════════════════════════════════
--  8. ASSIGNMENT DEFINITIONS
--  semester column added (required by db_writer2).
--  Peak distribution: weeks 3–7 and 9–14; never on exam weeks 8/18.
-- ══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS assignment_definitions (
  assignment_id   VARCHAR(20)  PRIMARY KEY,
  class_id        VARCHAR(20)  NOT NULL,
  subject_id      VARCHAR(15)  NOT NULL,
  semester        INT          NOT NULL,
  title           VARCHAR(120) NOT NULL,
  assigned_week   INT          NOT NULL,
  due_week        INT          NOT NULL,
  max_marks       INT          DEFAULT 10,
  FOREIGN KEY (class_id)   REFERENCES classes(class_id),
  FOREIGN KEY (subject_id) REFERENCES subjects(subject_id)
);

INSERT INTO assignment_definitions
  (assignment_id,class_id,subject_id,semester,title,assigned_week,due_week,max_marks)
VALUES
-- ── Year 1 / Sem 1 ───────────────────────────────────────────
('A_Y1S1_001','CSE_Y1_A','S1_MATH1',1,'Algebra problem set',           3, 5,10),
('A_Y1S1_002','CSE_Y1_A','S1_MATH1',1,'Calculus assignment',           5, 7,10),
('A_Y1S1_003','CSE_Y1_A','S1_MATH1',1,'Statistics worksheet',          9,11,10),
('A_Y1S1_004','CSE_Y1_A','S1_MATH1',1,'Integration problems',         11,13,10),
('A_Y1S1_005','CSE_Y1_A','S1_PHY',  1,'Lab report 1',                  3, 5,20),
('A_Y1S1_006','CSE_Y1_A','S1_PHY',  1,'Lab report 2',                  9,11,20),
('A_Y1S1_007','CSE_Y1_A','S1_PHY',  1,'Mechanics assignment',         12,14,10),
('A_Y1S1_008','CSE_Y1_A','S1_PROG', 1,'Hello World to functions',      2, 4,10),
('A_Y1S1_009','CSE_Y1_A','S1_PROG', 1,'Arrays and strings',            4, 6,10),
('A_Y1S1_010','CSE_Y1_A','S1_PROG', 1,'Loops and conditionals',        5, 7,10),
('A_Y1S1_011','CSE_Y1_A','S1_PROG', 1,'File handling program',         9,12,10),
('A_Y1S1_012','CSE_Y1_A','S1_PROG', 1,'Mini project',                 10,14,25),
('A_Y1S1_013','CSE_Y1_A','S1_ENG',  1,'Technical writing essay',       3, 6,10),
('A_Y1S1_014','CSE_Y1_A','S1_ENG',  1,'Presentation draft',            9,12,10),
('A_Y1S1_015','CSE_Y1_A','S1_DRAW', 1,'Drawing set 1',                 3, 6,20),
('A_Y1S1_016','CSE_Y1_A','S1_DRAW', 1,'Drawing set 2',                11,13,20),
-- ── Year 1 / Sem 2 ───────────────────────────────────────────
('A_Y1S2_001','CSE_Y1_A','S2_MATH2',2,'Differential equations set',    3, 5,10),
('A_Y1S2_002','CSE_Y1_A','S2_MATH2',2,'Vector calculus assignment',    5, 7,10),
('A_Y1S2_003','CSE_Y1_A','S2_MATH2',2,'Complex numbers worksheet',     9,11,10),
('A_Y1S2_004','CSE_Y1_A','S2_CHEM', 2,'Chemistry lab report 1',        3, 5,20),
('A_Y1S2_005','CSE_Y1_A','S2_CHEM', 2,'Chemistry lab report 2',        9,11,20),
('A_Y1S2_006','CSE_Y1_A','S2_DPROG',2,'Linked list implementation',    2, 4,10),
('A_Y1S2_007','CSE_Y1_A','S2_DPROG',2,'Stack and queue program',       4, 6,10),
('A_Y1S2_008','CSE_Y1_A','S2_DPROG',2,'Tree traversal assignment',     5, 7,10),
('A_Y1S2_009','CSE_Y1_A','S2_DPROG',2,'Sorting algorithms project',    9,14,25),
('A_Y1S2_010','CSE_Y1_A','S2_ELEC', 2,'Circuit analysis report',       4, 6,10),
('A_Y1S2_011','CSE_Y1_A','S2_ELEC', 2,'Logic gates assignment',       11,13,10),
('A_Y1S2_012','CSE_Y1_A','S2_EVS',  2,'Environmental impact report',   3, 7,10),
-- ── Year 2 / Sem 3 ───────────────────────────────────────────
('A_Y2S3_001','CSE_Y2_A','S3_DISC', 3,'Set theory problems',           3, 5,10),
('A_Y2S3_002','CSE_Y2_A','S3_DISC', 3,'Graph theory assignment',       5, 7,10),
('A_Y2S3_003','CSE_Y2_A','S3_DISC', 3,'Logic and proofs',              9,12,10),
('A_Y2S3_004','CSE_Y2_A','S3_CO',   3,'Number systems worksheet',      3, 5,10),
('A_Y2S3_005','CSE_Y2_A','S3_CO',   3,'Memory hierarchy report',       5, 7,10),
('A_Y2S3_006','CSE_Y2_A','S3_CO',   3,'Instruction set analysis',      9,11,10),
('A_Y2S3_007','CSE_Y2_A','S3_DBMS', 3,'ER diagram assignment',         2, 4,10),
('A_Y2S3_008','CSE_Y2_A','S3_DBMS', 3,'SQL queries lab',               4, 6,10),
('A_Y2S3_009','CSE_Y2_A','S3_DBMS', 3,'Normalisation problems',        6, 7,10),
('A_Y2S3_010','CSE_Y2_A','S3_DBMS', 3,'Transaction management',        9,12,10),
('A_Y2S3_011','CSE_Y2_A','S3_DBMS', 3,'Mini database project',        10,14,25),
('A_Y2S3_012','CSE_Y2_A','S3_OS',   3,'Process scheduling lab',        4, 6,10),
('A_Y2S3_013','CSE_Y2_A','S3_OS',   3,'Memory management report',      5, 7,10),
('A_Y2S3_014','CSE_Y2_A','S3_OS',   3,'File system assignment',        9,12,10),
('A_Y2S3_015','CSE_Y2_A','S3_SE',   3,'Requirements document',         4, 6,20),
('A_Y2S3_016','CSE_Y2_A','S3_SE',   3,'Design document',              11,13,20),
-- ── Year 2 / Sem 4 ───────────────────────────────────────────
('A_Y2S4_001','CSE_Y2_A','S4_TOC',  4,'Finite automata problems',      3, 5,10),
('A_Y2S4_002','CSE_Y2_A','S4_TOC',  4,'PDA and grammar assignment',    5, 7,10),
('A_Y2S4_003','CSE_Y2_A','S4_CN',   4,'Network topology report',       3, 5,10),
('A_Y2S4_004','CSE_Y2_A','S4_CN',   4,'TCP/IP protocol analysis',      9,12,10),
('A_Y2S4_005','CSE_Y2_A','S4_DAA',  4,'Sorting algorithm analysis',    4, 6,10),
('A_Y2S4_006','CSE_Y2_A','S4_DAA',  4,'Dynamic programming problems',  9,12,10),
('A_Y2S4_007','CSE_Y2_A','S4_JAVA', 4,'OOP concept implementation',    2, 4,10),
('A_Y2S4_008','CSE_Y2_A','S4_JAVA', 4,'Design patterns project',      10,14,25),
('A_Y2S4_009','CSE_Y2_A','S4_STAT', 4,'Probability worksheet',         5, 7,10),
('A_Y2S4_010','CSE_Y2_A','S4_STAT', 4,'Statistical inference report',  9,12,10),
-- ── Year 3 / Sem 5 ───────────────────────────────────────────
('A_Y3S5_001','CSE_Y3_A','S5_CD',   5,'Lexer implementation',          3, 5,10),
('A_Y3S5_002','CSE_Y3_A','S5_CD',   5,'Parser assignment',             5, 7,10),
('A_Y3S5_003','CSE_Y3_A','S5_CD',   5,'Code generation lab',           9,12,10),
('A_Y3S5_004','CSE_Y3_A','S5_AI',   5,'Search algorithms lab',         3, 5,10),
('A_Y3S5_005','CSE_Y3_A','S5_AI',   5,'Knowledge representation',      5, 7,10),
('A_Y3S5_006','CSE_Y3_A','S5_AI',   5,'ML basics assignment',          9,11,10),
('A_Y3S5_007','CSE_Y3_A','S5_AI',   5,'AI mini project',              10,14,25),
('A_Y3S5_008','CSE_Y3_A','S5_CC',   5,'Cloud deployment lab',          4, 6,10),
('A_Y3S5_009','CSE_Y3_A','S5_CC',   5,'Serverless functions',          9,12,10),
('A_Y3S5_010','CSE_Y3_A','S5_MD',   5,'Android app prototype',         4, 7,20),
('A_Y3S5_011','CSE_Y3_A','S5_MD',   5,'App with API integration',     11,14,20),
('A_Y3S5_012','CSE_Y3_A','S5_ELEC1',5,'Elective report 1',             5, 7,10),
('A_Y3S5_013','CSE_Y3_A','S5_ELEC1',5,'Elective report 2',            11,13,10),
-- ── Year 3 / Sem 6 ───────────────────────────────────────────
('A_Y3S6_001','CSE_Y3_A','S6_ML',   6,'Linear regression implementation',3,5,10),
('A_Y3S6_002','CSE_Y3_A','S6_ML',   6,'Classification model project', 10,14,25),
('A_Y3S6_003','CSE_Y3_A','S6_IS',   6,'Cryptography lab report',       4, 6,10),
('A_Y3S6_004','CSE_Y3_A','S6_IS',   6,'Vulnerability assessment',      9,12,10),
('A_Y3S6_005','CSE_Y3_A','S6_DV',   6,'Dashboard design assignment',   3, 5,10),
('A_Y3S6_006','CSE_Y3_A','S6_DV',   6,'Interactive chart project',     9,13,20),
('A_Y3S6_007','CSE_Y3_A','S6_ELEC2',6,'Elective II report 1',          5, 7,10),
('A_Y3S6_008','CSE_Y3_A','S6_ELEC2',6,'Elective II report 2',         11,13,10),
('A_Y3S6_009','CSE_Y3_A','S6_PROJ', 6,'Mini project proposal',         2, 4,10),
('A_Y3S6_010','CSE_Y3_A','S6_PROJ', 6,'Mini project prototype',        9,14,30),
-- ── Year 4 / Sem 7 ───────────────────────────────────────────
('A_Y4S7_001','CSE_Y4_A','S7_BDA',  7,'Hadoop lab report',             3, 5,10),
('A_Y4S7_002','CSE_Y4_A','S7_BDA',  7,'Spark streaming project',       9,13,20),
('A_Y4S7_003','CSE_Y4_A','S7_IOT',  7,'Sensor interface lab',          4, 6,10),
('A_Y4S7_004','CSE_Y4_A','S7_IOT',  7,'IoT prototype report',          9,12,10),
('A_Y4S7_005','CSE_Y4_A','S7_ELEC3',7,'Elective III assignment 1',     3, 5,10),
('A_Y4S7_006','CSE_Y4_A','S7_ELEC3',7,'Elective III assignment 2',    11,13,10),
('A_Y4S7_007','CSE_Y4_A','S7_ELEC4',7,'Elective IV assignment 1',      5, 7,10),
('A_Y4S7_008','CSE_Y4_A','S7_ELEC4',7,'Elective IV assignment 2',     11,14,10),
('A_Y4S7_009','CSE_Y4_A','S7_PROJ2',7,'Project Phase I proposal',      2, 4,20),
('A_Y4S7_010','CSE_Y4_A','S7_PROJ2',7,'Project Phase I milestone',     9,14,30),
-- ── Year 4 / Sem 8 ───────────────────────────────────────────
('A_Y4S8_001','CSE_Y4_A','S8_PROJ3',8,'Final project report draft',    3, 6,20),
('A_Y4S8_002','CSE_Y4_A','S8_PROJ3',8,'Final project submission',      9,14,50),
('A_Y4S8_003','CSE_Y4_A','S8_ELEC5',8,'Elective V assignment',         4, 6,10),
('A_Y4S8_004','CSE_Y4_A','S8_ELEC6',8,'Elective VI assignment',        5, 7,10),
('A_Y4S8_005','CSE_Y4_A','S8_INTERN',8,'Internship report',            9,13,20),
('A_Y4S8_006','CSE_Y4_A','S8_SEMINAR',8,'Seminar paper',               3, 7,15);


-- ══════════════════════════════════════════════════════════════
--  9. QUIZ DEFINITIONS
--  semester column added; quiz dates adjusted for 2024/2025.
--  Not scheduled on exam weeks 8 or 18.
-- ══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS quiz_definitions (
  quiz_id         VARCHAR(20)  PRIMARY KEY,
  class_id        VARCHAR(20)  NOT NULL,
  subject_id      VARCHAR(15)  NOT NULL,
  semester        INT          NOT NULL,
  title           VARCHAR(100) NOT NULL,
  scheduled_week  INT          NOT NULL,
  quiz_date       DATE,
  max_marks       INT          DEFAULT 10,
  duration_mins   INT          DEFAULT 20,
  FOREIGN KEY (class_id)   REFERENCES classes(class_id),
  FOREIGN KEY (subject_id) REFERENCES subjects(subject_id)
);

INSERT INTO quiz_definitions
  (quiz_id,class_id,subject_id,semester,title,scheduled_week,quiz_date,max_marks,duration_mins)
VALUES
-- ── Year 1 / Sem 1 ───────────────────────────────────────────
('Q_Y1S1_001','CSE_Y1_A','S1_MATH1',1,'Maths Quiz 1',            4,'2024-09-02',10,20),
('Q_Y1S1_002','CSE_Y1_A','S1_MATH1',1,'Maths Quiz 2',           12,'2024-10-28',10,20),
('Q_Y1S1_003','CSE_Y1_A','S1_PHY',  1,'Physics Quiz 1',          5,'2024-09-09',10,20),
('Q_Y1S1_004','CSE_Y1_A','S1_PHY',  1,'Physics Quiz 2',         13,'2024-11-04',10,20),
('Q_Y1S1_005','CSE_Y1_A','S1_PROG', 1,'Programming Quiz 1',      4,'2024-09-02',10,20),
('Q_Y1S1_006','CSE_Y1_A','S1_PROG', 1,'Programming Quiz 2',      6,'2024-09-16',10,20),
('Q_Y1S1_007','CSE_Y1_A','S1_PROG', 1,'Programming Quiz 3',     11,'2024-10-21',10,20),
-- ── Year 1 / Sem 2 ───────────────────────────────────────────
('Q_Y1S2_001','CSE_Y1_A','S2_MATH2',2,'Maths II Quiz 1',         4,'2025-02-03',10,20),
('Q_Y1S2_002','CSE_Y1_A','S2_MATH2',2,'Maths II Quiz 2',        12,'2025-03-31',10,20),
('Q_Y1S2_003','CSE_Y1_A','S2_DPROG',2,'Data Structures Quiz 1',  5,'2025-02-10',10,20),
('Q_Y1S2_004','CSE_Y1_A','S2_DPROG',2,'Data Structures Quiz 2', 11,'2025-03-24',10,20),
('Q_Y1S2_005','CSE_Y1_A','S2_ELEC', 2,'Electronics Quiz 1',      6,'2025-02-17',10,20),
-- ── Year 2 / Sem 3 ───────────────────────────────────────────
('Q_Y2S3_001','CSE_Y2_A','S3_DISC', 3,'Discrete Maths Q1',       4,'2024-09-02',10,20),
('Q_Y2S3_002','CSE_Y2_A','S3_DISC', 3,'Discrete Maths Q2',      12,'2024-10-28',10,20),
('Q_Y2S3_003','CSE_Y2_A','S3_CO',   3,'CO Quiz 1',               5,'2024-09-09',10,20),
('Q_Y2S3_004','CSE_Y2_A','S3_CO',   3,'CO Quiz 2',              13,'2024-11-04',10,20),
('Q_Y2S3_005','CSE_Y2_A','S3_DBMS', 3,'DBMS Quiz 1',             3,'2024-08-26',10,20),
('Q_Y2S3_006','CSE_Y2_A','S3_DBMS', 3,'DBMS Quiz 2',             6,'2024-09-16',10,20),
('Q_Y2S3_007','CSE_Y2_A','S3_DBMS', 3,'DBMS Quiz 3',            11,'2024-10-21',10,20),
('Q_Y2S3_008','CSE_Y2_A','S3_OS',   3,'OS Quiz 1',               5,'2024-09-09',10,20),
('Q_Y2S3_009','CSE_Y2_A','S3_OS',   3,'OS Quiz 2',              12,'2024-10-28',10,20),
-- ── Year 2 / Sem 4 ───────────────────────────────────────────
('Q_Y2S4_001','CSE_Y2_A','S4_TOC',  4,'TOC Quiz 1',              4,'2025-02-03',10,20),
('Q_Y2S4_002','CSE_Y2_A','S4_TOC',  4,'TOC Quiz 2',             12,'2025-03-31',10,20),
('Q_Y2S4_003','CSE_Y2_A','S4_CN',   4,'Networks Quiz 1',         5,'2025-02-10',10,20),
('Q_Y2S4_004','CSE_Y2_A','S4_DAA',  4,'DAA Quiz 1',              6,'2025-02-17',10,20),
('Q_Y2S4_005','CSE_Y2_A','S4_JAVA', 4,'Java Quiz 1',             4,'2025-02-03',10,20),
('Q_Y2S4_006','CSE_Y2_A','S4_JAVA', 4,'Java Quiz 2',            11,'2025-03-24',10,20),
-- ── Year 3 / Sem 5 ───────────────────────────────────────────
('Q_Y3S5_001','CSE_Y3_A','S5_CD',   5,'Compiler Design Q1',      4,'2024-09-02',10,20),
('Q_Y3S5_002','CSE_Y3_A','S5_CD',   5,'Compiler Design Q2',     12,'2024-10-28',10,20),
('Q_Y3S5_003','CSE_Y3_A','S5_AI',   5,'AI Quiz 1',               5,'2024-09-09',10,20),
('Q_Y3S5_004','CSE_Y3_A','S5_AI',   5,'AI Quiz 2',               6,'2024-09-16',10,20),
('Q_Y3S5_005','CSE_Y3_A','S5_AI',   5,'AI Quiz 3',              13,'2024-11-04',10,20),
('Q_Y3S5_006','CSE_Y3_A','S5_CC',   5,'Cloud Quiz 1',            5,'2024-09-09',10,20),
('Q_Y3S5_007','CSE_Y3_A','S5_MD',   5,'Mobile Dev Quiz 1',       6,'2024-09-16',10,20),
('Q_Y3S5_008','CSE_Y3_A','S5_MD',   5,'Mobile Dev Quiz 2',      11,'2024-10-21',10,20),
-- ── Year 3 / Sem 6 ───────────────────────────────────────────
('Q_Y3S6_001','CSE_Y3_A','S6_ML',   6,'ML Quiz 1',               4,'2025-02-03',10,20),
('Q_Y3S6_002','CSE_Y3_A','S6_ML',   6,'ML Quiz 2',              12,'2025-03-31',10,20),
('Q_Y3S6_003','CSE_Y3_A','S6_IS',   6,'InfoSec Quiz 1',          5,'2025-02-10',10,20),
('Q_Y3S6_004','CSE_Y3_A','S6_DV',   6,'DataViz Quiz 1',          6,'2025-02-17',10,20),
-- ── Year 4 / Sem 7 ───────────────────────────────────────────
('Q_Y4S7_001','CSE_Y4_A','S7_BDA',  7,'Big Data Quiz 1',         4,'2024-09-02',10,20),
('Q_Y4S7_002','CSE_Y4_A','S7_BDA',  7,'Big Data Quiz 2',        11,'2024-10-21',10,20),
('Q_Y4S7_003','CSE_Y4_A','S7_IOT',  7,'IoT Quiz 1',              5,'2024-09-09',10,20),
('Q_Y4S7_004','CSE_Y4_A','S7_ELEC3',7,'Elective III Quiz 1',     6,'2024-09-16',10,20),
-- ── Year 4 / Sem 8 ───────────────────────────────────────────
('Q_Y4S8_001','CSE_Y4_A','S8_ELEC5',8,'Elective V Quiz 1',       4,'2025-02-03',10,20),
('Q_Y4S8_002','CSE_Y4_A','S8_ELEC6',8,'Elective VI Quiz 1',      5,'2025-02-10',10,20);


-- ══════════════════════════════════════════════════════════════
--  10. SIM_STATE
--  sim_year = calendar year the odd semester started (2024).
--  current_week = 0 at database initialisation.
-- ══════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS sim_state (
  id            INT      PRIMARY KEY DEFAULT 1,
  current_week  INT      NOT NULL DEFAULT 0,   -- 0–36 global weeks
  sim_year      INT      NOT NULL DEFAULT 2024, -- odd-sem calendar year
  last_updated  DATETIME DEFAULT CURRENT_TIMESTAMP
                ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT single_row CHECK (id = 1)
);

INSERT INTO sim_state (id, current_week, sim_year)
VALUES (1, 0, 2024)
ON DUPLICATE KEY UPDATE id = 1;


-- ══════════════════════════════════════════════════════════════
--  11. TRANSACTIONAL TABLES  (schema only — zero rows at week 0)
--  These fill up as the simulator advances weeks.
-- ══════════════════════════════════════════════════════════════

-- Attendance gains a `semester` column (used in db_writer2 queries)
CREATE TABLE IF NOT EXISTS attendance (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  student_id      VARCHAR(10)  NOT NULL,
  class_id        VARCHAR(20)  NOT NULL,
  subject_id      VARCHAR(15)  NOT NULL,
  semester        INT          NOT NULL,
  week            INT          NOT NULL,   -- within-semester week (1–18)
  week_date       DATE         NOT NULL,
  lectures_held   INT          DEFAULT 3,
  present         INT,
  absent          INT,
  late            INT,
  attendance_pct  DECIMAL(5,2),
  FOREIGN KEY (student_id) REFERENCES students(student_id),
  FOREIGN KEY (class_id)   REFERENCES classes(class_id),
  FOREIGN KEY (subject_id) REFERENCES subjects(subject_id),
  UNIQUE KEY uq_att (student_id, subject_id, semester, week)
);

CREATE TABLE IF NOT EXISTS assignment_submissions (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  assignment_id   VARCHAR(20)  NOT NULL,
  student_id      VARCHAR(10)  NOT NULL,
  class_id        VARCHAR(20)  NOT NULL,
  status          VARCHAR(15)  NOT NULL DEFAULT 'pending',
  submission_date DATETIME,
  latency_hours   DECIMAL(6,1),
  marks_obtained  DECIMAL(5,2),
  quality_pct     DECIMAL(5,2),
  plagiarism_pct  DECIMAL(5,2) DEFAULT 0,
  FOREIGN KEY (assignment_id) REFERENCES assignment_definitions(assignment_id),
  FOREIGN KEY (student_id)    REFERENCES students(student_id),
  UNIQUE KEY uq_sub (assignment_id, student_id)
);

CREATE TABLE IF NOT EXISTS quiz_submissions (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  quiz_id         VARCHAR(20)  NOT NULL,
  student_id      VARCHAR(10)  NOT NULL,
  class_id        VARCHAR(20)  NOT NULL,
  attempted       TINYINT(1)   DEFAULT 0,
  attempt_date    DATETIME,
  marks_obtained  DECIMAL(5,2),
  score_pct       DECIMAL(5,2),
  FOREIGN KEY (quiz_id)    REFERENCES quiz_definitions(quiz_id),
  FOREIGN KEY (student_id) REFERENCES students(student_id),
  UNIQUE KEY uq_qsub (quiz_id, student_id)
);

-- library_visits gains a `semester` column
CREATE TABLE IF NOT EXISTS library_visits (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  student_id      VARCHAR(10)  NOT NULL,
  class_id        VARCHAR(20)  NOT NULL,
  semester        INT          NOT NULL,
  week            INT          NOT NULL,   -- within-semester week
  week_date       DATE,
  physical_visits INT          DEFAULT 0,
  FOREIGN KEY (student_id) REFERENCES students(student_id),
  UNIQUE KEY uq_lib (student_id, semester, week)
);

CREATE TABLE IF NOT EXISTS book_borrows (
  borrow_id       VARCHAR(20)  PRIMARY KEY,
  student_id      VARCHAR(10)  NOT NULL,
  class_id        VARCHAR(20)  NOT NULL,
  semester        INT          NOT NULL,
  book_title      VARCHAR(120),
  borrow_date     DATE,
  return_date     DATE,
  borrow_week     INT,
  return_week     INT,
  FOREIGN KEY (student_id) REFERENCES students(student_id)
);

CREATE TABLE IF NOT EXISTS exam_results (
  id              BIGINT AUTO_INCREMENT PRIMARY KEY,
  schedule_id     VARCHAR(25)  NOT NULL,
  student_id      VARCHAR(10)  NOT NULL,
  class_id        VARCHAR(20)  NOT NULL,
  marks_obtained  DECIMAL(5,2),
  max_marks       INT,
  score_pct       DECIMAL(5,2),
  pass_fail       CHAR(1),
  grade           VARCHAR(5),
  result_date     DATE,
  FOREIGN KEY (schedule_id) REFERENCES exam_schedule(schedule_id),
  FOREIGN KEY (student_id)  REFERENCES students(student_id),
  UNIQUE KEY uq_result (schedule_id, student_id)
);


-- ══════════════════════════════════════════════════════════════
--  12. INDEXES
-- ══════════════════════════════════════════════════════════════
CREATE INDEX idx_att_student_sem_week ON attendance(student_id, semester, week);
CREATE INDEX idx_att_class_sem_week   ON attendance(class_id, semester, week);
CREATE INDEX idx_sub_student          ON assignment_submissions(student_id);
CREATE INDEX idx_sub_assignment       ON assignment_submissions(assignment_id);
CREATE INDEX idx_qsub_student         ON quiz_submissions(student_id);
CREATE INDEX idx_lib_student_sem_week ON library_visits(student_id, semester, week);
CREATE INDEX idx_result_student       ON exam_results(student_id);
CREATE INDEX idx_result_schedule      ON exam_results(schedule_id);
CREATE INDEX idx_dropout_student      ON dropout_events(student_id);






-- check if records are being added or not 
USE edumetrics_client;
SELECT * FROM attendance 
ORDER BY week_date DESC;
