<?php
require_once __DIR__ . '/config/init.php';
requireLogin();

$courseId = (int)($_GET['course'] ?? 0);
if (!$courseId) { header('Location: courses.php'); exit; }

$user = currentUser();

// Check enrollment & exam unlock
$enrollment = Database::fetchOne(
    'SELECT * FROM course_enrollments WHERE user_id = ? AND course_id = ?',
    [$user['id'], $courseId]
);

if (!$enrollment) { header('Location: courses.php'); exit; }

// Auto check progress (in case backend missed it)
unlockExamIfReady($user['id'], $courseId);
$enrollment = Database::fetchOne(
    'SELECT * FROM course_enrollments WHERE user_id = ? AND course_id = ?',
    [$user['id'], $courseId]
);

if (!$enrollment['exam_unlocked']) {
    header('Location: course.php?id=' . $courseId . '&msg=complete_first');
    exit;
}

$course = Database::fetchOne(
    'SELECT c.*, s.name AS subject_name, s.icon AS subject_icon
     FROM courses c JOIN subjects s ON c.subject_id = s.id
     WHERE c.id = ?',
    [$courseId]
);
if (!$course) { header('Location: courses.php'); exit; }

// Get lessons for context (AI will use these titles as topic hints)
$lessons = Database::fetchAll(
    'SELECT title FROM lessons WHERE course_id = ? ORDER BY sort_order ASC',
    [$courseId]
);
$lessonTopics = implode(', ', array_column($lessons, 'title'));
?>
<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>AI Exam — <?= htmlspecialchars($course['title']) ?> — EduQuest</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;500;600;700;800&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;1,9..40,300&display=swap" rel="stylesheet">
<link rel="stylesheet" href="assets/css/main.css">
<link rel="stylesheet" href="assets/css/exam.css">
</head>
<body class="exam-page">
<button class="theme-toggle" id="themeToggle"><span class="theme-icon">🌙</span></button>
<div class="bg-grid"></div>
<div class="bg-orb orb-1"></div>

<!-- ══ START SCREEN ══ -->
<div class="exam-start-screen" id="examStartScreen">
  <div class="exam-start-card">
    <div class="exam-start-icon"><?= htmlspecialchars($course['subject_icon']) ?></div>
    <h1 class="exam-start-title">AI Exam</h1>
    <p class="exam-start-course"><?= htmlspecialchars($course['title']) ?></p>

    <div class="exam-info-grid">
      <div class="exam-info-item"><div class="eii-val">Socratic</div><div class="eii-label">Method</div></div>
      <div class="exam-info-item"><div class="eii-val">10–15</div><div class="eii-label">Questions</div></div>
      <div class="exam-info-item"><div class="eii-val">+<?= (int)$course['xp_reward'] ?> XP</div><div class="eii-label">On Pass</div></div>
    </div>

    <div class="exam-rules">
      <div class="exam-rule"><span>🧠</span> The AI uses the Socratic method — it guides you to the answer</div>
      <div class="exam-rule"><span>🚫</span> It will NOT give you direct answers — think it through!</div>
      <div class="exam-rule"><span>📈</span> Questions get harder as you progress</div>
      <div class="exam-rule"><span>🌐</span> Choose your exam language below</div>
    </div>

    <div class="exam-lang-wrap">
      <label class="exam-lang-label">Exam Language</label>
      <div class="exam-lang-options" id="langOptions">
        <button class="lang-btn active" data-lang="English">🇬🇧 English</button>
        <button class="lang-btn" data-lang="Chinese">🇨🇳 Chinese</button>
        <button class="lang-btn" data-lang="Tamil">🇮🇳 Tamil</button>
        <button class="lang-btn" data-lang="Malay">🇲🇾 Malay</button>
      </div>
    </div>

    <button class="btn-primary" id="startExamBtn" style="width:100%;padding:16px;font-size:1.05rem;margin-top:8px">
      Start AI Exam 🚀
    </button>
    <a href="course.php?id=<?= $courseId ?>" class="exam-back-link">← Back to Course</a>
  </div>
</div>

<!-- ══ EXAM INTERFACE ══ -->
<div class="exam-interface hidden" id="examInterface">

  <!-- EXAM TOP BAR -->
  <div class="exam-topbar">
    <div class="exam-topbar-left">
      <div class="exam-course-badge">
        <?= htmlspecialchars($course['subject_icon']) ?>
        <span><?= htmlspecialchars($course['title']) ?></span>
      </div>
    </div>
    <div class="exam-progress-wrap">
      <div class="exam-progress-dots" id="examProgressDots"></div>
      <span class="exam-q-count" id="examQCount">Q1</span>
    </div>
    <div class="exam-topbar-right">
      <div class="exam-lang-badge" id="examLangBadge">🇬🇧 English</div>
      <div class="exam-score-badge" id="examScoreBadge">Score: 0%</div>
    </div>
  </div>

  <!-- CHAT AREA -->
  <div class="exam-chat-wrap">
    <div class="exam-chat" id="examChat">
      <!-- Messages injected by JS -->
    </div>

    <!-- TYPING INDICATOR -->
    <div class="typing-indicator hidden" id="typingIndicator">
      <img class="typing-avatar" src="https://api.dicebear.com/7.x/bottts/svg?seed=exambot&backgroundColor=6366f1" alt="AI">
      <div class="typing-dots">
        <span></span><span></span><span></span>
      </div>
    </div>

    <!-- INPUT -->
    <div class="exam-input-wrap" id="examInputWrap">
      <textarea
        id="examInput"
        class="exam-input"
        placeholder="Type your answer here…"
        rows="1"
        maxlength="1000"
        disabled
      ></textarea>
      <button class="exam-send-btn" id="examSendBtn" disabled>
        <svg viewBox="0 0 24 24" fill="currentColor" width="20" height="20">
          <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"/>
        </svg>
      </button>
    </div>
  </div>

</div>

<!-- ══ RESULTS SCREEN ══ -->
<div class="exam-results hidden" id="examResults">
  <div class="exam-results-card">
    <div class="results-emoji" id="resultsEmoji">🎉</div>
    <h2 class="results-title" id="resultsTitle">Exam Complete!</h2>
    <div class="results-score-ring" id="resultsScoreRing">
      <div class="score-ring-inner">
        <div class="score-big" id="resultsBigScore">0%</div>
        <div class="score-label">Score</div>
      </div>
    </div>
    <div class="results-xp-earned" id="resultsXpEarned"></div>
    <div class="results-feedback" id="resultsFeedback"></div>
    <div class="results-actions">
      <a href="dashboard.php" class="btn-primary">🏠 Back to Dashboard</a>
      <a href="course.php?id=<?= $courseId ?>" class="btn-secondary">📚 Review Course</a>
    </div>
  </div>
</div>

<div class="xp-pop" id="xpPop"></div>
<div class="toast-container" id="toastContainer"></div>

<script src="assets/js/theme.js"></script>
<script>
window.EQ_USER   = <?= json_encode(['id'=>(int)$user['id'],'full_name'=>$user['full_name'],'total_xp'=>(int)$user['total_xp']]) ?>;
window.EQ_EXAM   = <?= json_encode([
  'course_id'    => (int)$courseId,
  'course_title' => $course['title'],
  'subject'      => $course['subject_name'],
  'subject_icon' => $course['subject_icon'],
  'xp_reward'    => (int)$course['xp_reward'],
  'lesson_topics'=> $lessonTopics,
  'already_passed'=> (bool)$enrollment['exam_passed'],
  'prev_score'    => (int)$enrollment['exam_score'],
]) ?>;
</script>
<script src="assets/js/exam.js"></script>
</body>
</html>
