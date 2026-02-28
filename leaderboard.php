<?php
require_once __DIR__ . '/config/init.php';
requireLogin();
$user = currentUser();
?>
<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Leaderboard — EduQuest</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;500;600;700;800&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;1,9..40,300&display=swap" rel="stylesheet">
<link rel="stylesheet" href="assets/css/main.css">
<link rel="stylesheet" href="assets/css/dashboard.css">
</head>
<body>
<button class="theme-toggle" id="themeToggle"><span class="theme-icon">🌙</span></button>
<div class="bg-grid"></div>
<div class="bg-orb orb-1"></div>

<nav class="navbar">
  <a href="dashboard.php" class="nav-brand">
    <div class="nav-brand-icon">⚡</div>
    <span class="nav-brand-name">EduQuest</span>
  </a>
  <div class="nav-spacer"></div>
  <div class="nav-links">
    <a href="dashboard.php"   class="nav-link">🏠 Dashboard</a>
    <a href="courses.php"     class="nav-link">📚 Courses</a>
    <a href="leaderboard.php" class="nav-link active">🏆 Leaderboard</a>
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
    <a href="courses.php?browse=1" class="sidebar-link"><span class="icon">🔍</span> Browse Courses</a>
    <a href="leaderboard.php"     class="sidebar-link active"><span class="icon">🏆</span> Leaderboard</a>
    <div class="sidebar-section-label">Account</div>
    <button class="sidebar-link" id="sidebarLogout"><span class="icon">🚪</span> Sign Out</button>
  </aside>

  <main class="main-content">

    <!-- PODIUM HEADER -->
    <div class="lb-hero">
      <h1 class="lb-title">🏆 Hall of Fame</h1>
      <p class="lb-sub">Who's grinding the hardest? Find out below.</p>
    </div>

    <!-- PODIUM (top 3) -->
    <div class="podium-wrap" id="podiumWrap">
      <!-- JS renders top 3 here -->
      <div class="podium-loading">
        <div class="skeleton" style="width:80px;height:80px;border-radius:50%;margin:0 auto 8px"></div>
        <div class="skeleton" style="height:16px;width:80px;margin:0 auto 6px"></div>
        <div class="skeleton" style="height:12px;width:50px;margin:0 auto"></div>
      </div>
    </div>

    <!-- FILTER BAR -->
    <div class="lb-filters card" style="margin-bottom:20px;padding:14px 20px;">
      <div class="lb-filter-row">
        <span class="text-muted text-sm">Filter:</span>
        <button class="lb-filter-btn active" data-filter="xp">⚡ Most XP</button>
        <button class="lb-filter-btn" data-filter="streak">🔥 Longest Streak</button>
      </div>
      <div class="lb-search-wrap">
        <input type="search" id="lbSearch" class="lb-search" placeholder="🔍 Search student...">
      </div>
    </div>

    <!-- FULL TABLE -->
    <div class="card lb-table-card">
      <table class="lb-table" id="lbTable">
        <thead>
          <tr>
            <th>#</th>
            <th>Student</th>
            <th>Level</th>
            <th>⚡ XP</th>
            <th>🔥 Streak</th>
            <th>Grade</th>
          </tr>
        </thead>
        <tbody id="lbTableBody">
          <tr><td colspan="6" style="text-align:center;padding:32px;color:var(--text-3)">Loading…</td></tr>
        </tbody>
      </table>
    </div>

    <!-- MY RANK CARD -->
    <div class="my-rank-card card" id="myRankCard" style="display:none">
      <span class="text-muted text-sm">Your position:</span>
      <div class="my-rank-inner" id="myRankInner"></div>
    </div>

  </main>
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
    <a href="dashboard.php"    class="sidebar-link"><span class="icon">🏠</span> Dashboard</a>
    <a href="courses.php"      class="sidebar-link"><span class="icon">📚</span> Courses</a>
    <a href="leaderboard.php"  class="sidebar-link active"><span class="icon">🏆</span> Leaderboard</a>
    <div style="flex:1"></div>
    <button class="sidebar-link" id="mobileLogout"><span class="icon">🚪</span> Sign Out</button>
  </div>
</div>

<script src="assets/js/theme.js"></script>
<script>
window.EQ_USER = <?= json_encode([
  'id'       => (int)$user['id'],
  'username' => $user['username'],
  'full_name'=> $user['full_name'],
  'avatar_url'=> $user['avatar_url'],
  'total_xp' => (int)$user['total_xp'],
]) ?>;
window.EQ_PAGE = 'leaderboard';
</script>
<script src="assets/js/dashboard.js"></script>
</body>
</html>
