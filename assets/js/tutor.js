/**
 * EduQuest — AI Tutor Engine
 * Educational Chatbot with:
 * 1. n8n webhook integration (Free-flowing educational chat)
 * 2. Intelligent local mock AI (fallback for explanations)
 */

/* ═══════════════════════════════════════════════════
   STATE
═══════════════════════════════════════════════════ */
const tutorState = {
  language:     'English',
  sessionId:    null,
  messages:     [],        // full conversation history
  isWaiting:    false,
};

// Avatar لون أخضر ليدل على أنه مساعد تعليمي وليس مختبر
const BOT_AVATAR = 'https://api.dicebear.com/7.x/bottts/svg?seed=tutorbot&backgroundColor=10b981';
const USER_AVATAR = window.EQ_USER?.avatar_url || 'https://api.dicebear.com/7.x/adventurer/svg?seed=user';

/* ═══════════════════════════════════════════════════
   TOAST (For Error Handling)
═══════════════════════════════════════════════════ */
const Toast = (() => {
  const c = () => document.getElementById('toastContainer');
  const I = {success:'✅',error:'❌',info:'💡',warning:'⚠️'};
  function show(type,title,msg='',dur=4000){
    const t=document.createElement('div');t.className=`toast ${type}`;
    t.innerHTML=`<span class="toast-icon">${I[type]}</span><div class="toast-body"><div class="toast-title">${title}</div>${msg?`<div class="toast-msg">${msg}</div>`:''}</div><button class="toast-close">×</button>`;
    t.querySelector('.toast-close').onclick=()=>dismiss(t);c()?.appendChild(t);if(dur>0)setTimeout(()=>dismiss(t),dur);
  }
  function dismiss(t){if(!t.parentNode)return;t.classList.add('removing');t.addEventListener('animationend',()=>t.remove(),{once:true});}
  return{success:(t,m,d)=>show('success',t,m,d),error:(t,m,d)=>show('error',t,m,d),info:(t,m,d)=>show('info',t,m,d),warning:(t,m,d)=>show('warning',t,m,d)};
})();

/* ═══════════════════════════════════════════════════
   MOCK AI ENGINE (Tutor Method)
   Local fallback — explains concepts instead of testing
═══════════════════════════════════════════════════ */
const MockTutorAI = (() => {
  const info = window.EQ_TUTOR || {};
  const subject = info.subject || 'the subject';
  const title   = info.course_title || 'this course';

  function respond(studentAnswer, lang) {
    const ans = studentAnswer.toLowerCase();
    let reply = '';

    // Simple mock logic for demonstration
    if (ans.includes('example') || ans.includes('مثال')) {
      reply = `Sure! Let's take a real-world example related to **${title}**. Imagine you have to apply this in your daily life. The core idea is to break the problem into smaller pieces. Does that clarify things?`;
    } else if (ans.includes('explain') || ans.includes('what is') || ans.includes('اشرح')) {
      reply = `Great question. In the context of **${subject}**, this concept simply means how different elements interact together to produce a final result. Think of it like a recipe. Need me to go deeper?`;
    } else {
      reply = `I'm here to help you understand **${title}**. That's an interesting point! Could you tell me exactly which part is confusing you? We can walk through it step-by-step.`;
    }

    // Language mock adjustments (just a prefix for the mock to show it detected language)
    const prefixes = {
      English: '',
      Chinese: '(Mock translation) ',
      Tamil: '(Mock translation) ',
      Malay: '(Mock translation) '
    };

    return { reply: prefixes[lang] + reply };
  }

  function getWelcomeMessage(lang) {
    const intros = {
      English: `Hello! 👋 I'm your AI Tutor for **${title}**.\n\nI'm here to help you understand the course. Ask me anything—request explanations, ask for examples, or tell me what you find confusing!`,
      Chinese:  `你好！👋 我是 **${title}** 的AI导师。\n\n我在这里帮助你理解课程。你可以问我任何问题——请求解释，要例子，或者告诉我你觉得哪里困惑！`,
      Tamil:    `வணக்கம்! 👋 நான் **${title}** பாடத்திற்கான உங்கள் AI ஆசிரியர்.\n\nபாடத்தைப் புரிந்துகொள்ள நான் உங்களுக்கு உதவுவேன். எதையும் கேளுங்கள்!`,
      Malay:    `Helo! 👋 Saya Tutor AI anda untuk **${title}**.\n\nSaya di sini untuk membantu anda memahami kursus ini. Tanya saya apa-apa sahaja!`,
    };
    return intros[lang] || intros.English;
  }

  return { respond, getWelcomeMessage };
})();

/* ═══════════════════════════════════════════════════
   n8n WEBHOOK INTEGRATION
═══════════════════════════════════════════════════ */
async function callAITutor(userMessage) {
  const history = tutorState.messages.map(m => ({
    role: m.role === 'assistant' ? 'assistant' : 'user',
    content: m.content
  }));

  // ⚠️ Different Webhook for Tutor (Change to your n8n URL)
  const webhookUrl = 'https://luhur.app.n8n.cloud/webhook/tutor-chat'; 
  
  if (webhookUrl) {
    try {
      const res = await fetch(webhookUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          mode:           'tutor', // Let n8n know this is a free chat, not an exam
          session_id:     tutorState.sessionId,
          user_id:        window.EQ_USER?.id,
          course_id:      window.EQ_TUTOR?.course_id,
          course_title:   window.EQ_TUTOR?.course_title,
          lesson_topics:  window.EQ_TUTOR?.lesson_topics,
          language:       tutorState.language,
          message:        userMessage,
          history,
        }),
        signal: AbortSignal.timeout(10000), // Give tutor slightly more time to generate explanations
      });

      if (res.ok) {
        const rawText = await res.text();
        let data = {};
        try {
          let parsed = JSON.parse(rawText);
          if (Array.isArray(parsed) && parsed.length > 0) parsed = parsed[0];
          
          if (parsed.output && typeof parsed.output === 'string') {
            let cleanOutput = parsed.output.replace(/```json/gi, '').replace(/```/g, '').trim();
            // In tutor mode, n8n might just return plain text instead of JSON
            try { data = JSON.parse(cleanOutput); } 
            catch { data = { reply: cleanOutput }; }
          } else {
            data = parsed;
          }
        } catch (e) {
          data.reply = rawText || "Error parsing AI response.";
        }

        return { reply: data.reply || data.output || data.text || "Error: Empty response." };
      }
    } catch (err) {
      console.warn('n8n webhook unavailable, using mock Tutor:', err.message);
    }
  }

  // Fallback: local mock Tutor
  return MockTutorAI.respond(userMessage, tutorState.language);
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

  tutorState.messages.push({ role, content });
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
   SEND MESSAGE
═══════════════════════════════════════════════════ */
async function sendMessage() {
  if (tutorState.isWaiting) return;

  const input = document.getElementById('examInput');
  const text  = input?.value.trim();
  if (!text) return;

  input.value = '';
  input.style.height = 'auto';
  setInputEnabled(false);
  tutorState.isWaiting = true;

  appendMessage('user', text);
  showTyping();
  
  await new Promise(r => setTimeout(r, 800 + Math.random() * 500));

  try {
    const aiResult = await callAITutor(text);
    hideTyping();
    appendMessage('assistant', aiResult.reply);
  } catch(err) {
    hideTyping();
    appendMessage('assistant', "I'm having trouble connecting right now. Please try again!");
  } finally {
    setInputEnabled(true);
    tutorState.isWaiting = false;
  }
}

/* ═══════════════════════════════════════════════════
   START CHAT
═══════════════════════════════════════════════════ */
function startChat() {
  tutorState.messages  = [];
  tutorState.sessionId = 'tutor_' + Date.now();

  // Switch screens
  document.getElementById('examStartScreen')?.classList.add('hidden');
  const iface = document.getElementById('examInterface');
  iface?.classList.remove('hidden');

  // Update Language Badge
  const langEmojis = { English:'🇬🇧', Chinese:'🇨🇳', Tamil:'🇮🇳', Malay:'🇲🇾' };
  document.getElementById('examLangBadge').textContent = `${langEmojis[tutorState.language] || '🌐'} ${tutorState.language}`;

  // Send Welcome Message
  setTimeout(async () => {
    showTyping();
    
    // We send a hidden system prompt to n8n to start the chat based on language
    try {
      const aiResult = await callAITutor("SYSTEM_START_TUTOR");
      hideTyping();
      // If n8n returns a proper greeting, use it. Otherwise fallback to local.
      const greeting = (aiResult && aiResult.reply && !aiResult.reply.includes("SYSTEM_START_TUTOR")) 
                       ? aiResult.reply 
                       : MockTutorAI.getWelcomeMessage(tutorState.language);
      appendMessage('assistant', greeting);
      setInputEnabled(true);
    } catch(err) {
      hideTyping();
      appendMessage('assistant', MockTutorAI.getWelcomeMessage(tutorState.language));
      setInputEnabled(true);
    }
  }, 400);
}

/* ═══════════════════════════════════════════════════
   INIT
═══════════════════════════════════════════════════ */
document.addEventListener('DOMContentLoaded', () => {
  // Theme Toggle
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

  // Language Selection
  document.getElementById('langOptions')?.addEventListener('click', e => {
    const btn = e.target.closest('.lang-btn');
    if (!btn) return;
    document.querySelectorAll('.lang-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    tutorState.language = btn.dataset.lang;
  });

  // Event Listeners for UI
  document.getElementById('startExamBtn')?.addEventListener('click', startChat); // Note: using the same ID from HTML
  document.getElementById('examSendBtn')?.addEventListener('click', sendMessage);

  document.getElementById('examInput')?.addEventListener('keydown', e => {
    if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); }
  });

  document.getElementById('examInput')?.addEventListener('input', function() {
    this.style.height = 'auto';
    this.style.height = Math.min(this.scrollHeight, 140) + 'px';
  });
});