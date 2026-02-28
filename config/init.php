<?php
/**
 * EduQuest LMS - Core Initialization
 * Bootstraps sessions, helpers, and shared utilities.
 * Include this at the top of every PHP file.
 */

require_once __DIR__ . '/db.php';

// ─────────────────────────────────────────────
// Session bootstrap
// ─────────────────────────────────────────────
if (session_status() === PHP_SESSION_NONE) {
    session_name(SESSION_NAME);
    session_set_cookie_params([
        'lifetime' => SESSION_LIFETIME,
        'path'     => '/',
        'secure'   => false,   // set true on HTTPS
        'httponly' => true,
        'samesite' => 'Lax',
    ]);
    session_start();
}

// ─────────────────────────────────────────────
// Security headers
// ─────────────────────────────────────────────
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: SAMEORIGIN');
header('X-XSS-Protection: 1; mode=block');
header('Referrer-Policy: strict-origin-when-cross-origin');

// ─────────────────────────────────────────────
// JSON API helper
// ─────────────────────────────────────────────
function jsonResponse(bool $success, mixed $data = null, string $message = '', int $httpCode = 200): never
{
    http_response_code($httpCode);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode([
        'success' => $success,
        'message' => $message,
        'data'    => $data,
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function jsonSuccess(mixed $data = null, string $message = 'OK'): never
{
    jsonResponse(true, $data, $message, 200);
}

function jsonError(string $message, int $code = 400, mixed $data = null): never
{
    jsonResponse(false, $data, $message, $code);
}

// ─────────────────────────────────────────────
// Auth helpers
// ─────────────────────────────────────────────
function isLoggedIn(): bool
{
    return isset($_SESSION['user_id']) && !empty($_SESSION['user_id']);
}

function currentUser(): ?array
{
    if (!isLoggedIn()) return null;

    // Return cached session user or re-fetch
    if (isset($_SESSION['user_cache'])) {
        return $_SESSION['user_cache'];
    }

    $user = Database::fetchOne(
        'SELECT id, username, email, full_name, avatar_url, role, grade_level,
                total_xp, current_streak, longest_streak, last_study_date
         FROM users WHERE id = ?',
        [$_SESSION['user_id']]
    );

    if ($user) {
        $_SESSION['user_cache'] = $user;
    }

    return $user ?: null;
}

function requireLogin(): void
{
    if (!isLoggedIn()) {
        if (isApiRequest()) {
            jsonError('Unauthorized. Please log in.', 401);
        }
        header('Location: ' . APP_URL . '/index.php?page=login&redirect=' . urlencode($_SERVER['REQUEST_URI']));
        exit;
    }
}

function requireRole(string ...$roles): void
{
    requireLogin();
    $user = currentUser();
    if (!in_array($user['role'], $roles, true)) {
        if (isApiRequest()) {
            jsonError('Forbidden. Insufficient privileges.', 403);
        }
        header('Location: ' . APP_URL . '/dashboard.php');
        exit;
    }
}

function isApiRequest(): bool
{
    return (
        (isset($_SERVER['HTTP_ACCEPT']) && str_contains($_SERVER['HTTP_ACCEPT'], 'application/json'))
        || str_contains($_SERVER['REQUEST_URI'], '/api/')
    );
}

// ─────────────────────────────────────────────
// Input sanitization
// ─────────────────────────────────────────────
function clean(string $value): string
{
    return htmlspecialchars(trim($value), ENT_QUOTES | ENT_HTML5, 'UTF-8');
}

function sanitizeEmail(string $email): string|false
{
    $email = trim(strtolower($email));
    return filter_var($email, FILTER_VALIDATE_EMAIL) ? $email : false;
}

function getPost(string $key, string $default = ''): string
{
    return clean($_POST[$key] ?? $default);
}

function getGet(string $key, string $default = ''): string
{
    return clean($_GET[$key] ?? $default);
}

function getJsonBody(): array
{
    $raw = file_get_contents('php://input');
    return json_decode($raw, true) ?? [];
}

// ─────────────────────────────────────────────
// CSRF protection
// ─────────────────────────────────────────────
function generateCsrfToken(): string
{
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

function verifyCsrfToken(string $token): bool
{
    if (empty($_SESSION['csrf_token'])) return false;
    return hash_equals($_SESSION['csrf_token'], $token);
}

// ─────────────────────────────────────────────
// XP & Gamification
// ─────────────────────────────────────────────
function awardXP(int $userId, int $amount, string $reason, string $refType = 'lesson', ?int $refId = null): void
{
    if ($amount <= 0) return;

    // Log the transaction
    Database::insert(
        'INSERT INTO xp_transactions (user_id, amount, reason, ref_type, ref_id)
         VALUES (?, ?, ?, ?, ?)',
        [$userId, $amount, $reason, $refType, $refId]
    );

    // Update user total
    Database::execute(
        'UPDATE users SET total_xp = total_xp + ? WHERE id = ?',
        [$amount, $userId]
    );

    // Clear user cache so next currentUser() re-fetches fresh data
    unset($_SESSION['user_cache']);

    // Check achievement milestones
    checkXpAchievements($userId);
}

function checkXpAchievements(int $userId): void
{
    $user = Database::fetchOne('SELECT total_xp FROM users WHERE id = ?', [$userId]);
    if (!$user) return;

    $xp = (int)$user['total_xp'];
    $milestones = [
        1000 => 6,   // XP Hunter
        5000 => 7,   // Elite Student
    ];

    foreach ($milestones as $threshold => $achievementId) {
        if ($xp >= $threshold) {
            grantAchievement($userId, $achievementId);
        }
    }
}

function grantAchievement(int $userId, int $achievementId): bool
{
    // Check if already earned
    $exists = Database::fetchOne(
        'SELECT 1 FROM user_achievements WHERE user_id = ? AND achievement_id = ?',
        [$userId, $achievementId]
    );
    if ($exists) return false;

    // Grant it
    Database::insert(
        'INSERT INTO user_achievements (user_id, achievement_id) VALUES (?, ?)',
        [$userId, $achievementId]
    );

    // Award bonus XP
    $achievement = Database::fetchOne(
        'SELECT xp_bonus, name FROM achievements WHERE id = ?',
        [$achievementId]
    );

    if ($achievement && $achievement['xp_bonus'] > 0) {
        Database::execute(
            'UPDATE users SET total_xp = total_xp + ? WHERE id = ?',
            [$achievement['xp_bonus'], $userId]
        );
        Database::insert(
            'INSERT INTO xp_transactions (user_id, amount, reason, ref_type, ref_id)
             VALUES (?, ?, ?, "achievement", ?)',
            [$userId, $achievement['xp_bonus'], 'Achievement unlocked: ' . $achievement['name'], $achievementId]
        );
    }

    unset($_SESSION['user_cache']);
    return true;
}

function updateStreak(int $userId): array
{
    $today = date('Y-m-d');

    $user = Database::fetchOne(
        'SELECT last_study_date, current_streak, longest_streak FROM users WHERE id = ?',
        [$userId]
    );
    if (!$user) return ['streak' => 0, 'bonus_xp' => 0, 'is_new_day' => false];

    $lastDate    = $user['last_study_date'];
    $streak      = (int)$user['current_streak'];
    $bonusXp     = 0;
    $isNewDay    = false;

    if ($lastDate === $today) {
        // Already studied today - just record session if not exists
        return ['streak' => $streak, 'bonus_xp' => 0, 'is_new_day' => false];
    }

    $isNewDay = true;
    $yesterday = date('Y-m-d', strtotime('-1 day'));

    if ($lastDate === $yesterday) {
        // Consecutive day — extend streak
        $streak++;
    } else {
        // Streak broken
        $streak = 1;
    }

    $longest = max((int)$user['longest_streak'], $streak);

    // Update user record
    Database::execute(
        'UPDATE users SET current_streak = ?, longest_streak = ?, last_study_date = ? WHERE id = ?',
        [$streak, $longest, $today, $userId]
    );

    // Record study session
    Database::insert(
        'INSERT IGNORE INTO study_sessions (user_id, study_date, xp_earned) VALUES (?, ?, 0)',
        [$userId, $today]
    );

    // Daily streak XP bonus
    $bonusXp = XP_STREAK_BONUS;
    awardXP($userId, $bonusXp, "Daily study streak bonus (Day $streak)", 'streak');

    // 7-day streak bonus
    if ($streak === 7 || ($streak > 7 && $streak % 7 === 0)) {
        awardXP($userId, XP_STREAK_WEEK, "7-day streak milestone! 🔥", 'streak');
        $bonusXp += XP_STREAK_WEEK;
        grantAchievement($userId, 2); // On Fire
    }

    // 30-day streak bonus
    if ($streak >= 30) {
        grantAchievement($userId, 3); // Unstoppable
    }

    unset($_SESSION['user_cache']);

    return [
        'streak'     => $streak,
        'bonus_xp'   => $bonusXp,
        'is_new_day' => true,
    ];
}

// ─────────────────────────────────────────────
// Course progress helpers
// ─────────────────────────────────────────────
function getCourseProgress(int $userId, int $courseId): array
{
    $total = Database::fetchOne(
        'SELECT COUNT(*) AS cnt FROM lessons WHERE course_id = ?',
        [$courseId]
    );
    $totalCount = (int)($total['cnt'] ?? 0);

    $done = Database::fetchOne(
        'SELECT COUNT(*) AS cnt
         FROM lesson_progress lp
         JOIN lessons l ON lp.lesson_id = l.id
         WHERE lp.user_id = ? AND l.course_id = ? AND lp.is_completed = 1',
        [$userId, $courseId]
    );
    $doneCount = (int)($done['cnt'] ?? 0);

    $percent = $totalCount > 0 ? round(($doneCount / $totalCount) * 100) : 0;

    return [
        'total'      => $totalCount,
        'completed'  => $doneCount,
        'percent'    => $percent,
        'is_done'    => $percent >= 100,
    ];
}

function unlockExamIfReady(int $userId, int $courseId): bool
{
    $progress = getCourseProgress($userId, $courseId);
    if (!$progress['is_done']) return false;

    $enrollment = Database::fetchOne(
        'SELECT exam_unlocked FROM course_enrollments WHERE user_id = ? AND course_id = ?',
        [$userId, $courseId]
    );

    if ($enrollment && !$enrollment['exam_unlocked']) {
        Database::execute(
            'UPDATE course_enrollments SET exam_unlocked = 1 WHERE user_id = ? AND course_id = ?',
            [$userId, $courseId]
        );
        return true; // newly unlocked
    }

    return (bool)($enrollment['exam_unlocked'] ?? false);
}

// ─────────────────────────────────────────────
// Leaderboard helper
// ─────────────────────────────────────────────
function getLeaderboard(int $limit = 10): array
{
    return Database::fetchAll(
        'SELECT id, username, full_name, avatar_url, total_xp, current_streak, grade_level,
                RANK() OVER (ORDER BY total_xp DESC) AS `rank`
         FROM users
         WHERE role = "student"
         ORDER BY total_xp DESC
         LIMIT ?',
        [$limit]
    );
}

// ─────────────────────────────────────────────
// Formatting helpers
// ─────────────────────────────────────────────
function formatXP(int $xp): string
{
    if ($xp >= 1000) {
        return round($xp / 1000, 1) . 'k';
    }
    return (string)$xp;
}

function timeAgo(string $datetime): string
{
    $diff = time() - strtotime($datetime);
    return match(true) {
        $diff < 60      => 'just now',
        $diff < 3600    => (int)($diff / 60) . 'm ago',
        $diff < 86400   => (int)($diff / 3600) . 'h ago',
        $diff < 604800  => (int)($diff / 86400) . 'd ago',
        default         => date('M j, Y', strtotime($datetime)),
    };
}

function secondsToTime(int $seconds): string
{
    $m = floor($seconds / 60);
    $s = $seconds % 60;
    return sprintf('%d:%02d', $m, $s);
}

function xpToLevel(int $xp): int
{
    // Level formula: level = floor(sqrt(xp / 50)) + 1
    return (int)(floor(sqrt($xp / 50))) + 1;
}

function xpForNextLevel(int $xp): array
{
    $level       = xpToLevel($xp);
    $current_min = (int)(50 * ($level - 1) ** 2);
    $next_min    = (int)(50 * $level ** 2);
    $progress    = $next_min > $current_min
        ? round(($xp - $current_min) / ($next_min - $current_min) * 100)
        : 100;

    return [
        'level'       => $level,
        'current_xp'  => $xp - $current_min,
        'needed_xp'   => $next_min - $current_min,
        'percent'     => min(100, $progress),
        'next_level'  => $level + 1,
    ];
}
