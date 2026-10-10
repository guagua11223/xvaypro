(function () {
  const LANG_KEY = "xvay-ui-lang";
  const USER_KEY = "xvay-users";
  const SESSION_KEY = "xvay-session";
  const PROMO_KEY = "xvay-promo";
  const TICKET_KEY = "xvay-tickets";

  const page = () => document.body.dataset.page || "home";
  const lang = () => (sessionStorage.getItem(LANG_KEY) === "en" ? "en" : "zh");
  const tx = (zh, en) => (lang() === "en" ? en : zh);
  const field = (item, key) => item[lang() === "en" ? key + "En" : key + "Zh"] || item[key + "Zh"] || "";

  function esc(value) {
    return String(value ?? "").replace(/[&<>"']/g, (ch) => ({
      "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;"
    }[ch]));
  }

  function hash(text) {
    let h = 2166136261;
    const s = "xvay|" + text;
    for (let i = 0; i < s.length; i++) {
      h ^= s.charCodeAt(i);
      h = Math.imul(h, 16777619);
    }
    return (h >>> 0).toString(16);
  }

  function users() {
    try { return JSON.parse(localStorage.getItem(USER_KEY)) || []; }
    catch { return []; }
  }
  function saveUsers(list) { localStorage.setItem(USER_KEY, JSON.stringify(list)); }
  function sessionEmail() { return localStorage.getItem(SESSION_KEY) || ""; }
  function currentUser() { return users().find((u) => u.email === sessionEmail()) || null; }
  function writeUser(next) {
    const list = users();
    const i = list.findIndex((u) => u.email === next.email);
    if (i >= 0) list[i] = next; else list.push(next);
    saveUsers(list);
  }

  function detectOS() {
    const ua = navigator.userAgent;
    if (/Android/i.test(ua)) return "android";
    if (/iPhone|iPad|iPod/i.test(ua)) return "ios";
    if (/Win/i.test(ua)) return "windows";
    if (/Linux/i.test(ua)) return "linux";
    return "mac";
  }

  const OS = {
    mac: { zh: "macOS", en: "Mac", file: "讯连宝-1.4.2-mac.txt", size: "86 MB" },
    windows: { zh: "Windows", en: "Windows", file: "讯连宝-1.4.2-windows.txt", size: "72 MB" },
    ios: { zh: "iOS", en: "iOS", file: "讯连宝-1.4.2-ios.txt", size: "App Store" },
    android: { zh: "Android", en: "Android", file: "讯连宝-1.4.2-android.txt", size: "48 MB" },
    linux: { zh: "Linux", en: "Linux", file: "讯连宝-1.4.2-linux.txt", size: "64 MB" }
  };

  function logo() {
    return `<svg viewBox="0 0 32 32" aria-hidden="true"><path d="M6 23c4-6.5 6-6.5 10 0s6 6.5 10 0" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round"/><path d="M6 17.5c4-6.5 6-6.5 10 0s6 6.5 10 0" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round" opacity=".72"/><path d="M6 12c4-6.5 6-6.5 10 0s6 6.5 10 0" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round" opacity=".4"/></svg>`;
  }

  function icon(name) {
    const paths = {
      mac: '<path d="M18 5c.3 1.8-1.2 3.4-2.6 4 1.5 2 .4 5.2-1.3 6.3 2.3.3 4 1.8 4.6 3.6-2.1 1.3-3.5.5-4.5-.1-.6 2.3.5 4.6 2.6 5.4-4 1.7-8.2-1.3-8.2-6C8.6 11.4 12.8 7.6 18 5z"/>',
      windows: '<path d="M5 7.2 13.5 6v7.2H5V7.2zm9.6-1.4L27 4.2V13.2h-12.4V5.8zM5 14.8h8.5V22L5 20.6v-5.8zm9.6 0H27V26l-12.4-1.8V14.8z"/>',
      ios: '<rect x="11" y="4" width="10" height="24" rx="2.5"/><path d="M16 24.5h.1"/>',
      android: '<path d="M9 13h14v9a2 2 0 0 1-2 2h-1.5v3h-2v-3h-3v3h-2v-3H11a2 2 0 0 1-2-2v-9z"/><path d="M11 11.5 9.5 8M21 11.5 22.5 8M12 16h.1M20 16h.1"/>',
      linux: '<circle cx="16" cy="17" r="7"/><path d="M12 10c.4-2 1.6-3 2.5-3M20 10c-.4-2-1.6-3-2.5-3M13.5 16h.1M18.5 16h.1M14 19c.8.8 2.7.8 4 0"/>',
      download: '<path d="M16 5v14M10 14l6 6 6-6M7 27h18"/>',
      chat: '<path d="M7 15a8 8 0 0 1 8-8h2a8 8 0 0 1 0 16h-.5L12 27v-4H15a8 8 0 0 1-8-8z"/>'
    };
    const body = paths[name] || paths.download;
    return `<svg viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${body}</svg>`;
  }

  function toast(message) {
    let el = document.querySelector(".toast");
    if (!el) {
      el = document.createElement("div");
      el.className = "toast";
      document.body.appendChild(el);
    }
    el.textContent = message;
    el.classList.add("show");
    clearTimeout(toast._t);
    toast._t = setTimeout(() => el.classList.remove("show"), 2800);
  }

  function deviceLabel() {
    const os = OS[detectOS()];
    const ua = navigator.userAgent;
    const browser = /Edg\//.test(ua) ? "Edge" : /Chrome\//.test(ua) ? "Chrome" : /Safari\//.test(ua) && !/Chrome\//.test(ua) ? "Safari" : /Firefox\//.test(ua) ? "Firefox" : "Browser";
    return `${lang() === "en" ? os.en : os.zh} · ${browser}`;
  }

  function rememberDevice(user) {
    const name = deviceLabel();
    user.devices = user.devices || [];
    let found = user.devices.find((d) => d.name === name);
    if (!found) {
      found = { id: Math.random().toString(36).slice(2, 8), name, last: Date.now() };
      user.devices.unshift(found);
    } else {
      found.last = Date.now();
    }
    user.devices = user.devices.slice(0, 8);
    return found.id;
  }

  function applyLang() {
    const en = lang() === "en";
    document.documentElement.lang = en ? "en" : "zh-CN";
    document.querySelectorAll("[data-zh]").forEach((el) => {
      const val = el.getAttribute(en ? "data-en" : "data-zh");
      if (val != null) el.textContent = val;
    });
    document.querySelectorAll("[data-placeholder-zh]").forEach((el) => {
      el.placeholder = el.getAttribute(en ? "data-placeholder-en" : "data-placeholder-zh") || "";
    });
    const title = document.body.getAttribute(en ? "data-title-en" : "data-title-zh");
    if (title) document.title = title;
    const current = document.getElementById("lang-current");
    if (current) current.textContent = en ? "English" : "简体中文";
    document.querySelectorAll("[data-lang]").forEach((btn) => {
      btn.classList.toggle("is-active", btn.dataset.lang === lang());
    });
  }

  function navLink(id, href, zh, en) {
    const active = page() === id ? " is-active" : "";
    const current = page() === id ? ' aria-current="page"' : "";
    return `<a class="nav-link${active}" href="${href}"${current}><span data-zh="${zh}" data-en="${en}">${zh}</span></a>`;
  }

  function renderHeader() {
    const root = document.getElementById("site-header");
    if (!root) return;
    const user = currentUser();
    const showPromo = page() === "home" && sessionStorage.getItem(PROMO_KEY) !== "off";
    const account = user
      ? `<a class="login-pill" href="account.html">${esc(user.name)}</a>`
      : `<a class="login-pill" href="login.html"><span data-zh="登录账户" data-en="Sign in">登录账户</span></a>`;
    root.innerHTML = `
      <a class="skip" href="#main" data-zh="跳到内容" data-en="Skip to content">跳到内容</a>
      <header class="header${page() !== "home" ? " is-solid" : ""}">
        ${showPromo ? `<div class="topbar"><span class="hide-sm" data-zh="讯连宝 支持 macOS、Windows、iOS、Android 与 Linux" data-en="讯连宝 runs on macOS, Windows, iOS, Android, and Linux">讯连宝 支持 macOS、Windows、iOS、Android 与 Linux</span><span class="show-sm" data-zh="电脑和手机都能用" data-en="Phone and desktop">电脑和手机都能用</span><button type="button" data-action="dismiss-promo" aria-label="close">×</button></div>` : ""}
        <div class="header-inner">
          <a class="brand" href="index.html">${logo()} 讯连宝 <small>VPN</small></a>
          <button class="menu-toggle" type="button" data-action="toggle-menu" aria-label="menu">
            <svg width="22" height="22" viewBox="0 0 22 22" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M3 6h16M3 11h16M3 16h16"/></svg>
          </button>
          <div class="nav-panel">
            <nav class="nav">
              ${navLink("home", "index.html", "主页", "Home")}
              ${navLink("blog", "blog.html", "博客", "Blog")}
              ${navLink("help", "help.html", "帮助中心", "Help")}
              ${navLink("download", "download.html", "下载", "Download")}
            </nav>
            <div class="header-actions">
              <div class="pop lang">
                <button class="lang-btn" type="button" id="lang-current" data-action="toggle-lang" aria-expanded="false">简体中文</button>
                <div class="pop-menu" id="lang-menu" hidden>
                  <button type="button" data-action="lang" data-lang="zh">简体中文</button>
                  <button type="button" data-action="lang" data-lang="en">English</button>
                </div>
              </div>
              ${account}
            </div>
          </div>
        </div>
      </header>`;
  }

  function renderFooter() {
    const root = document.getElementById("site-footer");
    if (!root) return;
    const cols = [
      ["软件下载", "Download", [
        ["download.html?os=windows", "Windows", "Windows"],
        ["download.html?os=android", "Android", "Android"],
        ["download.html?os=ios", "iOS", "iOS"],
        ["download.html?os=mac", "macOS", "Mac"]
      ]],
      ["相关资源", "Resources", [
        ["blog.html", "博客", "Blog"],
        ["help.html", "帮助中心", "Help center"],
        ["index.html#pricing", "会员方案", "Plans"]
      ]],
      ["用户协议", "Policies", [
        ["legal.html?doc=privacy", "隐私权政策", "Privacy"],
        ["legal.html?doc=terms", "服务条款", "Terms"],
        ["legal.html?doc=agreement", "注册协议", "Registration"]
      ]]
    ];
    root.innerHTML = `
      <footer class="footer">
        <div class="wrap footer-grid">
          <div>
            <a class="brand" href="index.html">${logo()} 讯连宝 <small>VPN</small></a>
            <p data-zh="一点连接，稳稳在线。到期即停，不会自动续费。" data-en="Tap once, stay online. Plans end when they end.">一点连接，稳稳在线。到期即停，不会自动续费。</p>
          </div>
          ${cols.map(([zh, en, links]) => `
            <div>
              <h3 data-zh="${zh}" data-en="${en}">${zh}</h3>
              ${links.map(([href, lzh, len]) => `<a href="${href}"><span data-zh="${lzh}" data-en="${len}">${lzh}</span></a>`).join("")}
            </div>`).join("")}
          <div>
            <h3 data-zh="更换语言" data-en="Language">更换语言</h3>
            <div class="lang-switch">
              <button type="button" data-action="lang" data-lang="zh">简体中文</button>
              <button type="button" data-action="lang" data-lang="en">English</button>
            </div>
          </div>
        </div>
        <div class="wrap fine">
          <span>© 2026 讯连宝</span>
          <span data-zh="本站为产品界面演示，开通与下载不会产生真实扣款或安装包。" data-en="This site is a product demo. Plans and downloads do not charge you or ship an installer.">本站为产品界面演示，开通与下载不会产生真实扣款或安装包。</span>
        </div>
      </footer>`;
  }

  function closePopovers() {
    document.querySelectorAll(".pop-menu").forEach((m) => m.setAttribute("hidden", ""));
    document.querySelectorAll("[aria-expanded]").forEach((b) => b.setAttribute("aria-expanded", "false"));
  }

  function syncHeader() {
    const header = document.querySelector(".header");
    if (!header) return;
    document.documentElement.style.setProperty("--header-h", header.offsetHeight + "px");
    if (page() === "home") header.classList.toggle("is-solid", window.scrollY > 8);
  }

  let helpQuery = "";
  let helpCat = "all";
  let blogTag = "all";
  let chatReady = false;
  let orbTimer = 0;

  function perks() {
    return lang() === "en"
      ? ["Up to 5 devices online", "No auto-renewal", "Stops when the term ends"]
      : ["最多 5 台同时在线", "不会自动续费", "到期即停止"];
  }

  function renderPlans() {
    const root = document.getElementById("plan-grid");
    if (!root || !window.XVAY) return;
    root.innerHTML = window.XVAY.plans.map((plan) => `
      <article class="plan${plan.featured ? " featured" : ""}">
        ${plan.featured ? `<span class="ribbon">${esc(tx("更多人选择", "Popular"))}</span>` : ""}
        <div class="name">${esc(field(plan, "name"))}</div>
        <div class="price">${esc(lang() === "en" ? plan.priceEn : plan.priceZh)}</div>
        <div class="note">${esc(field(plan, "note"))}</div>
        <ul>${perks().map((item) => `<li><span class="dot"></span>${esc(item)}</li>`).join("")}</ul>
        <button class="btn ${plan.featured ? "btn-primary" : "btn-line"}" type="button" data-action="choose-plan" data-plan="${plan.id}">${esc(tx("选择这个时长", "Choose this term"))}</button>
      </article>`).join("");
  }

  function renderReviews() {
    const root = document.getElementById("review-marquee");
    if (!root || !window.XVAY) return;
    const cards = window.XVAY.reviews.map((r) => `
      <article class="review">
        <div class="stars" aria-label="5">★★★★★</div>
        <p>${esc(lang() === "en" ? r.en : r.zh)}</p>
        <div class="who"><b>${esc(r.name)}</b><span>${esc(r.date)}</span></div>
      </article>`).join("");
    root.innerHTML = `<div class="marquee-track">${cards}${cards}</div>`;
  }

  function setupPrimaryDownload() {
    const btn = document.getElementById("primary-download");
    if (!btn) return;
    const os = detectOS();
    btn.dataset.platform = os;
    const name = OS[os];
    const label = btn.querySelector(".btn-label");
    label.setAttribute("data-zh", `下载 ${name.zh} 版`);
    label.setAttribute("data-en", `Download for ${name.en}`);
    label.textContent = lang() === "en" ? label.getAttribute("data-en") : label.getAttribute("data-zh");
    const iconHost = btn.querySelector(".btn-icon");
    if (iconHost) iconHost.innerHTML = icon("download");
  }

  function startOrb() {
    const orb = document.getElementById("connect-orb");
    const caption = document.getElementById("orb-caption");
    if (!orb || orbTimer) return;
    const frames = [
      { zh: "连接", en: "Go", on: false },
      { zh: "2", en: "2", on: false },
      { zh: "1", en: "1", on: false },
      { zh: "完成", en: "On", on: true }
    ];
    let i = 0;
    const tick = () => {
      const frame = frames[i % frames.length];
      orb.textContent = lang() === "en" ? frame.en : frame.zh;
      orb.classList.toggle("is-on", frame.on);
      if (caption) caption.textContent = frame.on ? tx("已接通", "Connected") : tx("点击连接", "Tap to connect");
      i += 1;
    };
    tick();
    orbTimer = window.setInterval(tick, 900);
  }

  function renderBlog() {
    const list = document.getElementById("blog-list");
    const filters = document.getElementById("blog-filters");
    if (!list || !window.XVAY) return;
    const id = new URLSearchParams(location.search).get("id");
    if (id) {
      const post = window.XVAY.posts.find((p) => p.id === id);
      const article = document.getElementById("blog-article");
      list.hidden = true;
      if (filters) filters.hidden = true;
      if (!article) return;
      article.hidden = false;
      if (!post) {
        article.innerHTML = `<p class="empty">${esc(tx("没有这篇文章。", "That article is missing."))}</p>`;
        return;
      }
      article.innerHTML = `
        <a class="back" href="blog.html">${esc(tx("返回博客", "Back to blog"))}</a>
        <div class="tag">${esc(field(post, "tag"))}</div>
        <h1>${esc(field(post, "title"))}</h1>
        <p class="date">${esc(post.date)}</p>
        <div class="prose" style="margin-top:18px">${(field(post, "body") || []).map((p) => `<p>${esc(p)}</p>`).join("")}</div>`;
      return;
    }
    const article = document.getElementById("blog-article");
    if (article) article.hidden = true;
    list.hidden = false;
    if (filters) filters.hidden = false;
    const tags = [{ id: "all", label: tx("全部", "All") }].concat(
      [...new Set(window.XVAY.posts.map((p) => p.tagZh))].map((id) => {
        const sample = window.XVAY.posts.find((p) => p.tagZh === id);
        return { id, label: field(sample, "tag") };
      })
    );
    if (filters) {
      filters.innerHTML = tags.map((tag) => `
        <button type="button" class="chip-btn${blogTag === tag.id ? " is-on" : ""}" data-action="blog-tag" data-tag="${esc(tag.id)}">${esc(tag.label)}</button>`).join("");
    }
    const posts = window.XVAY.posts.filter((p) => blogTag === "all" || p.tagZh === blogTag);
    list.innerHTML = posts.map((p, index) => `
      <a class="post" href="blog.html?id=${encodeURIComponent(p.id)}" style="${index === 0 ? "grid-row: span 2" : ""}">
        <div class="tag">${esc(field(p, "tag"))}</div>
        <h2>${esc(field(p, "title"))}</h2>
        <p>${esc(field(p, "excerpt"))}</p>
        <p class="date" style="margin-top:14px">${esc(p.date)}</p>
      </a>`).join("");
  }

  function renderHelp() {
    const cats = document.getElementById("help-cats");
    const list = document.getElementById("help-list");
    if (!list || !window.XVAY) return;
    const all = [{ id: "all", zh: "全部问题", en: "All" }].concat(window.XVAY.categories);
    if (cats) {
      cats.innerHTML = all.map((c) => `
        <button type="button" class="${helpCat === c.id ? "is-on" : ""}" data-action="help-cat" data-cat="${c.id}">${esc(lang() === "en" ? c.en : c.zh)}</button>`).join("");
    }
    const q = helpQuery.trim().toLowerCase();
    const items = window.XVAY.faqs.filter((f) => {
      const hitCat = helpCat === "all" || f.cat === helpCat;
      const blob = (f.qZh + f.qEn + f.aZh + f.aEn).toLowerCase();
      return hitCat && (!q || blob.includes(q));
    });
    list.innerHTML = items.length
      ? items.map((f) => `<details class="acc"><summary>${esc(field(f, "q"))}</summary><p>${esc(field(f, "a"))}</p></details>`).join("")
      : `<div class="empty">${esc(tx("没有匹配的问题。换个词，或在下面留言。", "No matching questions. Try another word, or leave a note below."))}</div>`;
    renderTickets();
  }

  function renderTickets() {
    const root = document.getElementById("ticket-list");
    if (!root) return;
    const items = JSON.parse(localStorage.getItem(TICKET_KEY) || "[]");
    if (!items.length) {
      root.innerHTML = "";
      return;
    }
    root.innerHTML = `<h3 style="margin:18px 0 8px">${esc(tx("本机留言", "Notes on this device"))}</h3>` +
      items.map((t) => `<div class="ticket"><b>${esc(t.email)}</b> · ${esc(t.topic)}<br>${esc(t.message)}</div>`).join("");
  }

  function renderLegal() {
    const nav = document.getElementById("legal-nav");
    const article = document.getElementById("legal-article");
    if (!article || !window.XVAY) return;
    const docs = [
      ["privacy", "隐私权政策", "Privacy"],
      ["terms", "服务条款", "Terms"],
      ["agreement", "注册协议", "Registration"]
    ];
    let doc = new URLSearchParams(location.search).get("doc") || "privacy";
    if (!window.XVAY.legal[doc]) doc = "privacy";
    if (nav) {
      nav.innerHTML = docs.map(([id, zh, en]) => `<a class="${id === doc ? "is-on" : ""}" href="legal.html?doc=${id}"><span data-zh="${zh}" data-en="${en}">${lang() === "en" ? en : zh}</span></a>`).join("");
    }
    const data = window.XVAY.legal[doc];
    article.innerHTML = `
      <p class="date">${esc(tx("更新于 ", "Updated "))} ${esc(data.updated)}</p>
      <h1 style="margin:8px 0 12px">${esc(field(data, "title"))}</h1>
      ${data.sections.map((s) => `<h2>${esc(field(s, "h"))}</h2>${(lang() === "en" ? s.pEn : s.pZh).map((p) => `<p>${esc(p)}</p>`).join("")}`).join("")}`;
  }

  function formatRemain(ms) {
    if (ms <= 0) return tx("已结束", "Ended");
    const h = Math.floor(ms / 3600000);
    const m = Math.floor((ms % 3600000) / 60000);
    return lang() === "en" ? `${h}h ${m}m left` : `剩余 ${h} 小时 ${m} 分`;
  }

  function membership(user) {
    const now = Date.now();
    if (user.plan && user.planExpire > now) {
      const plan = window.XVAY.plans.find((p) => p.id === user.plan);
      return { kind: "plan", label: plan ? field(plan, "name") : user.plan, remain: formatRemain(user.planExpire - now), until: new Date(user.planExpire) };
    }
    if (user.trialStart && user.trialStart + 72 * 3600000 > now) {
      return { kind: "trial", label: tx("72 小时试用", "72-hour trial"), remain: formatRemain(user.trialStart + 72 * 3600000 - now), until: new Date(user.trialStart + 72 * 3600000) };
    }
    return { kind: "none", label: tx("未开通", "No active plan"), remain: tx("可以领取试用，或选择一个时长", "Start a trial, or pick a term"), until: null };
  }

  function renderAccount() {
    const root = document.getElementById("account-root");
    if (!root) return;
    const user = currentUser();
    if (!user) {
      location.href = "login.html?next=" + encodeURIComponent("account.html" + location.search);
      return;
    }
    const params = new URLSearchParams(location.search);
    const pending = params.get("plan");
    const plan = window.XVAY.plans.find((p) => p.id === pending);
    const state = membership(user);
    const when = (ts) => new Date(ts).toLocaleString(lang() === "en" ? "en" : "zh-CN", { hour12: false });
    root.innerHTML = `
      <div class="account-grid">
        <section class="card">
          <div class="kicker">${esc(tx("当前状态", "Status"))}</div>
          <h2>${esc(user.name)}</h2>
          <p class="fine-note">${esc(user.email)}</p>
          <div class="stat-line"><span>${esc(tx("方案", "Plan"))}</span><b>${esc(state.label)}</b></div>
          <div class="stat-line"><span>${esc(tx("时间", "Time"))}</span><b>${esc(state.remain)}</b></div>
          ${state.until ? `<div class="stat-line"><span>${esc(tx("到期", "Ends"))}</span><span>${esc(state.until.toLocaleString(lang() === "en" ? "en" : "zh-CN", { hour12: false }))}</span></div>` : ""}
          <div style="display:flex;gap:8px;flex-wrap:wrap;margin-top:16px">
            ${state.kind === "none" ? `<button class="btn btn-primary" type="button" data-action="start-trial">${esc(tx("领取 72 小时试用", "Start 72-hour trial"))}</button>` : ""}
            <a class="btn btn-line" href="index.html#pricing">${esc(tx("查看时长", "See terms"))}</a>
            <button class="btn btn-line" type="button" data-action="logout">${esc(tx("退出登录", "Sign out"))}</button>
          </div>
          ${plan ? `<div class="ticket" style="margin-top:16px"><b>${esc(tx("确认开通", "Confirm"))} ${esc(field(plan, "name"))}</b><p>${esc(tx("这是演示，不会扣款。确认后只在这台浏览器里记录到期时间。", "This is a demo and will not charge you. Confirming only saves the expiry in this browser."))}</p><button class="btn btn-primary" type="button" data-action="confirm-plan" data-plan="${plan.id}">${esc(tx("确认开通", "Confirm plan"))}</button></div>` : ""}
          <h3 style="margin-top:22px">${esc(tx("订单", "Orders"))}</h3>
          ${(user.orders || []).length ? (user.orders || []).map((o) => `<div class="stat-line"><span>${esc(o.id)}</span><span>${esc(o.name)} · ${esc(when(o.at))}</span></div>`).join("") : `<p class="fine-note">${esc(tx("还没有订单。", "No orders yet."))}</p>`}
        </section>
        <section class="card">
          <h2>${esc(tx("设备", "Devices"))}</h2>
          <p class="fine-note">${esc(tx("最多 5 台同时在线。", "Up to 5 online at once."))}</p>
          ${(user.devices || []).map((d) => `
            <div class="device">
              <div><b>${esc(d.name)}</b><div class="fine-note">${esc(when(d.last))}</div></div>
              <button class="btn btn-line" type="button" data-action="remove-device" data-id="${esc(d.id)}">${esc(tx("移除", "Remove"))}</button>
            </div>`).join("")}
          <button class="btn btn-line" style="margin-top:16px" type="button" data-action="delete-account">${esc(tx("删除本机账户", "Delete local account"))}</button>
        </section>
      </div>`;
    if (params.get("trial") === "1" && !user.trialStart && !(user.planExpire > Date.now())) startTrial(false);
  }

  function startTrial(manual) {
    const user = currentUser();
    if (!user) {
      location.href = "login.html?mode=register&next=" + encodeURIComponent("account.html?trial=1");
      return;
    }
    if (!user.trialStart) user.trialStart = Date.now();
    writeUser(user);
    toast(tx("试用已开始，72 小时后结束。", "Trial started. It ends in 72 hours."));
    if (manual || page() === "account") renderAccount();
  }

  function confirmPlan(id) {
    const user = currentUser();
    const plan = window.XVAY.plans.find((p) => p.id === id);
    if (!user || !plan) return;
    const start = Math.max(Date.now(), user.planExpire || 0);
    user.plan = plan.id;
    user.planExpire = start + plan.days * 86400000;
    user.orders = user.orders || [];
    user.orders.unshift({ id: "XV" + Date.now().toString(36).toUpperCase(), name: field(plan, "name"), at: Date.now() });
    writeUser(user);
    history.replaceState({}, "", "account.html");
    toast(tx("已开通，这是演示订单。", "Plan saved. This order is a demo."));
    renderAccount();
  }

  let didScrollDownload = false;
  function highlightDownload() {
    const param = new URLSearchParams(location.search).get("os");
    const wanted = param || detectOS();
    document.querySelectorAll("[data-os]").forEach((card) => {
      const on = card.dataset.os === wanted;
      card.classList.toggle("is-current", on);
      const badge = card.querySelector(".current-os");
      if (badge) badge.hidden = !on;
    });
    const current = document.querySelector(`[data-os="${wanted}"]`);
    if (current && param && !didScrollDownload) {
      didScrollDownload = true;
      current.scrollIntoView({ block: "center" });
    }
    const link = document.getElementById("share-link");
    if (link) link.textContent = location.origin + location.pathname;
  }

  function downloadPlatform(id) {
    const spec = OS[id] || OS.mac;
    const text = [
      "讯连宝 VPN",
      `platform: ${spec.en}`,
      `version: 1.4.2`,
      "",
      lang() === "en"
        ? "This file is a demo note from the website. It is not the installable app."
        : "这是官网演示生成的说明文件，不是可安装的客户端。",
      ""
    ].join("\n");
    const blob = new Blob([text], { type: "text/plain;charset=utf-8" });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = spec.file;
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(a.href);
    toast(tx(`已下载 ${spec.file}`, `Downloaded ${spec.file}`));
  }

  function replyTo(text) {
    const hit = (window.XVAY.chat || []).find((item) => item.keys.some((key) => text.toLowerCase().includes(key.toLowerCase())));
    if (hit) return lang() === "en" ? hit.en : hit.zh;
    return tx("我可以回答试用、会员、设备、下载和连接。也可以去帮助中心搜索。", "I can help with the trial, plans, devices, downloads, and connection. You can also search the help center.");
  }

  function pushMsg(text, who) {
    const box = document.getElementById("chat-log");
    if (!box) return;
    const div = document.createElement("div");
    div.className = "bubble " + who;
    div.textContent = text;
    box.appendChild(div);
    box.scrollTop = box.scrollHeight;
  }

  function renderChat() {
    if (document.getElementById("chat-panel")) return;
    const root = document.createElement("div");
    root.innerHTML = `
      <section class="chat-panel" id="chat-panel">
        <div class="chat-hd"><strong>讯连宝</strong><button type="button" data-action="toggle-chat" aria-label="close">×</button></div>
        <div class="chat-log" id="chat-log"></div>
        <div class="chat-suggestions" id="chat-suggestions"></div>
        <form class="chat-form" id="chat-form">
          <input id="chat-input" data-placeholder-zh="问点什么" data-placeholder-en="Ask something" placeholder="问点什么" />
          <button class="btn btn-primary" type="submit" data-zh="发送" data-en="Send">发送</button>
        </form>
      </section>
      <button class="chat-fab" type="button" data-action="toggle-chat" aria-label="chat">${icon("chat")}</button>`;
    document.body.appendChild(root);
    document.getElementById("chat-form").addEventListener("submit", (e) => {
      e.preventDefault();
      const input = document.getElementById("chat-input");
      const text = input.value.trim();
      if (!text) return;
      pushMsg(text, "me");
      input.value = "";
      pushMsg(replyTo(text), "bot");
    });
  }

  function renderSuggestions() {
    const root = document.getElementById("chat-suggestions");
    if (!root) return;
    const items = lang() === "en" ? ["Trial", "Plans", "Devices"] : ["试用多久", "会员价格", "几台设备"];
    root.innerHTML = items.map((item) => `<button type="button" data-action="suggest" data-text="${esc(item)}">${esc(item)}</button>`).join("");
  }

  function openChat() {
    const panel = document.getElementById("chat-panel");
    panel.classList.toggle("is-open");
    if (panel.classList.contains("is-open") && !chatReady) {
      chatReady = true;
      pushMsg(tx("你好，我是迅连助手。可以问试用、会员、设备或连接。", "Hi. Ask me about the trial, plans, devices, or connecting."), "bot");
    }
  }

  function setLang(next) {
    if (next === "en") sessionStorage.setItem(LANG_KEY, "en");
    else sessionStorage.removeItem(LANG_KEY);
    localStorage.removeItem("xvay-lang");
    applyLang();
    refresh();
  }

  function refresh() {
    if (page() === "home") {
      renderPlans();
      renderReviews();
      setupPrimaryDownload();
    }
    if (page() === "blog") renderBlog();
    if (page() === "help") renderHelp();
    if (page() === "legal") renderLegal();
    if (page() === "account") renderAccount();
    if (page() === "download") highlightDownload();
    renderSuggestions();
    applyLang();
  }

  function safeNext(value) {
    if (!value) return "account.html";
    try { value = decodeURIComponent(value); } catch { /* keep raw */ }
    if (/^(index|download|blog|help|account|legal|login)\.html([?#].*)?$/.test(value)) return value;
    return "account.html";
  }

  function bindForms() {
    const login = document.getElementById("form-login");
    const reg = document.getElementById("form-register");
    const contact = document.getElementById("form-contact");
    if (login && !login.dataset.bound) {
      login.dataset.bound = "1";
      login.addEventListener("submit", (e) => {
        e.preventDefault();
        const email = login.email.value.trim().toLowerCase();
        const password = login.password.value;
        const alert = document.getElementById("login-alert");
        const user = users().find((u) => u.email === email && u.password === hash(password));
        if (!user) {
          alert.hidden = false;
          alert.textContent = tx("邮箱或密码不对。", "That email or password doesn't match.");
          return;
        }
        const id = rememberDevice(user);
        user.currentDevice = id;
        writeUser(user);
        localStorage.setItem(SESSION_KEY, user.email);
        location.href = safeNext(new URLSearchParams(location.search).get("next"));
      });
    }
    if (reg && !reg.dataset.bound) {
      reg.dataset.bound = "1";
      reg.addEventListener("submit", (e) => {
        e.preventDefault();
        const alert = document.getElementById("reg-alert");
        const name = reg.name.value.trim();
        const email = reg.email.value.trim().toLowerCase();
        const password = reg.password.value;
        const show = (msg) => { alert.hidden = false; alert.textContent = msg; };
        if (name.length < 2) return show(tx("名字至少 2 个字。", "Use at least 2 characters in the name."));
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return show(tx("邮箱格式不对。", "That email doesn't look right."));
        if (password.length < 6) return show(tx("密码至少 6 位。", "Use at least 6 characters."));
        if (password !== reg.confirm.value) return show(tx("两次密码不一致。", "The passwords don't match."));
        if (!reg.agree.checked) return show(tx("请先勾选注册协议。", "Please accept the registration agreement."));
        if (users().some((u) => u.email === email)) return show(tx("这个邮箱已经注册过。", "That email is already registered."));
        const user = { name, email, password: hash(password), createdAt: Date.now(), trialStart: Date.now(), devices: [], orders: [] };
        rememberDevice(user);
        writeUser(user);
        localStorage.setItem(SESSION_KEY, email);
        toast(tx("账户已就绪，试用开始了。", "Account ready. The trial has started."));
        location.href = safeNext(new URLSearchParams(location.search).get("next"));
      });
    }
    if (contact && !contact.dataset.bound) {
      contact.dataset.bound = "1";
      contact.addEventListener("submit", (e) => {
        e.preventDefault();
        const email = contact.email.value.trim();
        const message = contact.message.value.trim();
        const alert = document.getElementById("contact-alert");
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || message.length < 4) {
          alert.hidden = false;
          alert.textContent = tx("请填写有效邮箱，并写至少几个字。", "Add a valid email and a short message.");
          return;
        }
        const items = JSON.parse(localStorage.getItem(TICKET_KEY) || "[]");
        items.unshift({ email, topic: contact.topic.selectedOptions[0]?.textContent || contact.topic.value, message, at: Date.now() });
        localStorage.setItem(TICKET_KEY, JSON.stringify(items.slice(0, 8)));
        contact.reset();
        alert.hidden = false;
        alert.style.background = "#ecfdf3";
        alert.style.color = "#166534";
        alert.textContent = tx("已留在这台浏览器里。演示环境不会真的发给客服。", "Saved in this browser. The demo does not send it to an agent.");
        renderTickets();
      });
    }
  }

  function showAuth(tab) {
    const login = document.getElementById("panel-login");
    const register = document.getElementById("panel-register");
    if (!login || !register) return;
    login.hidden = tab !== "login";
    register.hidden = tab !== "register";
    document.querySelectorAll("[data-tab]").forEach((btn) => btn.classList.toggle("is-active", btn.dataset.tab === tab));
  }

  document.addEventListener("click", (e) => {
    const el = e.target.closest("[data-action]");
    if (!el) {
      if (!e.target.closest(".pop")) closePopovers();
      return;
    }
    const action = el.dataset.action;
    if (action === "toggle-lang" || action === "toggle-platforms") {
      const menu = el.parentElement.querySelector(".pop-menu");
      const willOpen = menu.hasAttribute("hidden");
      closePopovers();
      if (willOpen) {
        menu.removeAttribute("hidden");
        el.setAttribute("aria-expanded", "true");
      }
      return;
    }
    if (action === "lang") {
      setLang(el.dataset.lang);
      closePopovers();
      return;
    }
    if (action === "dismiss-promo") {
      sessionStorage.setItem(PROMO_KEY, "off");
      renderHeader();
      applyLang();
      syncHeader();
      return;
    }
    if (action === "toggle-menu") {
      document.querySelector(".header").classList.toggle("nav-open");
      return;
    }
    if (action === "toggle-password") {
      const input = document.getElementById(el.dataset.target);
      input.type = input.type === "password" ? "text" : "password";
      el.textContent = input.type === "password" ? tx("显示", "Show") : tx("隐藏", "Hide");
      return;
    }
    if (action === "auth-tab") {
      showAuth(el.dataset.tab);
      return;
    }
    if (action === "choose-plan") {
      const next = "account.html?plan=" + el.dataset.plan;
      location.href = currentUser() ? next : "login.html?next=" + encodeURIComponent(next);
      return;
    }
    if (action === "start-trial") { startTrial(true); return; }
    if (action === "confirm-plan") { confirmPlan(el.dataset.plan); return; }
    if (action === "logout") {
      localStorage.removeItem(SESSION_KEY);
      location.href = "index.html";
      return;
    }
    if (action === "delete-account") {
      const ok = window.confirm(tx("删除后，这个浏览器里的账户、试用和订单都会消失。", "This removes the account, trial, and orders stored in this browser."));
      if (!ok) return;
      const email = sessionEmail();
      saveUsers(users().filter((u) => u.email !== email));
      localStorage.removeItem(SESSION_KEY);
      toast(tx("本机账户已删除。", "Local account deleted."));
      location.href = "index.html";
      return;
    }
    if (action === "remove-device") {
      const user = currentUser();
      user.devices = (user.devices || []).filter((d) => d.id !== el.dataset.id);
      writeUser(user);
      renderAccount();
      return;
    }
    if (action === "download") {
      downloadPlatform(el.dataset.platform || detectOS());
      return;
    }
    if (action === "copy-link") {
      const text = document.getElementById("share-link")?.textContent || location.href;
      navigator.clipboard?.writeText(text).then(() => toast(tx("链接已复制。", "Link copied."))).catch(() => toast(text));
      return;
    }
    if (action === "blog-tag") {
      blogTag = el.dataset.tag;
      renderBlog();
      return;
    }
    if (action === "help-cat") {
      helpCat = el.dataset.cat;
      renderHelp();
      return;
    }
    if (action === "toggle-chat") { openChat(); return; }
    if (action === "suggest") {
      const input = document.getElementById("chat-input");
      input.value = el.dataset.text;
      input.focus();
      return;
    }
  });

  window.addEventListener("scroll", syncHeader, { passive: true });
  window.addEventListener("resize", syncHeader);

  function boot() {
    renderHeader();
    renderFooter();
    renderChat();
    applyLang();
    bindForms();
    if (page() === "login") showAuth(new URLSearchParams(location.search).get("mode") === "register" ? "register" : "login");
    refresh();
    if (page() === "home") startOrb();
    syncHeader();
    const search = document.getElementById("help-search");
    if (search) search.addEventListener("input", () => { helpQuery = search.value; renderHelp(); });
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", boot);
  else boot();
})();
