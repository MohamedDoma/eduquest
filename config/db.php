<?php
/**
 * EduQuest LMS - Database Configuration
 * Uses PDO with prepared statements for SQL injection prevention
 */

define('DB_HOST', 'localhost');
define('DB_PORT', '3306');
define('DB_NAME', 'eduquest_lms');
define('DB_USER', 'root');         // ← Change to your MySQL username
define('DB_PASS', '');             // ← Change to your MySQL password
define('DB_CHARSET', 'utf8mb4');

// Application settings
define('APP_NAME', 'EduQuest');
define('APP_URL',  'http://localhost/eduquest');  // ← Change to your domain
define('APP_VERSION', '1.0.0');

// Session settings
define('SESSION_LIFETIME', 86400);   // 24 hours
define('SESSION_NAME', 'eduquest_session');

// XP settings
define('XP_LESSON_COMPLETE',  20);
define('XP_EXAM_PASS',       100);
define('XP_STREAK_BONUS',     15);   // per day
define('XP_STREAK_WEEK',     100);   // 7-day streak bonus

// Video tracking - must watch this % before lesson counts as complete
define('VIDEO_COMPLETE_THRESHOLD', 90);

// n8n Webhook URLs (set these when your n8n workflow is ready)
define('N8N_WEBHOOK_CHAT',   getenv('N8N_CHAT_URL')   ?: '');
define('N8N_WEBHOOK_GRADE',  getenv('N8N_GRADE_URL')  ?: '');
define('N8N_MOCK_MODE',      true);   // ← Set to false when n8n is ready

// Error reporting (set to false in production)
define('DEBUG_MODE', true);

// ─────────────────────────────────────────────
// PDO Singleton
// ─────────────────────────────────────────────
class Database
{
    private static ?PDO $instance = null;

    private function __construct() {}
    private function __clone() {}

    public static function getInstance(): PDO
    {
        if (self::$instance === null) {
            $dsn = sprintf(
                'mysql:host=%s;port=%s;dbname=%s;charset=%s',
                DB_HOST, DB_PORT, DB_NAME, DB_CHARSET
            );

            $options = [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
                PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci",
            ];

            try {
                self::$instance = new PDO($dsn, DB_USER, DB_PASS, $options);
            } catch (PDOException $e) {
                if (DEBUG_MODE) {
                    die(json_encode(['success' => false, 'error' => 'DB Connection failed: ' . $e->getMessage()]));
                }
                die(json_encode(['success' => false, 'error' => 'Service temporarily unavailable.']));
            }
        }

        return self::$instance;
    }

    /**
     * Execute a query with optional bound parameters.
     * Returns the PDOStatement for flexibility.
     */
    public static function query(string $sql, array $params = []): PDOStatement
    {
        $stmt = self::getInstance()->prepare($sql);
        $stmt->execute($params);
        return $stmt;
    }

    /** Fetch a single row */
    public static function fetchOne(string $sql, array $params = []): ?array
    {
        $row = self::query($sql, $params)->fetch();
        return $row ?: null;
    }

    /** Fetch all rows */
    public static function fetchAll(string $sql, array $params = []): array
    {
        return self::query($sql, $params)->fetchAll();
    }

    /** Insert a row and return last insert ID */
    public static function insert(string $sql, array $params = []): int
    {
        self::query($sql, $params);
        return (int) self::getInstance()->lastInsertId();
    }

    /** Execute an update/delete and return affected rows */
    public static function execute(string $sql, array $params = []): int
    {
        return self::query($sql, $params)->rowCount();
    }
}
