// seed/seed_routes.js
// ═══════════════════════════════════════════════════════════════════════════
// Sube a Firestore el contenido de las rutas de bienestar definido en
// seed/routes/<id>.js. Una ruta por archivo; este script solo valida y escribe.
//
// Uso (desde la raíz del proyecto):
//   node seed/seed_routes.js emociones --dry-run   → valida y resume, no escribe
//   node seed/seed_routes.js emociones             → escribe esa ruta
//   node seed/seed_routes.js --all --dry-run       → valida todas
//   node seed/seed_routes.js emociones --prune     → además borra lecciones que
//                                                    están en Firestore pero ya
//                                                    no en el archivo
//
// QUÉ TOCA: wellness_routes/<id> (metadatos), sus lessons y sus steps.
// Los pasos de cada lección se borran y se reemplazan completos.
// NO toca users/{uid}: el progreso se guarda por id de lección, así que
// NUNCA renombres el id de una lección que ya existe.
//
// Validación: si algún paso tiene errores (campos faltantes, listas ES/EN de
// distinto largo, índices fuera de rango) no se escribe NADA.
// ═══════════════════════════════════════════════════════════════════════════

const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
const DRY_RUN = args.includes('--dry-run');
const PRUNE = args.includes('--prune');
const ALL = args.includes('--all');
const ROUTES_DIR = path.join(__dirname, 'routes');

// ── Esquema por tipo de paso ────────────────────────────────────────────────
// text: string bilingüe (campo_es / campo_en)
// list: lista bilingüe con el mismo largo en ambos idiomas
// raw:  campo sin idioma
const SCHEMA = {
  reading: { text: ['title', 'content'] },
  quiz: { text: ['question', 'explanation'], list: ['options'], raw: ['correctIndex'] },
  exercise: { text: ['title', 'instruction'], optText: ['placeholder'] },
  scenario: { text: ['title', 'situation'], list: ['options', 'outcomes'] },
  reveal: { text: ['question', 'answer'], optText: ['title'] },
  slider: { text: ['question', 'minLabel', 'maxLabel'], list: ['responses'], optText: ['title'] },
  sort: { text: ['title', 'instruction'], list: ['categories', 'items'], raw: ['itemCategory'], optText: ['explanation'] },
  mythfact: { text: ['title'], list: ['statements', 'feedbacks'], raw: ['truths'] },
  practice: { text: ['title', 'intro'], list: ['prompts'], raw: ['durations'], optText: ['outro'] },
  order: { text: ['title', 'instruction'], list: ['items'], optText: ['explanation'] },
  pick: { text: ['question'], list: ['options'], optText: ['explanation', 'title'], optList: ['responses'] },
  story: { text: ['title'], list: ['lines'] },
  commit: { text: ['title', 'content'], list: ['options'] },
};

const MOTIONS = ['in', 'out', 'hold', 'still'];

function validateStep(step, where) {
  const errors = [];
  const err = (m) => errors.push(`${where} [${step.type}] ${m}`);
  const schema = SCHEMA[step.type];
  if (!schema) {
    err(`tipo desconocido`);
    return errors;
  }

  const isText = (v) => typeof v === 'string' && v.trim().length > 0;
  for (const f of schema.text || []) {
    if (!isText(step[`${f}_es`])) err(`falta ${f}_es`);
    if (!isText(step[`${f}_en`])) err(`falta ${f}_en`);
  }
  for (const f of schema.optText || []) {
    if ((step[`${f}_es`] === undefined) !== (step[`${f}_en`] === undefined)) {
      err(`${f} existe solo en un idioma`);
    }
  }
  const checkList = (f, required) => {
    const es = step[`${f}_es`];
    const en = step[`${f}_en`];
    if (es === undefined && en === undefined && !required) return;
    if (!Array.isArray(es) || es.length === 0) return err(`falta lista ${f}_es`);
    if (!Array.isArray(en) || en.length === 0) return err(`falta lista ${f}_en`);
    if (es.length !== en.length) err(`${f}: ES tiene ${es.length}, EN tiene ${en.length}`);
    if (![...es, ...en].every(isText)) err(`${f}: hay elementos vacíos`);
  };
  for (const f of schema.list || []) checkList(f, true);
  for (const f of schema.optList || []) checkList(f, false);
  for (const f of schema.raw || []) {
    if (step[f] === undefined) err(`falta ${f}`);
  }

  const len = (f) => (step[`${f}_es`] || []).length;

  switch (step.type) {
    case 'quiz':
      if (!(step.correctIndex >= 0 && step.correctIndex < len('options'))) err('correctIndex fuera de rango');
      break;
    case 'scenario':
      if (len('options') !== len('outcomes')) err('options y outcomes deben tener el mismo largo');
      break;
    case 'slider':
      if (len('responses') !== 3) err('responses debe tener exactamente 3 (bajo, medio, alto)');
      break;
    case 'sort':
      if (!Array.isArray(step.itemCategory) || step.itemCategory.length !== len('items')) {
        err('itemCategory debe tener un índice por item');
      } else if (!step.itemCategory.every((c) => c >= 0 && c < len('categories'))) {
        err('itemCategory tiene categorías fuera de rango');
      }
      break;
    case 'mythfact':
      if (!Array.isArray(step.truths) || step.truths.length !== len('statements')) err('truths debe tener un booleano por afirmación');
      if (len('feedbacks') !== len('statements')) err('feedbacks debe tener uno por afirmación');
      if (Array.isArray(step.truths) && (step.truths.every(Boolean) || step.truths.every((t) => !t))) {
        err('mezcla mitos y realidades: si todas son iguales se adivina');
      }
      break;
    case 'practice':
      if (!Array.isArray(step.durations) || step.durations.length !== len('prompts')) err('durations debe tener un número por prompt');
      if (step.motions !== undefined) {
        if (!Array.isArray(step.motions) || step.motions.length !== len('prompts')) err('motions debe tener uno por prompt');
        else if (!step.motions.every((m) => MOTIONS.includes(m))) err(`motions solo admite ${MOTIONS.join('/')}`);
      }
      break;
    case 'order':
      if (len('items') < 3) err('order necesita al menos 3 items');
      break;
    case 'pick':
      if (step.responses_es !== undefined && len('responses') !== 3) err('responses de pick debe tener 3 (pocas, algunas, muchas)');
      break;
    case 'story':
      if (len('lines') < 3) err('una historia necesita al menos 3 líneas');
      break;
    case 'commit':
      if (len('options') < 1) err('commit necesita al menos un reto');
      break;
  }
  return errors;
}

/// Advertencias de variedad: no bloquean, pero señalan monotonía.
function varietyWarnings(route) {
  const warnings = [];
  let previousShape = null;
  route.lessons.forEach((lec) => {
    const types = lec.steps.map((s) => s.type);
    const shape = types.join('>');
    const distinct = new Set(types).size;
    if (lec.steps.length < 5) warnings.push(`${lec.id}: solo ${lec.steps.length} pasos`);
    if (distinct < 4) warnings.push(`${lec.id}: solo ${distinct} tipos distintos`);
    if (shape === previousShape) warnings.push(`${lec.id}: misma secuencia que la lección anterior`);
    for (let i = 1; i < types.length; i++) {
      if (types[i] === types[i - 1]) warnings.push(`${lec.id}: dos "${types[i]}" seguidos`);
    }
    if (types.filter((t) => t === 'reading').length > 1) warnings.push(`${lec.id}: más de una lectura`);
    previousShape = shape;
  });
  return warnings;
}

function validateRoute(route) {
  const errors = [];
  for (const f of ['title', 'description']) {
    if (!route[`${f}_es`] || !route[`${f}_en`]) errors.push(`ruta: falta ${f}_es/${f}_en`);
  }
  for (const f of ['id', 'emoji', 'color', 'colorDark', 'order']) {
    if (route[f] === undefined) errors.push(`ruta: falta ${f}`);
  }
  const ids = new Set();
  route.lessons.forEach((lec, li) => {
    if (ids.has(lec.id)) errors.push(`${lec.id}: id duplicado`);
    ids.add(lec.id);
    for (const f of ['title', 'subtitle']) {
      if (!lec[`${f}_es`] || !lec[`${f}_en`]) errors.push(`${lec.id}: falta ${f}_es/${f}_en`);
    }
    if (typeof lec.xpReward !== 'number') errors.push(`${lec.id}: falta xpReward`);
    if (!Array.isArray(lec.steps) || lec.steps.length === 0) errors.push(`${lec.id}: sin pasos`);
    (lec.steps || []).forEach((s, si) => {
      errors.push(...validateStep(s, `${lec.id} paso ${si}`));
    });
    if (lec.order !== undefined && lec.order !== li) {
      errors.push(`${lec.id}: order ${lec.order} no coincide con su posición ${li} (quita "order", se calcula solo)`);
    }
  });
  return errors;
}

function loadRoute(id) {
  const file = path.join(ROUTES_DIR, `${id}.js`);
  if (!fs.existsSync(file)) throw new Error(`No existe ${file}`);
  const route = require(file);
  if (route.id !== id) throw new Error(`${file} exporta id "${route.id}", se esperaba "${id}"`);
  return route;
}

async function writeRoute(db, route) {
  const routeRef = db.collection('wellness_routes').doc(route.id);
  const { lessons, ...meta } = route;
  await routeRef.set(meta, { merge: true });

  for (const [i, lec] of lessons.entries()) {
    const lecRef = routeRef.collection('lessons').doc(lec.id);
    const { steps, id, order, ...lessonMeta } = lec;
    await lecRef.set({ ...lessonMeta, order: i }, { merge: true });

    const old = await lecRef.collection('steps').get();
    const batch = db.batch();
    old.forEach((d) => batch.delete(d.ref));
    steps.forEach((step, si) => {
      const { type, ...fields } = step;
      batch.set(lecRef.collection('steps').doc(`step_${String(si).padStart(2, '0')}`), {
        type,
        order: si,
        ...fields,
      });
    });
    await batch.commit();
    console.log(`  ${lec.id}: ${old.size} pasos viejos → ${steps.length} nuevos`);
  }

  const existing = await routeRef.collection('lessons').get();
  const keep = new Set(lessons.map((l) => l.id));
  const orphans = existing.docs.filter((d) => !keep.has(d.id));
  for (const doc of orphans) {
    if (PRUNE) {
      const steps = await doc.ref.collection('steps').get();
      const batch = db.batch();
      steps.forEach((s) => batch.delete(s.ref));
      batch.delete(doc.ref);
      await batch.commit();
      console.log(`  ${doc.id}: borrada (--prune)`);
    } else {
      console.log(`  ⚠ ${doc.id} está en Firestore pero no en el archivo (usa --prune para borrarla)`);
    }
  }
}

async function main() {
  const ids = ALL
    ? fs.readdirSync(ROUTES_DIR).filter((f) => f.endsWith('.js')).map((f) => f.replace(/\.js$/, ''))
    : args.filter((a) => !a.startsWith('--'));

  if (ids.length === 0) {
    console.log('Uso: node seed/seed_routes.js <ruta...> | --all  [--dry-run] [--prune]');
    process.exit(1);
  }
  if (DRY_RUN) console.log('MODO SIMULACIÓN — no se escribe nada en Firestore\n');

  const routes = ids.map(loadRoute).sort((a, b) => a.order - b.order);
  let hasErrors = false;

  for (const route of routes) {
    const types = {};
    let steps = 0;
    console.log(`\n══ ${route.emoji} ${route.title_es} (${route.id}) ══`);
    route.lessons.forEach((lec, i) => {
      const t = lec.steps.map((s) => s.type);
      t.forEach((x) => (types[x] = (types[x] || 0) + 1));
      steps += t.length;
      console.log(`${String(i + 1).padStart(2)}. ${lec.id.padEnd(8)} ${lec.title_es}`);
      console.log(`    ${t.join(' → ')}`);
    });
    console.log(`lecciones: ${route.lessons.length} | pasos: ${steps}`);
    console.log('por tipo:', JSON.stringify(types));

    const errors = validateRoute(route);
    const warnings = varietyWarnings(route);
    warnings.forEach((w) => console.log(`  ⚠ ${w}`));
    errors.forEach((e) => console.log(`  ✖ ${e}`));
    if (errors.length) hasErrors = true;
    else console.log('  ✔ validación correcta');
  }

  if (hasErrors) {
    console.log('\nHay errores: no se escribió nada.');
    process.exit(1);
  }
  if (DRY_RUN) {
    console.log('\nPara escribir de verdad, quita --dry-run.');
    return;
  }

  const admin = require('firebase-admin');
  const serviceAccount = require(path.join(__dirname, '..', 'serviceAccountKey.json'));
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  const db = admin.firestore();

  for (const route of routes) {
    console.log(`\nEscribiendo ${route.id}...`);
    await writeRoute(db, route);
  }
  console.log('\nListo.');
}

main()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error('ERROR:', e.message);
    process.exit(1);
  });
