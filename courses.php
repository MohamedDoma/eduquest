<?php
require_once __DIR__ . '/config/init.php';
requireLogin();
$user   = currentUser();
$browse = !empty($_GET['browse']);
?>
<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Courses — EduQuest</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;500;600;700;800&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;1,9..40,300&display=swap" rel="stylesheet">
<link rel="stylesheet" href="assets/css/main.css">
<link rel="stylesheet" href="assets/css/dashboard.css">
<link rel="stylesheet" href="assets/css/courses.css">
</head>
<body>
<button class="theme-toggle" id="themeToggle"><span class="theme-icon">🌙</span></button>
<div class="bg-grid"></div><div class="bg-orb orb-1"></div>

<nav class="navbar">
  <a href="dashboard.php" class="nav-brand">
    <div class="nav-brand-icon">⚡</div>
    <span class="nav-brand-name">EduQuest</span>
  </a>
  <div class="nav-spacer"></div>
  <div class="nav-links">
    <a href="dashboard.php" class="nav-link">🏠 Dashboard</a>
    <a href="courses.php"   class="nav-link active">📚 Courses</a>
    <a href="leaderboard.php" class="nav-link">🏆 Leaderboard</a>
  </div>
  <button class="nav-avatar-btn" id="navAvatarBtn">
    <img src="<?= htmlspecialchars($user['avatar_url']) ?>" alt="">
  </button>
  <button class="nav-hamburger" id="navHamburger">☰</button>
</nav>

<div class="user-dropdown" id="userDropdown">
  <div class="dropdown-header">
    <img class="avatar avatar-sm" src="<?= htmlspecialchars($user['avatar_url']) ?>" alt="">
    <div>
      <div class="dropdown-name"><?= htmlspecialchars($user['full_name']) ?></div>
      <div class="dropdown-username text-muted text-xs">@<?= htmlspecialchars($user['username']) ?></div>
    </div>
  </div>
  <div class="dropdown-divider"></div>
  <a href="dashboard.php"   class="dropdown-item">🏠 Dashboard</a>
  <a href="courses.php"     class="dropdown-item">📚 Courses</a>
  <a href="leaderboard.php" class="dropdown-item">🏆 Leaderboard</a>
  <div class="dropdown-divider"></div>
  <button class="dropdown-item dropdown-logout" id="logoutBtn">🚪 Sign Out</button>
</div>

<div class="page-layout">
  <aside class="sidebar">
    <a href="dashboard.php"       class="sidebar-link"><span class="icon">🏠</span> Dashboard</a>
    <a href="courses.php"         class="sidebar-link"><span class="icon">📚</span> My Courses</a>
    <a href="courses.php?browse=1" class="sidebar-link active"><span class="icon">🔍</span> Browse Courses</a>
    <a href="leaderboard.php"     class="sidebar-link"><span class="icon">🏆</span> Leaderboard</a>
    <div class="sidebar-section-label">Account</div>
    <button class="sidebar-link" id="sidebarLogout"><span class="icon">🚪</span> Sign Out</button>
  </aside>

  <main class="main-content">
    <!-- HEADER -->
    <div class="courses-header">
      <div>
        <h1 class="section-title" style="font-size:1.8rem">📚 <?= $browse ? 'Browse Courses' : 'My Courses' ?></h1>
        <p class="text-muted" style="margin-top:4px">Find your next obsession.</p>
      </div>
      <div class="courses-tabs">
        <button class="courses-tab <?= !$browse ? 'active' : '' ?>" data-tab="mine">My Courses</button>
        <button class="courses-tab <?= $browse  ? 'active' : '' ?>" data-tab="browse">Browse All</button>
      </div>
    </div>

    <!-- FILTERS -->
    <div class="courses-filters card" id="coursesFilters">
      <div class="filter-search-wrap">
        <input type="search" id="courseSearch" class="lb-search" style="width:220px" placeholder="🔍 Search courses...">
      </div>
      <div class="filter-chips" id="subjectFilters">
        <button class="filter-chip active" data-subject="">All Subjects</button>
      </div>
      <div class="filter-chips">
        <button class="filter-chip active" data-diff="">Any Level</button>
        <button class="filter-chip" data-diff="beginner">Beginner</button>
        <button class="filter-chip" data-diff="intermediate">Intermediate</button>
        <button class="filter-chip" data-diff="advanced">Advanced</button>
      </div>
    </div>

    <!-- COURSE GRID -->
    <div class="courses-grid" id="coursesGrid">
      <!-- Skeletons -->
      <?php for($i=0;$i<6;$i++): ?>
      <div class="course-card-skeleton">
        <div class="skeleton" style="height:160px;border-radius:12px 12px 0 0"></div>
        <div style="padding:16px;display:flex;flex-direction:column;gap:10px">
          <div class="skeleton" style="height:14px;width:50%"></div>
          <div class="skeleton" style="height:18px;width:85%"></div>
          <div class="skeleton" style="height:12px;width:40%"></div>
          <div class="skeleton" style="height:8px;width:100%;border-radius:99px"></div>
        </div>
      </div>
      <?php endfor; ?>
    </div>

    <div class="courses-empty hidden" id="coursesEmpty">
      <div style="font-size:3rem;margin-bottom:12px">🔍</div>
      <p>No courses found. Try different filters.</p>
    </div>
  </main>
</div>

<!-- ENROLL MODAL -->
<div class="modal-overlay hidden" id="enrollModal">
  <div class="modal-card" id="enrollCard">
    <button class="modal-close" id="enrollClose">✕</button>
    <div id="enrollContent"></div>
  </div>
</div>

<div class="xp-pop" id="xpPop"></div>
<div class="toast-container" id="toastContainer"></div>

<div class="mobile-nav" id="mobileNav">
  <div class="mobile-nav-backdrop" id="mobileNavBackdrop"></div>
  <div class="mobile-nav-drawer">
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:20px">
      <span class="nav-brand-name">EduQuest</span>
      <button id="mobileNavClose" style="background:none;border:none;color:var(--text);font-size:24px">✕</button>
    </div>
    <a href="dashboard.php"  class="sidebar-link"><span class="icon">🏠</span> Dashboard</a>
    <a href="courses.php"    class="sidebar-link active"><span class="icon">📚</span> Courses</a>
    <a href="leaderboard.php" class="sidebar-link"><span class="icon">🏆</span> Leaderboard</a>
    <div style="flex:1"></div>
    <button class="sidebar-link" id="mobileLogout"><span class="icon">🚪</span> Sign Out</button>
  </div>
</div>

<script src="assets/js/theme.js"></script>
<script>
window.EQ_USER  = <?= json_encode(['id'=>(int)$user['id'],'username'=>$user['username'],'full_name'=>$user['full_name'],'avatar_url'=>$user['avatar_url']]) ?>;
window.EQ_PAGE  = 'courses';
window.EQ_BROWSE = <?= $browse ? 'true' : 'false' ?>;
</script>
<script src="assets/js/dashboard.js"></script>
<script src="assets/js/courses.js"></script>
</body>
</html>
