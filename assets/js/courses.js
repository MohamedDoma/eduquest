/**
 * EduQuest — Courses Listing JavaScript
 */

let allCourses  = [];
let allSubjects = [];
let activeTab   = window.EQ_BROWSE ? 'browse' : 'mine';
let filterSubject = '';
let filterDiff    = '';
let searchQuery   = '';

/* ── Fetch courses ────────────────────────────── */
async function loadCourses() {
  try {
    const res = await fetch('api/courses.php?action=list', { credentials: 'same-origin' });
    const data = await res.json();
    if (!data.success) return;
    allCourses  = data.data.courses  || [];
    allSubjects = data.data.subjects || [];
    buildSubjectFilters();
    renderCourses();
  } catch(e) {
    document.getElementById('coursesGrid').innerHTML =
      '<p style="color:var(--danger);padding:20px">Failed to load courses.</p>';
  }
}

/* ── Subject filter chips ─────────────────────── */
function buildSubjectFilters() {
  const el = document.getElementById('subjectFilters');
  if (!el) return;
  allSubjects.forEach(s => {
    const btn = document.createElement('button');
    btn.className = 'filter-chip';
    btn.dataset.subject = s.id;
    btn.textContent = s.icon + ' ' + s.name;
    el.appendChild(btn);
  });
  el.addEventListener('click', e => {
    const btn = e.target.closest('.filter-chip');
    if (!btn) return;
    el.querySelectorAll('.filter-chip').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    filterSubject = btn.dataset.subject || '';
    renderCourses();
  });
}

/* ── Render ───────────────────────────────────── */
function renderCourses() {
  const grid  = document.getElementById('coursesGrid');
  const empty = document.getElementById('coursesEmpty');
  const uid   = window.EQ_USER?.id;

  let list = allCourses.filter(c => {
    if (activeTab === 'mine' && !c.enrolled_at) return false;
    if (filterSubject && c.subject_id != filterSubject) return false;
    if (filterDiff    && c.difficulty !== filterDiff)   return false;
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      if (!c.title.toLowerCase().includes(q) && !c.description.toLowerCase().includes(q)) return false;
    }
    return true;
  });

  if (!list.length) {
    grid.innerHTML  = '';
    empty?.classList.remove('hidden');
    return;
  }
  empty?.classList.add('hidden');

  grid.innerHTML = list.map((c, i) => buildCourseCard(c, i)).join('');

  // Bind click
  grid.querySelectorAll('.course-card').forEach(card => {
    card.addEventListener('click', () => {
      const id = card.dataset.courseId;
      const course = allCourses.find(c => c.id == id);
      if (course) openEnrollModal(course);
    });
  });
}

function buildCourseCard(c, i) {
  const pct      = parseInt(c.progress_percent) || 0;
  const enrolled = !!c.enrolled_at;
  const done     = !!c.completed_at;
  const diffDot  = {beginner:'diff-beginner',intermediate:'diff-intermediate',advanced:'diff-advanced'};

  return `
    <div class="course-card" data-course-id="${c.id}" style="animation-delay:${i*.04}s">
      <div class="course-thumb-wrap">
        <img class="course-thumb" src="${c.thumbnail_url}" alt="${c.title}" loading="lazy"
             onerror="this.src='https://images.unsplash.com/photo-1509062522246-3755977927d7?w=600&q=80'">
        ${enrolled ? `<div class="course-enrolled-badge">${done ? '✓ Done' : pct+'% done'}</div>` : ''}
      </div>
      <div class="course-body">
        <div class="course-subject">
          <span>${c.subject_icon}</span>
          <span>${c.subject_name}</span>
          <span class="difficulty-dot ${diffDot[c.difficulty] || ''}"></span>
          <span style="color:var(--text-3);font-size:.7rem">${c.difficulty}</span>
        </div>
        <div class="course-title">${c.title}</div>
        <div class="course-meta">
          <span class="course-meta-item">📖 ${c.lesson_count} lessons</span>
          <span class="course-meta-item">⚡ +${c.xp_reward} XP</span>
          <span class="course-meta-item">Grade ${c.grade_level}</span>
        </div>
        ${enrolled ? `
          <div class="progress-bar" style="height:5px;margin-bottom:4px">
            <div class="progress-fill" style="width:${pct}%"></div>
          </div>` : ''}
        <div style="display:flex;align-items:center;justify-content:space-between;margin-top:${enrolled?'4px':'8px'}">
          <span style="font-size:.75rem;color:var(--text-3)">👤 ${c.teacher_name}</span>
          ${c.exam_unlocked ? '<span class="badge badge-success" style="font-size:.68rem">🧠 Exam Ready</span>' : ''}
        </div>
      </div>
    </div>`;
}

/* ── Enroll Modal ─────────────────────────────── */
function openEnrollModal(course) {
  const modal   = document.getElementById('enrollModal');
  const content = document.getElementById('enrollContent');
  if (!modal || !content) return;

  const enrolled = !!course.enrolled_at;
  const pct      = parseInt(course.progress_percent) || 0;

  content.innerHTML = `
    <div style="text-align:center;margin-bottom:20px">
      <img src="${course.thumbnail_url}" style="width:100%;height:180px;object-fit:cover;border-radius:var(--radius-lg);margin-bottom:16px"
           onerror="this.src='https://images.unsplash.com/photo-1509062522246-3755977927d7?w=600&q=80'">
      <div style="display:inline-flex;align-items:center;gap:6px;font-size:.8rem;color:var(--text-2);margin-bottom:8px">
        <span>${course.subject_icon}</span><span>${course.subject_name}</span>
      </div>
      <h2 style="font-family:var(--font-display);font-size:1.3rem;font-weight:800;margin-bottom:8px">${course.title}</h2>
      <p style="font-size:.85rem;color:var(--text-2);line-height:1.7;margin-bottom:16px">${course.description}</p>
      <div style="display:flex;justify-content:center;gap:12px;margin-bottom:20px;flex-wrap:wrap">
        <span class="badge badge-accent">📖 ${course.lesson_count} Lessons</span>
        <span class="badge badge-success">⚡ +${course.xp_reward} XP</span>
        <span class="badge badge-warning">Grade ${course.grade_level}</span>
      </div>
    </div>
    ${enrolled
      ? `<a href="course.php?id=${course.id}" class="btn-primary btn-full" style="font-size:.95rem;padding:14px">
           ${pct > 0 ? '▶ Continue Learning' : '▶ Start Learning'}
         </a>
         ${course.exam_unlocked
           ? `<a href="exam.php?course=${course.id}" class="btn-secondary btn-full" style="margin-top:10px;width:100%;justify-content:center">🧠 Take AI Exam</a>`
           : ''}`
      : `<button class="btn-primary btn-full" id="enrollNowBtn" data-course-id="${course.id}" style="font-size:.95rem;padding:14px">
           Enroll Now (Free) 🚀
         </button>`
    }`;

  modal.classList.remove('hidden');

  document.getElementById('enrollNowBtn')?.addEventListener('click', async function() {
    this.disabled   = true;
    this.textContent = 'Enrolling…';
    try {
      const res  = await fetch('api/courses.php?action=enroll', {
        method: 'POST',
        headers: {'Content-Type':'application/json'},
        body: JSON.stringify({ course_id: parseInt(this.dataset.courseId) }),
        credentials: 'same-origin',
      });
      const data = await res.json();
      if (data.success) {
        window.Toast?.success('Enrolled! 🎉', data.message);
        modal.classList.add('hidden');
        await loadCourses();
        setTimeout(() => { window.location.href = `course.php?id=${course.id}`; }, 500);
      } else {
        window.Toast?.error('Enrollment failed', data.message);
        this.disabled = false; this.textContent = 'Enroll Now (Free) 🚀';
      }
    } catch(e) {
      this.disabled = false; this.textContent = 'Enroll Now (Free) 🚀';
    }
  });
}

/* ── Init ─────────────────────────────────────── */
document.addEventListener('DOMContentLoaded', () => {
  loadCourses();

  // Tab switching
  document.querySelectorAll('.courses-tab').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.courses-tab').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      activeTab = btn.dataset.tab;
      renderCourses();
    });
  });

  // Difficulty filters
  document.querySelectorAll('[data-diff]').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('[data-diff]').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      filterDiff = btn.dataset.diff || '';
      renderCourses();
    });
  });

  // Search
  let searchTimer;
  document.getElementById('courseSearch')?.addEventListener('input', e => {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => { searchQuery = e.target.value.trim(); renderCourses(); }, 300);
  });

  // Modal close
  document.getElementById('enrollClose')?.addEventListener('click', () => {
    document.getElementById('enrollModal')?.classList.add('hidden');
  });
  document.getElementById('enrollModal')?.addEventListener('click', e => {
    if (e.target.id === 'enrollModal') e.target.classList.add('hidden');
  });
});
