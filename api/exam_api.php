<?php
/**
 * EduQuest — Exam API
 * Handles: start_session, save_message, save_result
 */
require_once __DIR__ . '/../config/init.php';

header('Content-Type: application/json; charset=utf-8');
requireLogin();

$body   = getJsonBody();
$action = $body['action'] ?? '';
$userId = $_SESSION['user_id'];

match($action) {
    'start_session' => handleStartSession($userId, $body),
    'save_message'  => handleSaveMessage($userId, $body),
    'save_result'   => handleSaveResult($userId, $body),
    default         => jsonError('Unknown action', 400),
};

function handleStartSession(int $userId, array $body): never
{
    $courseId = (int)($body['course_id'] ?? 0);
    $language = in_array($body['language'] ?? '', ['English','Chinese','Tamil','Malay'])
        ? $body['language'] : 'English';

    if (!$courseId) jsonError('Invalid course_id', 422);

    // Close any open sessions for same user+course
    Database::execute(
        "UPDATE chat_sessions SET status='abandoned', ended_at=NOW()
         WHERE user_id=? AND course_id=? AND status='active'",
        [$userId, $courseId]
    );

    $sessionId = Database::insert(
        'INSERT INTO chat_sessions (user_id, course_id, language) VALUES (?,?,?)',
        [$userId, $courseId, $language]
    );

    jsonSuccess(['session_id' => $sessionId]);
}

function handleSaveMessage(int $userId, array $body): never
{
    $sessionId = (int)($body['session_id'] ?? 0);
    $role      = in_array($body['role'] ?? '', ['user','assistant']) ? $body['role'] : 'user';
    $content   = trim($body['content'] ?? '');

    if (!$sessionId || !$content) jsonError('Missing fields', 422);

    // Verify ownership
    $session = Database::fetchOne(
        'SELECT id FROM chat_sessions WHERE id=? AND user_id=?',
        [$sessionId, $userId]
    );
    if (!$session) jsonError('Session not found', 404);

    Database::insert(
        'INSERT INTO chat_messages (session_id, role, content) VALUES (?,?,?)',
        [$sessionId, $role, $content]
    );

    jsonSuccess(['saved' => true]);
}

function handleSaveResult(int $userId, array $body): never
{
    $courseId = (int)($body['course_id'] ?? 0);
    $score    = min(100, max(0, (int)($body['score'] ?? 0)));
    $passed   = (bool)($body['passed'] ?? false);
    $language = $body['language'] ?? 'English';

    if (!$courseId) jsonError('Invalid course_id', 422);

    // Update enrollment
    Database::execute(
        'UPDATE course_enrollments
         SET exam_passed=?, exam_score=?,
             completed_at = CASE WHEN completed_at IS NULL AND ? = 1 THEN NOW() ELSE completed_at END
         WHERE user_id=? AND course_id=?',
        [$passed ? 1 : 0, $score, $passed ? 1 : 0, $userId, $courseId]
    );

    // Close chat session
    Database::execute(
        "UPDATE chat_sessions SET status=?, score=?, ended_at=NOW()
         WHERE user_id=? AND course_id=? AND status='active'",
        [$passed ? 'completed' : 'completed', $score, $userId, $courseId]
    );

    // Award XP for exam
    if ($passed) {
        $course = Database::fetchOne('SELECT xp_reward, title FROM courses WHERE id=?', [$courseId]);
        if ($course) {
            awardXP($userId, (int)$course['xp_reward'],
                'Exam passed: ' . $course['title'], 'exam', $courseId);
        }
        // Exam Ace achievement (90%+)
        if ($score >= 90) grantAchievement($userId, 9);
    } else {
        // Partial XP for participation
        $partial = max(5, (int)round($score * 0.3));
        awardXP($userId, $partial, 'Exam participation XP', 'exam', $courseId);
    }

    // Polyglot achievement
    if ($language !== 'English') grantAchievement($userId, 10);

    jsonSuccess([
        'score'  => $score,
        'passed' => $passed,
        'xp_awarded' => $passed ? 'full' : 'partial',
    ]);
}
