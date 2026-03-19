<?php
require_once __DIR__ . '/config/init.php';
requireLogin();

$courseId = (int)($_GET['id'] ?? 0);
if (!$courseId) { header('Location: courses.php'); exit; }

$user = currentUser();

// Verify enrollment
$enrollment = Database::fetchOne(
    'SELECT * FROM course_enrollments WHERE user_id = ? AND course_id = ?',
    [$user['id'], $courseId]
);

// Auto-enroll if not enrolled
if (!$enrollment) {
    Database::insert(
        'INSERT INTO course_enrollments (user_id, course_id) VALUES (?, ?)',
        [$user['id'], $courseId]
    );
    $enrollment = Database::fetchOne(
        'SELECT * FROM course_enrollments WHERE user_id = ? AND course_id = ?',
        [$user['id'], $courseId]
    );
}

// Get course info
$course = Database::fetchOne(
    'SELECT c.*, s.name AS subject_name, s.icon AS subject_icon, s.color AS subject_color,
            u.full_name AS teacher_name, u.avatar_url AS teacher_avatar
     FROM courses c
     JOIN subjects s ON c.subject_id = s.id
     JOIN users u ON c.teacher_id = u.id
     WHERE c.id = ? AND c.is_published = 1',
    [$courseId]
);
if (!$course) { header('Location: courses.php'); exit; }

// Get lessons with progress
$lessons = Database::fetchAll(
    'SELECT l.*, COALESCE(lp.watch_percent,0) AS watch_percent,
            COALESCE(lp.is_completed,0) AS is_completed
     FROM lessons l
     LEFT JOIN lesson_progress lp ON lp.lesson_id = l.id AND lp.user_id = ?
     WHERE l.course_id = ?
     ORDER BY l.sort_order ASC',
    [$user['id'], $courseId]
);

// First uncompleted lesson (or first lesson)
$currentLesson = null;
foreach ($lessons as $l) {
    if (!$l['is_completed']) { $currentLesson = $l; break; }
}
if (!$currentLesson && count($lessons)) {
    $currentLesson = $lessons[0];
}

$hasLessons = true;
if (!$currentLesson) {
    $hasLessons = false;
    $currentLesson = [
        'id' => 0,
        'title' => 'No lessons available',
        'description' => 'This course has no lessons yet. Check back later.',
        'video_url' => '',
        'video_duration' => 0,
        'xp_reward' => 0,
        'watch_percent' => 0,
        'is_completed' => 0,
    ];
}

$lessonId = (int)($_GET['lesson'] ?? $currentLesson['id'] ?? 0);
// Find requested lesson
$activeLessonIdx = 0;
foreach ($lessons as $idx => $l) {
    if ($l['id'] == $lessonId) { $currentLesson = $l; $activeLessonIdx = $idx; break; }
}

$progress = getCourseProgress($user['id'], $courseId);
?>
<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><?= htmlspecialchars($course['title']) ?> — EduQuest</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;500;600;700;800&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;1,9..40,300&display=swap" rel="stylesheet">
<link rel="stylesheet" href="assets/css/main.css">
<link rel="stylesheet" href="assets/css/player.css">
</head>
<body class="player-page">
<button class="theme-toggle" id="themeToggle"><span class="theme-icon">🌙</span></button>

<!-- TOP BAR -->
<div class="player-topbar">
  <a href="courses.php" class="player-back">← Back</a>
  <div class="player-course-title">
    <span><?= htmlspecialchars($course['subject_icon']) ?></span>
    <span><?= htmlspecialchars($course['title']) ?></span>
  </div>
  <div class="player-progress-wrap">
    <div class="player-progress-bar">
      <div class="player-progress-fill" id="courseProgressFill" style="width:<?= $progress['percent'] ?>%"></div>
    </div>
    <span class="player-progress-pct" id="courseProgressPct"><?= $progress['percent'] ?>%</span>
  </div>
  <div class="player-xp-badge">⚡ <span id="playerXp"><?= number_format($user['total_xp']) ?></span></div>
</div>

<!-- PLAYER LAYOUT -->
<div class="player-layout">

  <!-- VIDEO AREA -->
  <div class="player-main">

    <!-- VIDEO WRAPPER -->
    <div class="video-wrapper" id="videoWrapper">
      <div class="video-container" id="videoContainer">
        <!-- YouTube iframe injected by JS -->
        <div class="video-loading" id="videoLoading">
          <div class="video-loading-inner">
            <div class="video-spinner"></div>
            <p>Loading lesson…</p>
          </div>
        </div>
      </div>

      <!-- SKIP BLOCKER overlay (shown when user tries to skip) -->
      <div class="skip-blocker hidden" id="skipBlocker">
        <div class="skip-blocker-inner">
          <div class="skip-blocker-icon">🚫</div>
          <div class="skip-blocker-title">No skipping!</div>
          <div class="skip-blocker-sub">Watch the full video to earn XP and unlock the next lesson.</div>
        </div>
      </div>

      <!-- VIDEO COMPLETE OVERLAY -->
      <div class="video-complete hidden" id="videoComplete">
        <div class="video-complete-inner">
          <div class="complete-badge">✅</div>
          <h3 class="complete-title">Lesson Complete!</h3>
          <div class="complete-xp" id="completeXp">+0 XP</div>
          <?php if ($activeLessonIdx < count($lessons)-1): ?>
          <button class="btn-primary" id="nextLessonBtn">Next Lesson →</button>
          <?php else: ?>
          <div id="examUnlockBanner" class="exam-unlock-banner hidden">
            <div class="exam-unlock-icon">🧠</div>
            <div>
              <div class="exam-unlock-title">AI Exam Unlocked!</div>
              <div class="exam-unlock-sub">You've completed all lessons. Take the AI exam!</div>
            </div>
            <a href="exam.php?course=<?= $courseId ?>" class="btn-primary">Start Exam 🚀</a>
          </div>
          <?php endif; ?>
        </div>
      </div>
    </div>

    <!-- LESSON INFO -->
    <div class="lesson-info">
      <div class="lesson-info-top">
        <div>
          <h1 class="lesson-title" id="lessonTitle"><?= htmlspecialchars($currentLesson['title']) ?></h1>
          <div class="lesson-meta">
            <span class="badge badge-accent"><?= htmlspecialchars($course['subject_name']) ?></span>
            <span class="text-muted text-sm">🕒 <?= gmdate('i:s', (int)$currentLesson['video_duration']) ?></span>
            <span class="text-muted text-sm">⚡ +<?= (int)$currentLesson['xp_reward'] ?> XP</span>
          </div>
        </div>
        <div class="lesson-actions" style="display: flex; gap: 10px; flex-wrap: wrap;">
          <a href="tutor.php?course=<?= $courseId ?>" class="btn-secondary" style="font-size:.85rem;padding:10px 18px; border-color: #10b981; color: #10b981;">
            💬 Ask AI Tutor
          </a>
          
          <?php if ($progress['is_done'] || $enrollment['exam_unlocked']): ?>
          <a href="exam.php?course=<?= $courseId ?>" class="btn-primary" style="font-size:.85rem;padding:10px 18px;">
            🧠 Take AI Exam
          </a>
          <?php endif; ?>
        </div>
      </div>
      <?php if ($currentLesson['description']): ?>
      <p class="lesson-desc" id="lessonDesc"><?= htmlspecialchars($currentLesson['description']) ?></p>
      <?php endif; ?>
    </div>

    <!-- WATCH PROGRESS BAR -->
    <div class="watch-progress-wrap">
      <div class="watch-progress-label">
        <span>Watch Progress</span>
        <span id="watchPctLabel">0%</span>
      </div>
      <div class="progress-bar" style="height:6px">
        <div class="progress-fill" id="watchProgressBar" style="width:<?= $currentLesson['watch_percent'] ?>%"></div>
      </div>
      <div class="watch-threshold-note">Watch <?= VIDEO_COMPLETE_THRESHOLD ?>% to complete ✓</div>
    </div>

    <!-- TEACHER INFO -->
    <div class="teacher-card card">
      <img class="avatar" src="<?= htmlspecialchars($course['teacher_avatar']) ?>" alt="">
      <div>
        <div class="text-sm fw-bold"><?= htmlspecialchars($course['teacher_name']) ?></div>
        <div class="text-xs text-muted">Course Instructor</div>
      </div>
    </div>

  </div><!-- /.player-main -->

  <!-- SIDEBAR: LESSON LIST -->
  <aside class="player-sidebar" id="playerSidebar">
    <div class="player-sidebar-header">
      <h3>Course Content</h3>
      <div class="sidebar-progress-pill">
        <span id="sidebarCompletedCount"><?= $progress['completed'] ?></span>/<span><?= $progress['total'] ?></span>
        <span class="text-muted text-xs">lessons</span>
      </div>
    </div>

    <div class="lessons-list" id="lessonsList">
      <?php foreach ($lessons as $idx => $lesson): ?>
      <?php
        $isActive    = $lesson['id'] == $currentLesson['id'];
        $isCompleted = (bool)$lesson['is_completed'];
        $watchPct    = (int)$lesson['watch_percent'];
        $isLocked    = false; // All lessons accessible (progress tracked)
      ?>
      <a href="course.php?id=<?= $courseId ?>&lesson=<?= $lesson['id'] ?>"
         class="lesson-item <?= $isActive ? 'active' : '' ?> <?= $isCompleted ? 'completed' : '' ?>"
         data-lesson-id="<?= $lesson['id'] ?>"
         data-video-url="<?= htmlspecialchars($lesson['video_url']) ?>"
         data-duration="<?= (int)$lesson['video_duration'] ?>"
         data-xp="<?= (int)$lesson['xp_reward'] ?>"
         data-watch="<?= $watchPct ?>"
         data-completed="<?= $isCompleted ? '1' : '0' ?>"
         data-title="<?= htmlspecialchars($lesson['title']) ?>">
        <div class="lesson-num">
          <?php if ($isCompleted): ?>
            <span class="lesson-check">✓</span>
          <?php else: ?>
            <span><?= $idx + 1 ?></span>
          <?php endif; ?>
        </div>
        <div class="lesson-item-body">
          <div class="lesson-item-title"><?= htmlspecialchars($lesson['title']) ?></div>
          <div class="lesson-item-meta">
            🕒 <?= gmdate('i:s', (int)$lesson['video_duration']) ?>
            · ⚡+<?= (int)$lesson['xp_reward'] ?>
          </div>
          <?php if ($watchPct > 0 && !$isCompleted): ?>
          <div class="lesson-mini-progress">
            <div class="lesson-mini-fill" style="width:<?= $watchPct ?>%"></div>
          </div>
          <?php endif; ?>
        </div>
        <?php if ($isActive): ?>
        <div class="lesson-playing-dot"></div>
        <?php endif; ?>
      </a>
      <?php endforeach; ?>
    </div>
  </aside>

</div><!-- /.player-layout -->

<div class="xp-pop" id="xpPop"></div>
<div class="toast-container" id="toastContainer"></div>

<script src="/eduquest/assets/js/theme.js"></script>
<script>
window.EQ_USER   = <?= json_encode(['id'=>(int)$user['id'],'total_xp'=>(int)$user['total_xp']]) ?>;
window.EQ_COURSE = <?= json_encode([
  'id'          => (int)$courseId,
  'title'       => $course['title'],
  'total'       => $progress['total'],
  'completed'   => $progress['completed'],
  'percent'     => $progress['percent'],
  'exam_unlocked'=> (bool)$enrollment['exam_unlocked'],
]) ?>;
<?php
$videoUrl = trim($currentLesson['video_url'] ?? '');

// Accept direct URL, iframe embed, or watch URL, then normalize to embed URL.
if (stripos($videoUrl, '<iframe') !== false) {
    if (preg_match('/src=["\']([^"\']+)["\']/', $videoUrl, $match)) {
        $videoUrl = trim($match[1]);
    }
}

$youtubeId = null;
if (preg_match('/(?:youtu\.be\/|youtube\.com\/(?:embed\/|watch\?v=|v\/))([a-zA-Z0-9_-]{11})/', $videoUrl, $m)) {
    $youtubeId = $m[1];
}
if ($youtubeId) {
    $videoUrl = 'https://www.youtube.com/embed/' . $youtubeId;
}

$validVideoUrl = filter_var($videoUrl, FILTER_VALIDATE_URL) ? $videoUrl : '';
?>

window.EQ_LESSON = <?= json_encode([
  'id'           => (int)$currentLesson['id'],
  'video_url'    => $validVideoUrl,
  'duration'     => (int)$currentLesson['video_duration'],
  'xp_reward'    => (int)$currentLesson['xp_reward'],
  'watch_percent'=> (int)$currentLesson['watch_percent'],
  'is_completed' => (bool)$currentLesson['is_completed'],
  'title'        => $currentLesson['title'],
  'invalid_url'  => !$validVideoUrl,
]) ?>;
window.VIDEO_THRESHOLD = <?= VIDEO_COMPLETE_THRESHOLD ?>;
</script>
<script src="/eduquest/assets/js/player.js"></script>
</body>
</html>
