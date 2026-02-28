<?php
/**
 * EduQuest LMS - Authentication API
 * Endpoint: /api/auth.php
 * Handles: register, login, logout, me
 *
 * All responses are JSON.
 * POST body should be JSON or form-encoded.
 */

require_once __DIR__ . '/../config/init.php';

header('Content-Type: application/json; charset=utf-8');

// Only allow POST (and GET for /me & /logout convenience)
$method = $_SERVER['REQUEST_METHOD'];
$action = getGet('action') ?: (getJsonBody()['action'] ?? '');

// Support both JSON body and $_POST
$body = $method === 'POST'
    ? (empty($_POST) ? getJsonBody() : $_POST)
    : [];

// ─────────────────────────────────────────────
// Router
// ─────────────────────────────────────────────
match($action) {
    'register' => handleRegister($body),
    'login'    => handleLogin($body),
    'logout'   => handleLogout(),
    'me'       => handleMe(),
    default    => jsonError('Unknown action. Use: register, login, logout, me.', 400),
};

// ─────────────────────────────────────────────
// REGISTER
// ─────────────────────────────────────────────
function handleRegister(array $body): never
{
    // ── Validate required fields ──────────────
    $required = ['username', 'email', 'password', 'full_name'];
    foreach ($required as $field) {
        if (empty(trim($body[$field] ?? ''))) {
            jsonError("Field '$field' is required.", 422);
        }
    }

    $username   = trim($body['username']);
    $email      = sanitizeEmail($body['email'] ?? '');
    $password   = $body['password'];
    $fullName   = trim($body['full_name']);
    $gradeLevel = (int)($body['grade_level'] ?? 10);

    // ── Validation rules ─────────────────────
    if (!preg_match('/^[a-zA-Z0-9_]{3,30}$/', $username)) {
        jsonError('Username must be 3-30 characters (letters, numbers, underscore only).', 422);
    }

    if (!$email) {
        jsonError('Please enter a valid email address.', 422);
    }

    if (strlen($password) < 8) {
        jsonError('Password must be at least 8 characters.', 422);
    }

    if (strlen($fullName) < 2 || strlen($fullName) > 100) {
        jsonError('Full name must be between 2 and 100 characters.', 422);
    }

    if ($gradeLevel < 7 || $gradeLevel > 12) {
        jsonError('Grade level must be between 7 and 12.', 422);
    }

    // ── Uniqueness checks ─────────────────────
    $existingUser = Database::fetchOne(
        'SELECT id FROM users WHERE username = ? OR email = ?',
        [$username, $email]
    );
    if ($existingUser) {
        jsonError('Username or email is already taken. Please choose another.', 409);
    }

    // ── Create user ───────────────────────────
    $passwordHash = password_hash($password, PASSWORD_BCRYPT, ['cost' => 12]);

    // Generate avatar using Dicebear
    $seed      = urlencode($username . rand(1, 999));
    $avatarUrl = "https://api.dicebear.com/7.x/adventurer/svg?seed={$seed}";

    $userId = Database::insert(
        'INSERT INTO users (username, email, password_hash, full_name, avatar_url, grade_level)
         VALUES (?, ?, ?, ?, ?, ?)',
        [$username, $email, $passwordHash, $fullName, $avatarUrl, $gradeLevel]
    );

    if (!$userId) {
        jsonError('Registration failed. Please try again.', 500);
    }

    // Award "First Step" achievement potential (will trigger on first lesson complete)
    // Start session immediately
    $_SESSION['user_id']    = $userId;
    $_SESSION['user_cache'] = null;

    $user = Database::fetchOne(
        'SELECT id, username, full_name, avatar_url, role, grade_level, total_xp, current_streak
         FROM users WHERE id = ?',
        [$userId]
    );

    session_regenerate_id(true);

    jsonSuccess([
        'user'         => $user,
        'redirect'     => APP_URL . '/dashboard.php',
        'csrf_token'   => generateCsrfToken(),
    ], 'Welcome to EduQuest! 🎉 Your account has been created.');
}

// ─────────────────────────────────────────────
// LOGIN
// ─────────────────────────────────────────────
function handleLogin(array $body): never
{
    $identifier = trim($body['identifier'] ?? ''); // username or email
    $password   = $body['password'] ?? '';
    $remember   = !empty($body['remember']);

    if (empty($identifier) || empty($password)) {
        jsonError('Please enter your username/email and password.', 422);
    }

    // Find user by username OR email
    $user = Database::fetchOne(
        'SELECT id, username, email, password_hash, full_name, avatar_url,
                role, grade_level, total_xp, current_streak, longest_streak,
                last_study_date
         FROM users
         WHERE username = ? OR email = ?
         LIMIT 1',
        [$identifier, strtolower($identifier)]
    );

    if (!$user || !password_verify($password, $user['password_hash'])) {
        // Generic message to prevent user enumeration
        jsonError('Invalid username/email or password.', 401);
    }

    // ── Create session ────────────────────────
    session_regenerate_id(true);
    $_SESSION['user_id']    = $user['id'];
    $_SESSION['user_cache'] = null;

    if ($remember) {
        // Extend session cookie lifetime
        $params = session_get_cookie_params();
        setcookie(
            session_name(),
            session_id(),
            time() + (86400 * 30),
            $params['path'],
            $params['domain'],
            $params['secure'],
            $params['httponly']
        );
    }

    // ── Update streak ─────────────────────────
    $streakResult = updateStreak($user['id']);

    // Remove sensitive data before sending
    unset($user['password_hash']);

    // Refresh XP from DB (streak may have added XP)
    $freshUser = Database::fetchOne(
        'SELECT id, username, full_name, avatar_url, role, grade_level,
                total_xp, current_streak, longest_streak, last_study_date
         FROM users WHERE id = ?',
        [$user['id']]
    );

    jsonSuccess([
        'user'         => $freshUser,
        'streak'       => $streakResult,
        'redirect'     => APP_URL . '/dashboard.php',
        'csrf_token'   => generateCsrfToken(),
    ], 'Welcome back, ' . $freshUser['full_name'] . '! 👋');
}

// ─────────────────────────────────────────────
// LOGOUT
// ─────────────────────────────────────────────
function handleLogout(): never
{
    if (session_status() === PHP_SESSION_ACTIVE) {
        $_SESSION = [];
        session_destroy();

        // Clear session cookie
        if (ini_get('session.use_cookies')) {
            $params = session_get_cookie_params();
            setcookie(
                session_name(), '', time() - 3600,
                $params['path'], $params['domain'],
                $params['secure'], $params['httponly']
            );
        }
    }

    jsonSuccess(['redirect' => APP_URL . '/index.php'], 'You have been logged out. See you soon! 👋');
}

// ─────────────────────────────────────────────
// ME (get current authenticated user)
// ─────────────────────────────────────────────
function handleMe(): never
{
    if (!isLoggedIn()) {
        jsonError('Not authenticated.', 401);
    }

    $userId = $_SESSION['user_id'];

    $user = Database::fetchOne(
        'SELECT id, username, email, full_name, avatar_url, role, grade_level,
                total_xp, current_streak, longest_streak, last_study_date, created_at
         FROM users WHERE id = ?',
        [$userId]
    );

    if (!$user) {
        session_destroy();
        jsonError('User account not found.', 404);
    }

    // Level info
    $levelInfo = xpForNextLevel((int)$user['total_xp']);

    // Recent achievements
    $achievements = Database::fetchAll(
        'SELECT a.id, a.name, a.icon, a.description, ua.earned_at
         FROM user_achievements ua
         JOIN achievements a ON ua.achievement_id = a.id
         WHERE ua.user_id = ?
         ORDER BY ua.earned_at DESC
         LIMIT 5',
        [$userId]
    );

    // Enrolled courses count
    $enrollments = Database::fetchOne(
        'SELECT COUNT(*) AS total,
                SUM(CASE WHEN completed_at IS NOT NULL THEN 1 ELSE 0 END) AS completed
         FROM course_enrollments WHERE user_id = ?',
        [$userId]
    );

    // Leaderboard rank
    $rankRow = Database::fetchOne(
        'SELECT COUNT(*) + 1 AS `rank`
         FROM users
         WHERE role = "student" AND total_xp > (SELECT total_xp FROM users WHERE id = ?)',
        [$userId]
    );

    jsonSuccess([
        'user'         => $user,
        'level'        => $levelInfo,
        'achievements' => $achievements,
        'enrollments'  => $enrollments,
        'rank'         => (int)($rankRow['rank'] ?? 999),
        'csrf_token'   => generateCsrfToken(),
    ]);
}
