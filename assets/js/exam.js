/**
 * EduQuest — AI Exam Engine
 * Socratic Method chatbot with:
 *   1. n8n webhook integration (when N8N_MOCK_MODE = false)
 *   2. Intelligent local mock AI (fully functional fallback)
 */

/* ═══════════════════════════════════════════════════
   STATE
═══════════════════════════════════════════════════ */
const exam = {
  language:     'English',
  sessionId:    null,
  messages:     [],        // full conversation history
  questionNum:  0,
  maxQuestions: 12,
  correctCount: 0,
  wrongCount:   0,
  isWaiting:    false,
  isComplete:   false,
  score:        0,
};

const BOT_AVATAR = 'https://api.dicebear.com/7.x/bottts/svg?seed=exambot&backgroundColor=6366f1';
const USER_AVATAR = window.EQ_USER?.avatar_url || 'https://api.dicebear.com/7.x/adventurer/svg?seed=user';

/* ═══════════════════════════════════════════════════
   TOAST
═══════════════════════════════════════════════════ */
const Toast = (() => {
  const c = () => document.getElementById('toastContainer');
  const I = {success:'✅',error:'❌',info:'💡',warning:'⚠️'};
  function show(type,title,msg='',dur=4000){
    const t=document.createElement('div');t.className=`toast ${type}`;
    t.innerHTML=`<span class="toast-icon">${I[type]}</span><div class="toast-body"><div class="toast-title">${title}</div>${msg?`<div class="toast-msg">${msg}</div>`:''}</div><button class="toast-close">×</button>`;
    t.querySelector('.toast-close').onclick=()=>dismiss(t);c().appendChild(t);if(dur>0)setTimeout(()=>dismiss(t),dur);
  }
  function dismiss(t){if(!t.parentNode)return;t.classList.add('removing');t.addEventListener('animationend',()=>t.remove(),{once:true});}
  return{success:(t,m,d)=>show('success',t,m,d),error:(t,m,d)=>show('error',t,m,d),info:(t,m,d)=>show('info',t,m,d),warning:(t,m,d)=>show('warning',t,m,d)};
})();

function fireXpPop(xp) {
  const el = document.getElementById('xpPop');
  if (!el) return;
  el.textContent = `+${xp} XP ⚡`;
  el.style.cssText = 'left:50%;top:30%;transform:translateX(-50%)';
  el.className = 'xp-pop';
  void el.offsetWidth;
  el.classList.add('firing');
  el.addEventListener('animationend', () => { el.className='xp-pop'; }, {once:true});
}

/* ═══════════════════════════════════════════════════
   MOCK AI ENGINE (Socratic Method)
   Fully intelligent local fallback — no network needed
═══════════════════════════════════════════════════ */
const MockAI = (() => {

  const info = window.EQ_EXAM || {};
  const subject = info.subject || 'the subject';
  const topics  = (info.lesson_topics || '').split(', ').filter(Boolean);
  const title   = info.course_title || 'this course';

  // Question bank: Socratic-style, never gives answer directly
  function buildSystemPrompt(lang) {
    const langGuide = {
      English: 'Respond entirely in English.',
      Chinese:  'Respond entirely in Mandarin Chinese (中文).',
      Tamil:    'Respond entirely in Tamil (தமிழ்).',
      Malay:    'Respond entirely in Bahasa Melayu.',
    };
    return `You are a Socratic tutor for "${title}" (${subject}).
${langGuide[lang] || langGuide.English}
Rules:
- NEVER give the direct answer.
- Ask leading questions that guide the student to discover the answer themselves.
- If wrong, give a hint and ask a follow-up.
- If correct, praise briefly and escalate difficulty.
- Keep responses concise (2-4 sentences max).
- Topics covered: ${topics.join(', ')}.`;
  }

  // Question templates by difficulty tier
  const questionBank = {
    easy: [
      { q: `What is the main concept introduced in the first part of "${title}"? Describe it in your own words.`, topic: topics[0] },
      { q: `Can you explain the difference between the two key ideas covered early in this course?`, topic: topics[1] },
      { q: `What does "${topics[0]}" mean to you based on what you've learned?`, topic: topics[0] },
      { q: `Name one real-world example that relates to ${topics[0] || 'the first topic'}.`, topic: topics[0] },
    ],
    medium: [
      { q: `How does ${topics[1] || 'the second concept'} build upon what you learned in ${topics[0] || 'the beginning'}?`, topic: topics[1] },
      { q: `If I asked you to explain ${topics[2] || 'this concept'} to a friend who never studied it, what would you say first?`, topic: topics[2] },
      { q: `What would happen if you removed the key principle from ${topics[1] || 'this topic'}? Why?`, topic: topics[1] },
      { q: `Can you walk me through the steps involved in ${topics[3] || 'the process covered'}?`, topic: topics[3] },
    ],
    hard: [
      { q: `How do ${topics[topics.length-2] || 'the advanced topics'} connect to the foundational ideas you learned?`, topic: 'synthesis' },
      { q: `Challenge: What's a potential limitation or exception to the main principle of ${title}?`, topic: 'critical thinking' },
      { q: `Compare and contrast the approaches covered in the first and last lessons of this course.`, topic: 'comparison' },
      { q: `If you had to design a problem that tested understanding of "${title}", what would it look like?`, topic: 'application' },
    ],
  };

  // Socratic feedback responses
  const correctResponses = [
    "Excellent thinking! 🎯 You're connecting the ideas well. Let me push you a bit further:",
    "That's right! ✅ You've got a solid grasp. Now here's something trickier:",
    "Spot on! Your understanding is building nicely. Let's go deeper:",
    "Well done! 🌟 I can see you've been paying attention. One more challenge:",
    "Correct! Great reasoning. Now let's test if you can apply this:",
  ];

  const hintResponses = [
    "Hmm, you're on the right track, but let's think more carefully. Consider this: what would happen if you approached it from the opposite direction? Try again:",
    "Not quite — but don't worry! Think back to what you learned about [TOPIC]. Does that change your answer?",
    "That's an interesting take, but let's refine it. What's the core principle at play here? Start with that, then work outward.",
    "You're close! The key word you might be missing is related to [TOPIC]. Can you revisit your answer with that in mind?",
    "Good attempt! Think about it this way: what would a teacher highlight as the most important part of [TOPIC]? That might help.",
  ];

  const wrongResponses = [
    "I appreciate the effort! Let's approach this differently — what do you already know for certain about [TOPIC]? Build from there.",
    "Not exactly, but this is how learning works! Can I guide you with a hint? Think about what [TOPIC] is NOT, and that might help you define what it IS.",
    "Let's slow down a bit. Instead of jumping to the answer, what question would YOU ask if you were the teacher for [TOPIC]?",
  ];

  const endResponses = {
    pass:    "🎓 Incredible work! You've demonstrated genuine understanding through your own reasoning. That's the Socratic ideal — you didn't need me to tell you the answers, you discovered them yourself.",
    partial: "📚 Good effort! You showed solid understanding in most areas. Review the topics where you hesitated, then the answers will feel obvious. Keep going!",
    fail:    "💪 This was tough, but every struggle is learning in disguise. Go back to the course, let the ideas marinate, and come back. You'll get it next time!",
  };

  // Evaluate a student response (simplified heuristic)
  function evaluate(studentAnswer, questionNum) {
    const ans = studentAnswer.toLowerCase().trim();
    const minLength = 15;
    if (ans.length < minLength) return { correct: false, type: 'too_short' };

    // Keyword presence check (based on topics)
    const topicKeywords = topics.flatMap(t => t.toLowerCase().split(/\s+/));
    const matchCount = topicKeywords.filter(k => k.length > 3 && ans.includes(k)).length;

    // Difficulty-weighted scoring
    const tier = questionNum <= 4 ? 'easy' : questionNum <= 8 ? 'medium' : 'hard';
    const threshold = { easy: 1, medium: 2, hard: 2 }[tier];

    const correct = matchCount >= threshold || ans.split(' ').length > 20;
    return { correct, type: correct ? 'correct' : (Math.random() > 0.4 ? 'hint' : 'wrong') };
  }

  // Get next question
  function getQuestion(num) {
    const tier = num <= 4 ? 'easy' : num <= 8 ? 'medium' : 'hard';
    const pool = questionBank[tier];
    if (!pool.length) return questionBank.easy[0];
    return pool[(num - 1) % pool.length];
  }

  // Generate AI response
  function respond(studentAnswer, questionNum, lang) {
    const evaluation = evaluate(studentAnswer, questionNum);
    const isLast     = questionNum >= 12;

    let reply = '';
    const currentTopic = getQuestion(questionNum).topic || topics[0] || 'this concept';

    if (evaluation.correct) {
      const praise = correctResponses[Math.floor(Math.random() * correctResponses.length)];
      if (!isLast) {
        const next = getQuestion(questionNum + 1);
        reply = `${praise}\n\n${next.q}`;
      } else {
        reply = endResponses.pass;
      }
      return { reply, correct: true };
    } else {
      if (evaluation.type === 'hint') {
        const hint = hintResponses[Math.floor(Math.random() * hintResponses.length)]
          .replace('[TOPIC]', currentTopic);
        reply = hint;
      } else {
        const wrong = wrongResponses[Math.floor(Math.random() * wrongResponses.length)]
          .replace('[TOPIC]', currentTopic);
        reply = wrong;
      }
      return { reply, correct: false };
    }
  }

  function getFirstQuestion(lang) {
    const q = getQuestion(1);
    const intros = {
      English: `Welcome to your AI exam for **${title}**! 🎓\n\nI'm your Socratic tutor. I won't give you answers — instead I'll ask questions that guide your thinking.\n\nLet's begin!\n\n**Question 1:** ${q.q}`,
      Chinese:  `欢迎参加 **${title}** 的AI考试！🎓\n\n我是你的苏格拉底式导师。我不会直接给你答案，而是通过提问引导你思考。\n\n让我们开始！\n\n**第1题：** ${q.q}`,
      Tamil:    `**${title}** AI தேர்வுக்கு வரவேற்கிறோம்! 🎓\n\nநான் உங்கள் சொக்ரடீஸ் வழிகாட்டி. நான் நேரடியாக விடை சொல்ல மாட்டேன் — கேள்விகள் மூலம் உங்கள் சிந்தனையை வழிநடத்துவேன்.\n\nதொடங்குவோம்!\n\n**கேள்வி 1:** ${q.q}`,
      Malay:    `Selamat datang ke Peperiksaan AI **${title}**! 🎓\n\nSaya ialah tutor Socratic anda. Saya tidak akan memberi jawapan terus — sebaliknya saya akan memandu pemikiran anda melalui soalan.\n\nMari kita mulakan!\n\n**Soalan 1:** ${q.q}`,
    };
    return intros[lang] || intros.English;
  }

  return { respond, getFirstQuestion, getQuestion, evaluate };
})();

/* ═══════════════════════════════════════════════════
   n8n WEBHOOK INTEGRATION
═══════════════════════════════════════════════════ */
async function callAI(userMessage) {
  // Build full conversation history for context
  const history = exam.messages.map(m => ({
    role: m.role === 'assistant' ? 'assistant' : 'user',
    content: m.content
  }));

  // Try n8n webhook first
  const webhookUrl = 'https://luhur.app.n8n.cloud/webhook-test/tutor-chat'; // ← Set your n8n webhook URL here (e.g. https://your-n8n.com/webhook/exam-chat)
  if (webhookUrl) {
    try {
      const res = await fetch(webhookUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          session_id:     exam.sessionId,
          user_id:        window.EQ_USER?.id,
          course_id:      window.EQ_EXAM?.course_id,
          course_title:   window.EQ_EXAM?.course_title,
          subject:        window.EQ_EXAM?.subject,
          lesson_topics:  window.EQ_EXAM?.lesson_topics,
          language:       exam.language,
          question_num:   exam.questionNum,
          message:        userMessage,
          history,
        }),
        signal: AbortSignal.timeout(8000),
      });
      if (res.ok) {
        const rawText = await res.text();
        console.log("n8n Raw Response:", rawText);
        
        let data = {};
        try {
          // 1. نفك الـ JSON الخارجي
          let parsed = JSON.parse(rawText);
          
          // 2. لو هو مصفوفة (Array)، ناخد أول عنصر
          if (Array.isArray(parsed) && parsed.length > 0) {
            parsed = parsed[0];
          }
          
          // 3. نفك الـ String اللي جوه الـ output
          if (parsed.output && typeof parsed.output === 'string') {
            // ننظف الـ Markdown لو موجود ونفك الـ JSON الداخلي
            let cleanOutput = parsed.output.replace(/```json/gi, '').replace(/```/g, '').trim();
            data = JSON.parse(cleanOutput);
          } else {
            data = parsed;
          }
        } catch (e) {
          console.error("JSON Parse Error:", e);
          data.reply = "Error parsing AI response. Check console.";
        }

        return {
          reply:   data.reply || "Error: Could not extract reply.",
          correct: data.correct ?? null,
          done:    data.done === true || data.done === "true",
        };
      }
    } catch (err) {
      console.warn('n8n webhook unavailable, using mock AI:', err.message);
    }
  }

  // Fallback: local mock AI
  const result = MockAI.respond(userMessage, exam.questionNum, exam.language);
  const isLast = exam.questionNum >= exam.maxQuestions;
  return {
    reply:   result.reply,
    correct: result.correct,
    done:    isLast && result.correct,
    score:   null,
  };
}

/* ═══════════════════════════════════════════════════
   CHAT UI
═══════════════════════════════════════════════════ */
function appendMessage(role, content, animate = true) {
  const chat = document.getElementById('examChat');
  if (!chat) return;

  const isUser      = role === 'user';
  const isSystem    = role === 'system';
  const avatarSrc   = isUser ? USER_AVATAR : BOT_AVATAR;
  const now         = new Date().toLocaleTimeString('en-US', {hour:'2-digit', minute:'2-digit'});

  // Convert markdown-ish **bold** and newlines
  const formatted = content
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/\n\n/g, '</p><p>')
    .replace(/\n/g, '<br>');

  const msg = document.createElement('div');
  msg.className = `chat-msg ${role}`;

  if (isSystem) {
    msg.innerHTML = `<div class="msg-bubble"><p>${formatted}</p></div>`;
  } else {
    msg.innerHTML = `
      <img class="msg-avatar" src="${avatarSrc}" alt="">
      <div>
        <div class="msg-bubble"><p>${formatted}</p></div>
        <div class="msg-time">${now}</div>
      </div>`;
  }

  if (animate) msg.style.animationDelay = '0s';
  chat.appendChild(msg);
  chat.scrollTop = chat.scrollHeight;

  // Save to history
  exam.messages.push({ role, content });
}

function showTyping() {
  document.getElementById('typingIndicator')?.classList.remove('hidden');
  const chat = document.getElementById('examChat');
  if (chat) chat.scrollTop = chat.scrollHeight;
}
function hideTyping() {
  document.getElementById('typingIndicator')?.classList.add('hidden');
}

function setInputEnabled(enabled) {
  const input = document.getElementById('examInput');
  const btn   = document.getElementById('examSendBtn');
  if (input) input.disabled = !enabled;
  if (btn)   btn.disabled   = !enabled;
  if (enabled) input?.focus();
}

/* ═══════════════════════════════════════════════════
   PROGRESS DOTS
═══════════════════════════════════════════════════ */
function updateProgressDots(questionNum, lastCorrect = null) {
  const dotsEl = document.getElementById('examProgressDots');
  if (!dotsEl) return;

  // Build dots
  dotsEl.innerHTML = '';
  for (let i = 1; i <= exam.maxQuestions; i++) {
    const dot = document.createElement('div');
    dot.className = 'exam-dot';
    if (i < questionNum) {
      // Already answered - look up result from messages (simplified)
      dot.classList.add(i <= exam.correctCount + (questionNum - 1 - exam.correctCount - exam.wrongCount) ? 'correct' : 'wrong');
    } else if (i === questionNum) {
      dot.classList.add('current');
    }
    dotsEl.appendChild(dot);
  }

  document.getElementById('examQCount').textContent = `Q${questionNum}`;

  const pct = Math.round((exam.correctCount / Math.max(1, exam.questionNum - 1)) * 100);
  document.getElementById('examScoreBadge').textContent = `Score: ${isNaN(pct) ? 0 : pct}%`;
}

/* ═══════════════════════════════════════════════════
   SEND MESSAGE
═══════════════════════════════════════════════════ */
async function sendMessage() {
  if (exam.isWaiting || exam.isComplete) return;

  const input = document.getElementById('examInput');
  const text  = input?.value.trim();
  if (!text) return;

  input.value = '';
  input.style.height = 'auto';
  setInputEnabled(false);
  exam.isWaiting = true;

  // Show user message
  appendMessage('user', text);

  // Show typing
  showTyping();
  await new Promise(r => setTimeout(r, 1200 + Math.random() * 800)); // realistic delay

  try {
    const aiResult = await callAI(text);
    hideTyping();

    // Update score
    if (aiResult.correct === true)  { exam.correctCount++; }
    if (aiResult.correct === false) { exam.wrongCount++;   }

    // Append AI reply
    appendMessage('assistant', aiResult.reply);

    // Check if question was answered (move to next question on correct)
    if (aiResult.correct && !aiResult.done) {
      exam.questionNum++;
      updateProgressDots(exam.questionNum);
    } else if (aiResult.done || exam.questionNum >= exam.maxQuestions) {
      // Exam finished
      setTimeout(() => endExam(), 1500);
      return;
    } else if (exam.questionNum < exam.maxQuestions && aiResult.correct) {
      updateProgressDots(exam.questionNum);
    }

    setInputEnabled(true);
    exam.isWaiting = false;

  } catch(err) {
    hideTyping();
    appendMessage('assistant', "I'm having trouble connecting. Please try again!");
    setInputEnabled(true);
    exam.isWaiting = false;
  }
}

/* ═══════════════════════════════════════════════════
   END EXAM
═══════════════════════════════════════════════════ */
async function endExam() {
  exam.isComplete = true;
  setInputEnabled(false);

  // Calculate score
  const answered = exam.correctCount + exam.wrongCount;
  const score    = answered > 0 ? Math.round((exam.correctCount / answered) * 100) : 0;
  exam.score     = score;
  const passed   = score >= 60;

  // Save to server
  try {
    await fetch('api/exam_api.php', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'same-origin',
      body: JSON.stringify({
        action:    'save_result',
        course_id:  window.EQ_EXAM?.course_id,
        session_id: exam.sessionId,
        score,
        passed,
        language:  exam.language,
      }),
    });
  } catch(e) { /* silent */ }

  // Show results
  setTimeout(() => showResults(score, passed), 800);
}

function showResults(score, passed) {
  document.getElementById('examInterface')?.classList.add('hidden');
  const resultsEl = document.getElementById('examResults');
  resultsEl?.classList.remove('hidden');

  const emoji     = score >= 90 ? '🏆' : score >= 70 ? '🎉' : score >= 60 ? '😊' : '💪';
  const titleText = score >= 90 ? 'Outstanding!' : score >= 70 ? 'Great Job!' : score >= 60 ? 'You Passed!' : 'Keep Going!';
  const feedback  = score >= 90
    ? "You've mastered this course. Your reasoning was exceptional throughout the exam."
    : score >= 70
    ? "Solid understanding! A few areas to polish, but you clearly learned a lot."
    : score >= 60
    ? "You passed! Review the trickier topics and your understanding will deepen."
    : "Don't give up! Go back through the lessons, take notes, and come back stronger.";

  document.getElementById('resultsEmoji').textContent  = emoji;
  document.getElementById('resultsTitle').textContent  = titleText;
  document.getElementById('resultsBigScore').textContent = score + '%';
  document.getElementById('resultsFeedback').textContent = feedback;

  const xpEl = document.getElementById('resultsXpEarned');
  if (xpEl) {
    const xpEarned = passed ? window.EQ_EXAM?.xp_reward || 100 : Math.round((score / 100) * (window.EQ_EXAM?.xp_reward || 100));
    xpEl.textContent = `+${xpEarned} XP Earned`;
    setTimeout(() => fireXpPop(xpEarned), 600);
  }

  // Animate score ring
  const ring = document.getElementById('resultsScoreRing');
  if (ring) {
    const deg = Math.round((score / 100) * 360);
    setTimeout(() => { ring.style.setProperty('--score-deg', deg + 'deg'); }, 300);
  }

  if (passed) {
    Toast.success('Exam Passed! 🎓', `You scored ${score}%!`, 6000);
  } else {
    Toast.info('Exam Complete', `Score: ${score}%. Study more and try again!`, 5000);
  }
}

/* ═══════════════════════════════════════════════════
   START EXAM
═══════════════════════════════════════════════════ */
function startExam() {
  exam.questionNum  = 1;
  exam.correctCount = 0;
  exam.wrongCount   = 0;
  exam.messages     = [];
  exam.isComplete   = false;
  exam.sessionId    = 'session_' + Date.now();

  // Switch screens
  document.getElementById('examStartScreen')?.classList.add('hidden');
  const iface = document.getElementById('examInterface');
  iface?.classList.remove('hidden');

  // Update topbar
  const langEmojis = { English:'🇬🇧', Chinese:'🇨🇳', Tamil:'🇮🇳', Malay:'🇲🇾' };
  document.getElementById('examLangBadge').textContent = `${langEmojis[exam.language] || '🌐'} ${exam.language}`;

  updateProgressDots(1);

  // Send first AI message via n8n
  setTimeout(async () => {
    showTyping();
    try {
      // إرسال كود سري للـ AI ليبدأ هو المحادثة
      const aiResult = await callAI("SYSTEM_START_EXAM");
      hideTyping();
      appendMessage('assistant', aiResult.reply);
      setInputEnabled(true);
    } catch(err) {
      hideTyping();
      appendMessage('assistant', "Could not connect to the AI tutor. Please refresh the page.");
    }
  }, 400);

  // Save chat session to server
  fetch('api/exam_api.php', {
    method: 'POST',
    headers: {'Content-Type':'application/json'},
    credentials: 'same-origin',
    body: JSON.stringify({
      action: 'start_session',
      course_id: window.EQ_EXAM?.course_id,
      language: exam.language,
      session_id: exam.sessionId,
    }),
  }).catch(() => {});
}

/* ═══════════════════════════════════════════════════
   INIT
═══════════════════════════════════════════════════ */
document.addEventListener('DOMContentLoaded', () => {
  // Theme
  const saved = localStorage.getItem('eduquest_theme') || 'dark';
  document.documentElement.setAttribute('data-theme', saved);
  const icon = document.querySelector('#themeToggle .theme-icon');
  if (icon) icon.textContent = saved === 'dark' ? '☀️' : '🌙';
  document.getElementById('themeToggle')?.addEventListener('click', () => {
    const c = document.documentElement.getAttribute('data-theme');
    const n = c === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', n);
    localStorage.setItem('eduquest_theme', n);
    if (icon) icon.textContent = n === 'dark' ? '☀️' : '🌙';
  });

  // Language selection
  document.getElementById('langOptions')?.addEventListener('click', e => {
    const btn = e.target.closest('.lang-btn');
    if (!btn) return;
    document.querySelectorAll('.lang-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    exam.language = btn.dataset.lang;
  });

  // Start button
  document.getElementById('startExamBtn')?.addEventListener('click', startExam);

  // Send message
  document.getElementById('examSendBtn')?.addEventListener('click', sendMessage);

  document.getElementById('examInput')?.addEventListener('keydown', e => {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); }
  });

  // Auto-resize textarea
  document.getElementById('examInput')?.addEventListener('input', function() {
    this.style.height = 'auto';
    this.style.height = Math.min(this.scrollHeight, 140) + 'px';
  });

  // Show "already passed" notice
  if (window.EQ_EXAM?.already_passed) {
    const card = document.querySelector('.exam-start-card');
    if (card) {
      const notice = document.createElement('div');
      notice.style.cssText = 'background:rgba(52,211,153,.1);border:1px solid rgba(52,211,153,.3);border-radius:10px;padding:12px 16px;font-size:.85rem;color:var(--accent-2);text-align:center;';
      notice.textContent = `✅ You previously passed this exam with ${window.EQ_EXAM.prev_score}%. You can retake it anytime!`;
      const btn = card.querySelector('#startExamBtn');
      card.insertBefore(notice, btn);
    }
  }
});
