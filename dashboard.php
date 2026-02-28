<?php
require_once __DIR__ . '/config/init.php';
requireLogin();

$user = currentUser();
$csrf = generateCsrfToken();
?>
<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Dashboard — EduQuest</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;500;600;700;800&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;1,9..40,300&display=swap" rel="stylesheet">
<link rel="stylesheet" href="assets/css/main.css">
<link rel="stylesheet" href="assets/css/dashboard.css">
</head>
<body>

<!-- THEME TOGGLE -->
<button class="theme-toggle" id="themeToggle" aria-label="Toggle theme">
  <span class="theme-icon">🌙</span>
</button>

<!-- BG DECORATIONS -->
<div class="bg-grid"></div>
<div class="bg-orb orb-1"></div>
<div class="bg-orb orb-2"></div>

<!-- ═══ NAVBAR ═══ -->
<nav class="navbar">
  <a href="dashboard.php" class="nav-brand">
    <div class="nav-brand-icon">⚡</div>
    <span class="nav-brand-name">EduQuest</span>
  </a>
  <div class="nav-spacer"></div>
  <div class="nav-links">
    <a href="dashboard.php" class="nav-link active">🏠 Dashboard</a>
    <a href="courses.php"   class="nav-link">📚 Courses</a>
    <a href="leaderboard.php" class="nav-link">🏆 Leaderboard</a>
  </div>
  <div class="nav-xp-badge" id="navXpBadge">
    <span>⚡</span>
    <span id="navXpVal"><?= number_format($user['total_xp']) ?></span> XP
  </div>
  <button class="nav-avatar-btn" id="navAvatarBtn">
    <img src="<?= htmlspecialchars($user['avatar_url']) ?>" alt="avatar">
  </button>
  <button class="nav-hamburger" id="navHamburger">☰</button>
</nav>

<!-- USER DROPDOWN -->
<div class="user-dropdown" id="userDropdown">
  <div class="dropdown-header">
    <img class="avatar avatar-sm" src="<?= htmlspecialchars($user['avatar_url']) ?>" alt="">
    <div>
      <div class="dropdown-name"><?= htmlspecialchars($user['full_name']) ?></div>
      <div class="dropdown-username text-muted text-xs">@<?= htmlspecialchars($user['username']) ?></div>
    </div>
  </div>
  <div class="dropdown-divider"></div>
  <a href="dashboard.php" class="dropdown-item">🏠 Dashboard</a>
  <a href="courses.php"   class="dropdown-item">📚 My Courses</a>
  <a href="leaderboard.php" class="dropdown-item">🏆 Leaderboard</a>
  <div class="dropdown-divider"></div>
  <button class="dropdown-item dropdown-logout" id="logoutBtn">🚪 Sign Out</button>
</div>

<!-- PAGE LAYOUT -->
<div class="page-layout">

  <!-- SIDEBAR -->
  <aside class="sidebar">
    <a href="dashboard.php"    class="sidebar-link active"><span class="icon">🏠</span> Dashboard</a>
    <a href="courses.php"      class="sidebar-link"><span class="icon">📚</span> My Courses</a>
    <a href="courses.php?browse=1" class="sidebar-link"><span class="icon">🔍</span> Browse Courses</a>
    <a href="leaderboard.php"  class="sidebar-link"><span class="icon">🏆</span> Leaderboard</a>
    <div class="sidebar-section-label">Account</div>
    <button class="sidebar-link" id="sidebarLogout"><span class="icon">🚪</span> Sign Out</button>
  </aside>

  <!-- MAIN -->
  <main class="main-content" id="mainContent">

    <!-- GREETING BANNER -->
    <div class="greeting-banner" id="greetingBanner">
      <div class="greeting-left">
        <div class="greeting-avatar-wrap">
          <img class="greeting-avatar" src="<?= htmlspecialchars($user['avatar_url']) ?>" alt="avatar">
          <div class="greeting-level-ring" id="greetingLevelRing">
            <span id="greetingLevelNum">1</span>
          </div>
        </div>
        <div>
          <div class="greeting-hey" id="greetingHey">Good morning ☀️</div>
          <h1 class="greeting-name"><?= htmlspecialchars(explode(' ', $user['full_name'])[0]) ?> <span class="text-accent">!</span></h1>
          <div class="greeting-sub">Grade <?= $user['grade_level'] ?> student • Keep the momentum going</div>
        </div>
      </div>
      <div class="greeting-right">
        <div class="streak-display" id="streakDisplay">
          <span class="streak-flame">🔥</span>
          <div>
            <div class="streak-count" id="streakCount"><?= $user['current_streak'] ?></div>
            <div class="streak-label">day streak</div>
          </div>
        </div>
      </div>
    </div>

    <!-- STATS GRID -->
    <div class="stats-grid" id="statsGrid">
      <div class="stat-card" id="statXp">
        <div class="stat-card-icon">⚡</div>
        <div class="stat-card-val counter" data-target="<?= $user['total_xp'] ?>">0</div>
        <div class="stat-card-label">Total XP</div>
        <div class="stat-card-sub" id="statLevel">Level 1</div>
      </div>
      <div class="stat-card" id="statStreak">
        <div class="stat-card-icon">🔥</div>
        <div class="stat-card-val counter" data-target="<?= $user['current_streak'] ?>">0</div>
        <div class="stat-card-label">Current Streak</div>
        <div class="stat-card-sub">Best: <span id="bestStreak"><?= $user['longest_streak'] ?></span> days</div>
      </div>
      <div class="stat-card" id="statCourses">
        <div class="stat-card-icon">📚</div>
        <div class="stat-card-val counter" data-target="0" id="statCoursesVal">0</div>
        <div class="stat-card-label">Courses Enrolled</div>
        <div class="stat-card-sub"><span id="statCoursesCompleted">0</span> completed</div>
      </div>
      <div class="stat-card" id="statRank">
        <div class="stat-card-icon">🏆</div>
        <div class="stat-card-val" id="statRankVal">#—</div>
        <div class="stat-card-label">Global Rank</div>
        <div class="stat-card-sub">Among all students</div>
      </div>
    </div>

    <!-- LEVEL PROGRESS -->
    <div class="level-progress-card card" id="levelProgressCard">
      <div class="level-progress-header">
        <div class="level-badge-lg" id="levelBadgeLg">
          <span>⭐</span> Level <span id="levelNum">1</span>
        </div>
        <div class="level-xp-info">
          <span id="levelXpCurrent">0</span> / <span id="levelXpNeeded">50</span> XP
          <span class="text-muted text-xs">to next level</span>
        </div>
      </div>
      <div class="progress-bar" style="height:12px;">
        <div class="progress-fill" id="levelProgressFill" style="width:0%"></div>
      </div>
      <div class="level-milestones" id="levelMilestones"></div>
    </div>

    <!-- MAIN GRID: courses + right column -->
    <div class="dashboard-grid">

      <!-- MY COURSES -->
      <section class="section">
        <div class="section-header">
          <h2 class="section-title">My Courses</h2>
          <a href="courses.php?browse=1" class="btn-secondary" style="font-size:.82rem;padding:8px 16px;">Browse More</a>
        </div>
        <div class="my-courses-list" id="myCoursesList">
          <!-- Skeleton -->
          <div class="course-progress-card skeleton-card">
            <div class="skeleton" style="width:56px;height:56px;border-radius:12px;flex-shrink:0"></div>
            <div style="flex:1;display:flex;flex-direction:column;gap:8px">
              <div class="skeleton" style="height:16px;width:70%"></div>
              <div class="skeleton" style="height:12px;width:40%"></div>
              <div class="skeleton" style="height:8px;width:100%;border-radius:99px"></div>
            </div>
          </div>
          <div class="course-progress-card skeleton-card">
            <div class="skeleton" style="width:56px;height:56px;border-radius:12px;flex-shrink:0"></div>
            <div style="flex:1;display:flex;flex-direction:column;gap:8px">
              <div class="skeleton" style="height:16px;width:60%"></div>
              <div class="skeleton" style="height:12px;width:35%"></div>
              <div class="skeleton" style="height:8px;width:100%;border-radius:99px"></div>
            </div>
          </div>
        </div>
      </section>

      <!-- RIGHT COLUMN -->
      <div class="dashboard-right">

        <!-- STREAK HEATMAP -->
        <div class="card heatmap-card">
          <div class="section-header" style="margin-bottom:14px">
            <h3 class="section-title" style="font-size:1rem">Study Activity</h3>
            <span class="text-muted text-xs">Last 14 days</span>
          </div>
          <div class="heatmap-grid" id="heatmapGrid"></div>
          <div class="heatmap-legend">
            <span class="text-muted text-xs">Less</span>
            <div class="heatmap-dot hd-0"></div>
            <div class="heatmap-dot hd-1"></div>
            <div class="heatmap-dot hd-2"></div>
            <div class="heatmap-dot hd-3"></div>
            <div class="heatmap-dot hd-4"></div>
            <span class="text-muted text-xs">More</span>
          </div>
        </div>

        <!-- MINI LEADERBOARD -->
        <div class="card leaderboard-mini-card">
          <div class="section-header" style="margin-bottom:14px">
            <h3 class="section-title" style="font-size:1rem">🏆 Top Students</h3>
            <a href="leaderboard.php" class="text-accent text-xs fw-bold">See all →</a>
          </div>
          <div id="miniLeaderboard">
            <!-- Populated by JS -->
          </div>
        </div>

        <!-- ACHIEVEMENTS -->
        <div class="card achievements-card">
          <div class="section-header" style="margin-bottom:14px">
            <h3 class="section-title" style="font-size:1rem">🎖️ Achievements</h3>
          </div>
          <div class="achievements-grid" id="achievementsGrid">
            <!-- Populated by JS -->
          </div>
        </div>

        <!-- RECENT XP -->
        <div class="card xp-log-card">
          <div class="section-header" style="margin-bottom:14px">
            <h3 class="section-title" style="font-size:1rem">⚡ XP History</h3>
          </div>
          <div id="xpLog"></div>
        </div>

      </div><!-- /.dashboard-right -->
    </div><!-- /.dashboard-grid -->

  </main>
</div>

<!-- XP POP + TOASTS -->
<div class="xp-pop" id="xpPop"></div>
<div class="toast-container" id="toastContainer"></div>

<!-- MOBILE NAV -->
<div class="mobile-nav" id="mobileNav">
  <div class="mobile-nav-backdrop" id="mobileNavBackdrop"></div>
  <div class="mobile-nav-drawer">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:20px">
      <span class="nav-brand-name">EduQuest</span>
      <button id="mobileNavClose" style="background:none;border:none;color:var(--text);font-size:24px">✕</button>
    </div>
    <a href="dashboard.php" class="sidebar-link active"><span class="icon">🏠</span> Dashboard</a>
    <a href="courses.php"   class="sidebar-link"><span class="icon">📚</span> Courses</a>
    <a href="leaderboard.php" class="sidebar-link"><span class="icon">🏆</span> Leaderboard</a>
    <div style="flex:1"></div>
    <button class="sidebar-link" id="mobileLogout"><span class="icon">🚪</span> Sign Out</button>
  </div>
</div>

<script src="assets/js/theme.js"></script>
<script>
  // Pass PHP data to JS
  window.EQ_USER = <?= json_encode([
    'id'             => (int)$user['id'],
    'username'       => $user['username'],
    'full_name'      => $user['full_name'],
    'avatar_url'     => $user['avatar_url'],
    'total_xp'       => (int)$user['total_xp'],
    'current_streak' => (int)$user['current_streak'],
    'longest_streak' => (int)$user['longest_streak'],
    'grade_level'    => (int)$user['grade_level'],
  ]) ?>;
</script>
<script src="assets/js/dashboard.js"></script>
</body>
</html>
