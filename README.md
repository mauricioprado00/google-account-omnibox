# google-account-omnibox

Type `gmail` + Tab or `drive` + Tab in Chrome's address bar to pick any signed-in Google account,
and go to `https://mail.google.com/mail/u/N/` or `https://drive.google.com/drive/u/N/my-drive`.

- `./build.sh` builds `dist/gmail/` and `dist/drive/` (one extension per keyword: Chrome allows one keyword each).
- Load each in `chrome://extensions` → Developer mode → Load unpacked. After a rebuild, press the reload icon on each card.
- Accounts come from `accounts.google.com/ListAccounts` (what Chrome itself uses), fetched each time the keyword is entered;
  as a fallback, every Gmail/Drive page you open reports its `/u/N/` index and email (from the account button).
- Filter by name, email or index number; Enter opens the first match; Alt+Enter opens in a new tab.
