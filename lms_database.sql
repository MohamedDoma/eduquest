-- ============================================================
--  EduQuest LMS - Complete Database Schema & Seed Data
--  Designed for MySQL 8.0+
-- ============================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';

-- ============================================================
-- 1. CREATE DATABASE
-- ============================================================
CREATE DATABASE IF NOT EXISTS `eduquest_lms`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `eduquest_lms`;

-- ============================================================
-- 2. TABLE: users
-- ============================================================
CREATE TABLE IF NOT EXISTS `users` (
  `id`              INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `username`        VARCHAR(50)      NOT NULL UNIQUE,
  `email`           VARCHAR(120)     NOT NULL UNIQUE,
  `password_hash`   VARCHAR(255)     NOT NULL,
  `full_name`       VARCHAR(100)     NOT NULL,
  `avatar_url`      VARCHAR(512)     NOT NULL DEFAULT '',
  `role`            ENUM('student','teacher','admin') NOT NULL DEFAULT 'student',
  `grade_level`     TINYINT UNSIGNED NOT NULL DEFAULT 10 COMMENT '7-12 for middle/high school',
  `total_xp`        INT UNSIGNED     NOT NULL DEFAULT 0,
  `current_streak`  SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `longest_streak`  SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `last_study_date` DATE             NULL,
  `created_at`      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_users_xp` (`total_xp` DESC),
  INDEX `idx_users_streak` (`current_streak` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 3. TABLE: subjects
-- ============================================================
CREATE TABLE IF NOT EXISTS `subjects` (
  `id`          TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(60)      NOT NULL,
  `icon`        VARCHAR(10)      NOT NULL DEFAULT '📚',
  `color`       VARCHAR(7)       NOT NULL DEFAULT '#6366f1',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 4. TABLE: courses
-- ============================================================
CREATE TABLE IF NOT EXISTS `courses` (
  `id`            INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  `subject_id`    TINYINT UNSIGNED NOT NULL,
  `teacher_id`    INT UNSIGNED     NOT NULL,
  `title`         VARCHAR(150)     NOT NULL,
  `description`   TEXT             NOT NULL,
  `thumbnail_url` VARCHAR(512)     NOT NULL DEFAULT '',
  `grade_level`   TINYINT UNSIGNED NOT NULL DEFAULT 10,
  `difficulty`    ENUM('beginner','intermediate','advanced') NOT NULL DEFAULT 'beginner',
  `xp_reward`     SMALLINT UNSIGNED NOT NULL DEFAULT 100 COMMENT 'XP earned on course completion',
  `is_published`  TINYINT(1)       NOT NULL DEFAULT 1,
  `created_at`    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`subject_id`) REFERENCES `subjects`(`id`) ON DELETE RESTRICT,
  FOREIGN KEY (`teacher_id`) REFERENCES `users`(`id`) ON DELETE RESTRICT,
  INDEX `idx_courses_subject` (`subject_id`),
  INDEX `idx_courses_grade` (`grade_level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 5. TABLE: lessons
-- ============================================================
CREATE TABLE IF NOT EXISTS `lessons` (
  `id`            INT UNSIGNED      NOT NULL AUTO_INCREMENT,
  `course_id`     INT UNSIGNED      NOT NULL,
  `title`         VARCHAR(200)      NOT NULL,
  `description`   TEXT              NULL,
  `video_url`     VARCHAR(512)      NOT NULL COMMENT 'YouTube embed or direct URL',
  `video_duration` SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'seconds',
  `sort_order`    TINYINT UNSIGNED  NOT NULL DEFAULT 0,
  `xp_reward`     SMALLINT UNSIGNED NOT NULL DEFAULT 20,
  `created_at`    DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`course_id`) REFERENCES `courses`(`id`) ON DELETE CASCADE,
  INDEX `idx_lessons_course` (`course_id`, `sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 6. TABLE: lesson_progress
-- ============================================================
CREATE TABLE IF NOT EXISTS `lesson_progress` (
  `id`               INT UNSIGNED      NOT NULL AUTO_INCREMENT,
  `user_id`          INT UNSIGNED      NOT NULL,
  `lesson_id`        INT UNSIGNED      NOT NULL,
  `watch_percent`    TINYINT UNSIGNED  NOT NULL DEFAULT 0 COMMENT '0-100',
  `is_completed`     TINYINT(1)        NOT NULL DEFAULT 0,
  `completed_at`     DATETIME          NULL,
  `xp_awarded`       TINYINT(1)        NOT NULL DEFAULT 0,
  `updated_at`       DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_lesson` (`user_id`, `lesson_id`),
  FOREIGN KEY (`user_id`)   REFERENCES `users`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`lesson_id`) REFERENCES `lessons`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 7. TABLE: course_enrollments
-- ============================================================
CREATE TABLE IF NOT EXISTS `course_enrollments` (
  `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`         INT UNSIGNED NOT NULL,
  `course_id`       INT UNSIGNED NOT NULL,
  `enrolled_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `completed_at`    DATETIME     NULL,
  `exam_unlocked`   TINYINT(1)   NOT NULL DEFAULT 0,
  `exam_passed`     TINYINT(1)   NOT NULL DEFAULT 0,
  `exam_score`      TINYINT UNSIGNED NULL COMMENT '0-100',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_enrollment` (`user_id`, `course_id`),
  FOREIGN KEY (`user_id`)   REFERENCES `users`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`course_id`) REFERENCES `courses`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 8. TABLE: xp_transactions
-- ============================================================
CREATE TABLE IF NOT EXISTS `xp_transactions` (
  `id`          INT UNSIGNED  NOT NULL AUTO_INCREMENT,
  `user_id`     INT UNSIGNED  NOT NULL,
  `amount`      SMALLINT      NOT NULL COMMENT 'can be negative for penalties',
  `reason`      VARCHAR(120)  NOT NULL,
  `ref_type`    ENUM('lesson','exam','streak','achievement','admin') NOT NULL DEFAULT 'lesson',
  `ref_id`      INT UNSIGNED  NULL,
  `created_at`  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  INDEX `idx_xp_user` (`user_id`, `created_at` DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 9. TABLE: achievements
-- ============================================================
CREATE TABLE IF NOT EXISTS `achievements` (
  `id`          TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name`        VARCHAR(80)      NOT NULL,
  `description` VARCHAR(255)     NOT NULL,
  `icon`        VARCHAR(10)      NOT NULL,
  `xp_bonus`    SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `criteria`    VARCHAR(100)     NOT NULL COMMENT 'e.g. streak_7, xp_1000, lessons_10',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 10. TABLE: user_achievements
-- ============================================================
CREATE TABLE IF NOT EXISTS `user_achievements` (
  `user_id`        INT UNSIGNED     NOT NULL,
  `achievement_id` TINYINT UNSIGNED NOT NULL,
  `earned_at`      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`, `achievement_id`),
  FOREIGN KEY (`user_id`)        REFERENCES `users`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`achievement_id`) REFERENCES `achievements`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 11. TABLE: chat_sessions
-- ============================================================
CREATE TABLE IF NOT EXISTS `chat_sessions` (
  `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`     INT UNSIGNED NOT NULL,
  `course_id`   INT UNSIGNED NOT NULL,
  `language`    ENUM('English','Chinese','Tamil','Malay') NOT NULL DEFAULT 'English',
  `status`      ENUM('active','completed','abandoned') NOT NULL DEFAULT 'active',
  `score`       TINYINT UNSIGNED NULL,
  `started_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ended_at`    DATETIME NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`user_id`)   REFERENCES `users`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`course_id`) REFERENCES `courses`(`id`) ON DELETE CASCADE,
  INDEX `idx_chat_user` (`user_id`, `course_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 12. TABLE: chat_messages
-- ============================================================
CREATE TABLE IF NOT EXISTS `chat_messages` (
  `id`          INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  `session_id`  INT UNSIGNED   NOT NULL,
  `role`        ENUM('user','assistant') NOT NULL,
  `content`     TEXT           NOT NULL,
  `created_at`  DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`session_id`) REFERENCES `chat_sessions`(`id`) ON DELETE CASCADE,
  INDEX `idx_chat_session` (`session_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 13. TABLE: study_sessions (for streak tracking)
-- ============================================================
CREATE TABLE IF NOT EXISTS `study_sessions` (
  `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `user_id`    INT UNSIGNED NOT NULL,
  `study_date` DATE         NOT NULL,
  `xp_earned`  SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_user_date` (`user_id`, `study_date`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- ============================================================
--  SEED DATA
-- ============================================================
-- ============================================================

-- ============================================================
-- SUBJECTS
-- ============================================================
INSERT INTO `subjects` (`id`, `name`, `icon`, `color`) VALUES
(1, 'Mathematics',        '🔢', '#6366f1'),
(2, 'Science',            '🔬', '#10b981'),
(3, 'English Language',   '📖', '#f59e0b'),
(4, 'History',            '🏛️', '#ef4444'),
(5, 'Computer Science',   '💻', '#3b82f6'),
(6, 'Physics',            '⚛️', '#8b5cf6'),
(7, 'Chemistry',          '🧪', '#06b6d4'),
(8, 'Biology',            '🧬', '#84cc16');

-- ============================================================
-- USERS (admin + teachers + 30 students)
-- Password for ALL users: "Password123!" 
-- bcrypt hash of "Password123!" (cost 12)
-- ============================================================
INSERT INTO `users` (`id`,`username`,`email`,`password_hash`,`full_name`,`avatar_url`,`role`,`grade_level`,`total_xp`,`current_streak`,`longest_streak`,`last_study_date`) VALUES

-- ADMIN
(1,'admin','admin@eduquest.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'EduQuest Admin',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=admin&backgroundColor=6366f1',
 'admin', 12, 0, 0, 0, NULL),

-- TEACHERS
(2,'mr_chen','chen@eduquest.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Mr. David Chen',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=davidchen&backgroundColor=3b82f6',
 'teacher', 12, 0, 0, 0, NULL),

(3,'ms_patel','patel@eduquest.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Ms. Priya Patel',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=priyapatel&backgroundColor=10b981',
 'teacher', 12, 0, 0, 0, NULL),

(4,'mr_williams','williams@eduquest.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Mr. James Williams',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=jameswilliams&backgroundColor=f59e0b',
 'teacher', 12, 0, 0, 0, NULL),

(5,'ms_lim','lim@eduquest.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Ms. Sarah Lim',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=sarahlim&backgroundColor=ef4444',
 'teacher', 12, 0, 0, 0, NULL),

-- STUDENTS (grade 7-12, varied XP and streaks)
(6,'alex_ng','alex.ng@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Alex Ng Zhi Wei',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=alexng&backgroundColor=6366f1',
 'student', 11, 4850, 28, 35, CURDATE()),

(7,'zara_khan','zara.khan@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Zara Khan',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=zarakhan&backgroundColor=f59e0b',
 'student', 10, 4210, 21, 21, CURDATE()),

(8,'ethan_lee','ethan.lee@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Ethan Lee Kai Sheng',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=ethanlee&backgroundColor=10b981',
 'student', 12, 3990, 14, 30, CURDATE()),

(9,'maya_raj','maya.raj@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Maya Rajasekaran',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=mayaraj&backgroundColor=8b5cf6',
 'student', 10, 3750, 18, 22, CURDATE()),

(10,'lucas_tan','lucas.tan@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Lucas Tan Jing Hong',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=lucastan&backgroundColor=06b6d4',
 'student', 11, 3520, 7, 25, CURDATE()),

(11,'sofia_kim','sofia.kim@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Sofia Kim Min Ji',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=sofiakia&backgroundColor=ec4899',
 'student', 9, 3100, 12, 20, CURDATE()),

(12,'ryan_ahmad','ryan.ahmad@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Ryan Ahmad Firdaus',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=ryanahmad&backgroundColor=f97316',
 'student', 12, 2890, 5, 15, DATE_SUB(CURDATE(),INTERVAL 1 DAY)),

(13,'bella_ong','bella.ong@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Bella Ong Xin Yi',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=bellaong&backgroundColor=84cc16',
 'student', 11, 2760, 9, 18, CURDATE()),

(14,'aiden_wu','aiden.wu@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Aiden Wu Jian Ming',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=aidenwu&backgroundColor=3b82f6',
 'student', 10, 2580, 3, 10, DATE_SUB(CURDATE(),INTERVAL 2 DAY)),

(15,'nadia_jose','nadia.jose@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Nadia De Jose',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=nadiajose&backgroundColor=6366f1',
 'student', 9, 2340, 6, 14, CURDATE()),

(16,'jaxon_ho','jaxon.ho@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Jaxon Ho Wei Lun',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=jaxonho&backgroundColor=10b981',
 'student', 8, 2100, 0, 8, DATE_SUB(CURDATE(),INTERVAL 5 DAY)),

(17,'lily_tam','lily.tam@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Lily Tam Shu Ling',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=lilytam&backgroundColor=ec4899',
 'student', 7, 1950, 4, 12, CURDATE()),

(18,'omar_hassan','omar.hassan@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Omar Hassan Malik',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=omarhassan&backgroundColor=f59e0b',
 'student', 12, 1820, 2, 9, DATE_SUB(CURDATE(),INTERVAL 1 DAY)),

(19,'chloe_yap','chloe.yap@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Chloe Yap Jia Qi',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=chloeyap&backgroundColor=8b5cf6',
 'student', 10, 1700, 8, 11, CURDATE()),

(20,'noah_singh','noah.singh@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Noah Singh Arjun',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=noahsingh&backgroundColor=ef4444',
 'student', 11, 1550, 1, 6, DATE_SUB(CURDATE(),INTERVAL 2 DAY)),

(21,'isla_chong','isla.chong@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Isla Chong Mei Ling',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=islachong&backgroundColor=06b6d4',
 'student', 9, 1420, 5, 10, CURDATE()),

(22,'kai_ibrahim','kai.ibrahim@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Kai Ibrahim Razif',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=kaiibrahim&backgroundColor=84cc16',
 'student', 8, 1280, 0, 4, DATE_SUB(CURDATE(),INTERVAL 7 DAY)),

(23,'emma_foo','emma.foo@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Emma Foo Shan Shan',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=emmafoo&backgroundColor=f97316',
 'student', 7, 1100, 3, 7, CURDATE()),

(24,'luca_thong','luca.thong@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Luca Thong Wei Xiang',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=lucathong&backgroundColor=3b82f6',
 'student', 11, 980, 2, 5, DATE_SUB(CURDATE(),INTERVAL 3 DAY)),

(25,'ana_santos','ana.santos@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Ana Santos Cruz',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=anastos&backgroundColor=6366f1',
 'student', 12, 870, 0, 3, DATE_SUB(CURDATE(),INTERVAL 10 DAY)),

(26,'ivan_goh','ivan.goh@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Ivan Goh Cheng Tat',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=ivangoh&backgroundColor=10b981',
 'student', 10, 760, 1, 4, DATE_SUB(CURDATE(),INTERVAL 1 DAY)),

(27,'sara_osman','sara.osman@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Sara Osman Binti Ahmad',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=saraosman&backgroundColor=ec4899',
 'student', 9, 640, 4, 6, CURDATE()),

(28,'felix_kwan','felix.kwan@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Felix Kwan Jia Hao',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=felixkwan&backgroundColor=8b5cf6',
 'student', 8, 510, 0, 2, DATE_SUB(CURDATE(),INTERVAL 14 DAY)),

(29,'mia_joseph','mia.joseph@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Mia Joseph Nair',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=miajoseph&backgroundColor=f59e0b',
 'student', 7, 420, 2, 3, CURDATE()),

(30,'ben_leow','ben.leow@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Ben Leow Zi Yang',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=benleow&backgroundColor=06b6d4',
 'student', 11, 350, 1, 1, DATE_SUB(CURDATE(),INTERVAL 2 DAY)),

(31,'nina_raj','nina.raj@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Nina Rajendran',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=ninaraj&backgroundColor=84cc16',
 'student', 10, 280, 0, 1, DATE_SUB(CURDATE(),INTERVAL 20 DAY)),

(32,'cole_fung','cole.fung@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Cole Fung Chun Wei',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=colefung&backgroundColor=ef4444',
 'student', 12, 200, 3, 3, CURDATE()),

(33,'ava_krishna','ava.krishna@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Ava Krishnamurthy',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=avakrishna&backgroundColor=3b82f6',
 'student', 9, 150, 0, 0, NULL),

(34,'sam_low','sam.low@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Sam Low Boon Kiat',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=samlow&backgroundColor=6366f1',
 'student', 8, 80, 1, 1, CURDATE()),

(35,'jade_aziz','jade.aziz@student.edu',
 '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
 'Jade Aziz Harun',
 'https://api.dicebear.com/7.x/adventurer/svg?seed=jadeaziz&backgroundColor=10b981',
 'student', 7, 40, 0, 0, NULL);

-- ============================================================
-- ACHIEVEMENTS
-- ============================================================
INSERT INTO `achievements` (`id`,`name`,`description`,`icon`,`xp_bonus`,`criteria`) VALUES
(1,  'First Step',       'Complete your very first lesson',              '👶', 10,  'lessons_1'),
(2,  'On Fire',          'Study 7 days in a row',                        '🔥', 100, 'streak_7'),
(3,  'Unstoppable',      'Study 30 days in a row',                       '🌟', 500, 'streak_30'),
(4,  'Quick Learner',    'Complete 10 lessons',                          '⚡', 50,  'lessons_10'),
(5,  'Scholar',          'Complete 50 lessons',                          '📚', 200, 'lessons_50'),
(6,  'XP Hunter',        'Earn 1000 total XP',                           '💎', 50,  'xp_1000'),
(7,  'Elite Student',    'Earn 5000 total XP',                           '👑', 250, 'xp_5000'),
(8,  'Course Champion',  'Complete your first course',                   '🏆', 150, 'courses_1'),
(9,  'Exam Ace',         'Pass an AI exam with 90%+ score',              '🎓', 200, 'exam_90'),
(10, 'Polyglot',         'Take an exam in a non-English language',       '🌐', 75,  'exam_multilang');

-- ============================================================
-- COURSES (10 courses across subjects)
-- ============================================================
INSERT INTO `courses` (`id`,`subject_id`,`teacher_id`,`title`,`description`,`thumbnail_url`,`grade_level`,`difficulty`,`xp_reward`,`is_published`) VALUES

(1, 1, 2,
 'Algebra Fundamentals',
 'Master the basics of algebra: variables, expressions, equations, and inequalities. Perfect for building a solid math foundation.',
 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=600&q=80',
 9, 'beginner', 300, 1),

(2, 5, 2,
 'Introduction to Python Programming',
 'Learn Python from scratch! Variables, loops, functions, and your first projects. Become a coding superstar!',
 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=600&q=80',
 10, 'beginner', 350, 1),

(3, 6, 3,
 'Physics: Forces & Motion',
 'Explore Newton\'s Laws, gravity, velocity, and acceleration through real-world examples and experiments.',
 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=600&q=80',
 10, 'intermediate', 400, 1),

(4, 7, 3,
 'Chemistry: Atoms & The Periodic Table',
 'Dive into the building blocks of matter. Understand atomic structure, elements, and chemical bonding.',
 'https://images.unsplash.com/photo-1532094349884-543559081c68?w=600&q=80',
 10, 'intermediate', 400, 1),

(5, 8, 3,
 'Biology: Cell Biology & Life Processes',
 'Discover the microscopic world inside living things. Cell structure, mitosis, and essential life processes.',
 'https://images.unsplash.com/photo-1614935151651-0bea6508db6b?w=600&q=80',
 9, 'beginner', 300, 1),

(6, 4, 4,
 'World History: Ancient Civilizations',
 'Journey through time — Mesopotamia, Egypt, Greece, Rome. Understand how ancient worlds shaped today.',
 'https://images.unsplash.com/photo-1608742213509-815b97c30b36?w=600&q=80',
 8, 'beginner', 250, 1),

(7, 3, 4,
 'English: Creative Writing & Storytelling',
 'Unlock your inner author. Plot structure, character development, dialogue, and writing techniques that wow.',
 'https://images.unsplash.com/photo-1455390582262-044cdead277a?w=600&q=80',
 9, 'beginner', 250, 1),

(8, 1, 2,
 'Calculus: Limits & Derivatives',
 'Conquer calculus step by step. From limits to differentiation rules — make calculus click for you.',
 'https://images.unsplash.com/photo-1518133910546-b6c2fb7d79e3?w=600&q=80',
 12, 'advanced', 500, 1),

(9, 5, 2,
 'Web Development: HTML, CSS & JavaScript',
 'Build real websites from scratch! Learn how the internet actually works and create your own pages.',
 'https://images.unsplash.com/photo-1547658719-da2b51169166?w=600&q=80',
 11, 'intermediate', 450, 1),

(10, 2, 3,
 'Science: Earth & Space Systems',
 'Explore plate tectonics, weather systems, the solar system, and the universe beyond. Space is wild!',
 'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?w=600&q=80',
 8, 'beginner', 280, 1);

-- ============================================================
-- LESSONS (5-6 lessons per course)
-- ============================================================

-- Course 1: Algebra Fundamentals
INSERT INTO `lessons` (`id`,`course_id`,`title`,`description`,`video_url`,`video_duration`,`sort_order`,`xp_reward`) VALUES
(1,  1, 'What is Algebra? Variables & Expressions', 'Introduction to algebraic thinking and symbolic representation.', 'https://www.youtube.com/embed/NybHckSEQBI', 480, 1, 25),
(2,  1, 'Solving One-Step Equations',               'Learn to isolate variables using inverse operations.',             'https://www.youtube.com/embed/1q4QhPaKfGo', 510, 2, 25),
(3,  1, 'Two-Step Equations & Word Problems',       'Apply equations to solve real-world problems.',                   'https://www.youtube.com/embed/LDIiYKYvvdA', 540, 3, 25),
(4,  1, 'Linear Inequalities',                      'Understand inequality symbols and solve linear inequalities.',    'https://www.youtube.com/embed/VgDe_D8ojxw', 490, 4, 25),
(5,  1, 'Graphing Linear Equations',                'Plot equations on coordinate planes, slope and intercept.',      'https://www.youtube.com/embed/2UrcUfBizyw', 600, 5, 30),
(6,  1, 'Systems of Equations',                     'Solve systems using substitution and elimination methods.',       'https://www.youtube.com/embed/vA-55wZtLeE', 630, 6, 30);

-- Course 2: Python Programming
INSERT INTO `lessons` (`id`,`course_id`,`title`,`description`,`video_url`,`video_duration`,`sort_order`,`xp_reward`) VALUES
(7,  2, 'Python Setup & Your First Program',        'Install Python, run Hello World, understand the REPL.',          'https://www.youtube.com/embed/_uQrJ0TkZlc', 720, 1, 30),
(8,  2, 'Variables, Data Types & Operators',        'Store and manipulate data using Python variables.',              'https://www.youtube.com/embed/Z1Yd7upQsXY', 660, 2, 30),
(9,  2, 'Conditional Statements: if/elif/else',     'Make decisions in code with boolean logic.',                     'https://www.youtube.com/embed/AWek49wXGzI', 590, 3, 25),
(10, 2, 'Loops: for and while',                     'Automate repetition with powerful loop structures.',             'https://www.youtube.com/embed/6iF8Xb7Z3wQ', 650, 4, 25),
(11, 2, 'Functions & Scope',                        'Write reusable blocks of code with functions.',                  'https://www.youtube.com/embed/9Os0o3wzS_I', 700, 5, 30),
(12, 2, 'Lists, Tuples & Dictionaries',             'Master Python\'s core data structures.',                        'https://www.youtube.com/embed/W8KRzm-HUcc', 780, 6, 35);

-- Course 3: Physics Forces & Motion
INSERT INTO `lessons` (`id`,`course_id`,`title`,`description`,`video_url`,`video_duration`,`sort_order`,`xp_reward`) VALUES
(13, 3, 'Introduction to Forces',                   'What is a force? Contact vs. non-contact forces.',               'https://www.youtube.com/embed/JJLJ4LZAGEY', 520, 1, 30),
(14, 3, 'Newton\'s First Law: Inertia',             'Objects in motion stay in motion — understand inertia.',         'https://www.youtube.com/embed/kKKM8Y-u7ds', 540, 2, 30),
(15, 3, 'Newton\'s Second Law: F = ma',             'Force, mass, and acceleration relationships.',                   'https://www.youtube.com/embed/fvTTefBqjq8', 580, 3, 35),
(16, 3, 'Newton\'s Third Law: Action & Reaction',   'Every action has an equal and opposite reaction.',               'https://www.youtube.com/embed/By-ggTfeuJU', 500, 4, 30),
(17, 3, 'Gravity & Free Fall',                      'Understanding gravitational force and free-fall motion.',        'https://www.youtube.com/embed/E43-CfukEgs', 610, 5, 35),
(18, 3, 'Velocity, Speed & Acceleration',           'Distinguish between scalar and vector motion quantities.',       'https://www.youtube.com/embed/oRKxmXwLvUU', 570, 6, 35);

-- Course 4: Chemistry
INSERT INTO `lessons` (`id`,`course_id`,`title`,`description`,`video_url`,`video_duration`,`sort_order`,`xp_reward`) VALUES
(19, 4, 'What is an Atom?',                         'Protons, neutrons, electrons — atomic structure basics.',        'https://www.youtube.com/embed/7WoNn1sqp2k', 490, 1, 30),
(20, 4, 'The Periodic Table Explained',             'How to read and use the periodic table like a pro.',             'https://www.youtube.com/embed/0RRVV4Diomg', 720, 2, 35),
(21, 4, 'Elements, Compounds & Mixtures',           'Distinguish between pure substances and mixtures.',              'https://www.youtube.com/embed/VB4BKnJtues', 550, 3, 30),
(22, 4, 'Chemical Bonding: Ionic & Covalent',       'How atoms join together to form molecules.',                     'https://www.youtube.com/embed/QXT4OLXYDIE', 620, 4, 35),
(23, 4, 'Chemical Reactions & Equations',           'Write and balance chemical equations.',                          'https://www.youtube.com/embed/SjQG3rKSZUQ', 680, 5, 40),
(24, 4, 'Acids, Bases & pH Scale',                  'Understand pH, neutralization, and common acids and bases.',     'https://www.youtube.com/embed/LS67vS10O5Y', 590, 6, 35);

-- Course 5: Biology
INSERT INTO `lessons` (`id`,`course_id`,`title`,`description`,`video_url`,`video_duration`,`sort_order`,`xp_reward`) VALUES
(25, 5, 'The Cell: Unit of Life',                   'Plant vs. animal cells, organelles and their functions.',        'https://www.youtube.com/embed/URUJD5NEXC8', 560, 1, 25),
(26, 5, 'Cell Membrane & Transport',                'Osmosis, diffusion, active and passive transport.',              'https://www.youtube.com/embed/tnCBKGPMCzk', 540, 2, 25),
(27, 5, 'DNA: The Blueprint of Life',               'Structure of DNA, base pairs, and genetic information.',         'https://www.youtube.com/embed/TNKWgcFPHqw', 620, 3, 30),
(28, 5, 'Cell Division: Mitosis',                   'Phases of mitosis and why cell division is essential.',          'https://www.youtube.com/embed/f-ldPgEfAHI', 680, 4, 30),
(29, 5, 'Photosynthesis',                           'How plants make food from sunlight, water and CO2.',             'https://www.youtube.com/embed/g78utcLQrJ4', 590, 5, 25),
(30, 5, 'Cellular Respiration',                     'How cells release energy from glucose — ATP production.',        'https://www.youtube.com/embed/Gh2P5CmCC0M', 640, 6, 30);

-- Course 6: World History
INSERT INTO `lessons` (`id`,`course_id`,`title`,`description`,`video_url`,`video_duration`,`sort_order`,`xp_reward`) VALUES
(31, 6, 'Mesopotamia: The Cradle of Civilization',  'Sumerians, writing, ziggurats — the world\'s first cities.',     'https://www.youtube.com/embed/sohXPx_XZ6Y', 500, 1, 20),
(32, 6, 'Ancient Egypt: Pharaohs & Pyramids',       'Egyptian society, mummies, hieroglyphics and the Nile.',         'https://www.youtube.com/embed/pKlpLn9pHSQ', 540, 2, 20),
(33, 6, 'Ancient Greece: Democracy & Philosophy',   'Athens, Sparta, philosophy, and the birth of democracy.',        'https://www.youtube.com/embed/MjCHzPGPDZs', 570, 3, 25),
(34, 6, 'The Roman Empire',                         'Rise and fall of Rome, Roman engineering and law.',              'https://www.youtube.com/embed/wOO1YrmBt-U', 610, 4, 25),
(35, 6, 'Ancient India & China',                    'The Indus Valley, Han Dynasty, Silk Road, and early empires.',   'https://www.youtube.com/embed/pgZXVH6otOw', 590, 5, 25);

-- Course 7: Creative Writing
INSERT INTO `lessons` (`id`,`course_id`,`title`,`description`,`video_url`,`video_duration`,`sort_order`,`xp_reward`) VALUES
(36, 7, 'Story Structure: The 3-Act Framework',     'Beginning, middle, end — and why this formula works.',           'https://www.youtube.com/embed/9h3NNsHB83s', 480, 1, 20),
(37, 7, 'Creating Compelling Characters',           'Give your characters depth, flaws, and believable motivations.', 'https://www.youtube.com/embed/UOIwRSKsc80', 510, 2, 20),
(38, 7, 'Writing Dialogue Like a Pro',              'Make characters talk naturally — show don\'t tell.',             'https://www.youtube.com/embed/a2qHkTnW6TM', 490, 3, 20),
(39, 7, 'Setting & World Building',                 'Create vivid settings that make readers feel present.',          'https://www.youtube.com/embed/BNP4FvL2Hkk', 520, 4, 20),
(40, 7, 'Point of View & Narrative Voice',          'First, second, third person — choosing the right lens.',         'https://www.youtube.com/embed/kVy3qCFRfvY', 500, 5, 20),
(41, 7, 'Editing & Polishing Your Writing',         'Self-editing techniques to sharpen and elevate your prose.',     'https://www.youtube.com/embed/M5bEivOBGP4', 460, 6, 20);

-- Course 8: Calculus
INSERT INTO `lessons` (`id`,`course_id`,`title`,`description`,`video_url`,`video_duration`,`sort_order`,`xp_reward`) VALUES
(42, 8, 'Introduction to Limits',                   'The concept of a limit and how to evaluate them.',               'https://www.youtube.com/embed/riXcZT2ICjA', 720, 1, 40),
(43, 8, 'Limit Laws & Continuity',                  'Apply limit laws and understand function continuity.',           'https://www.youtube.com/embed/kfF40MiS7zA', 740, 2, 40),
(44, 8, 'The Derivative: Definition',               'Derivative as rate of change and the formal definition.',        'https://www.youtube.com/embed/rAof9Ld5sOg', 780, 3, 45),
(45, 8, 'Differentiation Rules',                    'Power, product, quotient, and chain rules.',                     'https://www.youtube.com/embed/IvLpN1G1Ncg', 800, 4, 45),
(46, 8, 'Derivatives of Trig Functions',            'Differentiating sine, cosine, and other trig functions.',        'https://www.youtube.com/embed/l7QBGQcB9Lk', 750, 5, 40),
(47, 8, 'Applications of Derivatives',              'Using derivatives to find maxima, minima, and rates of change.', 'https://www.youtube.com/embed/KKpDhSJOCIs', 820, 6, 50);

-- Course 9: Web Development
INSERT INTO `lessons` (`id`,`course_id`,`title`,`description`,`video_url`,`video_duration`,`sort_order`,`xp_reward`) VALUES
(48, 9, 'How the Web Works: HTTP & Browsers',       'DNS, HTTP requests, how browsers render pages.',                 'https://www.youtube.com/embed/hJHvdBlSxug', 540, 1, 35),
(49, 9, 'HTML: Structure & Semantic Elements',      'Build the skeleton of web pages with semantic HTML5.',           'https://www.youtube.com/embed/qz0aGYrrlhU', 680, 2, 35),
(50, 9, 'CSS: Styling & Layouts',                   'Colors, fonts, box model, Flexbox, and Grid.',                   'https://www.youtube.com/embed/1Rs2ND1ryYc', 780, 3, 40),
(51, 9, 'JavaScript: DOM Manipulation',             'Select and modify HTML elements with JS.',                       'https://www.youtube.com/embed/5fb2aPlgoys', 720, 4, 40),
(52, 9, 'JavaScript: Events & Interactivity',       'Handle clicks, inputs, forms and make pages interactive.',       'https://www.youtube.com/embed/jS4aFq5-91M', 690, 5, 40),
(53, 9, 'Build Your First Responsive Website',      'Combine HTML, CSS, JS into a complete responsive site.',         'https://www.youtube.com/embed/mU6anWqZJcc', 900, 6, 45);

-- Course 10: Earth & Space
INSERT INTO `lessons` (`id`,`course_id`,`title`,`description`,`video_url`,`video_duration`,`sort_order`,`xp_reward`) VALUES
(54, 10, 'Earth\'s Structure & Plate Tectonics',    'Layers of Earth, tectonic plates, earthquakes and volcanoes.',   'https://www.youtube.com/embed/kwfNGatxUJI', 560, 1, 22),
(55, 10, 'The Rock Cycle & Minerals',               'Igneous, sedimentary, metamorphic rocks and how they form.',     'https://www.youtube.com/embed/E_4bqyJCSOc', 530, 2, 22),
(56, 10, 'Earth\'s Atmosphere & Weather',           'Layers of atmosphere, weather patterns and climate basics.',     'https://www.youtube.com/embed/UXl4Mz3KgIQ', 570, 3, 22),
(57, 10, 'The Solar System',                        'Planets, moons, asteroids, and what makes each world unique.',   'https://www.youtube.com/embed/libKVRa01L8', 640, 4, 25),
(58, 10, 'Stars, Galaxies & The Universe',          'Life cycle of stars, the Milky Way, and the expanding universe.','https://www.youtube.com/embed/HdPzOWlLrbE', 690, 5, 25),
(59, 10, 'Space Exploration & Future Missions',     'History of space missions and humanity\'s future in space.',     'https://www.youtube.com/embed/WpnIW3tMBkA', 610, 6, 28);

-- ============================================================
-- COURSE ENROLLMENTS
-- ============================================================
INSERT INTO `course_enrollments` (`user_id`,`course_id`,`enrolled_at`,`completed_at`,`exam_unlocked`,`exam_passed`,`exam_score`) VALUES
-- Alex Ng (top student - multiple completions)
(6, 1, DATE_SUB(NOW(),INTERVAL 45 DAY), DATE_SUB(NOW(),INTERVAL 30 DAY), 1, 1, 95),
(6, 2, DATE_SUB(NOW(),INTERVAL 40 DAY), DATE_SUB(NOW(),INTERVAL 20 DAY), 1, 1, 88),
(6, 5, DATE_SUB(NOW(),INTERVAL 35 DAY), NULL, 0, 0, NULL),
(6, 9, DATE_SUB(NOW(),INTERVAL 15 DAY), NULL, 0, 0, NULL),

-- Zara Khan
(7, 1, DATE_SUB(NOW(),INTERVAL 30 DAY), DATE_SUB(NOW(),INTERVAL 10 DAY), 1, 1, 91),
(7, 3, DATE_SUB(NOW(),INTERVAL 25 DAY), NULL, 0, 0, NULL),
(7, 7, DATE_SUB(NOW(),INTERVAL 20 DAY), DATE_SUB(NOW(),INTERVAL 5 DAY), 1, 1, 85),

-- Ethan Lee
(8, 2, DATE_SUB(NOW(),INTERVAL 50 DAY), DATE_SUB(NOW(),INTERVAL 35 DAY), 1, 1, 78),
(8, 8, DATE_SUB(NOW(),INTERVAL 30 DAY), NULL, 0, 0, NULL),
(8, 9, DATE_SUB(NOW(),INTERVAL 20 DAY), NULL, 0, 0, NULL),

-- Maya Raj
(9, 5, DATE_SUB(NOW(),INTERVAL 40 DAY), DATE_SUB(NOW(),INTERVAL 18 DAY), 1, 1, 93),
(9, 4, DATE_SUB(NOW(),INTERVAL 25 DAY), NULL, 0, 0, NULL),

-- Lucas Tan
(10, 2, DATE_SUB(NOW(),INTERVAL 35 DAY), DATE_SUB(NOW(),INTERVAL 15 DAY), 1, 0, 62),
(10, 9, DATE_SUB(NOW(),INTERVAL 20 DAY), NULL, 0, 0, NULL),

-- Sofia Kim
(11, 7, DATE_SUB(NOW(),INTERVAL 28 DAY), DATE_SUB(NOW(),INTERVAL 8 DAY), 1, 1, 87),
(11, 6, DATE_SUB(NOW(),INTERVAL 15 DAY), NULL, 0, 0, NULL),

-- Ryan Ahmad
(12, 3, DATE_SUB(NOW(),INTERVAL 30 DAY), NULL, 0, 0, NULL),
(12, 4, DATE_SUB(NOW(),INTERVAL 20 DAY), NULL, 0, 0, NULL),

-- Bella Ong
(13, 1, DATE_SUB(NOW(),INTERVAL 25 DAY), DATE_SUB(NOW(),INTERVAL 10 DAY), 1, 1, 82),
(13, 5, DATE_SUB(NOW(),INTERVAL 15 DAY), NULL, 0, 0, NULL),

-- Aiden Wu
(14, 2, DATE_SUB(NOW(),INTERVAL 22 DAY), NULL, 0, 0, NULL),

-- Nadia Jose
(15, 7, DATE_SUB(NOW(),INTERVAL 18 DAY), NULL, 0, 0, NULL),
(15, 6, DATE_SUB(NOW(),INTERVAL 12 DAY), NULL, 0, 0, NULL),

-- Various other students enrolled in courses
(16, 1, DATE_SUB(NOW(),INTERVAL 20 DAY), NULL, 0, 0, NULL),
(17, 5, DATE_SUB(NOW(),INTERVAL 15 DAY), NULL, 0, 0, NULL),
(17, 10, DATE_SUB(NOW(),INTERVAL 10 DAY), NULL, 0, 0, NULL),
(18, 8, DATE_SUB(NOW(),INTERVAL 25 DAY), NULL, 0, 0, NULL),
(19, 1, DATE_SUB(NOW(),INTERVAL 14 DAY), NULL, 0, 0, NULL),
(20, 3, DATE_SUB(NOW(),INTERVAL 12 DAY), NULL, 0, 0, NULL),
(21, 5, DATE_SUB(NOW(),INTERVAL 10 DAY), NULL, 0, 0, NULL),
(22, 10, DATE_SUB(NOW(),INTERVAL 8 DAY), NULL, 0, 0, NULL),
(23, 6, DATE_SUB(NOW(),INTERVAL 7 DAY), NULL, 0, 0, NULL),
(24, 2, DATE_SUB(NOW(),INTERVAL 6 DAY), NULL, 0, 0, NULL),
(25, 9, DATE_SUB(NOW(),INTERVAL 5 DAY), NULL, 0, 0, NULL),
(26, 1, DATE_SUB(NOW(),INTERVAL 4 DAY), NULL, 0, 0, NULL),
(27, 7, DATE_SUB(NOW(),INTERVAL 3 DAY), NULL, 0, 0, NULL),
(32, 1, DATE_SUB(NOW(),INTERVAL 3 DAY), NULL, 0, 0, NULL),
(33, 5, DATE_SUB(NOW(),INTERVAL 2 DAY), NULL, 0, 0, NULL),
(34, 10, DATE_SUB(NOW(),INTERVAL 1 DAY), NULL, 0, 0, NULL);

-- ============================================================
-- LESSON PROGRESS (realistic watch data)
-- ============================================================
-- Alex Ng - Course 1 (completed), Course 2 (completed)
INSERT INTO `lesson_progress` (`user_id`,`lesson_id`,`watch_percent`,`is_completed`,`completed_at`,`xp_awarded`) VALUES
(6,1,100,1,DATE_SUB(NOW(),INTERVAL 44 DAY),1),(6,2,100,1,DATE_SUB(NOW(),INTERVAL 43 DAY),1),
(6,3,100,1,DATE_SUB(NOW(),INTERVAL 42 DAY),1),(6,4,100,1,DATE_SUB(NOW(),INTERVAL 41 DAY),1),
(6,5,100,1,DATE_SUB(NOW(),INTERVAL 40 DAY),1),(6,6,100,1,DATE_SUB(NOW(),INTERVAL 39 DAY),1),
(6,7,100,1,DATE_SUB(NOW(),INTERVAL 38 DAY),1),(6,8,100,1,DATE_SUB(NOW(),INTERVAL 37 DAY),1),
(6,9,100,1,DATE_SUB(NOW(),INTERVAL 36 DAY),1),(6,10,100,1,DATE_SUB(NOW(),INTERVAL 35 DAY),1),
(6,11,100,1,DATE_SUB(NOW(),INTERVAL 34 DAY),1),(6,12,100,1,DATE_SUB(NOW(),INTERVAL 33 DAY),1),
-- Alex Ng - Course 5 partial (4/6 lessons done)
(6,25,100,1,DATE_SUB(NOW(),INTERVAL 14 DAY),1),(6,26,100,1,DATE_SUB(NOW(),INTERVAL 13 DAY),1),
(6,27,100,1,DATE_SUB(NOW(),INTERVAL 12 DAY),1),(6,28,75,0,NULL,0),
-- Alex Ng - Course 9 partial (2/6 done)
(6,48,100,1,DATE_SUB(NOW(),INTERVAL 10 DAY),1),(6,49,60,0,NULL,0),

-- Zara Khan - Course 1 completed
(7,1,100,1,DATE_SUB(NOW(),INTERVAL 29 DAY),1),(7,2,100,1,DATE_SUB(NOW(),INTERVAL 28 DAY),1),
(7,3,100,1,DATE_SUB(NOW(),INTERVAL 27 DAY),1),(7,4,100,1,DATE_SUB(NOW(),INTERVAL 26 DAY),1),
(7,5,100,1,DATE_SUB(NOW(),INTERVAL 25 DAY),1),(7,6,100,1,DATE_SUB(NOW(),INTERVAL 24 DAY),1),
-- Zara Khan - Course 3 partial
(7,13,100,1,DATE_SUB(NOW(),INTERVAL 12 DAY),1),(7,14,80,0,NULL,0),
-- Zara Khan - Course 7 completed
(7,36,100,1,DATE_SUB(NOW(),INTERVAL 19 DAY),1),(7,37,100,1,DATE_SUB(NOW(),INTERVAL 18 DAY),1),
(7,38,100,1,DATE_SUB(NOW(),INTERVAL 17 DAY),1),(7,39,100,1,DATE_SUB(NOW(),INTERVAL 16 DAY),1),
(7,40,100,1,DATE_SUB(NOW(),INTERVAL 15 DAY),1),(7,41,100,1,DATE_SUB(NOW(),INTERVAL 14 DAY),1),

-- Ethan Lee - Course 2 completed
(8,7,100,1,DATE_SUB(NOW(),INTERVAL 49 DAY),1),(8,8,100,1,DATE_SUB(NOW(),INTERVAL 48 DAY),1),
(8,9,100,1,DATE_SUB(NOW(),INTERVAL 47 DAY),1),(8,10,100,1,DATE_SUB(NOW(),INTERVAL 46 DAY),1),
(8,11,100,1,DATE_SUB(NOW(),INTERVAL 45 DAY),1),(8,12,100,1,DATE_SUB(NOW(),INTERVAL 44 DAY),1),
-- Ethan Lee - Course 8 partial (advanced)
(8,42,100,1,DATE_SUB(NOW(),INTERVAL 20 DAY),1),(8,43,100,1,DATE_SUB(NOW(),INTERVAL 18 DAY),1),
(8,44,90,0,NULL,0),
-- Ethan Lee - Course 9 partial
(8,48,100,1,DATE_SUB(NOW(),INTERVAL 15 DAY),1),(8,49,100,1,DATE_SUB(NOW(),INTERVAL 12 DAY),1),
(8,50,45,0,NULL,0),

-- Maya Raj - Course 5 completed
(9,25,100,1,DATE_SUB(NOW(),INTERVAL 39 DAY),1),(9,26,100,1,DATE_SUB(NOW(),INTERVAL 37 DAY),1),
(9,27,100,1,DATE_SUB(NOW(),INTERVAL 35 DAY),1),(9,28,100,1,DATE_SUB(NOW(),INTERVAL 32 DAY),1),
(9,29,100,1,DATE_SUB(NOW(),INTERVAL 29 DAY),1),(9,30,100,1,DATE_SUB(NOW(),INTERVAL 26 DAY),1),
-- Maya Raj - Course 4 partial
(9,19,100,1,DATE_SUB(NOW(),INTERVAL 15 DAY),1),(9,20,100,1,DATE_SUB(NOW(),INTERVAL 12 DAY),1),
(9,21,70,0,NULL,0),

-- Lucas Tan - Course 2 completed (but failed exam)
(10,7,100,1,DATE_SUB(NOW(),INTERVAL 34 DAY),1),(10,8,100,1,DATE_SUB(NOW(),INTERVAL 32 DAY),1),
(10,9,100,1,DATE_SUB(NOW(),INTERVAL 30 DAY),1),(10,10,100,1,DATE_SUB(NOW(),INTERVAL 28 DAY),1),
(10,11,100,1,DATE_SUB(NOW(),INTERVAL 26 DAY),1),(10,12,100,1,DATE_SUB(NOW(),INTERVAL 24 DAY),1),
-- Lucas Tan - Course 9 partial
(10,48,100,1,DATE_SUB(NOW(),INTERVAL 12 DAY),1),(10,49,50,0,NULL,0),

-- Sofia Kim - Course 7 completed
(11,36,100,1,DATE_SUB(NOW(),INTERVAL 27 DAY),1),(11,37,100,1,DATE_SUB(NOW(),INTERVAL 25 DAY),1),
(11,38,100,1,DATE_SUB(NOW(),INTERVAL 23 DAY),1),(11,39,100,1,DATE_SUB(NOW(),INTERVAL 21 DAY),1),
(11,40,100,1,DATE_SUB(NOW(),INTERVAL 19 DAY),1),(11,41,100,1,DATE_SUB(NOW(),INTERVAL 17 DAY),1),
-- Sofia Kim - Course 6 partial
(11,31,100,1,DATE_SUB(NOW(),INTERVAL 10 DAY),1),(11,32,80,0,NULL,0),

-- Bella Ong - Course 1 completed
(13,1,100,1,DATE_SUB(NOW(),INTERVAL 24 DAY),1),(13,2,100,1,DATE_SUB(NOW(),INTERVAL 23 DAY),1),
(13,3,100,1,DATE_SUB(NOW(),INTERVAL 22 DAY),1),(13,4,100,1,DATE_SUB(NOW(),INTERVAL 21 DAY),1),
(13,5,100,1,DATE_SUB(NOW(),INTERVAL 20 DAY),1),(13,6,100,1,DATE_SUB(NOW(),INTERVAL 19 DAY),1),
-- Bella Ong - Course 5 partial
(13,25,100,1,DATE_SUB(NOW(),INTERVAL 10 DAY),1),(13,26,65,0,NULL,0),

-- Various partial progress for other students
(12,13,100,1,DATE_SUB(NOW(),INTERVAL 15 DAY),1),(12,14,100,1,DATE_SUB(NOW(),INTERVAL 12 DAY),1),(12,15,40,0,NULL,0),
(14,7,100,1,DATE_SUB(NOW(),INTERVAL 10 DAY),1),(14,8,70,0,NULL,0),
(15,36,100,1,DATE_SUB(NOW(),INTERVAL 8 DAY),1),(15,37,55,0,NULL,0),
(16,1,100,1,DATE_SUB(NOW(),INTERVAL 6 DAY),1),(16,2,30,0,NULL,0),
(17,25,100,1,DATE_SUB(NOW(),INTERVAL 5 DAY),1),
(19,1,100,1,DATE_SUB(NOW(),INTERVAL 4 DAY),1),(19,2,20,0,NULL,0),
(21,25,60,0,NULL,0),
(23,31,100,1,DATE_SUB(NOW(),INTERVAL 3 DAY),1),
(24,7,40,0,NULL,0),
(32,1,100,1,DATE_SUB(NOW(),INTERVAL 2 DAY),1),(32,2,100,1,DATE_SUB(NOW(),INTERVAL 1 DAY),1),(32,3,50,0,NULL,0);

-- ============================================================
-- XP TRANSACTIONS (for top students)
-- ============================================================
INSERT INTO `xp_transactions` (`user_id`,`amount`,`reason`,`ref_type`,`ref_id`,`created_at`) VALUES
-- Alex Ng xp log
(6, 25, 'Lesson completed: Variables & Expressions', 'lesson', 1, DATE_SUB(NOW(),INTERVAL 44 DAY)),
(6, 25, 'Lesson completed: One-Step Equations', 'lesson', 2, DATE_SUB(NOW(),INTERVAL 43 DAY)),
(6, 25, 'Lesson completed: Two-Step Equations', 'lesson', 3, DATE_SUB(NOW(),INTERVAL 42 DAY)),
(6, 25, 'Lesson completed: Linear Inequalities', 'lesson', 4, DATE_SUB(NOW(),INTERVAL 41 DAY)),
(6, 30, 'Lesson completed: Graphing Linear Equations', 'lesson', 5, DATE_SUB(NOW(),INTERVAL 40 DAY)),
(6, 30, 'Lesson completed: Systems of Equations', 'lesson', 6, DATE_SUB(NOW(),INTERVAL 39 DAY)),
(6, 300,'Course completed: Algebra Fundamentals', 'exam', 1, DATE_SUB(NOW(),INTERVAL 30 DAY)),
(6, 100,'Achievement: On Fire (7-day streak)', 'achievement', 2, DATE_SUB(NOW(),INTERVAL 35 DAY)),
(6, 500,'Achievement: Elite Student (5000 XP)', 'achievement', 7, DATE_SUB(NOW(),INTERVAL 20 DAY)),
-- Zara, Ethan, Maya aggregated bonuses
(7, 100, '7-day streak bonus', 'streak', NULL, DATE_SUB(NOW(),INTERVAL 20 DAY)),
(7, 250, 'Course completion XP: Algebra', 'exam', 1, DATE_SUB(NOW(),INTERVAL 10 DAY)),
(8, 350, 'Course completion XP: Python', 'exam', 2, DATE_SUB(NOW(),INTERVAL 35 DAY)),
(9, 300, 'Course completion XP: Cell Biology', 'exam', 5, DATE_SUB(NOW(),INTERVAL 18 DAY)),
(9, 200, 'Achievement: Exam Ace (93%)', 'achievement', 9, DATE_SUB(NOW(),INTERVAL 18 DAY)),
(11, 250, 'Course completion XP: Creative Writing', 'exam', 7, DATE_SUB(NOW(),INTERVAL 8 DAY)),
(13, 300, 'Course completion XP: Algebra', 'exam', 1, DATE_SUB(NOW(),INTERVAL 10 DAY));

-- ============================================================
-- USER ACHIEVEMENTS
-- ============================================================
INSERT INTO `user_achievements` (`user_id`,`achievement_id`,`earned_at`) VALUES
-- Alex Ng
(6, 1, DATE_SUB(NOW(),INTERVAL 44 DAY)),  -- First Step
(6, 2, DATE_SUB(NOW(),INTERVAL 35 DAY)),  -- On Fire
(6, 3, DATE_SUB(NOW(),INTERVAL 10 DAY)),  -- Unstoppable (30 days)
(6, 4, DATE_SUB(NOW(),INTERVAL 40 DAY)),  -- Quick Learner
(6, 5, DATE_SUB(NOW(),INTERVAL 20 DAY)),  -- Scholar
(6, 6, DATE_SUB(NOW(),INTERVAL 38 DAY)),  -- XP Hunter 1k
(6, 7, DATE_SUB(NOW(),INTERVAL 20 DAY)),  -- Elite 5k
(6, 8, DATE_SUB(NOW(),INTERVAL 30 DAY)),  -- Course Champion
(6, 9, DATE_SUB(NOW(),INTERVAL 30 DAY)),  -- Exam Ace
-- Zara Khan
(7, 1, DATE_SUB(NOW(),INTERVAL 29 DAY)),
(7, 2, DATE_SUB(NOW(),INTERVAL 21 DAY)),
(7, 4, DATE_SUB(NOW(),INTERVAL 14 DAY)),
(7, 8, DATE_SUB(NOW(),INTERVAL 10 DAY)),
(7, 9, DATE_SUB(NOW(),INTERVAL 10 DAY)),
-- Maya Raj
(9, 1, DATE_SUB(NOW(),INTERVAL 39 DAY)),
(9, 4, DATE_SUB(NOW(),INTERVAL 30 DAY)),
(9, 6, DATE_SUB(NOW(),INTERVAL 25 DAY)),
(9, 8, DATE_SUB(NOW(),INTERVAL 18 DAY)),
(9, 9, DATE_SUB(NOW(),INTERVAL 18 DAY)),
-- Ethan Lee
(8, 1, DATE_SUB(NOW(),INTERVAL 49 DAY)),
(8, 2, DATE_SUB(NOW(),INTERVAL 30 DAY)),
(8, 4, DATE_SUB(NOW(),INTERVAL 44 DAY)),
(8, 8, DATE_SUB(NOW(),INTERVAL 35 DAY)),
-- Sofia Kim
(11, 1, DATE_SUB(NOW(),INTERVAL 27 DAY)),
(11, 4, DATE_SUB(NOW(),INTERVAL 18 DAY)),
(11, 8, DATE_SUB(NOW(),INTERVAL 8 DAY)),
-- Bella Ong
(13, 1, DATE_SUB(NOW(),INTERVAL 24 DAY)),
(13, 4, DATE_SUB(NOW(),INTERVAL 15 DAY)),
(13, 8, DATE_SUB(NOW(),INTERVAL 10 DAY)),
-- Smaller students - just first step
(10, 1, DATE_SUB(NOW(),INTERVAL 34 DAY)),
(12, 1, DATE_SUB(NOW(),INTERVAL 15 DAY)),
(14, 1, DATE_SUB(NOW(),INTERVAL 10 DAY)),
(15, 1, DATE_SUB(NOW(),INTERVAL 8 DAY)),
(16, 1, DATE_SUB(NOW(),INTERVAL 6 DAY)),
(17, 1, DATE_SUB(NOW(),INTERVAL 5 DAY)),
(23, 1, DATE_SUB(NOW(),INTERVAL 3 DAY)),
(32, 1, DATE_SUB(NOW(),INTERVAL 2 DAY));

-- ============================================================
-- STUDY SESSIONS (last 14 days for active students)
-- ============================================================
INSERT INTO `study_sessions` (`user_id`, `study_date`, `xp_earned`) VALUES
-- Alex Ng 28-day streak
(6, CURDATE(), 150),
(6, DATE_SUB(CURDATE(), INTERVAL 1 DAY), 120),
(6, DATE_SUB(CURDATE(), INTERVAL 2 DAY), 100),
(6, DATE_SUB(CURDATE(), INTERVAL 3 DAY), 90),
(6, DATE_SUB(CURDATE(), INTERVAL 4 DAY), 110),
(6, DATE_SUB(CURDATE(), INTERVAL 5 DAY), 80),
(6, DATE_SUB(CURDATE(), INTERVAL 6 DAY), 95),
(6, DATE_SUB(CURDATE(), INTERVAL 7 DAY), 70),
(6, DATE_SUB(CURDATE(), INTERVAL 8 DAY), 85),
(6, DATE_SUB(CURDATE(), INTERVAL 9 DAY), 60),
(6, DATE_SUB(CURDATE(), INTERVAL 10 DAY), 100),
(6, DATE_SUB(CURDATE(), INTERVAL 11 DAY), 75),
(6, DATE_SUB(CURDATE(), INTERVAL 12 DAY), 90),
(6, DATE_SUB(CURDATE(), INTERVAL 13 DAY), 55),

-- Zara Khan 21-day streak
(7, CURDATE(), 130),
(7, DATE_SUB(CURDATE(), INTERVAL 1 DAY), 110),
(7, DATE_SUB(CURDATE(), INTERVAL 2 DAY), 95),
(7, DATE_SUB(CURDATE(), INTERVAL 3 DAY), 80),
(7, DATE_SUB(CURDATE(), INTERVAL 4 DAY), 100),
(7, DATE_SUB(CURDATE(), INTERVAL 5 DAY), 70),
(7, DATE_SUB(CURDATE(), INTERVAL 6 DAY), 85),
(7, DATE_SUB(CURDATE(), INTERVAL 7 DAY), 60),

-- Maya Raj 18-day streak
(9, CURDATE(), 100),
(9, DATE_SUB(CURDATE(), INTERVAL 1 DAY), 90),
(9, DATE_SUB(CURDATE(), INTERVAL 2 DAY), 80),
(9, DATE_SUB(CURDATE(), INTERVAL 3 DAY), 70),
(9, DATE_SUB(CURDATE(), INTERVAL 4 DAY), 85),
(9, DATE_SUB(CURDATE(), INTERVAL 5 DAY), 65),

-- Sofia Kim 12-day streak
(11, CURDATE(), 80),
(11, DATE_SUB(CURDATE(), INTERVAL 1 DAY), 70),
(11, DATE_SUB(CURDATE(), INTERVAL 2 DAY), 60),
(11, DATE_SUB(CURDATE(), INTERVAL 3 DAY), 75),
(11, DATE_SUB(CURDATE(), INTERVAL 4 DAY), 55),

-- Others
(13, CURDATE(), 70),
(13, DATE_SUB(CURDATE(), INTERVAL 1 DAY), 60),
(13, DATE_SUB(CURDATE(), INTERVAL 2 DAY), 50),
(15, CURDATE(), 60),
(17, CURDATE(), 45),
(19, CURDATE(), 55),
(21, CURDATE(), 40),
(23, CURDATE(), 35),
(27, CURDATE(), 30),
(29, CURDATE(), 25),
(32, CURDATE(), 40),
(34, CURDATE(), 20);

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- SUMMARY
-- ============================================================
-- Tables: users, subjects, courses, lessons, lesson_progress,
--         course_enrollments, xp_transactions, achievements,
--         user_achievements, chat_sessions, chat_messages,
--         study_sessions
--
-- Seed Data:
--   - 35 users (1 admin, 4 teachers, 30 students)
--   - 8 subjects, 10 courses, 59 lessons
--   - 38 enrollments with varied completion status
--   - 80+ lesson progress records with realistic watch %
--   - 16 XP transactions
--   - 10 achievement types + 30+ user achievement records
--   - 40+ study session records
--
-- DEFAULT LOGIN (all users): Password123!
-- Admin: admin / admin@eduquest.edu
-- Demo Student: alex_ng / alex.ng@student.edu
-- ============================================================
