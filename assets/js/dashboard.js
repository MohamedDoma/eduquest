/**
 * EduQuest — Dashboard + Leaderboard JavaScript
 * Handles: stats loading, counter animations, heatmap,
 *          mini-leaderboard, achievements, XP log,
 *          full leaderboard page, podium, nav interactions.
 */

/* ═══════════════════════════════════════════════════
   SHARED UTILITIES
═══════════════════════════════════════════════════ */
const Toast = window.Toast || {
  success: (t,m) => console.log(t,m),
  error:   (t,m) => console.error(t,m),
  info:    (t,m) => console.log(t,m),
};

async function apiFetch(url) {
  const res = await fetch(url, { credentials: 'same-origin' });
  return res.json();
}

function formatXP(xp) {
  return xp >= 1000 ? (xp / 1000).toFixed(1).replace(/\.0$/, '') + 'k' : xp.toString();
}

function timeAgo(dateStr) {
  const diff = (Date.now() - new Date(dateStr)) / 1000;
  if (diff < 60)     return 'just now';
  if (diff < 3600)   return Math.floor(diff/60) + 'm ago';
  if (diff < 86400)  return Math.floor(diff/3600) + 'h ago';
  if (diff < 604800) return Math.floor(diff/86400) + 'd ago';
  return new Date(dateStr).toLocaleDateString('en-US', {month:'short', day:'numeric'});
}

function xpToLevel(xp) {
  return Math.floor(Math.sqrt(xp / 50)) + 1;
}

function xpForNextLevel(xp) {
  const level    = xpToLevel(xp);
  const currMin  = 50 * Math.pow(level - 1, 2);
  const nextMin  = 50 * Math.pow(level, 2);
  const pct      = Math.min(100, Math.round((xp - currMin) / (nextMin - currMin) * 100));
  return { level, current: xp - currMin, needed: nextMin - currMin, percent: pct, next: level + 1 };
}

/* ═══════════════════════════════════════════════════
   COUNTER ANIMATION
═══════════════════════════════════════════════════ */
function animateCounter(el, target, duration = 1200) {
  const start = performance.now();
  const from  = 0;

  function step(now) {
    const elapsed = now - start;
    const progress = Math.min(elapsed / duration, 1);
    // Ease out cubic
    const eased = 1 - Math.pow(1 - progress, 3);
    const val = Math.round(from + (target - from) * eased);
    el.textContent = val.toLocaleString();
    if (progress < 1) requestAnimationFrame(step);
  }
  requestAnimationFrame(step);
}

function initCounters() {
  const counters = document.querySelectorAll('.counter');
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const el = entry.target;
        const target = parseInt(el.dataset.target) || 0;
        animateCounter(el, target);
        observer.unobserve(el);
      }
    });
  }, { threshold: 0.2 });

  counters.forEach(c => observer.observe(c));
}

/* ═══════════════════════════════════════════════════
   GREETING
═══════════════════════════════════════════════════ */
function setGreeting() {
  const el = document.getElementById('greetingHey');
  if (!el) return;
  const h = new Date().getHours();
  if (h < 12) el.textContent = 'Good morning ☀️';
  else if (h < 17) el.textContent = 'Good afternoon 🌤️';
  else el.textContent = 'Good evening 🌙';
}

/* ═══════════════════════════════════════════════════
   HEATMAP
═══════════════════════════════════════════════════ */
function renderHeatmap(studyData) {
  const grid = document.getElementById('heatmapGrid');
  if (!grid) return;

  // Build lookup: date → xp
  const map = {};
  studyData.forEach(s => { map[s.study_date] = parseInt(s.xp_earned) || 1; });

  // Get max XP for scaling
  const maxXp = Math.max(...Object.values(map), 1);

  // Build 14 days ending today
  grid.innerHTML = '';
  const today = new Date();
  today.setHours(0,0,0,0);

  for (let i = 13; i >= 0; i--) {
    const d = new Date(today);
    d.setDate(d.getDate() - i);
    const key = d.toISOString().split('T')[0];
    const xp  = map[key] || 0;

    let level = 0;
    if (xp > 0) {
      const ratio = xp / maxXp;
      level = ratio > .75 ? 4 : ratio > .50 ? 3 : ratio > .25 ? 2 : 1;
    }

    const cell = document.createElement('div');
    cell.className = `heatmap-day hd-${level}${i === 0 ? ' today' : ''}`;
    cell.title = `${key}: ${xp > 0 ? xp + ' XP' : 'No activity'}`;
    grid.appendChild(cell);
  }
}

/* ═══════════════════════════════════════════════════
   MINI LEADERBOARD
═══════════════════════════════════════════════════ */
function renderMiniLeaderboard(students) {
  const el = document.getElementById('miniLeaderboard');
  if (!el) return;

  const rankEmoji = ['🥇','🥈','🥉'];
  const rankClass = ['gold','silver','bronze'];
  const userId    = window.EQ_USER?.id;

  el.innerHTML = students.map((s, i) => `
    <div class="mini-lb-row">
      <div class="mini-lb-rank ${rankClass[i] || ''}">
        ${i < 3 ? rankEmoji[i] : s.rank}
      </div>
      <img class="avatar avatar-sm" src="${s.avatar_url}" alt="">
      <div class="mini-lb-name ${s.id == userId ? 'is-me' : ''}">
        ${s.id == userId ? '(You) ' : ''}${s.full_name.split(' ')[0]}
        <div class="text-xs text-muted">Lv.${xpToLevel(parseInt(s.total_xp))}</div>
      </div>
      <div class="mini-lb-xp">⚡${formatXP(parseInt(s.total_xp))}</div>
    </div>
  `).join('');
}

/* ═══════════════════════════════════════════════════
   ACHIEVEMENTS
═══════════════════════════════════════════════════ */
const ALL_ACHIEVEMENTS = [
  {id:1,icon:'👶',name:'First Step'},
  {id:2,icon:'🔥',name:'On Fire'},
  {id:3,icon:'🌟',name:'Unstoppable'},
  {id:4,icon:'⚡',name:'Quick Learner'},
  {id:5,icon:'📚',name:'Scholar'},
  {id:6,icon:'💎',name:'XP Hunter'},
  {id:7,icon:'👑',name:'Elite Student'},
  {id:8,icon:'🏆',name:'Course Champion'},
  {id:9,icon:'🎓',name:'Exam Ace'},
  {id:10,icon:'🌐',name:'Polyglot'},
];

function renderAchievements(earned) {
  const el = document.getElementById('achievementsGrid');
  if (!el) return;
  const earnedIds = new Set(earned.map(a => a.id));

  el.innerHTML = ALL_ACHIEVEMENTS.map((a, i) => `
    <div class="achievement-item ${earnedIds.has(a.id) ? '' : 'locked'}"
         title="${a.name}"
         style="animation-delay:${i * .04}s">
      <div class="achievement-icon">${a.icon}</div>
      <div class="achievement-name">${a.name}</div>
    </div>
  `).join('');
}

/* ═══════════════════════════════════════════════════
   XP LOG
═══════════════════════════════════════════════════ */
const XP_ICONS = { lesson:'📖', exam:'🎓', streak:'🔥', achievement:'🏆', admin:'⚙️' };

function renderXpLog(items) {
  const el = document.getElementById('xpLog');
  if (!el) return;
  if (!items.length) { el.innerHTML = '<p class="text-muted text-sm" style="padding:8px 0">No XP activity yet.</p>'; return; }

  el.innerHTML = items.map((item, i) => `
    <div class="xp-log-item" style="animation-delay:${i*.04}s">
      <div class="xp-log-icon">${XP_ICONS[item.ref_type] || '⚡'}</div>
      <div class="xp-log-body">
        <div class="xp-log-reason">${item.reason}</div>
        <div class="xp-log-time">${timeAgo(item.created_at)}</div>
      </div>
      <div class="xp-log-amount">+${item.amount} XP</div>
    </div>
  `).join('');
}

/* ═══════════════════════════════════════════════════
   MY COURSES
═══════════════════════════════════════════════════ */
function renderMyCourses(enrollments) {
  const el = document.getElementById('myCoursesList');
  if (!el) return;

  if (!enrollments.length) {
    el.innerHTML = `
      <div class="empty-courses">
        <div class="empty-icon">📚</div>
        <p>You haven't enrolled in any courses yet.</p>
        <a href="courses.php?browse=1" class="btn-primary" style="font-size:.85rem;padding:10px 20px;">Browse Courses</a>
      </div>`;
    return;
  }

  el.innerHTML = enrollments.map((e, i) => {
    const pct   = parseInt(e.progress_percent) || 0;
    const done  = !!e.completed_at;
    const exam  = !!e.exam_unlocked;
    return `
      <a href="course.php?id=${e.course_id}" class="course-progress-card" style="animation-delay:${i*.06}s">
        <div class="cpc-subject-icon" style="background:${e.subject_color}22">${e.subject_icon}</div>
        <div class="cpc-body">
          <div class="cpc-title">${e.title}</div>
          <div class="cpc-meta">
            <span>${e.subject_name}</span>
            <span>•</span>
            <span>${pct}% complete</span>
            ${done ? '<span>•</span><span style="color:var(--accent-2)">✓ Done</span>' : ''}
          </div>
          <div class="cpc-progress-row">
            <div class="progress-bar" style="flex:1;height:6px">
              <div class="progress-fill" style="width:${pct}%"></div>
            </div>
            <div class="cpc-percent">${pct}%</div>
          </div>
        </div>
        <div class="cpc-right">
          <div class="cpc-exam-badge ${exam ? '' : 'cpc-exam-locked'}">
            ${exam ? '🧠 Exam Ready' : '🔒 Exam'}
          </div>
        </div>
      </a>`;
  }).join('');
}

/* ═══════════════════════════════════════════════════
   LEVEL PROGRESS UI
═══════════════════════════════════════════════════ */
function updateLevelUI(xp) {
  const info = xpForNextLevel(xp);

  document.querySelectorAll('#levelNum').forEach(el => el.textContent = info.level);
  const ringEl = document.getElementById('greetingLevelNum');
  if (ringEl) ringEl.textContent = info.level;

  const badgeEl = document.getElementById('levelBadgeLg');
  if (badgeEl) {
    const medal = info.level >= 10 ? '👑' : info.level >= 5 ? '⭐' : '📗';
    badgeEl.innerHTML = `<span>${medal}</span> Level <span id="levelNum">${info.level}</span>`;
  }

  const fillEl = document.getElementById('levelProgressFill');
  if (fillEl) {
    setTimeout(() => { fillEl.style.width = info.percent + '%'; }, 100);
  }

  const currEl = document.getElementById('levelXpCurrent');
  const needEl = document.getElementById('levelXpNeeded');
  if (currEl) currEl.textContent = info.current.toLocaleString();
  if (needEl) needEl.textContent = info.needed.toLocaleString();

  const statEl = document.getElementById('statLevel');
  if (statEl) statEl.textContent = `Level ${info.level}`;

  // Milestones
  const milestonesEl = document.getElementById('levelMilestones');
  if (milestonesEl) {
    const milestones = [
      {lvl:5, label:'5 — Apprentice', icon:'📗'},
      {lvl:10, label:'10 — Scholar',  icon:'📘'},
      {lvl:20, label:'20 — Expert',   icon:'📙'},
      {lvl:30, label:'30 — Master',   icon:'📕'},
      {lvl:50, label:'50 — Legend',   icon:'👑'},
    ];
    milestonesEl.innerHTML = milestones.map(m => `
      <div class="milestone-badge ${info.level >= m.lvl ? 'reached' : ''}">
        ${m.icon} Lv.${m.label}
      </div>`).join('');
  }
}

/* ═══════════════════════════════════════════════════
   DASHBOARD: LOAD ALL DATA
═══════════════════════════════════════════════════ */
async function loadDashboard() {
  try {
    const res = await apiFetch('api/courses.php?action=dashboard_stats');
    if (!res.success) { Toast.error('Failed to load dashboard', res.message); return; }

    const d = res.data;

    // Update stat cards
    const xpEl = document.querySelector('#statXp .stat-card-val');
    if (xpEl) { xpEl.dataset.target = d.user.total_xp; }

    document.querySelector('#statStreak .stat-card-val')?.setAttribute('data-target', d.user.current_streak);
    document.getElementById('bestStreak').textContent = d.user.longest_streak;

    const coursesVal = document.getElementById('statCoursesVal');
    if (coursesVal) { coursesVal.dataset.target = d.enrollments?.length || 0; }
    const completed = d.enrollments?.filter(e => e.completed_at).length || 0;
    document.getElementById('statCoursesCompleted').textContent = completed;

    const rankEl = document.getElementById('statRankVal');
    if (rankEl) rankEl.textContent = `#${d.rank}`;

    // Init counters
    initCounters();

    // Level progress
    updateLevelUI(parseInt(d.user.total_xp));

    // Nav XP
    document.getElementById('navXpVal').textContent = parseInt(d.user.total_xp).toLocaleString();

    // Streak count (already in PHP, but update from fresh API)
    document.getElementById('streakCount').textContent = d.user.current_streak;

    // My courses
    renderMyCourses(d.enrollments || []);

    // Heatmap
    renderHeatmap(d.streak_data || []);

    // Mini leaderboard
    renderMiniLeaderboard(d.top_students || []);

    // Achievements
    renderAchievements(d.achievements || []);

    // XP log
    renderXpLog(d.recent_xp || []);

  } catch (err) {
    console.error('Dashboard load error:', err);
    Toast.error('Network error', 'Could not load your dashboard data.');
  }
}

/* ═══════════════════════════════════════════════════
   LEADERBOARD PAGE
═══════════════════════════════════════════════════ */
let lbData     = [];
let lbFilter   = 'xp';
let lbSearchQ  = '';

async function loadLeaderboard() {
  try {
    const res = await apiFetch('api/courses.php?action=leaderboard&limit=30');
    if (!res.success) return;
    lbData = res.data.leaderboard || [];
    renderPodium(lbData.slice(0, 3));
    renderTable(lbData);
    renderMyRank(lbData);
  } catch(err) {
    console.error(err);
  }
}

function renderPodium(top3) {
  const wrap = document.getElementById('podiumWrap');
  if (!wrap || !top3.length) return;

  // Arrange: 2nd, 1st, 3rd
  const order    = [top3[1], top3[0], top3[2]].filter(Boolean);
  const classes  = top3[1] ? ['podium-2nd','podium-1st','podium-3rd'] : ['podium-1st'];
  const medals   = ['🥈','🥇','🥉'];

  wrap.innerHTML = order.map((s, i) => {
    const cls = classes[i];
    const isPrimary = cls === 'podium-1st';
    return `
      <div class="podium-slot ${cls}">
        <div class="podium-avatar-wrap">
          <img class="podium-avatar" src="${s.avatar_url}" alt="${s.full_name}">
          <div class="podium-rank-badge">${medals[i]}</div>
        </div>
        <div class="podium-name">${s.full_name.split(' ')[0]}</div>
        <div class="podium-xp">⚡${formatXP(parseInt(s.total_xp))}</div>
        <div class="podium-plinth">${s.rank}</div>
      </div>`;
  }).join('');
}

function renderTable(data) {
  const tbody = document.getElementById('lbTableBody');
  if (!tbody) return;
  const userId = window.EQ_USER?.id;

  let filtered = [...data];

  if (lbFilter === 'streak') {
    filtered.sort((a,b) => parseInt(b.current_streak) - parseInt(a.current_streak));
    filtered.forEach((s,i) => s._displayRank = i+1);
  } else {
    filtered.sort((a,b) => parseInt(b.total_xp) - parseInt(a.total_xp));
    filtered.forEach((s,i) => s._displayRank = i+1);
  }

  if (lbSearchQ) {
    const q = lbSearchQ.toLowerCase();
    filtered = filtered.filter(s =>
      s.full_name.toLowerCase().includes(q) ||
      s.username.toLowerCase().includes(q)
    );
  }

  if (!filtered.length) {
    tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:32px;color:var(--text-3)">No students found.</td></tr>';
    return;
  }

  const rankLabels = {1:'🥇',2:'🥈',3:'🥉'};
  tbody.innerHTML = filtered.map((s, i) => {
    const rank     = s._displayRank;
    const isMe     = s.id == userId;
    const level    = xpToLevel(parseInt(s.total_xp));
    const rankDisp = rankLabels[rank] || rank;
    return `
      <tr class="${isMe ? 'is-me' : ''}" style="animation-delay:${i*.025}s">
        <td><div class="lb-rank-cell ${rank <= 3 ? 'top-3' : ''}">${rankDisp}</div></td>
        <td>
          <div class="lb-student-cell">
            <img class="avatar avatar-sm" src="${s.avatar_url}" alt="">
            <div>
              <div class="lb-student-name ${isMe ? 'is-me' : ''}">${s.full_name}${isMe ? ' (You)' : ''}</div>
              <div class="lb-student-username">@${s.username} • Grade ${s.grade_level}</div>
            </div>
          </div>
        </td>
        <td>
          <div class="lb-level-cell">
            <span class="level-badge" style="font-size:.75rem;padding:3px 10px;">⭐ Lv.${level}</span>
          </div>
        </td>
        <td><div class="lb-xp-cell">⚡${formatXP(parseInt(s.total_xp))}</div></td>
        <td><div class="lb-streak-cell">${s.current_streak > 0 ? '🔥' : ''}${s.current_streak}d</div></td>
        <td><span class="badge badge-accent" style="font-size:.7rem">${s.grade_level}</span></td>
      </tr>`;
  }).join('');
}

function renderMyRank(data) {
  const card  = document.getElementById('myRankCard');
  const inner = document.getElementById('myRankInner');
  if (!card || !inner) return;
  const userId = window.EQ_USER?.id;
  const me = data.find(s => s.id == userId);
  if (!me) return;

  const level = xpToLevel(parseInt(me.total_xp));
  inner.innerHTML = `
    <img class="avatar" src="${me.avatar_url}" alt="">
    <div>
      <div style="font-family:var(--font-display);font-weight:700">${me.full_name}</div>
      <div class="text-muted text-xs">@${me.username}</div>
    </div>
    <div class="level-badge" style="margin-left:8px">⭐ Lv.${level}</div>
    <div style="flex:1"></div>
    <div style="text-align:right">
      <div style="font-family:var(--font-display);font-size:1.5rem;font-weight:800;color:var(--accent)">#${me.rank}</div>
      <div class="text-xs text-muted">⚡${parseInt(me.total_xp).toLocaleString()} XP</div>
    </div>`;
  card.style.display = 'flex';
}

/* ═══════════════════════════════════════════════════
   NAV: DROPDOWN + HAMBURGER + LOGOUT
═══════════════════════════════════════════════════ */
function initNav() {
  // Avatar dropdown
  const avatarBtn  = document.getElementById('navAvatarBtn');
  const dropdown   = document.getElementById('userDropdown');
  avatarBtn?.addEventListener('click', e => {
    e.stopPropagation();
    dropdown?.classList.toggle('open');
  });
  document.addEventListener('click', () => dropdown?.classList.remove('open'));

  // Logout
  async function doLogout() {
    try {
      await fetch('api/auth.php?action=logout', { credentials: 'same-origin' });
    } finally {
      window.location.href = 'index.php';
    }
  }
  document.getElementById('logoutBtn')?.addEventListener('click', doLogout);
  document.getElementById('sidebarLogout')?.addEventListener('click', doLogout);
  document.getElementById('mobileLogout')?.addEventListener('click', doLogout);

  // Hamburger
  const hamburger = document.getElementById('navHamburger');
  const mobileNav = document.getElementById('mobileNav');
  const backdrop  = document.getElementById('mobileNavBackdrop');
  const closeBtn  = document.getElementById('mobileNavClose');
  function openMobileNav()  { mobileNav?.classList.add('open'); }
  function closeMobileNav() { mobileNav?.classList.remove('open'); }
  hamburger?.addEventListener('click', openMobileNav);
  backdrop?.addEventListener('click', closeMobileNav);
  closeBtn?.addEventListener('click', closeMobileNav);
}

/* ═══════════════════════════════════════════════════
   INIT
═══════════════════════════════════════════════════ */
document.addEventListener('DOMContentLoaded', () => {
  // Apply saved theme
  const savedTheme = localStorage.getItem('eduquest_theme');
  if (savedTheme) document.documentElement.setAttribute('data-theme', savedTheme);

  initNav();
  setGreeting();

  const page = window.EQ_PAGE || 'dashboard';

  if (page === 'leaderboard') {
    loadLeaderboard();

    // Filter buttons
    document.querySelectorAll('.lb-filter-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('.lb-filter-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        lbFilter = btn.dataset.filter;
        renderTable(lbData);
      });
    });

    // Search
    document.getElementById('lbSearch')?.addEventListener('input', e => {
      lbSearchQ = e.target.value.trim();
      renderTable(lbData);
    });

  } else {
    // Dashboard
    loadDashboard();
  }

  // Toast utility export
  window.Toast     = window.Toast     || Toast;
  window.fireXpPop = window.fireXpPop || (() => {});
});
