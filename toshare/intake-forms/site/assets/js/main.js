/* eslint-disable no-undef */
// Stable interactions — modals, write-ins, pricing logic (no email field filtering)

const getFocusable = (container) => {
  const selector = [
    'a[href]', 'button:not([disabled])', 'input:not([disabled])',
    'select:not([disabled])', 'textarea:not([disabled])',
    '[tabindex]:not([tabindex="-1"])', '[contenteditable="true"]',
  ].join(',');
  return Array.from(container.querySelectorAll(selector)).filter(
    (el) => el.offsetParent !== null || el === document.activeElement,
  );
};

// Select → write-in (used in project-client role, etc.)
const toggleOther = (selectId, wrapId, inputId) => {
  const selectEl = document.getElementById(selectId);
  const wrapEl = document.getElementById(wrapId);
  const inputEl = document.getElementById(inputId);
  if (!selectEl || !wrapEl || !inputEl) return;
  const apply = () => {
    if (selectEl.value === 'Other (write-in)') {
      wrapEl.classList.remove('hidden');
      inputEl.required = true; inputEl.disabled = false;
    } else {
      wrapEl.classList.add('hidden');
      inputEl.required = false; inputEl.value = ''; inputEl.disabled = true;
    }
  };
  selectEl.addEventListener('change', apply);
  apply();
};

// Radios → write-in (project_type, client_role_radio, team_role_radio)
const toggleOtherRadio = (name, otherValue, wrapId, inputId) => {
  const radios = document.querySelectorAll(`input[type="radio"][name="${name}"]`);
  const wrapEl = document.getElementById(wrapId);
  const inputEl = document.getElementById(inputId);
  if (!radios.length || !wrapEl || !inputEl) return;
  const current = () => document.querySelector(`input[name="${name}"]:checked`);
  const apply = () => {
    const val = current()?.value;
    if (val === otherValue) {
      wrapEl.classList.remove('hidden');
      inputEl.required = true; inputEl.disabled = false; inputEl.focus();
    } else {
      wrapEl.classList.add('hidden');
      inputEl.required = false; inputEl.value = ''; inputEl.disabled = true;
    }
  };
  radios.forEach((r) => r.addEventListener('change', apply));
  apply();
};

// Project: primary client contact checkbox
const projectContactToggle = () => {
  const checkbox = document.getElementById('project-client-new');
  const details = document.getElementById('project-client-details');
  const email = document.getElementById('project-client-email');
  const phone = document.getElementById('project-client-phone');
  const role = document.getElementById('project-client-role');
  const roleOtherWrap = document.getElementById('project-client-role-other-wrap');
  const roleOther = document.getElementById('project-client-role-other');
  if (!checkbox || !details || !email || !phone || !role) return;
  const apply = () => {
    if (checkbox.checked) {
      details.classList.remove('hidden');
      email.disabled = false; phone.disabled = false; role.disabled = false;
      email.required = true; phone.required = true; role.required = true;
    } else {
      details.classList.add('hidden');
      [email, phone, role].forEach((el) => { el.required = false; el.value = ''; el.disabled = true; });
      if (roleOther) { roleOther.required = false; roleOther.value = ''; roleOther.disabled = true; }
      if (roleOtherWrap) roleOtherWrap.classList.add('hidden');
    }
  };
  checkbox.addEventListener('change', apply);
  checkbox.checked = false; // default
  apply();
};

// Invoice pricing mode (project | ballpark | hours | flat)
const invoicePricingToggle = () => {
  const form = document.forms['invoice-request'];
  if (!form) return;
  const priceWrap = document.getElementById('invoice-price-wrap');
  const priceInput = document.getElementById('invoice-price');
  const priceReq = document.getElementById('invoice-price-req');
  const calcWrap = document.getElementById('invoice-calc-wrap');
  const hoursInput = document.getElementById('invoice-hours');
  const hoursReq = document.getElementById('invoice-hours-req');
  const expensesInput = document.getElementById('invoice-expenses');
  const expensesReq = document.getElementById('invoice-expenses-req');
  const radios = form.querySelectorAll('input[name="price_mode"]');
  if (!radios.length) return;

  const hideAll = () => {
    priceWrap.classList.add('hidden'); calcWrap.classList.add('hidden');
    if (priceInput) { priceInput.required = false; priceInput.value = ''; priceInput.disabled = true; }
    if (hoursInput) { hoursInput.required = false; hoursInput.disabled = true; hoursInput.value = ''; }
    if (expensesInput) { expensesInput.required = false; expensesInput.disabled = true; expensesInput.value = ''; }
    if (priceReq) priceReq.classList.add('hidden');
    if (hoursReq) hoursReq.classList.add('hidden');
    if (expensesReq) expensesReq.classList.add('hidden');
  };

  const apply = () => {
    const mode = form.querySelector('input[name="price_mode"]:checked')?.value;
    hideAll();
    switch (mode) {
      case 'flat':
        priceWrap.classList.remove('hidden');
        if (priceInput) { priceInput.disabled = false; priceInput.required = true; priceInput.focus(); }
        if (priceReq) priceReq.classList.remove('hidden');
        break;
      case 'hours':
        calcWrap.classList.remove('hidden');
        if (hoursInput) { hoursInput.disabled = false; hoursInput.required = true; }
        if (expensesInput) { expensesInput.disabled = false; expensesInput.required = true; }
        if (hoursReq) hoursReq.classList.remove('hidden');
        if (expensesReq) expensesReq.classList.remove('hidden');
        break;
      case 'project':
      case 'ballpark':
      default:
        break;
    }
  };

  radios.forEach((r) => r.addEventListener('change', apply));
  apply();
};

// Modal controller
const ModalCtl = (() => {
  let openModal = null; let lastFocus = null;
  const lockScroll = () => { document.documentElement.classList.add('noscroll'); document.body.classList.add('noscroll'); };
  const unlockScroll = () => { document.documentElement.classList.remove('noscroll'); document.body.classList.remove('noscroll'); };
  const show = (id) => { const m = document.getElementById(id); if (!m) return; lastFocus = document.activeElement; m.classList.add('open'); lockScroll(); openModal = m; const first = getFocusable(m)[0]; if (first) first.focus(); };
  const hide = () => { if (!openModal) return; openModal.classList.remove('open'); unlockScroll(); if (lastFocus) lastFocus.focus(); openModal = null; };
  const onBackdrop = (e) => { if (e.target.classList && e.target.classList.contains('modal')) hide(); }
  const onEsc = (e) => { if (e.key === 'Escape') hide(); };
  const trap = (e) => { if (!openModal || e.key !== 'Tab') return; const nodes = getFocusable(openModal); if (!nodes.length) return; const f = nodes[0]; const l = nodes[nodes.length - 1]; if (e.shiftKey && document.activeElement === f) { e.preventDefault(); l.focus(); } else if (!e.shiftKey && document.activeElement === l) { e.preventDefault(); f.focus(); } };
  const wire = () => {
    document.querySelectorAll('[data-open-modal]').forEach((btn) => {
      const id = btn.getAttribute('data-open-modal');
      btn.addEventListener('click', (ev) => { ev.preventDefault(); show(id); });
    });
    document.querySelectorAll('[data-close-modal]').forEach((btn) => {
      btn.addEventListener('click', (ev) => { ev.preventDefault(); hide(); });
    });
    document.querySelectorAll('.modal').forEach((m) => m.addEventListener('click', onBackdrop));
    document.addEventListener('keydown', onEsc); document.addEventListener('keydown', trap);
  };
  return { wire };
})();

// Init
window.addEventListener('DOMContentLoaded', () => {
  ModalCtl.wire();
  // Select-based write-ins still used in project-client role
  toggleOther('client-role', 'client-role-other-wrap', 'client-role-other');
  toggleOther('project-client-role', 'project-client-role-other-wrap', 'project-client-role-other');
  toggleOther('project-type', 'project-type-other-wrap', 'project-type-other');
  toggleOther('team-role', 'team-role-other-wrap', 'team-role-other');

  // Radio-based write-ins for new radio groups
  toggleOtherRadio('project_type', 'Other (write-in)', 'project-type-other-wrap', 'project-type-other');
  toggleOtherRadio('client_role_radio', 'Other (write-in)', 'client-role-other-wrap', 'client-role-other');
  toggleOtherRadio('team_role_radio', 'Other (write-in)', 'team-role-other-wrap', 'team-role-other');

  projectContactToggle();
  invoicePricingToggle();
});
