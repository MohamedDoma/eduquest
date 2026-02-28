/**
 * EduQuest — Course Player JavaScript
 * YouTube IFrame API + video progress tracking + skip prevention
 */

/* ═══════════════════════════════════════════════════
   TOAST (local fallback)
═══════════════════════════════════════════════════ */
const Toast = (() => {
  const c = () => document.getElementById('toastContainer');
  const I = {success:'✅',error:'❌',info:'💡',warning:'⚠️'};
  function show(type,title,msg='',dur=4000){
    const t=document.createElement('div');
    t.className=`toast ${type}`;
    t.innerHTML=`<span class="toast-icon">${I[type]}</span><div class="toast-body"><div class="toast-title">${title}</div>${msg?`<div class="toast-msg">${msg}</div>`:''}</div><button class="toast-close">×</button>`;
    t.querySelector('.toast-close').onclick=()=>dismiss(t);
    c().appendChild(t);
    if(dur>0)setTimeout(()=>dismiss(t),dur);
  }
  function dismiss(t){if(!t.parentNode)return;t.classList.add('removing');t.addEventListener('animationend',()=>t.remove(),{once:true});}
  return{success:(t,m,d)=>show('success',t,m,d),error:(t,m,d)=>show('error',t,m,d),info:(t,m,d)=>show('info',t,m,d),warning:(t,m,d)=>show('warning',t,m,d)};
})();

function fireXpPop(xp) {
  const el = document.getElementById('xpPop');
  if (!el) return;
  el.textContent = `+${xp} XP ⚡`;
  el.style.left = '50%'; el.style.top = '30%';
  el.style.transform = 'translateX(-50%)';
  el.className = 'xp-pop';
  void el.offsetWidth;
  el.classList.add('firing');
  el.addEventListener('animationend', () => { el.className='xp-pop'; el.style.transform=''; }, {once:true});
}

/* ═══════════════════════════════════════════════════
   STATE
═══════════════════════════════════════════════════ */
let player        = null;
let trackInterval = null;
let lastSavedPct  = 0;
let isCompleted   = window.EQ_LESSON?.is_completed || false;
let xpAwarded     = false;
let skipWarned    = false;
let prevTime      = 0;
let currentLesson = { ...window.EQ_LESSON };

const THRESHOLD = window.VIDEO_THRESHOLD || 90;

/* ═══════════════════════════════════════════════════
   YOUTUBE IFRAME API
═══════════════════════════════════════════════════ */
function loadYouTubeAPI() {
  const tag = document.createElement('script');
  tag.src   = 'https://www.youtube.com/iframe_api';
  document.head.appendChild(tag);
}

// Extract YouTube video ID from URL
function getYouTubeId(url) {
  const m = url.match(/(?:embed\/|v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/);
  return m ? m[1] : null;
}

// Called automatically by YouTube API when ready
window.onYouTubeIframeAPIReady = function () {
  initPlayer(currentLesson.video_url, currentLesson.watch_percent);
};

function initPlayer(videoUrl, startPercent = 0) {
  const videoId = getYouTubeId(videoUrl);
  if (!videoId) {
    showVideoError('Invalid video URL.');
    return;
  }

  const container = document.getElementById('videoContainer');
  container.innerHTML = '<div id="ytPlayer"></div>';

  const startSeconds = startPercent > 0 && startPercent < THRESHOLD
    ? Math.floor((startPercent / 100) * (currentLesson.duration || 300))
    : 0;

  player = new YT.Player('ytPlayer', {
    width: '100%',
    height: '100%',
    videoId,
    playerVars: {
      autoplay:       1,
      rel:            0,
      modestbranding: 1,
      iv_load_policy: 3,
      disablekb:      1,   // disable keyboard shortcuts (skip prevention)
      fs:             1,
      start:          startSeconds,
    },
    events: {
      onReady:       onPlayerReady,
      onStateChange: onPlayerStateChange,
      onError:       onPlayerError,
    },
  });
}

function onPlayerReady(event) {
  document.getElementById('videoLoading')?.remove();
  startTracking();
  // Update watch bar from saved progress
  updateWatchUI(currentLesson.watch_percent);
  if (isCompleted) showCompletedState();
}

function onPlayerStateChange(event) {
  const PLAYING = YT.PlayerState.PLAYING;
  const PAUSED  = YT.PlayerState.PAUSED;
  const ENDED   = YT.PlayerState.ENDED;

  if (event.data === PLAYING) {
    checkForSkip();
    startTracking();
  } else if (event.data === PAUSED || event.data === ENDED) {
    saveProgress();
    if (event.data === ENDED) {
      const pct = getWatchPercent();
      if (pct >= THRESHOLD) onLessonComplete();
    }
  }
}

function onPlayerError(event) {
  showVideoError('Video could not be loaded. Please try refreshing.');
}

/* ═══════════════════════════════════════════════════
   SKIP PREVENTION
═══════════════════════════════════════════════════ */
function checkForSkip() {
  if (!player || isCompleted) return;
  const current = player.getCurrentTime();
  const allowed = (currentLesson.watch_percent / 100) * (player.getDuration() || currentLesson.duration);

  // Allow a 5 second tolerance
  if (current > allowed + 5 && current > 10) {
    // User tried to skip ahead — seek back
    player.seekTo(Math.max(0, allowed - 2), true);
    showSkipBlocker();
  }
  prevTime = current;
}

function showSkipBlocker() {
  if (skipWarned) return;
  skipWarned = true;
  const el = document.getElementById('skipBlocker');
  el?.classList.remove('hidden');
  player?.pauseVideo();
  setTimeout(() => {
    el?.classList.add('hidden');
    player?.playVideo();
    skipWarned = false;
  }, 2500);
}

/* ═══════════════════════════════════════════════════
   PROGRESS TRACKING
═══════════════════════════════════════════════════ */
function getWatchPercent() {
  if (!player) return currentLesson.watch_percent;
  const duration = player.getDuration();
  if (!duration) return 0;
  const current = player.getCurrentTime();
  return Math.min(100, Math.round((current / duration) * 100));
}

function startTracking() {
  if (trackInterval) clearInterval(trackInterval);
  trackInterval = setInterval(() => {
    if (!player) return;
    const state = player.getPlayerState();
    if (state !== YT.PlayerState.PLAYING) return;

    checkForSkip();
    const pct = getWatchPercent();
    updateWatchUI(pct);

    // Save every 5% increase
    if (pct >= lastSavedPct + 5) {
      saveProgress(pct);
      lastSavedPct = pct;
    }

    if (pct >= THRESHOLD && !isCompleted) {
      onLessonComplete();
    }
  }, 2000);
}

function updateWatchUI(pct) {
  const bar   = document.getElementById('watchProgressBar');
  const label = document.getElementById('watchPctLabel');
  if (bar)   bar.style.width = pct + '%';
  if (label) label.textContent = pct + '%';
}

async function saveProgress(pct) {
  pct = pct ?? getWatchPercent();
  if (pct <= currentLesson.watch_percent && pct < THRESHOLD) return;

  try {
    const res = await fetch('api/courses.php?action=update_progress', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ lesson_id: currentLesson.id, watch_percent: pct }),
      credentials: 'same-origin',
    });
    const data = await res.json();

    if (data.success) {
      currentLesson.watch_percent = pct;

      if (data.data?.newly_completed && !xpAwarded) {
        xpAwarded = true;
        const xp = data.data.xp_awarded || 0;
        if (xp > 0) {
          // Update XP display
          const xpEl = document.getElementById('playerXp');
          if (xpEl) {
            const current = parseInt(xpEl.textContent.replace(/,/g,'')) || 0;
            xpEl.textContent = (current + xp).toLocaleString();
          }
          fireXpPop(xp);
        }

        // Update sidebar item
        updateSidebarItem(currentLesson.id, 100, true);
        updateCourseProgress(data.data.course_progress);

        if (data.data.exam_unlocked) {
          showExamUnlockBanner();
        }
      }
    }
  } catch(e) { /* silent */ }
}

/* ═══════════════════════════════════════════════════
   LESSON COMPLETE
═══════════════════════════════════════════════════ */
function onLessonComplete() {
  if (isCompleted) return;
  isCompleted = true;
  if (trackInterval) clearInterval(trackInterval);
  saveProgress(100);
  showCompletedState();
}

function showCompletedState() {
  const overlay = document.getElementById('videoComplete');
  const xpEl    = document.getElementById('completeXp');
  if (!overlay) return;

  if (xpEl) xpEl.textContent = `+${currentLesson.xp_reward} XP`;

  overlay.classList.remove('hidden');

  // Show exam unlock if already unlocked
  if (window.EQ_COURSE?.exam_unlocked) {
    showExamUnlockBanner();
  }
}

function showExamUnlockBanner() {
  const banner = document.getElementById('examUnlockBanner');
  banner?.classList.remove('hidden');
  Toast.success('🧠 AI Exam Unlocked!', 'You completed all lessons! Start your exam now.', 6000);
}

function showVideoError(msg) {
  const container = document.getElementById('videoContainer');
  if (container) {
    container.innerHTML = `
      <div style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;background:#000;color:var(--text-2);flex-direction:column;gap:12px">
        <div style="font-size:2.5rem">📺</div>
        <p style="font-size:.9rem;text-align:center;max-width:260px">${msg}</p>
      </div>`;
  }
}

/* ═══════════════════════════════════════════════════
   SIDEBAR & PROGRESS UPDATES
═══════════════════════════════════════════════════ */
function updateSidebarItem(lessonId, pct, completed) {
  const item = document.querySelector(`.lesson-item[data-lesson-id="${lessonId}"]`);
  if (!item) return;
  if (completed) item.classList.add('completed');
  const numEl = item.querySelector('.lesson-num');
  if (numEl && completed) numEl.innerHTML = '<span class="lesson-check">✓</span>';

  let miniBar = item.querySelector('.lesson-mini-progress');
  if (!miniBar && pct > 0 && !completed) {
    const body = item.querySelector('.lesson-item-body');
    miniBar = document.createElement('div');
    miniBar.className = 'lesson-mini-progress';
    miniBar.innerHTML = '<div class="lesson-mini-fill"></div>';
    body?.appendChild(miniBar);
  }
  if (miniBar) {
    const fill = miniBar.querySelector('.lesson-mini-fill');
    if (fill) fill.style.width = pct + '%';
    if (completed) miniBar.remove();
  }
}

function updateCourseProgress(progressData) {
  if (!progressData) return;
  const pct = progressData.percent || 0;
  document.getElementById('courseProgressFill').style.width = pct + '%';
  document.getElementById('courseProgressPct').textContent  = pct + '%';

  const completed = document.getElementById('sidebarCompletedCount');
  if (completed) completed.textContent = progressData.completed;

  window.EQ_COURSE.percent   = pct;
  window.EQ_COURSE.completed = progressData.completed;

  if (pct >= 100) {
    window.EQ_COURSE.exam_unlocked = true;
  }
}

/* ═══════════════════════════════════════════════════
   LESSON SWITCHING (client-side SPA)
═══════════════════════════════════════════════════ */
function switchLesson(item) {
  // Save current progress first
  if (player) saveProgress();

  const lessonId   = parseInt(item.dataset.lessonId);
  const videoUrl   = item.dataset.videoUrl;
  const duration   = parseInt(item.dataset.duration) || 0;
  const xp         = parseInt(item.dataset.xp) || 20;
  const watchPct   = parseInt(item.dataset.watch) || 0;
  const completed  = item.dataset.completed === '1';
  const title      = item.dataset.title || '';

  // Update state
  currentLesson = { id: lessonId, video_url: videoUrl, duration, xp_reward: xp, watch_percent: watchPct, is_completed: completed, title };
  isCompleted   = completed;
  xpAwarded     = completed;
  lastSavedPct  = watchPct;
  prevTime      = 0;

  // Update sidebar active state
  document.querySelectorAll('.lesson-item').forEach(el => {
    el.classList.remove('active');
    el.querySelector('.lesson-playing-dot')?.remove();
  });
  item.classList.add('active');
  const dot = document.createElement('div');
  dot.className = 'lesson-playing-dot';
  item.appendChild(dot);

  // Update title & meta in main area
  document.getElementById('lessonTitle').textContent = title;
  document.getElementById('watchPctLabel').textContent = watchPct + '%';
  updateWatchUI(watchPct);

  // Hide/show complete overlay
  document.getElementById('videoComplete')?.classList.add('hidden');

  // Update URL without reload
  const url = new URL(window.location);
  url.searchParams.set('lesson', lessonId);
  history.pushState({}, '', url);

  // Reload player
  if (player) {
    const newId = getYouTubeId(videoUrl);
    if (newId) {
      const startSec = watchPct > 0 && watchPct < THRESHOLD
        ? Math.floor((watchPct / 100) * duration) : 0;
      player.loadVideoById({ videoId: newId, startSeconds: startSec });
    }
  }

  if (completed) {
    setTimeout(showCompletedState, 500);
  }

  // Scroll sidebar to active
  item.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}

/* ═══════════════════════════════════════════════════
   NEXT LESSON BUTTON
═══════════════════════════════════════════════════ */
function goToNextLesson() {
  const items  = Array.from(document.querySelectorAll('.lesson-item'));
  const active = document.querySelector('.lesson-item.active');
  const idx    = items.indexOf(active);
  if (idx >= 0 && idx < items.length - 1) {
    document.getElementById('videoComplete')?.classList.add('hidden');
    switchLesson(items[idx + 1]);
  }
}

/* ═══════════════════════════════════════════════════
   THEME TOGGLE
═══════════════════════════════════════════════════ */
function initThemeToggle() {
  const saved = localStorage.getItem('eduquest_theme') || 'dark';
  document.documentElement.setAttribute('data-theme', saved);
  const icon = document.querySelector('#themeToggle .theme-icon');
  if (icon) icon.textContent = saved === 'dark' ? '☀️' : '🌙';
  document.getElementById('themeToggle')?.addEventListener('click', () => {
    const curr = document.documentElement.getAttribute('data-theme');
    const next = curr === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', next);
    localStorage.setItem('eduquest_theme', next);
    if (icon) icon.textContent = next === 'dark' ? '☀️' : '🌙';
  });
}

/* ═══════════════════════════════════════════════════
   INIT
═══════════════════════════════════════════════════ */
document.addEventListener('DOMContentLoaded', () => {
  initThemeToggle();

  // Lesson list clicks
  document.getElementById('lessonsList')?.addEventListener('click', e => {
    const item = e.target.closest('.lesson-item');
    if (item) { e.preventDefault(); switchLesson(item); }
  });

  // Next lesson button
  document.getElementById('nextLessonBtn')?.addEventListener('click', goToNextLesson);

  // Load YouTube API
  loadYouTubeAPI();

  // Mark current lesson as saved
  lastSavedPct = currentLesson.watch_percent;
});

// Save on page unload
window.addEventListener('beforeunload', () => {
  if (player) saveProgress();
});
