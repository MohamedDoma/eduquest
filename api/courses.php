<?php
/**
 * EduQuest LMS - Courses API
 * Endpoint: /api/courses.php
 * Handles: list, view, enroll, progress, lesson_complete
 */

require_once __DIR__ . '/../config/init.php';

header('Content-Type: application/json; charset=utf-8');

requireLogin();

$method = $_SERVER['REQUEST_METHOD'];
$action = getGet('action');
$userId = $_SESSION['user_id'];
$body   = $method === 'POST' ? getJsonBody() : [];

match($action) {
    'list'             => handleList($userId),
    'view'             => handleView($userId, (int)getGet('id')),
    'enroll'           => handleEnroll($userId, (int)($body['course_id'] ?? 0)),
    'update_progress'  => handleUpdateProgress($userId, $body),
    'leaderboard'      => handleLeaderboard(),
    'dashboard_stats'  => handleDashboardStats($userId),
    default            => jsonError('Unknown action.', 400),
};

// ─────────────────────────────────────────────
// LIST all published courses
// ─────────────────────────────────────────────
function handleList(int $userId): never
{
    $subjectId  = (int)getGet('subject_id');
    $difficulty = getGet('difficulty');
    $gradeLevel = (int)getGet('grade_level');
    $search     = getGet('search');

    $where  = ['c.is_published = 1'];
    $params = [];

    if ($subjectId > 0) {
        $where[]  = 'c.subject_id = ?';
        $params[] = $subjectId;
    }
    if ($difficulty) {
        $where[]  = 'c.difficulty = ?';
        $params[] = $difficulty;
    }
    if ($gradeLevel > 0) {
        $where[]  = 'c.grade_level = ?';
        $params[] = $gradeLevel;
    }
    if ($search) {
        $where[]  = '(c.title LIKE ? OR c.description LIKE ?)';
        $params[] = "%$search%";
        $params[] = "%$search%";
    }

    $whereClause = implode(' AND ', $where);

    $courses = Database::fetchAll(
        "SELECT c.id, c.title, c.description, c.thumbnail_url, c.grade_level,
                c.difficulty, c.xp_reward,
                s.name AS subject_name, s.icon AS subject_icon, s.color AS subject_color,
                u.full_name AS teacher_name,
                COUNT(DISTINCT l.id) AS lesson_count,
                ce.enrolled_at, ce.completed_at, ce.exam_unlocked, ce.exam_passed,
                COALESCE(
                    ROUND(
                        SUM(CASE WHEN lp.is_completed = 1 THEN 1 ELSE 0 END) * 100.0
                        / NULLIF(COUNT(DISTINCT l.id), 0)
                    ), 0
                ) AS progress_percent
         FROM courses c
         JOIN subjects s ON c.subject_id = s.id
         JOIN users u ON c.teacher_id = u.id
         LEFT JOIN lessons l ON l.course_id = c.id
         LEFT JOIN course_enrollments ce ON ce.course_id = c.id AND ce.user_id = ?
         LEFT JOIN lesson_progress lp ON lp.lesson_id = l.id AND lp.user_id = ?
         WHERE $whereClause
         GROUP BY c.id, ce.enrolled_at, ce.completed_at, ce.exam_unlocked, ce.exam_passed
         ORDER BY c.created_at DESC",
        array_merge([$userId, $userId], $params)
    );

    $subjects = Database::fetchAll('SELECT * FROM subjects ORDER BY name');

    jsonSuccess([
        'courses'  => $courses,
        'subjects' => $subjects,
        'total'    => count($courses),
    ]);
}

// ─────────────────────────────────────────────
// VIEW single course with lessons
// ─────────────────────────────────────────────
function handleView(int $userId, int $courseId): never
{
    if ($courseId <= 0) jsonError('Invalid course ID.', 422);

    $course = Database::fetchOne(
        "SELECT c.id, c.title, c.description, c.thumbnail_url, c.grade_level,
                c.difficulty, c.xp_reward,
                s.name AS subject_name, s.icon AS subject_icon, s.color AS subject_color,
                u.full_name AS teacher_name, u.avatar_url AS teacher_avatar,
                ce.enrolled_at, ce.completed_at, ce.exam_unlocked, ce.exam_passed, ce.exam_score
         FROM courses c
         JOIN subjects s ON c.subject_id = s.id
         JOIN users u ON c.teacher_id = u.id
         LEFT JOIN course_enrollments ce ON ce.course_id = c.id AND ce.user_id = ?
         WHERE c.id = ? AND c.is_published = 1",
        [$userId, $courseId]
    );

    if (!$course) jsonError('Course not found.', 404);

    // Get lessons with progress
    $lessons = Database::fetchAll(
        "SELECT l.id, l.title, l.description, l.video_url, l.video_duration,
                l.sort_order, l.xp_reward,
                COALESCE(lp.watch_percent, 0) AS watch_percent,
                COALESCE(lp.is_completed, 0) AS is_completed
         FROM lessons l
         LEFT JOIN lesson_progress lp ON lp.lesson_id = l.id AND lp.user_id = ?
         WHERE l.course_id = ?
         ORDER BY l.sort_order ASC",
        [$userId, $courseId]
    );

    // Progress summary
    $progress = getCourseProgress($userId, $courseId);

    jsonSuccess([
        'course'   => $course,
        'lessons'  => $lessons,
        'progress' => $progress,
    ]);
}

// ─────────────────────────────────────────────
// ENROLL in a course
// ─────────────────────────────────────────────
function handleEnroll(int $userId, int $courseId): never
{
    if ($courseId <= 0) jsonError('Invalid course ID.', 422);

    $course = Database::fetchOne('SELECT id FROM courses WHERE id = ? AND is_published = 1', [$courseId]);
    if (!$course) jsonError('Course not found.', 404);

    $existing = Database::fetchOne(
        'SELECT id FROM course_enrollments WHERE user_id = ? AND course_id = ?',
        [$userId, $courseId]
    );

    if ($existing) {
        jsonSuccess(['already_enrolled' => true], 'You are already enrolled in this course.');
    }

    Database::insert(
        'INSERT INTO course_enrollments (user_id, course_id) VALUES (?, ?)',
        [$userId, $courseId]
    );

    jsonSuccess(['enrolled' => true], "Successfully enrolled! Let's start learning! 🚀");
}

// ─────────────────────────────────────────────
// UPDATE lesson video progress
// ─────────────────────────────────────────────
function handleUpdateProgress(int $userId, array $body): never
{
    $lessonId    = (int)($body['lesson_id'] ?? 0);
    $watchPercent = min(100, max(0, (int)($body['watch_percent'] ?? 0)));

    if ($lessonId <= 0) jsonError('Invalid lesson ID.', 422);

    // Get lesson info
    $lesson = Database::fetchOne(
        'SELECT l.id, l.course_id, l.xp_reward
         FROM lessons l
         JOIN course_enrollments ce ON ce.course_id = l.course_id AND ce.user_id = ?
         WHERE l.id = ?',
        [$userId, $lessonId]
    );

    if (!$lesson) jsonError('Lesson not found or not enrolled.', 404);

    // Get existing progress
    $existing = Database::fetchOne(
        'SELECT id, is_completed, xp_awarded, watch_percent FROM lesson_progress
         WHERE user_id = ? AND lesson_id = ?',
        [$userId, $lessonId]
    );

    $isNowComplete = $watchPercent >= VIDEO_COMPLETE_THRESHOLD;
    $xpAwarded     = 0;
    $newlyCompleted = false;

    if (!$existing) {
        // First time watching
        Database::insert(
            'INSERT INTO lesson_progress (user_id, lesson_id, watch_percent, is_completed, completed_at, xp_awarded)
             VALUES (?, ?, ?, ?, ?, ?)',
            [
                $userId, $lessonId, $watchPercent,
                $isNowComplete ? 1 : 0,
                $isNowComplete ? date('Y-m-d H:i:s') : null,
                0
            ]
        );
        $newlyCompleted = $isNowComplete;
    } else {
        // Update progress (only increase, never decrease watch_percent)
        $newPercent = max($existing['watch_percent'], $watchPercent);
        $wasCompleted = (bool)$existing['is_completed'];

        Database::execute(
            'UPDATE lesson_progress
             SET watch_percent = ?,
                 is_completed  = ?,
                 completed_at  = CASE WHEN is_completed = 0 AND ? = 1 THEN NOW() ELSE completed_at END
             WHERE user_id = ? AND lesson_id = ?',
            [
                $newPercent,
                ($wasCompleted || $isNowComplete) ? 1 : 0,
                $isNowComplete ? 1 : 0,
                $userId, $lessonId
            ]
        );

        $newlyCompleted = (!$wasCompleted && $isNowComplete);
    }

    // Award XP on first completion
    if ($newlyCompleted && (!$existing || !$existing['xp_awarded'])) {
        $xpToAward = $lesson['xp_reward'] > 0 ? $lesson['xp_reward'] : XP_LESSON_COMPLETE;
        awardXP($userId, $xpToAward, 'Lesson completed', 'lesson', $lessonId);
        $xpAwarded = $xpToAward;

        // Mark xp_awarded = 1
        Database::execute(
            'UPDATE lesson_progress SET xp_awarded = 1 WHERE user_id = ? AND lesson_id = ?',
            [$userId, $lessonId]
        );

        // Check first lesson achievement
        $lessonCount = Database::fetchOne(
            'SELECT COUNT(*) AS cnt FROM lesson_progress WHERE user_id = ? AND is_completed = 1',
            [$userId]
        );
        $cnt = (int)($lessonCount['cnt'] ?? 0);
        if ($cnt === 1)  grantAchievement($userId, 1);   // First Step
        if ($cnt >= 10)  grantAchievement($userId, 4);   // Quick Learner
        if ($cnt >= 50)  grantAchievement($userId, 5);   // Scholar

        // Update study session XP
        updateStreak($userId);
    }

    // Check if course is now fully complete
    $examJustUnlocked = false;
    if ($isNowComplete) {
        $examJustUnlocked = unlockExamIfReady($userId, $lesson['course_id']);

        if ($examJustUnlocked) {
            // Award course completion XP
            $course = Database::fetchOne('SELECT xp_reward, title FROM courses WHERE id = ?', [$lesson['course_id']]);
            if ($course) {
                awardXP($userId, (int)$course['xp_reward'], 'Course completed: ' . $course['title'], 'exam', $lesson['course_id']);
                grantAchievement($userId, 8); // Course Champion
            }
        }
    }

    $progress = getCourseProgress($userId, $lesson['course_id']);

    jsonSuccess([
        'watch_percent'     => $watchPercent,
        'newly_completed'   => $newlyCompleted,
        'xp_awarded'        => $xpAwarded,
        'exam_unlocked'     => $examJustUnlocked,
        'course_progress'   => $progress,
    ]);
}

// ─────────────────────────────────────────────
// LEADERBOARD
// ─────────────────────────────────────────────
function handleLeaderboard(): never
{
    $limit = min(50, max(5, (int)(getGet('limit') ?: 10)));

    $leaders = Database::fetchAll(
        "SELECT id, username, full_name, avatar_url, total_xp, current_streak,
                longest_streak, grade_level,
                RANK() OVER (ORDER BY total_xp DESC) AS `rank`
         FROM users
         WHERE role = 'student'
         ORDER BY total_xp DESC
         LIMIT ?",
        [$limit]
    );

    // Add level info to each
    foreach ($leaders as &$leader) {
        $leader['level'] = xpToLevel((int)$leader['total_xp']);
        $leader['formatted_xp'] = formatXP((int)$leader['total_xp']);
    }

    jsonSuccess(['leaderboard' => $leaders]);
}

// ─────────────────────────────────────────────
// DASHBOARD STATS
// ─────────────────────────────────────────────
function handleDashboardStats(int $userId): never
{
    $user = Database::fetchOne(
        'SELECT id, username, full_name, avatar_url, grade_level,
                total_xp, current_streak, longest_streak, last_study_date, created_at
         FROM users WHERE id = ?',
        [$userId]
    );

    // Enrollments
    $enrollments = Database::fetchAll(
        "SELECT c.id AS course_id, c.title, c.thumbnail_url, c.xp_reward,
                s.name AS subject_name, s.icon AS subject_icon, s.color AS subject_color,
                ce.enrolled_at, ce.completed_at, ce.exam_unlocked, ce.exam_passed,
                COALESCE(
                    ROUND(
                        SUM(CASE WHEN lp.is_completed = 1 THEN 1 ELSE 0 END) * 100.0
                        / NULLIF(COUNT(DISTINCT l.id), 0)
                    ), 0
                ) AS progress_percent
         FROM course_enrollments ce
         JOIN courses c ON ce.course_id = c.id
         JOIN subjects s ON c.subject_id = s.id
         LEFT JOIN lessons l ON l.course_id = c.id
         LEFT JOIN lesson_progress lp ON lp.lesson_id = l.id AND lp.user_id = ce.user_id
         WHERE ce.user_id = ?
         GROUP BY c.id, ce.enrolled_at, ce.completed_at, ce.exam_unlocked, ce.exam_passed
         ORDER BY ce.enrolled_at DESC",
        [$userId]
    );

    // Recent achievements
    $achievements = Database::fetchAll(
        "SELECT a.id, a.name, a.description, a.icon, ua.earned_at
         FROM user_achievements ua
         JOIN achievements a ON ua.achievement_id = a.id
         WHERE ua.user_id = ?
         ORDER BY ua.earned_at DESC
         LIMIT 6",
        [$userId]
    );

    // Recent XP activity
    $recentXp = Database::fetchAll(
        "SELECT amount, reason, ref_type, created_at
         FROM xp_transactions
         WHERE user_id = ?
         ORDER BY created_at DESC
         LIMIT 8",
        [$userId]
    );

    // Study streak data (last 14 days for heatmap)
    $streakData = Database::fetchAll(
        "SELECT study_date, xp_earned
         FROM study_sessions
         WHERE user_id = ? AND study_date >= DATE_SUB(CURDATE(), INTERVAL 14 DAY)
         ORDER BY study_date ASC",
        [$userId]
    );

    // Rank
    $rankRow = Database::fetchOne(
        "SELECT COUNT(*) + 1 AS `rank` FROM users
         WHERE role = 'student' AND total_xp > (SELECT total_xp FROM users WHERE id = ?)",
        [$userId]
    );

    $levelInfo = xpForNextLevel((int)$user['total_xp']);

    // Mini leaderboard (top 5)
    $topStudents = Database::fetchAll(
        "SELECT id, username, full_name, avatar_url, total_xp,
                RANK() OVER (ORDER BY total_xp DESC) AS `rank`
         FROM users WHERE role = 'student'
         ORDER BY total_xp DESC LIMIT 5",
        []
    );

    foreach ($topStudents as &$s) {
        $s['level'] = xpToLevel((int)$s['total_xp']);
        $s['formatted_xp'] = formatXP((int)$s['total_xp']);
    }

    jsonSuccess([
        'user'          => $user,
        'level'         => $levelInfo,
        'rank'          => (int)($rankRow['rank'] ?? 999),
        'enrollments'   => $enrollments,
        'achievements'  => $achievements,
        'recent_xp'     => $recentXp,
        'streak_data'   => $streakData,
        'top_students'  => $topStudents,
    ]);
}
