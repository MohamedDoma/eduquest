<?php
require_once __DIR__ . '/config/init.php';

// Already logged in → redirect to dashboard
if (isLoggedIn()) {
    header('Location: dashboard.php');
    exit;
}

$csrf = generateCsrfToken();
?>
<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>EduQuest — Level Up Your Learning</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Syne:wght@400;500;600;700;800&family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;1,9..40,300&display=swap" rel="stylesheet">
<link rel="stylesheet" href="assets/css/main.css">
<link rel="stylesheet" href="assets/css/auth.css">
</head>
<body class="auth-page">

<!-- ═══ THEME TOGGLE ═══ -->
<button class="theme-toggle" id="themeToggle" aria-label="Toggle theme">
  <span class="theme-icon">🌙</span>
</button>

<!-- ═══ BACKGROUND GRID ═══ -->
<div class="bg-grid"></div>
<div class="bg-orb orb-1"></div>
<div class="bg-orb orb-2"></div>
<div class="bg-orb orb-3"></div>

<!-- ═══ MAIN WRAPPER ═══ -->
<div class="auth-wrapper">

  <!-- LEFT PANEL -->
  <div class="auth-left">
    <div class="brand">
      <div class="brand-logo">
        <span class="brand-icon">⚡</span>
      </div>
      <span class="brand-name">EduQuest</span>
    </div>

    <div class="hero-text">
      <div class="hero-badge">
        <span class="badge-dot"></span>
        <span>30+ students learning right now</span>
      </div>
      <h1 class="hero-heading">
        Learn.<br>
        <span class="heading-accent">Level Up.</span><br>
        Dominate.
      </h1>
      <p class="hero-sub">
        Streak-based learning, AI-powered exams, and a leaderboard that keeps you hungry.
        School just got interesting.
      </p>
    </div>

    <!-- Stats pills -->
    <div class="stat-pills">
      <div class="stat-pill">
        <span class="stat-emoji">🔥</span>
        <div>
          <div class="stat-num">28</div>
          <div class="stat-label">Day streak record</div>
        </div>
      </div>
      <div class="stat-pill">
        <span class="stat-emoji">⚡</span>
        <div>
          <div class="stat-num">4.8k</div>
          <div class="stat-label">XP earned today</div>
        </div>
      </div>
      <div class="stat-pill">
        <span class="stat-emoji">🏆</span>
        <div>
          <div class="stat-num">59</div>
          <div class="stat-label">Total lessons</div>
        </div>
      </div>
    </div>

    <!-- Floating avatars -->
    <div class="floating-avatars">
      <img src="https://api.dicebear.com/7.x/adventurer/svg?seed=alexng&backgroundColor=6366f1"    class="favatar fa-1" alt="">
      <img src="https://api.dicebear.com/7.x/adventurer/svg?seed=zarakhan&backgroundColor=f59e0b"  class="favatar fa-2" alt="">
      <img src="https://api.dicebear.com/7.x/adventurer/svg?seed=mayaraj&backgroundColor=8b5cf6"   class="favatar fa-3" alt="">
      <img src="https://api.dicebear.com/7.x/adventurer/svg?seed=ethanlee&backgroundColor=10b981"  class="favatar fa-4" alt="">
      <img src="https://api.dicebear.com/7.x/adventurer/svg?seed=sofiakia&backgroundColor=ec4899"  class="favatar fa-5" alt="">
    </div>
  </div>

  <!-- RIGHT PANEL -->
  <div class="auth-right">
    <div class="auth-card">

      <!-- TABS -->
      <div class="auth-tabs">
        <button class="auth-tab active" data-tab="login">Sign In</button>
        <button class="auth-tab" data-tab="register">Join Now</button>
      </div>

      <!-- ══ LOGIN FORM ══ -->
      <form class="auth-form active" id="loginForm" data-tab-form="login" novalidate>
        <input type="hidden" name="csrf_token" value="<?= $csrf ?>">
        <input type="hidden" name="action" value="login">

        <div class="form-group">
          <label class="form-label" for="login_identifier">Username or Email</label>
          <div class="input-wrap">
            <span class="input-icon">👤</span>
            <input
              class="form-input"
              type="text"
              id="login_identifier"
              name="identifier"
              placeholder="alex_ng or alex@email.com"
              autocomplete="username"
              required
            >
          </div>
        </div>

        <div class="form-group">
          <label class="form-label" for="login_password">
            Password
            <a href="#" class="form-link forgot-link">Forgot?</a>
          </label>
          <div class="input-wrap">
            <span class="input-icon">🔒</span>
            <input
              class="form-input"
              type="password"
              id="login_password"
              name="password"
              placeholder="••••••••"
              autocomplete="current-password"
              required
            >
            <button type="button" class="pw-toggle" aria-label="Show password">👁</button>
          </div>
        </div>

        <div class="form-check">
          <label class="check-label">
            <input type="checkbox" name="remember" class="check-input">
            <span class="check-custom"></span>
            Keep me signed in for 30 days
          </label>
        </div>

        <div class="form-error" id="loginError" role="alert" aria-live="polite"></div>

        <button type="submit" class="btn-primary btn-full" id="loginBtn">
          <span class="btn-text">Sign In</span>
          <span class="btn-loader hidden">
            <svg class="spin" viewBox="0 0 24 24" fill="none">
              <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="3" stroke-dasharray="31.4" stroke-dashoffset="10"/>
            </svg>
          </span>
        </button>

        <div class="form-divider"><span>or try the demo</span></div>

        <button type="button" class="btn-demo" id="demoLoginBtn">
          ⚡ Login as Alex Ng (Top Student)
        </button>
      </form>

      <!-- ══ REGISTER FORM ══ -->
      <form class="auth-form" id="registerForm" data-tab-form="register" novalidate>
        <input type="hidden" name="csrf_token" value="<?= $csrf ?>">
        <input type="hidden" name="action" value="register">

        <div class="form-row">
          <div class="form-group">
            <label class="form-label" for="reg_fullname">Full Name</label>
            <div class="input-wrap">
              <span class="input-icon">✨</span>
              <input
                class="form-input"
                type="text"
                id="reg_fullname"
                name="full_name"
                placeholder="Your real name"
                autocomplete="name"
                required
              >
            </div>
          </div>
          <div class="form-group">
            <label class="form-label" for="reg_username">Username</label>
            <div class="input-wrap">
              <span class="input-icon">🎮</span>
              <input
                class="form-input"
                type="text"
                id="reg_username"
                name="username"
                placeholder="cool_username"
                autocomplete="username"
                pattern="[a-zA-Z0-9_]{3,30}"
                required
              >
            </div>
            <div class="input-hint" id="usernameHint"></div>
          </div>
        </div>

        <div class="form-group">
          <label class="form-label" for="reg_email">School Email</label>
          <div class="input-wrap">
            <span class="input-icon">📧</span>
            <input
              class="form-input"
              type="email"
              id="reg_email"
              name="email"
              placeholder="you@school.edu"
              autocomplete="email"
              required
            >
          </div>
        </div>

        <div class="form-row">
          <div class="form-group">
            <label class="form-label" for="reg_grade">Grade Level</label>
            <div class="input-wrap">
              <span class="input-icon">🎓</span>
              <select class="form-input form-select" id="reg_grade" name="grade_level" required>
                <option value="">Select grade</option>
                <option value="7">Grade 7</option>
                <option value="8">Grade 8</option>
                <option value="9">Grade 9</option>
                <option value="10">Grade 10</option>
                <option value="11">Grade 11</option>
                <option value="12">Grade 12</option>
              </select>
            </div>
          </div>
          <div class="form-group">
            <label class="form-label" for="reg_password">Password</label>
            <div class="input-wrap">
              <span class="input-icon">🔒</span>
              <input
                class="form-input"
                type="password"
                id="reg_password"
                name="password"
                placeholder="Min. 8 characters"
                autocomplete="new-password"
                required
                minlength="8"
              >
              <button type="button" class="pw-toggle" aria-label="Show password">👁</button>
            </div>
            <!-- Password strength bar -->
            <div class="pw-strength">
              <div class="pw-strength-bar" id="pwStrengthBar"></div>
            </div>
            <div class="pw-strength-label" id="pwStrengthLabel"></div>
          </div>
        </div>

        <div class="form-error" id="registerError" role="alert" aria-live="polite"></div>

        <button type="submit" class="btn-primary btn-full" id="registerBtn">
          <span class="btn-text">Create My Account 🚀</span>
          <span class="btn-loader hidden">
            <svg class="spin" viewBox="0 0 24 24" fill="none">
              <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="3" stroke-dasharray="31.4" stroke-dashoffset="10"/>
            </svg>
          </span>
        </button>

        <p class="form-legal">
          By joining, you agree to our
          <a href="#" class="form-link">Terms</a> and
          <a href="#" class="form-link">Privacy Policy</a>.
        </p>
      </form>

    </div><!-- /.auth-card -->
  </div><!-- /.auth-right -->

</div><!-- /.auth-wrapper -->

<!-- ═══ XP POP ANIMATION ═══ -->
<div class="xp-pop" id="xpPop"></div>

<!-- ═══ TOAST NOTIFICATIONS ═══ -->
<div class="toast-container" id="toastContainer"></div>

<script src="assets/js/theme.js"></script>
<script src="assets/js/auth.js"></script>
</body>
</html>
