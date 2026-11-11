const assert = require('node:assert/strict');
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require('@firebase/rules-unit-testing');
const { Timestamp, doc, getDoc, setDoc, updateDoc, deleteDoc } = require('firebase/firestore');
const fs = require('node:fs');

const OWNER = 'owner-uid';
const OTHER = 'other-uid';
const gateway = {
  name: 'Home', scheme: 'https', baseUrl: 'gateway.example.test',
  apiToken: 'test-token', ownerId: OWNER,
  createdAt: Timestamp.fromMillis(1000),
  updatedAt: Timestamp.fromMillis(1000),
};

function ref(db, uid = OWNER) {
  return doc(db, `users/${uid}/gateways/gateway-1`);
}

async function main() {
  const env = await initializeTestEnvironment({
    projectId: 'wol-client-rules-test',
    firestore: { rules: fs.readFileSync('firestore.rules', 'utf8') },
  });
  try {
    const owner = env.authenticatedContext(OWNER).firestore();
    const other = env.authenticatedContext(OTHER).firestore();
    const guest = env.unauthenticatedContext().firestore();

    await assertSucceeds(setDoc(ref(owner), gateway));
    await assertSucceeds(getDoc(ref(owner)));
    await assertSucceeds(updateDoc(ref(owner), { name: 'Office' }));
    await assertSucceeds(deleteDoc(ref(owner)));
    await assertFails(setDoc(ref(guest), gateway));
    await assertFails(getDoc(ref(guest)));
    await assertFails(getDoc(ref(other, OWNER)));
    await assertFails(setDoc(ref(other, OWNER), gateway));

    await env.withSecurityRulesDisabled(async (context) => {
      await setDoc(ref(context.firestore()), gateway);
    });
    await assertFails(updateDoc(ref(owner), { ownerId: OTHER }));
    await assertFails(updateDoc(ref(owner), { scheme: 'ftp' }));
    await assertFails(updateDoc(ref(owner), { unexpected: true }));
  } finally {
    await env.cleanup();
  }
  assert.ok(true);
  console.log('Firestore Rules checks passed');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
