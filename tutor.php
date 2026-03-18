<?php
require_once __DIR__ . '/config/init.php';
requireLogin();

$courseId = (int)($_GET['course'] ?? 0);
if (!$courseId) { header('Location: courses.php'); exit; }

$user = currentUser();

// Check enrollment only (No need to check exam_unlocked for the Tutor)
$enrollment = Database::fetchOne(
    'SELECT * FROM course_enrollments WHERE user_id = ? AND course_id = ?',
    [$user['id'], $courseId]
);

if (!$enrollment) { header('Location: courses.php'); exit; }

$course = Database::fetchOne(
    'SELECT c.*, s.name AS subject_name, s.icon AS subject_icon
     FROM courses c JOIN subjects s ON c.subject_id = s.id
     WHERE c.id = ?',
    [$courseId]
);
if (!$course) { header('Location: courses.php'); exit; }

// Get lessons for context (AI Tutor will use these to know what the student is studying)
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
<title>AI Tutor — <?= htmlspecialchars($course['title']) ?> — EduQuest</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;500;600;700;800&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;1,9..40,300&display=swap" rel="stylesheet">
<link rel="stylesheet" href="assets/css/main.css">
<link rel="stylesheet" href="assets/css/exam.css"> </head>
<body class="exam-page">
<button class="theme-toggle" id="themeToggle"><span class="theme-icon">🌙</span></button>
<div class="bg-grid"></div>
<div class="bg-orb orb-1"></div>

<div class="exam-start-screen" id="examStartScreen">
  <div class="exam-start-card">
    <div class="exam-start-icon">🤖</div>
    <h1 class="exam-start-title">AI Course Tutor</h1>
    <p class="exam-start-course"><?= htmlspecialchars($course['title']) ?></p>

    <div class="exam-info-grid">
      <div class="exam-info-item"><div class="eii-val">24/7</div><div class="eii-label">Availability</div></div>
      <div class="exam-info-item"><div class="eii-val">Deep</div><div class="eii-label">Explanations</div></div>
      <div class="exam-info-item"><div class="eii-val">Zero</div><div class="eii-label">Pressure</div></div>
    </div>

    <div class="exam-rules">
      <div class="exam-rule"><span>🧠</span> Ask me anything about the course topics.</div>
      <div class="exam-rule"><span>💡</span> Need more examples? Just ask!</div>
      <div class="exam-rule"><span>💬</span> This is a learning space, no grades or scores.</div>
      <div class="exam-rule"><span>🌐</span> Choose your preferred explanation language below.</div>
    </div>

    <div class="exam-lang-wrap">
      <label class="exam-lang-label">Tutor Language</label>
      <div class="exam-lang-options" id="langOptions">
        <button class="lang-btn active" data-lang="English">🇬🇧 English</button>
        <button class="lang-btn" data-lang="Chinese">🇨🇳 Chinese</button>
        <button class="lang-btn" data-lang="Tamil">🇮🇳 Tamil</button>
        <button class="lang-btn" data-lang="Malay">🇲🇾 Malay</button>
      </div>
    </div>

    <button class="btn-primary" id="startExamBtn" style="width:100%;padding:16px;font-size:1.05rem;margin-top:8px">
      Start Chatting 💬
    </button>
    
    <!-- <a href="exam.php?course=<?= $courseId ?>" class="btn-secondary" style="display:block; text-align:center; width:100%; padding:16px; font-size:1.05rem; margin-top:8px; background-color: #374151; color: white; border-radius: 8px; text-decoration: none;">
      📝 Take the AI Exam
    </a> -->

    <a href="course.php?id=<?= $courseId ?>" class="exam-back-link">← Back to Course</a>
  </div>
</div>

<div class="exam-interface hidden" id="examInterface">

  <div class="exam-topbar">
    <div class="exam-topbar-left">
      <div class="exam-course-badge">
        🤖
        <span><?= htmlspecialchars($course['title']) ?> - Tutor</span>
      </div>
    </div>
    <div class="exam-topbar-right">
      <div class="exam-lang-badge" id="examLangBadge">🇬🇧 English</div>
      </div>
  </div>

  <div class="exam-chat-wrap">
    <div class="exam-chat" id="examChat">
      </div>

    <div class="typing-indicator hidden" id="typingIndicator">
      <img class="typing-avatar" src="https://api.dicebear.com/7.x/bottts/svg?seed=tutorbot&backgroundColor=10b981" alt="AI">
      <div class="typing-dots">
        <span></span><span></span><span></span>
      </div>
    </div>

    <div class="exam-input-wrap" id="examInputWrap">
      <textarea
        id="examInput"
        class="exam-input"
        placeholder="Ask a question about the course..."
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

<div class="toast-container" id="toastContainer"></div>

<script src="assets/js/theme.js"></script>
<script>
window.EQ_USER   = <?= json_encode(['id'=>(int)$user['id'],'full_name'=>$user['full_name']]) ?>;
window.EQ_TUTOR  = <?= json_encode([
  'course_id'    => (int)$courseId,
  'course_title' => $course['title'],
  'subject'      => $course['subject_name'],
  'lesson_topics'=> $lessonTopics,
  'mode'         => 'tutor' // To let the JS know we are in tutor mode, not exam mode
]) ?>;
</script>
<script src="assets/js/tutor.js"></script>
</body>
</html>