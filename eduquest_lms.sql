-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Mar 01, 2026 at 06:06 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `eduquest_lms`
--

-- --------------------------------------------------------

--
-- Table structure for table `achievements`
--

CREATE TABLE `achievements` (
  `id` tinyint(3) UNSIGNED NOT NULL,
  `name` varchar(80) NOT NULL,
  `description` varchar(255) NOT NULL,
  `icon` varchar(10) NOT NULL,
  `xp_bonus` smallint(5) UNSIGNED NOT NULL DEFAULT 0,
  `criteria` varchar(100) NOT NULL COMMENT 'e.g. streak_7, xp_1000, lessons_10'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `achievements`
--

INSERT INTO `achievements` (`id`, `name`, `description`, `icon`, `xp_bonus`, `criteria`) VALUES
(1, 'First Step', 'Complete your very first lesson', '👶', 10, 'lessons_1'),
(2, 'On Fire', 'Study 7 days in a row', '🔥', 100, 'streak_7'),
(3, 'Unstoppable', 'Study 30 days in a row', '🌟', 500, 'streak_30'),
(4, 'Quick Learner', 'Complete 10 lessons', '⚡', 50, 'lessons_10'),
(5, 'Scholar', 'Complete 50 lessons', '📚', 200, 'lessons_50'),
(6, 'XP Hunter', 'Earn 1000 total XP', '💎', 50, 'xp_1000'),
(7, 'Elite Student', 'Earn 5000 total XP', '👑', 250, 'xp_5000'),
(8, 'Course Champion', 'Complete your first course', '🏆', 150, 'courses_1'),
(9, 'Exam Ace', 'Pass an AI exam with 90%+ score', '🎓', 200, 'exam_90'),
(10, 'Polyglot', 'Take an exam in a non-English language', '🌐', 75, 'exam_multilang');

-- --------------------------------------------------------

--
-- Table structure for table `chat_messages`
--

CREATE TABLE `chat_messages` (
  `id` int(10) UNSIGNED NOT NULL,
  `session_id` int(10) UNSIGNED NOT NULL,
  `role` enum('user','assistant') NOT NULL,
  `content` text NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `chat_sessions`
--

CREATE TABLE `chat_sessions` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `course_id` int(10) UNSIGNED NOT NULL,
  `language` enum('English','Chinese','Tamil','Malay') NOT NULL DEFAULT 'English',
  `status` enum('active','completed','abandoned') NOT NULL DEFAULT 'active',
  `score` tinyint(3) UNSIGNED DEFAULT NULL,
  `started_at` datetime NOT NULL DEFAULT current_timestamp(),
  `ended_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `chat_sessions`
--

INSERT INTO `chat_sessions` (`id`, `user_id`, `course_id`, `language`, `status`, `score`, `started_at`, `ended_at`) VALUES
(1, 6, 2, 'English', 'active', NULL, '2026-02-28 17:35:45', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `courses`
--

CREATE TABLE `courses` (
  `id` int(10) UNSIGNED NOT NULL,
  `subject_id` tinyint(3) UNSIGNED NOT NULL,
  `teacher_id` int(10) UNSIGNED NOT NULL,
  `title` varchar(150) NOT NULL,
  `description` text NOT NULL,
  `thumbnail_url` varchar(512) NOT NULL DEFAULT '',
  `grade_level` tinyint(3) UNSIGNED NOT NULL DEFAULT 10,
  `difficulty` enum('beginner','intermediate','advanced') NOT NULL DEFAULT 'beginner',
  `xp_reward` smallint(5) UNSIGNED NOT NULL DEFAULT 100 COMMENT 'XP earned on course completion',
  `is_published` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `courses`
--

INSERT INTO `courses` (`id`, `subject_id`, `teacher_id`, `title`, `description`, `thumbnail_url`, `grade_level`, `difficulty`, `xp_reward`, `is_published`, `created_at`) VALUES
(1, 1, 2, 'Algebra Fundamentals', 'Master the basics of algebra: variables, expressions, equations, and inequalities. Perfect for building a solid math foundation.', 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=600&q=80', 9, 'beginner', 300, 1, '2026-02-28 17:08:34'),
(2, 5, 2, 'Introduction to Python Programming', 'Learn Python from scratch! Variables, loops, functions, and your first projects. Become a coding superstar!', 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=600&q=80', 10, 'beginner', 350, 1, '2026-02-28 17:08:34'),
(3, 6, 3, 'Physics: Forces & Motion', 'Explore Newton\'s Laws, gravity, velocity, and acceleration through real-world examples and experiments.', 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=600&q=80', 10, 'intermediate', 400, 1, '2026-02-28 17:08:34'),
(4, 7, 3, 'Chemistry: Atoms & The Periodic Table', 'Dive into the building blocks of matter. Understand atomic structure, elements, and chemical bonding.', 'https://images.unsplash.com/photo-1532094349884-543559081c68?w=600&q=80', 10, 'intermediate', 400, 1, '2026-02-28 17:08:34'),
(5, 8, 3, 'Biology: Cell Biology & Life Processes', 'Discover the microscopic world inside living things. Cell structure, mitosis, and essential life processes.', 'https://images.unsplash.com/photo-1614935151651-0bea6508db6b?w=600&q=80', 9, 'beginner', 300, 1, '2026-02-28 17:08:34'),
(6, 4, 4, 'World History: Ancient Civilizations', 'Journey through time — Mesopotamia, Egypt, Greece, Rome. Understand how ancient worlds shaped today.', 'https://images.unsplash.com/photo-1608742213509-815b97c30b36?w=600&q=80', 8, 'beginner', 250, 1, '2026-02-28 17:08:34'),
(7, 3, 4, 'English: Creative Writing & Storytelling', 'Unlock your inner author. Plot structure, character development, dialogue, and writing techniques that wow.', 'https://images.unsplash.com/photo-1455390582262-044cdead277a?w=600&q=80', 9, 'beginner', 250, 1, '2026-02-28 17:08:34'),
(8, 1, 2, 'Calculus: Limits & Derivatives', 'Conquer calculus step by step. From limits to differentiation rules — make calculus click for you.', 'https://images.unsplash.com/photo-1518133910546-b6c2fb7d79e3?w=600&q=80', 12, 'advanced', 500, 1, '2026-02-28 17:08:34'),
(9, 5, 2, 'Web Development: HTML, CSS & JavaScript', 'Build real websites from scratch! Learn how the internet actually works and create your own pages.', 'https://images.unsplash.com/photo-1547658719-da2b51169166?w=600&q=80', 11, 'intermediate', 450, 1, '2026-02-28 17:08:34'),
(10, 2, 3, 'Science: Earth & Space Systems', 'Explore plate tectonics, weather systems, the solar system, and the universe beyond. Space is wild!', 'https://images.unsplash.com/photo-1446776811953-b23d57bd21aa?w=600&q=80', 8, 'beginner', 280, 1, '2026-02-28 17:08:34'),
(11, 4, 4, 'Malaysian History: From Melaka to Merdeka', 'Explore the major events and figures in Malaysian history, from the Sultanate of Melaka to independence and nation-building.', 'https://www.youtube.com/watch?v=1HRPIlg0QIk', 10, 'intermediate', 310, 1, '2026-03-19 00:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `course_enrollments`
--

CREATE TABLE `course_enrollments` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `course_id` int(10) UNSIGNED NOT NULL,
  `enrolled_at` datetime NOT NULL DEFAULT current_timestamp(),
  `completed_at` datetime DEFAULT NULL,
  `exam_unlocked` tinyint(1) NOT NULL DEFAULT 0,
  `exam_passed` tinyint(1) NOT NULL DEFAULT 0,
  `exam_score` tinyint(3) UNSIGNED DEFAULT NULL COMMENT '0-100'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `course_enrollments`
--

INSERT INTO `course_enrollments` (`id`, `user_id`, `course_id`, `enrolled_at`, `completed_at`, `exam_unlocked`, `exam_passed`, `exam_score`) VALUES
(1, 6, 1, '2026-01-14 17:08:34', '2026-01-29 17:08:34', 1, 1, 95),
(2, 6, 2, '2026-01-19 17:08:34', '2026-02-08 17:08:34', 1, 1, 88),
(3, 6, 5, '2026-01-24 17:08:34', NULL, 0, 0, NULL),
(4, 6, 9, '2026-02-13 17:08:34', NULL, 0, 0, NULL),
(5, 7, 1, '2026-01-29 17:08:34', '2026-02-18 17:08:34', 1, 1, 91),
(6, 7, 3, '2026-02-03 17:08:34', NULL, 0, 0, NULL),
(7, 7, 7, '2026-02-08 17:08:34', '2026-02-23 17:08:34', 1, 1, 85),
(8, 8, 2, '2026-01-09 17:08:34', '2026-01-24 17:08:34', 1, 1, 78),
(9, 8, 8, '2026-01-29 17:08:34', NULL, 0, 0, NULL),
(10, 8, 9, '2026-02-08 17:08:34', NULL, 0, 0, NULL),
(11, 9, 5, '2026-01-19 17:08:34', '2026-02-10 17:08:34', 1, 1, 93),
(12, 9, 4, '2026-02-03 17:08:34', NULL, 0, 0, NULL),
(13, 10, 2, '2026-01-24 17:08:34', '2026-02-13 17:08:34', 1, 0, 62),
(14, 10, 9, '2026-02-08 17:08:34', NULL, 0, 0, NULL),
(15, 11, 7, '2026-01-31 17:08:34', '2026-02-20 17:08:34', 1, 1, 87),
(16, 11, 6, '2026-02-13 17:08:34', NULL, 0, 0, NULL),
(17, 12, 3, '2026-01-29 17:08:34', NULL, 0, 0, NULL),
(18, 12, 4, '2026-02-08 17:08:34', NULL, 0, 0, NULL),
(19, 13, 1, '2026-02-03 17:08:34', '2026-02-18 17:08:34', 1, 1, 82),
(20, 13, 5, '2026-02-13 17:08:34', NULL, 0, 0, NULL),
(21, 14, 2, '2026-02-06 17:08:34', NULL, 0, 0, NULL),
(22, 15, 7, '2026-02-10 17:08:34', NULL, 0, 0, NULL),
(23, 15, 6, '2026-02-16 17:08:34', NULL, 0, 0, NULL),
(24, 16, 1, '2026-02-08 17:08:34', NULL, 0, 0, NULL),
(25, 17, 5, '2026-02-13 17:08:34', NULL, 0, 0, NULL),
(26, 17, 10, '2026-02-18 17:08:34', NULL, 0, 0, NULL),
(27, 18, 8, '2026-02-03 17:08:34', NULL, 0, 0, NULL),
(28, 19, 1, '2026-02-14 17:08:34', NULL, 0, 0, NULL),
(29, 20, 3, '2026-02-16 17:08:34', NULL, 0, 0, NULL),
(30, 21, 5, '2026-02-18 17:08:34', NULL, 0, 0, NULL),
(31, 22, 10, '2026-02-20 17:08:34', NULL, 0, 0, NULL),
(32, 23, 6, '2026-02-21 17:08:34', NULL, 0, 0, NULL),
(33, 24, 2, '2026-02-22 17:08:34', NULL, 0, 0, NULL),
(34, 25, 9, '2026-02-23 17:08:34', NULL, 0, 0, NULL),
(35, 26, 1, '2026-02-24 17:08:34', NULL, 0, 0, NULL),
(36, 27, 7, '2026-02-25 17:08:34', NULL, 0, 0, NULL),
(37, 32, 1, '2026-02-25 17:08:34', NULL, 0, 0, NULL),
(38, 33, 5, '2026-02-26 17:08:34', NULL, 0, 0, NULL),
(39, 34, 10, '2026-02-27 17:08:34', NULL, 0, 0, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `lessons`
--

CREATE TABLE `lessons` (
  `id` int(10) UNSIGNED NOT NULL,
  `course_id` int(10) UNSIGNED NOT NULL,
  `title` varchar(200) NOT NULL,
  `description` text DEFAULT NULL,
  `video_url` varchar(512) NOT NULL COMMENT 'YouTube embed or direct URL',
  `video_duration` smallint(5) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'seconds',
  `sort_order` tinyint(3) UNSIGNED NOT NULL DEFAULT 0,
  `xp_reward` smallint(5) UNSIGNED NOT NULL DEFAULT 20,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `lessons`
--

INSERT INTO `lessons` (`id`, `course_id`, `title`, `description`, `video_url`, `video_duration`, `sort_order`, `xp_reward`, `created_at`) VALUES
(1, 1, 'What is Algebra? Variables & Expressions', 'Introduction to algebraic thinking and symbolic representation.', 'https://www.youtube.com/embed/NybHckSEQBI', 480, 1, 25, '2026-02-28 17:08:34'),
(2, 1, 'Solving One-Step Equations', 'Learn to isolate variables using inverse operations.', 'https://www.youtube.com/embed/1q4QhPaKfGo', 510, 2, 25, '2026-02-28 17:08:34'),
(3, 1, 'Two-Step Equations & Word Problems', 'Apply equations to solve real-world problems.', 'https://www.youtube.com/embed/LDIiYKYvvdA', 540, 3, 25, '2026-02-28 17:08:34'),
(4, 1, 'Linear Inequalities', 'Understand inequality symbols and solve linear inequalities.', 'https://www.youtube.com/embed/VgDe_D8ojxw', 490, 4, 25, '2026-02-28 17:08:34'),
(5, 1, 'Graphing Linear Equations', 'Plot equations on coordinate planes, slope and intercept.', 'https://www.youtube.com/embed/2UrcUfBizyw', 600, 5, 30, '2026-02-28 17:08:34'),
(6, 1, 'Systems of Equations', 'Solve systems using substitution and elimination methods.', 'https://www.youtube.com/embed/vA-55wZtLeE', 630, 6, 30, '2026-02-28 17:08:34'),
(7, 2, 'Python Setup & Your First Program', 'Install Python, run Hello World, understand the REPL.', 'https://www.youtube.com/embed/_uQrJ0TkZlc', 720, 1, 30, '2026-02-28 17:08:34'),
(8, 2, 'Variables, Data Types & Operators', 'Store and manipulate data using Python variables.', 'https://www.youtube.com/embed/Z1Yd7upQsXY', 660, 2, 30, '2026-02-28 17:08:34'),
(9, 2, 'Conditional Statements: if/elif/else', 'Make decisions in code with boolean logic.', 'https://www.youtube.com/embed/AWek49wXGzI', 590, 3, 25, '2026-02-28 17:08:34'),
(10, 2, 'Loops: for and while', 'Automate repetition with powerful loop structures.', 'https://www.youtube.com/embed/6iF8Xb7Z3wQ', 650, 4, 25, '2026-02-28 17:08:34'),
(11, 2, 'Functions & Scope', 'Write reusable blocks of code with functions.', 'https://www.youtube.com/embed/9Os0o3wzS_I', 700, 5, 30, '2026-02-28 17:08:34'),
(12, 2, 'Lists, Tuples & Dictionaries', 'Master Python\'s core data structures.', 'https://www.youtube.com/embed/W8KRzm-HUcc', 780, 6, 35, '2026-02-28 17:08:34'),
(13, 3, 'Introduction to Forces', 'What is a force? Contact vs. non-contact forces.', 'https://www.youtube.com/embed/JJLJ4LZAGEY', 520, 1, 30, '2026-02-28 17:08:34'),
(14, 3, 'Newton\'s First Law: Inertia', 'Objects in motion stay in motion — understand inertia.', 'https://www.youtube.com/embed/kKKM8Y-u7ds', 540, 2, 30, '2026-02-28 17:08:34'),
(15, 3, 'Newton\'s Second Law: F = ma', 'Force, mass, and acceleration relationships.', 'https://www.youtube.com/embed/fvTTefBqjq8', 580, 3, 35, '2026-02-28 17:08:34'),
(16, 3, 'Newton\'s Third Law: Action & Reaction', 'Every action has an equal and opposite reaction.', 'https://www.youtube.com/embed/By-ggTfeuJU', 500, 4, 30, '2026-02-28 17:08:34'),
(17, 3, 'Gravity & Free Fall', 'Understanding gravitational force and free-fall motion.', 'https://www.youtube.com/embed/E43-CfukEgs', 610, 5, 35, '2026-02-28 17:08:34'),
(18, 3, 'Velocity, Speed & Acceleration', 'Distinguish between scalar and vector motion quantities.', 'https://www.youtube.com/embed/oRKxmXwLvUU', 570, 6, 35, '2026-02-28 17:08:34'),
(19, 4, 'What is an Atom?', 'Protons, neutrons, electrons — atomic structure basics.', 'https://www.youtube.com/embed/7WoNn1sqp2k', 490, 1, 30, '2026-02-28 17:08:34'),
(20, 4, 'The Periodic Table Explained', 'How to read and use the periodic table like a pro.', 'https://www.youtube.com/embed/0RRVV4Diomg', 720, 2, 35, '2026-02-28 17:08:34'),
(21, 4, 'Elements, Compounds & Mixtures', 'Distinguish between pure substances and mixtures.', 'https://www.youtube.com/embed/VB4BKnJtues', 550, 3, 30, '2026-02-28 17:08:34'),
(22, 4, 'Chemical Bonding: Ionic & Covalent', 'How atoms join together to form molecules.', 'https://www.youtube.com/embed/QXT4OLXYDIE', 620, 4, 35, '2026-02-28 17:08:34'),
(23, 4, 'Chemical Reactions & Equations', 'Write and balance chemical equations.', 'https://www.youtube.com/embed/SjQG3rKSZUQ', 680, 5, 40, '2026-02-28 17:08:34'),
(24, 4, 'Acids, Bases & pH Scale', 'Understand pH, neutralization, and common acids and bases.', 'https://www.youtube.com/embed/LS67vS10O5Y', 590, 6, 35, '2026-02-28 17:08:34'),
(25, 5, 'The Cell: Unit of Life', 'Plant vs. animal cells, organelles and their functions.', 'https://www.youtube.com/embed/URUJD5NEXC8', 560, 1, 25, '2026-02-28 17:08:34'),
(26, 5, 'Cell Membrane & Transport', 'Osmosis, diffusion, active and passive transport.', 'https://www.youtube.com/embed/tnCBKGPMCzk', 540, 2, 25, '2026-02-28 17:08:34'),
(27, 5, 'DNA: The Blueprint of Life', 'Structure of DNA, base pairs, and genetic information.', 'https://www.youtube.com/embed/TNKWgcFPHqw', 620, 3, 30, '2026-02-28 17:08:34'),
(28, 5, 'Cell Division: Mitosis', 'Phases of mitosis and why cell division is essential.', 'https://www.youtube.com/embed/f-ldPgEfAHI', 680, 4, 30, '2026-02-28 17:08:34'),
(29, 5, 'Photosynthesis', 'How plants make food from sunlight, water and CO2.', 'https://www.youtube.com/embed/g78utcLQrJ4', 590, 5, 25, '2026-02-28 17:08:34'),
(30, 5, 'Cellular Respiration', 'How cells release energy from glucose — ATP production.', 'https://www.youtube.com/embed/Gh2P5CmCC0M', 640, 6, 30, '2026-02-28 17:08:34'),
(31, 6, 'Mesopotamia: The Cradle of Civilization', 'Sumerians, writing, ziggurats — the world\'s first cities.', 'https://www.youtube.com/embed/sohXPx_XZ6Y', 500, 1, 20, '2026-02-28 17:08:34'),
(32, 6, 'Ancient Egypt: Pharaohs & Pyramids', 'Egyptian society, mummies, hieroglyphics and the Nile.', 'https://www.youtube.com/embed/pKlpLn9pHSQ', 540, 2, 20, '2026-02-28 17:08:34'),
(33, 6, 'Ancient Greece: Democracy & Philosophy', 'Athens, Sparta, philosophy, and the birth of democracy.', 'https://www.youtube.com/embed/MjCHzPGPDZs', 570, 3, 25, '2026-02-28 17:08:34'),
(34, 6, 'The Roman Empire', 'Rise and fall of Rome, Roman engineering and law.', 'https://www.youtube.com/embed/wOO1YrmBt-U', 610, 4, 25, '2026-02-28 17:08:34'),
(35, 6, 'Ancient India & China', 'The Indus Valley, Han Dynasty, Silk Road, and early empires.', 'https://www.youtube.com/embed/pgZXVH6otOw', 590, 5, 25, '2026-02-28 17:08:34'),
(36, 7, 'Story Structure: The 3-Act Framework', 'Beginning, middle, end — and why this formula works.', 'https://www.youtube.com/embed/9h3NNsHB83s', 480, 1, 20, '2026-02-28 17:08:34'),
(37, 7, 'Creating Compelling Characters', 'Give your characters depth, flaws, and believable motivations.', 'https://www.youtube.com/embed/UOIwRSKsc80', 510, 2, 20, '2026-02-28 17:08:34'),
(38, 7, 'Writing Dialogue Like a Pro', 'Make characters talk naturally — show don\'t tell.', 'https://www.youtube.com/embed/a2qHkTnW6TM', 490, 3, 20, '2026-02-28 17:08:34'),
(39, 7, 'Setting & World Building', 'Create vivid settings that make readers feel present.', 'https://www.youtube.com/embed/BNP4FvL2Hkk', 520, 4, 20, '2026-02-28 17:08:34'),
(40, 7, 'Point of View & Narrative Voice', 'First, second, third person — choosing the right lens.', 'https://www.youtube.com/embed/kVy3qCFRfvY', 500, 5, 20, '2026-02-28 17:08:34'),
(41, 7, 'Editing & Polishing Your Writing', 'Self-editing techniques to sharpen and elevate your prose.', 'https://www.youtube.com/embed/M5bEivOBGP4', 460, 6, 20, '2026-02-28 17:08:34'),
(42, 8, 'Introduction to Limits', 'The concept of a limit and how to evaluate them.', 'https://www.youtube.com/embed/riXcZT2ICjA', 720, 1, 40, '2026-02-28 17:08:34'),
(43, 8, 'Limit Laws & Continuity', 'Apply limit laws and understand function continuity.', 'https://www.youtube.com/embed/kfF40MiS7zA', 740, 2, 40, '2026-02-28 17:08:34'),
(44, 8, 'The Derivative: Definition', 'Derivative as rate of change and the formal definition.', 'https://www.youtube.com/embed/rAof9Ld5sOg', 780, 3, 45, '2026-02-28 17:08:34'),
(45, 8, 'Differentiation Rules', 'Power, product, quotient, and chain rules.', 'https://www.youtube.com/embed/IvLpN1G1Ncg', 800, 4, 45, '2026-02-28 17:08:34'),
(46, 8, 'Derivatives of Trig Functions', 'Differentiating sine, cosine, and other trig functions.', 'https://www.youtube.com/embed/l7QBGQcB9Lk', 750, 5, 40, '2026-02-28 17:08:34'),
(47, 8, 'Applications of Derivatives', 'Using derivatives to find maxima, minima, and rates of change.', 'https://www.youtube.com/embed/KKpDhSJOCIs', 820, 6, 50, '2026-02-28 17:08:34'),
(48, 9, 'How the Web Works: HTTP & Browsers', 'DNS, HTTP requests, how browsers render pages.', 'https://www.youtube.com/embed/hJHvdBlSxug', 540, 1, 35, '2026-02-28 17:08:34'),
(49, 9, 'HTML: Structure & Semantic Elements', 'Build the skeleton of web pages with semantic HTML5.', 'https://www.youtube.com/embed/qz0aGYrrlhU', 680, 2, 35, '2026-02-28 17:08:34'),
(50, 9, 'CSS: Styling & Layouts', 'Colors, fonts, box model, Flexbox, and Grid.', 'https://www.youtube.com/embed/1Rs2ND1ryYc', 780, 3, 40, '2026-02-28 17:08:34'),
(51, 9, 'JavaScript: DOM Manipulation', 'Select and modify HTML elements with JS.', 'https://www.youtube.com/embed/5fb2aPlgoys', 720, 4, 40, '2026-02-28 17:08:34'),
(52, 9, 'JavaScript: Events & Interactivity', 'Handle clicks, inputs, forms and make pages interactive.', 'https://www.youtube.com/embed/jS4aFq5-91M', 690, 5, 40, '2026-02-28 17:08:34'),
(53, 9, 'Build Your First Responsive Website', 'Combine HTML, CSS, JS into a complete responsive site.', 'https://www.youtube.com/embed/mU6anWqZJcc', 900, 6, 45, '2026-02-28 17:08:34'),
(54, 10, 'Earth\'s Structure & Plate Tectonics', 'Layers of Earth, tectonic plates, earthquakes and volcanoes.', 'https://www.youtube.com/embed/kwfNGatxUJI', 560, 1, 22, '2026-02-28 17:08:34'),
(55, 10, 'The Rock Cycle & Minerals', 'Igneous, sedimentary, metamorphic rocks and how they form.', 'https://www.youtube.com/embed/E_4bqyJCSOc', 530, 2, 22, '2026-02-28 17:08:34'),
(56, 10, 'Earth\'s Atmosphere & Weather', 'Layers of atmosphere, weather patterns and climate basics.', 'https://www.youtube.com/embed/UXl4Mz3KgIQ', 570, 3, 22, '2026-02-28 17:08:34'),
(57, 10, 'The Solar System', 'Planets, moons, asteroids, and what makes each world unique.', 'https://www.youtube.com/embed/libKVRa01L8', 640, 4, 25, '2026-02-28 17:08:34'),
(58, 10, 'Stars, Galaxies & The Universe', 'Life cycle of stars, the Milky Way, and the expanding universe.', 'https://www.youtube.com/embed/HdPzOWlLrbE', 690, 5, 25, '2026-02-28 17:08:34'),
(59, 10, 'Space Exploration & Future Missions', 'History of space missions and humanity\'s future in space.', 'https://www.youtube.com/embed/WpnIW3tMBkA', 610, 6, 28, '2026-02-28 17:08:34');

-- --------------------------------------------------------

--
-- Table structure for table `lesson_progress`
--

CREATE TABLE `lesson_progress` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `lesson_id` int(10) UNSIGNED NOT NULL,
  `watch_percent` tinyint(3) UNSIGNED NOT NULL DEFAULT 0 COMMENT '0-100',
  `is_completed` tinyint(1) NOT NULL DEFAULT 0,
  `completed_at` datetime DEFAULT NULL,
  `xp_awarded` tinyint(1) NOT NULL DEFAULT 0,
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `lesson_progress`
--

INSERT INTO `lesson_progress` (`id`, `user_id`, `lesson_id`, `watch_percent`, `is_completed`, `completed_at`, `xp_awarded`, `updated_at`) VALUES
(1, 6, 1, 100, 1, '2026-01-15 17:08:34', 1, '2026-02-28 17:08:34'),
(2, 6, 2, 100, 1, '2026-01-16 17:08:34', 1, '2026-02-28 17:08:34'),
(3, 6, 3, 100, 1, '2026-01-17 17:08:34', 1, '2026-02-28 17:08:34'),
(4, 6, 4, 100, 1, '2026-01-18 17:08:34', 1, '2026-02-28 17:08:34'),
(5, 6, 5, 100, 1, '2026-01-19 17:08:34', 1, '2026-02-28 17:08:34'),
(6, 6, 6, 100, 1, '2026-01-20 17:08:34', 1, '2026-02-28 17:08:34'),
(7, 6, 7, 100, 1, '2026-01-21 17:08:34', 1, '2026-02-28 17:08:34'),
(8, 6, 8, 100, 1, '2026-01-22 17:08:34', 1, '2026-02-28 17:08:34'),
(9, 6, 9, 100, 1, '2026-01-23 17:08:34', 1, '2026-02-28 17:08:34'),
(10, 6, 10, 100, 1, '2026-01-24 17:08:34', 1, '2026-02-28 17:08:34'),
(11, 6, 11, 100, 1, '2026-01-25 17:08:34', 1, '2026-02-28 17:08:34'),
(12, 6, 12, 100, 1, '2026-01-26 17:08:34', 1, '2026-02-28 17:08:34'),
(13, 6, 25, 100, 1, '2026-02-14 17:08:34', 1, '2026-02-28 17:08:34'),
(14, 6, 26, 100, 1, '2026-02-15 17:08:34', 1, '2026-02-28 17:08:34'),
(15, 6, 27, 100, 1, '2026-02-16 17:08:34', 1, '2026-02-28 17:08:34'),
(16, 6, 28, 100, 1, NULL, 1, '2026-03-01 08:55:07'),
(17, 6, 48, 100, 1, '2026-02-18 17:08:34', 1, '2026-02-28 17:08:34'),
(18, 6, 49, 60, 0, NULL, 0, '2026-02-28 17:08:34'),
(19, 7, 1, 100, 1, '2026-01-30 17:08:34', 1, '2026-02-28 17:08:34'),
(20, 7, 2, 100, 1, '2026-01-31 17:08:34', 1, '2026-02-28 17:08:34'),
(21, 7, 3, 100, 1, '2026-02-01 17:08:34', 1, '2026-02-28 17:08:34'),
(22, 7, 4, 100, 1, '2026-02-02 17:08:34', 1, '2026-02-28 17:08:34'),
(23, 7, 5, 100, 1, '2026-02-03 17:08:34', 1, '2026-02-28 17:08:34'),
(24, 7, 6, 100, 1, '2026-02-04 17:08:34', 1, '2026-02-28 17:08:34'),
(25, 7, 13, 100, 1, '2026-02-16 17:08:34', 1, '2026-02-28 17:08:34'),
(26, 7, 14, 80, 0, NULL, 0, '2026-02-28 17:08:34'),
(27, 7, 36, 100, 1, '2026-02-09 17:08:34', 1, '2026-02-28 17:08:34'),
(28, 7, 37, 100, 1, '2026-02-10 17:08:34', 1, '2026-02-28 17:08:34'),
(29, 7, 38, 100, 1, '2026-02-11 17:08:34', 1, '2026-02-28 17:08:34'),
(30, 7, 39, 100, 1, '2026-02-12 17:08:34', 1, '2026-02-28 17:08:34'),
(31, 7, 40, 100, 1, '2026-02-13 17:08:34', 1, '2026-02-28 17:08:34'),
(32, 7, 41, 100, 1, '2026-02-14 17:08:34', 1, '2026-02-28 17:08:34'),
(33, 8, 7, 100, 1, '2026-01-10 17:08:34', 1, '2026-02-28 17:08:34'),
(34, 8, 8, 100, 1, '2026-01-11 17:08:34', 1, '2026-02-28 17:08:34'),
(35, 8, 9, 100, 1, '2026-01-12 17:08:34', 1, '2026-02-28 17:08:34'),
(36, 8, 10, 100, 1, '2026-01-13 17:08:34', 1, '2026-02-28 17:08:34'),
(37, 8, 11, 100, 1, '2026-01-14 17:08:34', 1, '2026-02-28 17:08:34'),
(38, 8, 12, 100, 1, '2026-01-15 17:08:34', 1, '2026-02-28 17:08:34'),
(39, 8, 42, 100, 1, '2026-02-08 17:08:34', 1, '2026-02-28 17:08:34'),
(40, 8, 43, 100, 1, '2026-02-10 17:08:34', 1, '2026-02-28 17:08:34'),
(41, 8, 44, 90, 0, NULL, 0, '2026-02-28 17:08:34'),
(42, 8, 48, 100, 1, '2026-02-13 17:08:34', 1, '2026-02-28 17:08:34'),
(43, 8, 49, 100, 1, '2026-02-16 17:08:34', 1, '2026-02-28 17:08:34'),
(44, 8, 50, 45, 0, NULL, 0, '2026-02-28 17:08:34'),
(45, 9, 25, 100, 1, '2026-01-20 17:08:34', 1, '2026-02-28 17:08:34'),
(46, 9, 26, 100, 1, '2026-01-22 17:08:34', 1, '2026-02-28 17:08:34'),
(47, 9, 27, 100, 1, '2026-01-24 17:08:34', 1, '2026-02-28 17:08:34'),
(48, 9, 28, 100, 1, '2026-01-27 17:08:34', 1, '2026-02-28 17:08:34'),
(49, 9, 29, 100, 1, '2026-01-30 17:08:34', 1, '2026-02-28 17:08:34'),
(50, 9, 30, 100, 1, '2026-02-02 17:08:34', 1, '2026-02-28 17:08:34'),
(51, 9, 19, 100, 1, '2026-02-13 17:08:34', 1, '2026-02-28 17:08:34'),
(52, 9, 20, 100, 1, '2026-02-16 17:08:34', 1, '2026-02-28 17:08:34'),
(53, 9, 21, 70, 0, NULL, 0, '2026-02-28 17:08:34'),
(54, 10, 7, 100, 1, '2026-01-25 17:08:34', 1, '2026-02-28 17:08:34'),
(55, 10, 8, 100, 1, '2026-01-27 17:08:34', 1, '2026-02-28 17:08:34'),
(56, 10, 9, 100, 1, '2026-01-29 17:08:34', 1, '2026-02-28 17:08:34'),
(57, 10, 10, 100, 1, '2026-01-31 17:08:34', 1, '2026-02-28 17:08:34'),
(58, 10, 11, 100, 1, '2026-02-02 17:08:34', 1, '2026-02-28 17:08:34'),
(59, 10, 12, 100, 1, '2026-02-04 17:08:34', 1, '2026-02-28 17:08:34'),
(60, 10, 48, 100, 1, '2026-02-16 17:08:34', 1, '2026-02-28 17:08:34'),
(61, 10, 49, 50, 0, NULL, 0, '2026-02-28 17:08:34'),
(62, 11, 36, 100, 1, '2026-02-01 17:08:34', 1, '2026-02-28 17:08:34'),
(63, 11, 37, 100, 1, '2026-02-03 17:08:34', 1, '2026-02-28 17:08:34'),
(64, 11, 38, 100, 1, '2026-02-05 17:08:34', 1, '2026-02-28 17:08:34'),
(65, 11, 39, 100, 1, '2026-02-07 17:08:34', 1, '2026-02-28 17:08:34'),
(66, 11, 40, 100, 1, '2026-02-09 17:08:34', 1, '2026-02-28 17:08:34'),
(67, 11, 41, 100, 1, '2026-02-11 17:08:34', 1, '2026-02-28 17:08:34'),
(68, 11, 31, 100, 1, '2026-02-18 17:08:34', 1, '2026-02-28 17:08:34'),
(69, 11, 32, 80, 0, NULL, 0, '2026-02-28 17:08:34'),
(70, 13, 1, 100, 1, '2026-02-04 17:08:34', 1, '2026-02-28 17:08:34'),
(71, 13, 2, 100, 1, '2026-02-05 17:08:34', 1, '2026-02-28 17:08:34'),
(72, 13, 3, 100, 1, '2026-02-06 17:08:34', 1, '2026-02-28 17:08:34'),
(73, 13, 4, 100, 1, '2026-02-07 17:08:34', 1, '2026-02-28 17:08:34'),
(74, 13, 5, 100, 1, '2026-02-08 17:08:34', 1, '2026-02-28 17:08:34'),
(75, 13, 6, 100, 1, '2026-02-09 17:08:34', 1, '2026-02-28 17:08:34'),
(76, 13, 25, 100, 1, '2026-02-18 17:08:34', 1, '2026-02-28 17:08:34'),
(77, 13, 26, 65, 0, NULL, 0, '2026-02-28 17:08:34'),
(78, 12, 13, 100, 1, '2026-02-13 17:08:34', 1, '2026-02-28 17:08:34'),
(79, 12, 14, 100, 1, '2026-02-16 17:08:34', 1, '2026-02-28 17:08:34'),
(80, 12, 15, 40, 0, NULL, 0, '2026-02-28 17:08:34'),
(81, 14, 7, 100, 1, '2026-02-18 17:08:34', 1, '2026-02-28 17:08:34'),
(82, 14, 8, 70, 0, NULL, 0, '2026-02-28 17:08:34'),
(83, 15, 36, 100, 1, '2026-02-20 17:08:34', 1, '2026-02-28 17:08:34'),
(84, 15, 37, 55, 0, NULL, 0, '2026-02-28 17:08:34'),
(85, 16, 1, 100, 1, '2026-02-22 17:08:34', 1, '2026-02-28 17:08:34'),
(86, 16, 2, 30, 0, NULL, 0, '2026-02-28 17:08:34'),
(87, 17, 25, 100, 1, '2026-02-23 17:08:34', 1, '2026-02-28 17:08:34'),
(88, 19, 1, 100, 1, '2026-02-24 17:08:34', 1, '2026-02-28 17:08:34'),
(89, 19, 2, 20, 0, NULL, 0, '2026-02-28 17:08:34'),
(90, 21, 25, 60, 0, NULL, 0, '2026-02-28 17:08:34'),
(91, 23, 31, 100, 1, '2026-02-25 17:08:34', 1, '2026-02-28 17:08:34'),
(92, 24, 7, 40, 0, NULL, 0, '2026-02-28 17:08:34'),
(93, 32, 1, 100, 1, '2026-02-26 17:08:34', 1, '2026-02-28 17:08:34'),
(94, 32, 2, 100, 1, '2026-02-27 17:08:34', 1, '2026-02-28 17:08:34'),
(95, 32, 3, 50, 0, NULL, 0, '2026-02-28 17:08:34'),
(96, 6, 29, 100, 1, '2026-03-01 02:16:34', 1, '2026-03-01 09:16:37');

-- --------------------------------------------------------

--
-- Table structure for table `study_sessions`
--

CREATE TABLE `study_sessions` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `study_date` date NOT NULL,
  `xp_earned` smallint(5) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `study_sessions`
--

INSERT INTO `study_sessions` (`id`, `user_id`, `study_date`, `xp_earned`) VALUES
(1, 6, '2026-02-28', 150),
(2, 6, '2026-02-27', 120),
(3, 6, '2026-02-26', 100),
(4, 6, '2026-02-25', 90),
(5, 6, '2026-02-24', 110),
(6, 6, '2026-02-23', 80),
(7, 6, '2026-02-22', 95),
(8, 6, '2026-02-21', 70),
(9, 6, '2026-02-20', 85),
(10, 6, '2026-02-19', 60),
(11, 6, '2026-02-18', 100),
(12, 6, '2026-02-17', 75),
(13, 6, '2026-02-16', 90),
(14, 6, '2026-02-15', 55),
(15, 7, '2026-02-28', 130),
(16, 7, '2026-02-27', 110),
(17, 7, '2026-02-26', 95),
(18, 7, '2026-02-25', 80),
(19, 7, '2026-02-24', 100),
(20, 7, '2026-02-23', 70),
(21, 7, '2026-02-22', 85),
(22, 7, '2026-02-21', 60),
(23, 9, '2026-02-28', 100),
(24, 9, '2026-02-27', 90),
(25, 9, '2026-02-26', 80),
(26, 9, '2026-02-25', 70),
(27, 9, '2026-02-24', 85),
(28, 9, '2026-02-23', 65),
(29, 11, '2026-02-28', 80),
(30, 11, '2026-02-27', 70),
(31, 11, '2026-02-26', 60),
(32, 11, '2026-02-25', 75),
(33, 11, '2026-02-24', 55),
(34, 13, '2026-02-28', 70),
(35, 13, '2026-02-27', 60),
(36, 13, '2026-02-26', 50),
(37, 15, '2026-02-28', 60),
(38, 17, '2026-02-28', 45),
(39, 19, '2026-02-28', 55),
(40, 21, '2026-02-28', 40),
(41, 23, '2026-02-28', 35),
(42, 27, '2026-02-28', 30),
(43, 29, '2026-02-28', 25),
(44, 32, '2026-02-28', 40),
(45, 34, '2026-02-28', 20),
(46, 6, '2026-03-01', 0);

-- --------------------------------------------------------

--
-- Table structure for table `subjects`
--

CREATE TABLE `subjects` (
  `id` tinyint(3) UNSIGNED NOT NULL,
  `name` varchar(60) NOT NULL,
  `icon` varchar(10) NOT NULL DEFAULT '?',
  `color` varchar(7) NOT NULL DEFAULT '#6366f1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `subjects`
--

INSERT INTO `subjects` (`id`, `name`, `icon`, `color`) VALUES
(1, 'Mathematics', '🔢', '#6366f1'),
(2, 'Science', '🔬', '#10b981'),
(3, 'English Language', '📖', '#f59e0b'),
(4, 'History', '🏛️', '#ef4444'),
(5, 'Computer Science', '💻', '#3b82f6'),
(6, 'Physics', '⚛️', '#8b5cf6'),
(7, 'Chemistry', '🧪', '#06b6d4'),
(8, 'Biology', '🧬', '#84cc16');

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(10) UNSIGNED NOT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(120) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `full_name` varchar(100) NOT NULL,
  `avatar_url` varchar(512) NOT NULL DEFAULT '',
  `role` enum('student','teacher','admin') NOT NULL DEFAULT 'student',
  `grade_level` tinyint(3) UNSIGNED NOT NULL DEFAULT 10 COMMENT '7-12 for middle/high school',
  `total_xp` int(10) UNSIGNED NOT NULL DEFAULT 0,
  `current_streak` smallint(5) UNSIGNED NOT NULL DEFAULT 0,
  `longest_streak` smallint(5) UNSIGNED NOT NULL DEFAULT 0,
  `last_study_date` date DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `username`, `email`, `password_hash`, `full_name`, `avatar_url`, `role`, `grade_level`, `total_xp`, `current_streak`, `longest_streak`, `last_study_date`, `created_at`, `updated_at`) VALUES
(1, 'admin', 'admin@eduquest.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'EduQuest Admin', 'https://api.dicebear.com/7.x/adventurer/svg?seed=admin&backgroundColor=6366f1', 'admin', 12, 0, 0, 0, NULL, '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(2, 'mr_chen', 'chen@eduquest.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Mr. David Chen', 'https://api.dicebear.com/7.x/adventurer/svg?seed=davidchen&backgroundColor=3b82f6', 'teacher', 12, 0, 0, 0, NULL, '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(3, 'ms_patel', 'patel@eduquest.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Ms. Priya Patel', 'https://api.dicebear.com/7.x/adventurer/svg?seed=priyapatel&backgroundColor=10b981', 'teacher', 12, 0, 0, 0, NULL, '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(4, 'mr_williams', 'williams@eduquest.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Mr. James Williams', 'https://api.dicebear.com/7.x/adventurer/svg?seed=jameswilliams&backgroundColor=f59e0b', 'teacher', 12, 0, 0, 0, NULL, '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(5, 'ms_lim', 'lim@eduquest.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Ms. Sarah Lim', 'https://api.dicebear.com/7.x/adventurer/svg?seed=sarahlim&backgroundColor=ef4444', 'teacher', 12, 0, 0, 0, NULL, '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(6, 'alex_ng', 'alex.ng@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Alex Ng Zhi Wei', 'https://api.dicebear.com/7.x/adventurer/svg?seed=alexng&backgroundColor=6366f1', 'student', 11, 4920, 29, 35, '2026-03-01', '2026-02-28 17:08:34', '2026-03-01 09:16:34'),
(7, 'zara_khan', 'zara.khan@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Zara Khan', 'https://api.dicebear.com/7.x/adventurer/svg?seed=zarakhan&backgroundColor=f59e0b', 'student', 10, 4210, 21, 21, '2026-02-28', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(8, 'ethan_lee', 'ethan.lee@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Ethan Lee Kai Sheng', 'https://api.dicebear.com/7.x/adventurer/svg?seed=ethanlee&backgroundColor=10b981', 'student', 12, 3990, 14, 30, '2026-02-28', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(9, 'maya_raj', 'maya.raj@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Maya Rajasekaran', 'https://api.dicebear.com/7.x/adventurer/svg?seed=mayaraj&backgroundColor=8b5cf6', 'student', 10, 3750, 18, 22, '2026-02-28', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(10, 'lucas_tan', 'lucas.tan@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Lucas Tan Jing Hong', 'https://api.dicebear.com/7.x/adventurer/svg?seed=lucastan&backgroundColor=06b6d4', 'student', 11, 3520, 7, 25, '2026-02-28', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(11, 'sofia_kim', 'sofia.kim@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Sofia Kim Min Ji', 'https://api.dicebear.com/7.x/adventurer/svg?seed=sofiakia&backgroundColor=ec4899', 'student', 9, 3100, 12, 20, '2026-02-28', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(12, 'ryan_ahmad', 'ryan.ahmad@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Ryan Ahmad Firdaus', 'https://api.dicebear.com/7.x/adventurer/svg?seed=ryanahmad&backgroundColor=f97316', 'student', 12, 2890, 5, 15, '2026-02-27', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(13, 'bella_ong', 'bella.ong@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Bella Ong Xin Yi', 'https://api.dicebear.com/7.x/adventurer/svg?seed=bellaong&backgroundColor=84cc16', 'student', 11, 2760, 9, 18, '2026-02-28', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(14, 'aiden_wu', 'aiden.wu@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Aiden Wu Jian Ming', 'https://api.dicebear.com/7.x/adventurer/svg?seed=aidenwu&backgroundColor=3b82f6', 'student', 10, 2580, 3, 10, '2026-02-26', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(15, 'nadia_jose', 'nadia.jose@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Nadia De Jose', 'https://api.dicebear.com/7.x/adventurer/svg?seed=nadiajose&backgroundColor=6366f1', 'student', 9, 2340, 6, 14, '2026-02-28', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(16, 'jaxon_ho', 'jaxon.ho@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Jaxon Ho Wei Lun', 'https://api.dicebear.com/7.x/adventurer/svg?seed=jaxonho&backgroundColor=10b981', 'student', 8, 2100, 0, 8, '2026-02-23', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(17, 'lily_tam', 'lily.tam@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Lily Tam Shu Ling', 'https://api.dicebear.com/7.x/adventurer/svg?seed=lilytam&backgroundColor=ec4899', 'student', 7, 1950, 4, 12, '2026-02-28', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(18, 'omar_hassan', 'omar.hassan@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Omar Hassan Malik', 'https://api.dicebear.com/7.x/adventurer/svg?seed=omarhassan&backgroundColor=f59e0b', 'student', 12, 1820, 2, 9, '2026-02-27', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(19, 'chloe_yap', 'chloe.yap@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Chloe Yap Jia Qi', 'https://api.dicebear.com/7.x/adventurer/svg?seed=chloeyap&backgroundColor=8b5cf6', 'student', 10, 1700, 8, 11, '2026-02-28', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(20, 'noah_singh', 'noah.singh@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Noah Singh Arjun', 'https://api.dicebear.com/7.x/adventurer/svg?seed=noahsingh&backgroundColor=ef4444', 'student', 11, 1550, 1, 6, '2026-02-26', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(21, 'isla_chong', 'isla.chong@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Isla Chong Mei Ling', 'https://api.dicebear.com/7.x/adventurer/svg?seed=islachong&backgroundColor=06b6d4', 'student', 9, 1420, 5, 10, '2026-02-28', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(22, 'kai_ibrahim', 'kai.ibrahim@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Kai Ibrahim Razif', 'https://api.dicebear.com/7.x/adventurer/svg?seed=kaiibrahim&backgroundColor=84cc16', 'student', 8, 1280, 0, 4, '2026-02-21', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(23, 'emma_foo', 'emma.foo@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Emma Foo Shan Shan', 'https://api.dicebear.com/7.x/adventurer/svg?seed=emmafoo&backgroundColor=f97316', 'student', 7, 1100, 3, 7, '2026-02-28', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(24, 'luca_thong', 'luca.thong@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Luca Thong Wei Xiang', 'https://api.dicebear.com/7.x/adventurer/svg?seed=lucathong&backgroundColor=3b82f6', 'student', 11, 980, 2, 5, '2026-02-25', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(25, 'ana_santos', 'ana.santos@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Ana Santos Cruz', 'https://api.dicebear.com/7.x/adventurer/svg?seed=anastos&backgroundColor=6366f1', 'student', 12, 870, 0, 3, '2026-02-18', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(26, 'ivan_goh', 'ivan.goh@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Ivan Goh Cheng Tat', 'https://api.dicebear.com/7.x/adventurer/svg?seed=ivangoh&backgroundColor=10b981', 'student', 10, 760, 1, 4, '2026-02-27', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(27, 'sara_osman', 'sara.osman@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Sara Osman Binti Ahmad', 'https://api.dicebear.com/7.x/adventurer/svg?seed=saraosman&backgroundColor=ec4899', 'student', 9, 640, 4, 6, '2026-02-28', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(28, 'felix_kwan', 'felix.kwan@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Felix Kwan Jia Hao', 'https://api.dicebear.com/7.x/adventurer/svg?seed=felixkwan&backgroundColor=8b5cf6', 'student', 8, 510, 0, 2, '2026-02-14', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(29, 'mia_joseph', 'mia.joseph@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Mia Joseph Nair', 'https://api.dicebear.com/7.x/adventurer/svg?seed=miajoseph&backgroundColor=f59e0b', 'student', 7, 420, 2, 3, '2026-02-28', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(30, 'ben_leow', 'ben.leow@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Ben Leow Zi Yang', 'https://api.dicebear.com/7.x/adventurer/svg?seed=benleow&backgroundColor=06b6d4', 'student', 11, 350, 1, 1, '2026-02-26', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(31, 'nina_raj', 'nina.raj@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Nina Rajendran', 'https://api.dicebear.com/7.x/adventurer/svg?seed=ninaraj&backgroundColor=84cc16', 'student', 10, 280, 0, 1, '2026-02-08', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(32, 'cole_fung', 'cole.fung@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Cole Fung Chun Wei', 'https://api.dicebear.com/7.x/adventurer/svg?seed=colefung&backgroundColor=ef4444', 'student', 12, 200, 3, 3, '2026-02-28', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(33, 'ava_krishna', 'ava.krishna@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Ava Krishnamurthy', 'https://api.dicebear.com/7.x/adventurer/svg?seed=avakrishna&backgroundColor=3b82f6', 'student', 9, 150, 0, 0, NULL, '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(34, 'sam_low', 'sam.low@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Sam Low Boon Kiat', 'https://api.dicebear.com/7.x/adventurer/svg?seed=samlow&backgroundColor=6366f1', 'student', 8, 80, 1, 1, '2026-02-28', '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(35, 'jade_aziz', 'jade.aziz@student.edu', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Jade Aziz Harun', 'https://api.dicebear.com/7.x/adventurer/svg?seed=jadeaziz&backgroundColor=10b981', 'student', 7, 40, 0, 0, NULL, '2026-02-28 17:08:34', '2026-02-28 17:19:58'),
(36, 'MoDoma', 'modoma2002@gmail.com', '$2y$12$P9/QfNKh6lhwZeJ3PIxsKeq39Si./rVrqCpnUEKFLgZVELdlTLXoK', 'Mohamed Doma', 'https://api.dicebear.com/7.x/adventurer/svg?seed=MoDoma516', 'student', 9, 0, 0, 0, NULL, '2026-02-28 17:16:04', '2026-02-28 17:19:58');

-- --------------------------------------------------------

--
-- Table structure for table `user_achievements`
--

CREATE TABLE `user_achievements` (
  `user_id` int(10) UNSIGNED NOT NULL,
  `achievement_id` tinyint(3) UNSIGNED NOT NULL,
  `earned_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_achievements`
--

INSERT INTO `user_achievements` (`user_id`, `achievement_id`, `earned_at`) VALUES
(6, 1, '2026-01-15 17:08:34'),
(6, 2, '2026-01-24 17:08:34'),
(6, 3, '2026-02-18 17:08:34'),
(6, 4, '2026-01-19 17:08:34'),
(6, 5, '2026-02-08 17:08:34'),
(6, 6, '2026-01-21 17:08:34'),
(6, 7, '2026-02-08 17:08:34'),
(6, 8, '2026-01-29 17:08:34'),
(6, 9, '2026-01-29 17:08:34'),
(7, 1, '2026-01-30 17:08:34'),
(7, 2, '2026-02-07 17:08:34'),
(7, 4, '2026-02-14 17:08:34'),
(7, 8, '2026-02-18 17:08:34'),
(7, 9, '2026-02-18 17:08:34'),
(8, 1, '2026-01-10 17:08:34'),
(8, 2, '2026-01-29 17:08:34'),
(8, 4, '2026-01-15 17:08:34'),
(8, 8, '2026-01-24 17:08:34'),
(9, 1, '2026-01-20 17:08:34'),
(9, 4, '2026-01-29 17:08:34'),
(9, 6, '2026-02-03 17:08:34'),
(9, 8, '2026-02-10 17:08:34'),
(9, 9, '2026-02-10 17:08:34'),
(10, 1, '2026-01-25 17:08:34'),
(11, 1, '2026-02-01 17:08:34'),
(11, 4, '2026-02-10 17:08:34'),
(11, 8, '2026-02-20 17:08:34'),
(12, 1, '2026-02-13 17:08:34'),
(13, 1, '2026-02-04 17:08:34'),
(13, 4, '2026-02-13 17:08:34'),
(13, 8, '2026-02-18 17:08:34'),
(14, 1, '2026-02-18 17:08:34'),
(15, 1, '2026-02-20 17:08:34'),
(16, 1, '2026-02-22 17:08:34'),
(17, 1, '2026-02-23 17:08:34'),
(23, 1, '2026-02-25 17:08:34'),
(32, 1, '2026-02-26 17:08:34');

-- --------------------------------------------------------

--
-- Table structure for table `xp_transactions`
--

CREATE TABLE `xp_transactions` (
  `id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `amount` smallint(6) NOT NULL COMMENT 'can be negative for penalties',
  `reason` varchar(120) NOT NULL,
  `ref_type` enum('lesson','exam','streak','achievement','admin') NOT NULL DEFAULT 'lesson',
  `ref_id` int(10) UNSIGNED DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `xp_transactions`
--

INSERT INTO `xp_transactions` (`id`, `user_id`, `amount`, `reason`, `ref_type`, `ref_id`, `created_at`) VALUES
(1, 6, 25, 'Lesson completed: Variables & Expressions', 'lesson', 1, '2026-01-15 17:08:34'),
(2, 6, 25, 'Lesson completed: One-Step Equations', 'lesson', 2, '2026-01-16 17:08:34'),
(3, 6, 25, 'Lesson completed: Two-Step Equations', 'lesson', 3, '2026-01-17 17:08:34'),
(4, 6, 25, 'Lesson completed: Linear Inequalities', 'lesson', 4, '2026-01-18 17:08:34'),
(5, 6, 30, 'Lesson completed: Graphing Linear Equations', 'lesson', 5, '2026-01-19 17:08:34'),
(6, 6, 30, 'Lesson completed: Systems of Equations', 'lesson', 6, '2026-01-20 17:08:34'),
(7, 6, 300, 'Course completed: Algebra Fundamentals', 'exam', 1, '2026-01-29 17:08:34'),
(8, 6, 100, 'Achievement: On Fire (7-day streak)', 'achievement', 2, '2026-01-24 17:08:34'),
(9, 6, 500, 'Achievement: Elite Student (5000 XP)', 'achievement', 7, '2026-02-08 17:08:34'),
(10, 7, 100, '7-day streak bonus', 'streak', NULL, '2026-02-08 17:08:34'),
(11, 7, 250, 'Course completion XP: Algebra', 'exam', 1, '2026-02-18 17:08:34'),
(12, 8, 350, 'Course completion XP: Python', 'exam', 2, '2026-01-24 17:08:34'),
(13, 9, 300, 'Course completion XP: Cell Biology', 'exam', 5, '2026-02-10 17:08:34'),
(14, 9, 200, 'Achievement: Exam Ace (93%)', 'achievement', 9, '2026-02-10 17:08:34'),
(15, 11, 250, 'Course completion XP: Creative Writing', 'exam', 7, '2026-02-20 17:08:34'),
(16, 13, 300, 'Course completion XP: Algebra', 'exam', 1, '2026-02-18 17:08:34'),
(17, 6, 30, 'Lesson completed', 'lesson', 28, '2026-03-01 08:55:07'),
(18, 6, 15, 'Daily study streak bonus (Day 29)', 'streak', NULL, '2026-03-01 08:55:07'),
(19, 6, 25, 'Lesson completed', 'lesson', 29, '2026-03-01 09:16:34');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `achievements`
--
ALTER TABLE `achievements`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `chat_messages`
--
ALTER TABLE `chat_messages`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_chat_session` (`session_id`,`created_at`);

--
-- Indexes for table `chat_sessions`
--
ALTER TABLE `chat_sessions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `course_id` (`course_id`),
  ADD KEY `idx_chat_user` (`user_id`,`course_id`);

--
-- Indexes for table `courses`
--
ALTER TABLE `courses`
  ADD PRIMARY KEY (`id`),
  ADD KEY `teacher_id` (`teacher_id`),
  ADD KEY `idx_courses_subject` (`subject_id`),
  ADD KEY `idx_courses_grade` (`grade_level`);

--
-- Indexes for table `course_enrollments`
--
ALTER TABLE `course_enrollments`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_enrollment` (`user_id`,`course_id`),
  ADD KEY `course_id` (`course_id`);

--
-- Indexes for table `lessons`
--
ALTER TABLE `lessons`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_lessons_course` (`course_id`,`sort_order`);

--
-- Indexes for table `lesson_progress`
--
ALTER TABLE `lesson_progress`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_user_lesson` (`user_id`,`lesson_id`),
  ADD KEY `lesson_id` (`lesson_id`);

--
-- Indexes for table `study_sessions`
--
ALTER TABLE `study_sessions`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_user_date` (`user_id`,`study_date`);

--
-- Indexes for table `subjects`
--
ALTER TABLE `subjects`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `idx_users_xp` (`total_xp`),
  ADD KEY `idx_users_streak` (`current_streak`);

--
-- Indexes for table `user_achievements`
--
ALTER TABLE `user_achievements`
  ADD PRIMARY KEY (`user_id`,`achievement_id`),
  ADD KEY `achievement_id` (`achievement_id`);

--
-- Indexes for table `xp_transactions`
--
ALTER TABLE `xp_transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_xp_user` (`user_id`,`created_at`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `achievements`
--
ALTER TABLE `achievements`
  MODIFY `id` tinyint(3) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `chat_messages`
--
ALTER TABLE `chat_messages`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `chat_sessions`
--
ALTER TABLE `chat_sessions`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `courses`
--
ALTER TABLE `courses`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `course_enrollments`
--
ALTER TABLE `course_enrollments`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=40;

--
-- AUTO_INCREMENT for table `lessons`
--
ALTER TABLE `lessons`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=60;

--
-- AUTO_INCREMENT for table `lesson_progress`
--
ALTER TABLE `lesson_progress`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=97;

--
-- AUTO_INCREMENT for table `study_sessions`
--
ALTER TABLE `study_sessions`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=47;

--
-- AUTO_INCREMENT for table `subjects`
--
ALTER TABLE `subjects`
  MODIFY `id` tinyint(3) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=37;

--
-- AUTO_INCREMENT for table `xp_transactions`
--
ALTER TABLE `xp_transactions`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=20;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `chat_messages`
--
ALTER TABLE `chat_messages`
  ADD CONSTRAINT `chat_messages_ibfk_1` FOREIGN KEY (`session_id`) REFERENCES `chat_sessions` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `chat_sessions`
--
ALTER TABLE `chat_sessions`
  ADD CONSTRAINT `chat_sessions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `chat_sessions_ibfk_2` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `courses`
--
ALTER TABLE `courses`
  ADD CONSTRAINT `courses_ibfk_1` FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`id`),
  ADD CONSTRAINT `courses_ibfk_2` FOREIGN KEY (`teacher_id`) REFERENCES `users` (`id`);

--
-- Constraints for table `course_enrollments`
--
ALTER TABLE `course_enrollments`
  ADD CONSTRAINT `course_enrollments_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `course_enrollments_ibfk_2` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `lessons`
--
ALTER TABLE `lessons`
  ADD CONSTRAINT `lessons_ibfk_1` FOREIGN KEY (`course_id`) REFERENCES `courses` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `lesson_progress`
--
ALTER TABLE `lesson_progress`
  ADD CONSTRAINT `lesson_progress_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `lesson_progress_ibfk_2` FOREIGN KEY (`lesson_id`) REFERENCES `lessons` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `study_sessions`
--
ALTER TABLE `study_sessions`
  ADD CONSTRAINT `study_sessions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `user_achievements`
--
ALTER TABLE `user_achievements`
  ADD CONSTRAINT `user_achievements_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_achievements_ibfk_2` FOREIGN KEY (`achievement_id`) REFERENCES `achievements` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `xp_transactions`
--
ALTER TABLE `xp_transactions`
  ADD CONSTRAINT `xp_transactions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
