// Runs on Gmail and Drive pages. Reads which account this tab is signed in as
// (the account button at the top right) and the /u/N/ index from the URL, and
// reports the pair to background.js so it is remembered.

(() => {
  function indexFromUrl() {
    const m = location.pathname.match(/\/u\/(\d+)(\/|$)/);
    if (m) return Number(m[1]);
    const authuser = new URLSearchParams(location.search).get("authuser");
    if (authuser !== null) return /^\d+$/.test(authuser) ? Number(authuser) : null;
    return 0; // no /u/N/ in the URL means the default (first) account
  }

  function readAccount() {
    // The avatar button links to the sign-out options page; its aria-label reads
    // "Google Account: <Name>  (<email>)" in English, similar in other languages.
    const btn = document.querySelector('a[href*="accounts.google.com/SignOutOptions"][aria-label]');
    const label = btn?.getAttribute("aria-label") || "";
    let email = (label.match(/[\w.+-]+@[\w-]+(\.[\w-]+)+/) || [])[0];
    let name = "";
    if (email) {
      name = label.slice(label.indexOf(":") + 1, label.indexOf(email)).replace(/[()\s]+$/, "").trim();
    } else {
      // Gmail fallback: "Inbox (3) - someone@gmail.com - Gmail"
      email = (document.title.match(/[\w.+-]+@[\w-]+(\.[\w-]+)+/) || [])[0];
    }
    return email ? { email: email.toLowerCase(), name } : null;
  }

  let lastSent = "";
  function report() {
    const index = indexFromUrl();
    const acc = readAccount();
    if (index === null || !acc) return false;
    const key = `${index}|${acc.email}|${acc.name}`;
    if (key !== lastSent) {
      lastSent = key;
      chrome.runtime.sendMessage({ type: "account-seen", index, ...acc }).catch(() => {});
    }
    return true;
  }

  // The header renders after the page loads; try for a while, then on URL changes.
  let tries = 0;
  const timer = setInterval(() => {
    if (report() || ++tries > 60) clearInterval(timer);
  }, 1000);
  let lastUrl = location.href;
  setInterval(() => {
    if (location.href !== lastUrl) {
      lastUrl = location.href;
      report();
    }
  }, 3000);
})();
