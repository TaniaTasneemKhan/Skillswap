// SkillSwap push notifications (Module 4).
// Deploy with: firebase deploy --only functions   (requires the Blaze plan)
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();
const db = getFirestore();

const STALE = [
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
];

/** Send a push to every device registered by [uid]; prune dead tokens. */
async function notify(uid, title, body, data = {}) {
  if (!uid) return;
  const snap = await db.collection('users').doc(uid).collection('tokens').get();
  const tokens = snap.docs.map((d) => d.id);
  if (!tokens.length) return;

  const res = await getMessaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data,
    android: { priority: 'high' },
  });

  const dead = [];
  res.responses.forEach((r, i) => {
    if (!r.success && STALE.includes(r.error && r.error.code)) dead.push(tokens[i]);
  });
  await Promise.all(dead.map((t) => db.collection('users').doc(uid).collection('tokens').doc(t).delete()));
}

// ---- exchange requests ----
exports.onRequestCreated = onDocumentCreated('requests/{id}', async (event) => {
  const r = event.data && event.data.data();
  if (!r) return;
  await notify(
    r.toId,
    'New swap request',
    `${r.fromName} wants to teach ${r.skillOffered} and learn ${r.skillWanted}`,
    { type: 'request', requestId: event.params.id },
  );
});

exports.onRequestUpdated = onDocumentUpdated('requests/{id}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (before.status !== 'pending' || before.status === after.status) return;
  if (after.status === 'accepted') {
    await notify(after.fromId, 'Request accepted',
      `${after.toName} accepted your swap request. Say hello!`,
      { type: 'request', requestId: event.params.id });
  } else if (after.status === 'rejected') {
    await notify(after.fromId, 'Request declined',
      `${after.toName} declined your swap request.`,
      { type: 'request', requestId: event.params.id });
  }
});

// ---- chat messages ----
exports.onMessageCreated = onDocumentCreated('chats/{chatId}/messages/{id}', async (event) => {
  const m = event.data && event.data.data();
  if (!m) return;
  const chat = (await db.collection('chats').doc(event.params.chatId).get()).data();
  if (!chat) return;
  const to = (chat.participants || []).find((p) => p !== m.senderId);
  const senderName = (chat.participantNames && chat.participantNames[m.senderId]) || 'New message';
  const text = m.text.length > 100 ? `${m.text.slice(0, 97)}...` : m.text;
  await notify(to, senderName, text, { type: 'message', chatId: event.params.chatId });
});

// ---- sessions ----
exports.onSessionCreated = onDocumentCreated('sessions/{id}', async (event) => {
  const s = event.data && event.data.data();
  if (!s) return;
  await notify(s.inviteeId, 'Session proposed',
    `${s.proposerName} proposed a session: ${s.topic}`,
    { type: 'session', sessionId: event.params.id });
});

exports.onSessionUpdated = onDocumentUpdated('sessions/{id}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (before.status === after.status) return;

  const actor = after.updatedBy;
  const other = (after.participants || []).find((p) => p !== actor);
  const actorName = actor === after.proposerId ? after.proposerName : after.inviteeName;
  const titles = {
    confirmed: ['Session confirmed', `${actorName} confirmed "${after.topic}"`],
    declined: ['Session declined', `${actorName} declined "${after.topic}"`],
    cancelled: ['Session cancelled', `${actorName} cancelled "${after.topic}"`],
    completed: ['Session completed', `${actorName} marked "${after.topic}" as completed`],
  };
  const t = titles[after.status];
  if (t) await notify(other, t[0], t[1], { type: 'session', sessionId: event.params.id });
});

// ---- reminders: runs every 5 minutes, alerts both users ~30 min before ----
exports.sessionReminders = onSchedule('every 5 minutes', async () => {
  const now = Timestamp.now();
  const soon = Timestamp.fromMillis(now.toMillis() + 30 * 60 * 1000);
  const snap = await db.collection('sessions')
    .where('status', '==', 'confirmed')
    .where('startAt', '>', now)
    .where('startAt', '<=', soon)
    .get();

  for (const doc of snap.docs) {
    const s = doc.data();
    if (s.reminderSent) continue;
    await Promise.all([
      notify(s.proposerId, 'Session starting soon',
        `"${s.topic}" with ${s.inviteeName} starts in about 30 minutes`,
        { type: 'session', sessionId: doc.id }),
      notify(s.inviteeId, 'Session starting soon',
        `"${s.topic}" with ${s.proposerName} starts in about 30 minutes`,
        { type: 'session', sessionId: doc.id }),
    ]);
    await doc.ref.update({ reminderSent: true });
  }
});

// ---- reviews (Module 5) ----
exports.onReviewCreated = onDocumentCreated('reviews/{id}', async (event) => {
  const r = event.data && event.data.data();
  if (!r) return;
  await notify(r.revieweeId, 'New review',
    `${r.reviewerName} rated you ${r.rating}/5 for "${r.topic}"`,
    { type: 'session', sessionId: r.sessionId });
});
