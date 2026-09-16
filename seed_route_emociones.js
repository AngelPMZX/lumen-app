// seed_route_emociones.js
// ═══════════════════════════════════════════════════════════════════════════
// Reescribe los pasos de la ruta "emociones" usando los tipos nuevos
// (scenario, reveal, slider, sort) además de reading / quiz / exercise.
//
// Uso:
//   node seed_route_emociones.js --dry-run   → muestra qué haría, sin escribir
//   node seed_route_emociones.js             → escribe en Firestore
//
// QUÉ TOCA: solo wellness_routes/emociones/lessons/*/steps.
// Los pasos viejos de esas lecciones se borran y se reemplazan (cambia el
// número de pasos, así que mezclarlos dejaría contenido duplicado).
// NO toca el progreso de los usuarios: eso vive en users/{uid}.
// ═══════════════════════════════════════════════════════════════════════════

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

const DRY_RUN = process.argv.includes('--dry-run');
const ROUTE_ID = 'emociones';

const LECCIONES = [
  // ═════════════════════════════════════════════════════════════════════════
  {
    id: 'emo_1',
    title_es: '¿Qué son las emociones?',
    title_en: 'What are emotions?',
    subtitle_es: 'Tu GPS interno, no tu enemigo',
    subtitle_en: 'Your internal GPS, not your enemy',
    xpReward: 20,
    order: 0,
    steps: [
      {
        type: 'reading',
        title_es: 'Tu radar emocional',
        title_en: 'Your emotional radar',
        content_es:
          'Las emociones son señales que tu cuerpo y tu mente te mandan para ayudarte a navegar la vida. No son buenas ni malas: son información.\n\nPiensa en el clima. A veces hay sol, a veces lluvia. No te enojas con la lluvia por existir; sacas un paraguas.\n\nLa clave no es dejar de sentir, sino aprender a leer lo que cada emoción te está diciendo.',
        content_en:
          'Emotions are signals your body and mind send to help you navigate life. They are neither good nor bad: they are information.\n\nThink of the weather. Sometimes it is sunny, sometimes it rains. You do not get angry at the rain for existing; you grab an umbrella.\n\nThe point is not to stop feeling, but to learn to read what each emotion is telling you.',
      },
      {
        type: 'reveal',
        question_es: '¿Para qué sirve el enojo?',
        question_en: 'What is anger for?',
        answer_es:
          'El enojo aparece cuando algo que te importa fue cruzado: un límite, un valor, una necesidad.\n\nNo es una falla de carácter. Es una alarma que señala "esto me importaba". Lo que decides hacer con esa información ya es otra cosa.',
        answer_en:
          'Anger shows up when something you care about was crossed: a boundary, a value, a need.\n\nIt is not a character flaw. It is an alarm pointing at "this mattered to me". What you decide to do with that information is a separate question.',
      },
      {
        type: 'quiz',
        question_es: '¿Las emociones negativas son malas?',
        question_en: 'Are negative emotions bad?',
        options_es: [
          'Sí, hay que evitarlas siempre',
          'No, todas las emociones son información útil',
          'Solo algunas sirven de algo',
        ],
        options_en: [
          'Yes, they should always be avoided',
          'No, all emotions are useful information',
          'Only some of them are useful',
        ],
        correctIndex: 1,
        explanation_es:
          'Todas las emociones cumplen una función. La tristeza te ayuda a procesar pérdidas, el miedo te protege, y el enojo te avisa que algo te importa.',
        explanation_en:
          'Every emotion serves a purpose. Sadness helps you process loss, fear protects you, and anger tells you something matters to you.',
      },
      {
        type: 'scenario',
        title_es: 'Un mensaje que no llega',
        title_en: 'A message that never comes',
        situation_es:
          'Le escribiste a alguien importante para ti hace seis horas. Ves que leyó el mensaje. No ha contestado.\n\nSientes un nudo en el estómago.',
        situation_en:
          'You texted someone important to you six hours ago. You can see they read it. No reply.\n\nYou feel a knot in your stomach.',
        options_es: [
          'Le escribo otra vez: "¿todo bien?"',
          'Guardo el teléfono y sigo con mi día',
          'Me quedo dándole vueltas a qué hice mal',
        ],
        options_en: [
          'Text again: "everything okay?"',
          'Put the phone away and get on with my day',
          'Keep replaying what I might have done wrong',
        ],
        outcomes_es: [
          'Buscar información es válido. Ojo con el motivo: si escribes para calmar tu ansiedad, el alivio dura poco y la ansiedad vuelve más fuerte.',
          'Tolerar la incertidumbre es un músculo. No estás ignorando lo que sientes, estás decidiendo no actuar desde la urgencia.',
          'Esto se llama rumiar. Tu mente cree que resolver el pasado te dará control, pero girar sobre lo mismo sin información nueva solo alimenta la angustia.',
        ],
        outcomes_en: [
          'Seeking information is valid. Watch the motive: if you text to soothe your anxiety, the relief is brief and the anxiety comes back stronger.',
          'Tolerating uncertainty is a muscle. You are not ignoring what you feel, you are choosing not to act from urgency.',
          'This is called rumination. Your mind believes solving the past gives you control, but circling with no new information only feeds the distress.',
        ],
      },
      {
        type: 'slider',
        question_es: '¿Qué tan seguido intentas "no sentir" lo que sientes?',
        question_en: 'How often do you try to "not feel" what you feel?',
        minLabel_es: 'Casi nunca',
        minLabel_en: 'Almost never',
        maxLabel_es: 'Todo el tiempo',
        maxLabel_en: 'All the time',
        responses_es: [
          'Sueles dejar que las emociones pasen por ti sin pelearte con ellas. Eso es justamente lo que se entrena aquí.',
          'A veces sientes y a veces empujas la emoción hacia abajo. Fíjate qué emoción concreta es la que más te cuesta dejar entrar.',
          'Empujar lo que sientes funciona a corto plazo y cobra caro después. No se trata de sentirlo todo de golpe, sino de dejar de gastar energía en tapar.',
        ],
        responses_en: [
          'You tend to let emotions move through you without fighting them. That is exactly what this trains.',
          'Sometimes you feel it, sometimes you push it down. Notice which specific emotion is the hardest to let in.',
          'Pushing feelings down works short term and charges interest later. The goal is not to feel everything at once, but to stop spending energy on covering up.',
        ],
      },
      {
        type: 'exercise',
        title_es: 'Nombra tu emoción',
        title_en: 'Name your emotion',
        instruction_es:
          'Cierra los ojos diez segundos. ¿Qué emoción hay ahora mismo? Escríbela y di en qué parte del cuerpo la sientes.',
        instruction_en:
          'Close your eyes for ten seconds. What emotion is here right now? Write it down and say where in your body you feel it.',
        placeholder_es: 'Ej: siento curiosidad, como energía en el pecho...',
        placeholder_en: 'E.g.: I feel curious, like energy in my chest...',
      },
    ],
  },

  // ═════════════════════════════════════════════════════════════════════════
  {
    id: 'emo_2',
    title_es: 'La rueda emocional',
    title_en: 'The emotion wheel',
    subtitle_es: 'Más palabras, más control',
    subtitle_en: 'More words, more control',
    xpReward: 20,
    order: 1,
    steps: [
      {
        type: 'reading',
        title_es: 'Más allá de "bien" o "mal"',
        title_en: 'Beyond "fine" or "bad"',
        content_es:
          'La mayoría de la gente usa tres o cuatro palabras para describir cómo se siente: bien, mal, cansado, estresado.\n\nPero existen decenas de emociones distintas. Cuanto más preciso eres al nombrar lo que sientes, más fácil es manejarlo.\n\nSe llama granularidad emocional, y hay evidencia de que mejora el bienestar: nombrar con precisión baja la intensidad.',
        content_en:
          'Most people use three or four words to describe how they feel: fine, bad, tired, stressed.\n\nBut there are dozens of distinct emotions. The more precise you are at naming what you feel, the easier it is to handle.\n\nIt is called emotional granularity, and there is evidence it improves wellbeing: naming precisely lowers the intensity.',
      },
      {
        type: 'sort',
        title_es: 'Afina la palabra',
        title_en: 'Sharpen the word',
        instruction_es:
          'Arrastra cada frase a la emoción que la describe mejor. No es lo mismo estar frustrado que decepcionado.',
        instruction_en:
          'Drag each sentence to the emotion that best describes it. Being frustrated is not the same as being disappointed.',
        categories_es: ['Frustración', 'Decepción', 'Ansiedad'],
        categories_en: ['Frustration', 'Disappointment', 'Anxiety'],
        items_es: [
          'Llevo tres intentos y no me sale',
          'Esperaba más de esa persona',
          'No dejo de pensar en lo que puede salir mal',
          'Confiaba en que esta vez sí iba a pasar',
        ],
        items_en: [
          'Three attempts in and it still will not work',
          'I expected more from that person',
          'I cannot stop thinking about what could go wrong',
          'I trusted that this time it would happen',
        ],
        itemCategory: [0, 1, 2, 1],
        explanation_es:
          'La frustración mira un obstáculo, la decepción mira una expectativa rota, y la ansiedad mira al futuro. Son tres respuestas distintas porque piden tres cosas distintas.',
        explanation_en:
          'Frustration looks at an obstacle, disappointment looks at a broken expectation, and anxiety looks at the future. They call for three different responses.',
      },
      {
        type: 'quiz',
        question_es: '¿Qué es la granularidad emocional?',
        question_en: 'What is emotional granularity?',
        options_es: [
          'Sentir muchas emociones a la vez',
          'Poder nombrar lo que sientes con precisión',
          'Aprender a no sentir nada',
        ],
        options_en: [
          'Feeling many emotions at once',
          'Being able to name what you feel precisely',
          'Learning not to feel anything',
        ],
        correctIndex: 1,
        explanation_es:
          'Es poder distinguir entre "estoy frustrado" y "estoy decepcionado". Esa precisión te da más herramientas para responder bien.',
        explanation_en:
          'It is being able to tell "I am frustrated" from "I am disappointed". That precision gives you better tools to respond.',
      },
      {
        type: 'reveal',
        question_es: '¿Por qué nombrar una emoción la calma?',
        question_en: 'Why does naming an emotion calm it down?',
        answer_es:
          'Ponerle palabras a lo que sientes mueve la actividad desde la parte del cerebro que reacciona hacia la que analiza.\n\nEn otras palabras: dejas de estar dentro de la emoción y pasas a mirarla. Sigue ahí, pero ya no maneja ella.',
        answer_en:
          'Putting words to what you feel shifts activity from the part of the brain that reacts toward the part that analyzes.\n\nIn other words: you stop being inside the emotion and start looking at it. It is still there, but it is no longer driving.',
      },
      {
        type: 'exercise',
        title_es: 'Expande tu vocabulario',
        title_en: 'Expand your vocabulary',
        instruction_es:
          'Piensa en tu día. En vez de "bien" o "mal", usa al menos tres palabras distintas para describir cómo te sentiste en distintos momentos.',
        instruction_en:
          'Think about your day. Instead of "fine" or "bad", use at least three different words for how you felt at different moments.',
        placeholder_es:
          'Ej: en la mañana motivado, al mediodía abrumado, ahora tranquilo...',
        placeholder_en:
          'E.g.: motivated in the morning, overwhelmed at noon, calm now...',
      },
    ],
  },

  // ═════════════════════════════════════════════════════════════════════════
  {
    id: 'emo_3',
    title_es: 'La ola emocional',
    title_en: 'The emotional wave',
    subtitle_es: 'Toda emoción sube y baja',
    subtitle_en: 'Every emotion rises and falls',
    xpReward: 20,
    order: 2,
    steps: [
      {
        type: 'reading',
        title_es: 'Nada dura para siempre',
        title_en: 'Nothing lasts forever',
        content_es:
          'Una emoción intensa se comporta como una ola: sube, llega a un pico y baja. Aunque en el pico parezca eterna, tiene fecha de caducidad.\n\nEl problema no suele ser la ola, sino lo que hacemos para no mojarnos: contestar de más, huir, revisar el teléfono cien veces.\n\nSurfear la ola es simplemente quedarte mientras baja, sin apagarla a la fuerza.',
        content_en:
          'An intense emotion behaves like a wave: it rises, peaks, and falls. Even if it feels eternal at the peak, it has an expiry date.\n\nThe problem is usually not the wave, but what we do to avoid getting wet: over-responding, running, checking the phone a hundred times.\n\nSurfing the wave simply means staying while it comes down, without forcing it off.',
      },
      {
        type: 'slider',
        question_es: 'Cuando una emoción te golpea fuerte, ¿qué tanto necesitas que se vaya YA?',
        question_en: 'When an emotion hits hard, how badly do you need it gone RIGHT NOW?',
        minLabel_es: 'Puedo esperar',
        minLabel_en: 'I can wait it out',
        maxLabel_es: 'Necesito que pare ya',
        maxLabel_en: 'I need it to stop now',
        responses_es: [
          'Tienes tolerancia al malestar, que es la base de todo lo demás. Aprovecha esa calma para acompañar a otros.',
          'A veces aguantas y a veces la urgencia gana. Cuando notes la prisa, prueba poner un cronómetro de diez minutos antes de actuar.',
          'La urgencia por que pare es normal, y también es la trampa: casi todo lo que hacemos para apagar una emoción rápido nos cuesta caro después. Empieza por bajar un punto.',
        ],
        responses_en: [
          'You have distress tolerance, which is the foundation of everything else. Use that calm to support others too.',
          'Sometimes you ride it out, sometimes urgency wins. When you notice the rush, try setting a ten-minute timer before acting.',
          'The urgency for it to stop is normal, and it is also the trap: most things we do to switch an emotion off fast cost us later. Start by lowering it one point.',
        ],
      },
      {
        type: 'scenario',
        title_es: 'Diez minutos antes de la junta',
        title_en: 'Ten minutes before the meeting',
        situation_es:
          'Faltan diez minutos para una presentación importante. El corazón te late fuerte, las manos te sudan y tu cabeza repite "se me va a olvidar todo".',
        situation_en:
          'Ten minutes before an important presentation. Your heart is pounding, your hands are sweaty, and your head repeats "I am going to forget everything".',
        options_es: [
          'Repaso las notas una y otra vez hasta que empiece',
          'Respiro lento treinta segundos y acepto que estoy nervioso',
          'Me digo "cálmate, no es para tanto"',
        ],
        options_en: [
          'Review the notes over and over until it starts',
          'Breathe slowly for thirty seconds and accept that I am nervous',
          'Tell myself "calm down, it is not a big deal"',
        ],
        outcomes_es: [
          'Repasar da sensación de control, pero a esta altura ya no agrega nada: mantiene el cuerpo en alerta y gasta la energía que necesitas para presentar.',
          'Aceptar el nervio baja la pelea interna. Los nervios antes de algo que importa no son un error del sistema, son el sistema funcionando.',
          'Ordenarte calma suele hacer lo contrario: agregas juicio encima del nervio. Ahora estás nervioso y además enojado contigo.',
        ],
        outcomes_en: [
          'Reviewing feels like control, but at this point it adds nothing: it keeps your body on alert and burns the energy you need to present.',
          'Accepting the nerves lowers the internal fight. Nerves before something that matters are not a system error, they are the system working.',
          'Ordering yourself to calm down usually backfires: you add judgment on top of the nerves. Now you are nervous and angry at yourself.',
        ],
      },
      {
        type: 'quiz',
        question_es: '¿Qué suele alargar una emoción intensa?',
        question_en: 'What usually makes an intense emotion last longer?',
        options_es: [
          'Dejarla estar mientras baja',
          'Pelearte con ella para que se vaya rápido',
          'Nombrarla con precisión',
        ],
        options_en: [
          'Letting it be while it comes down',
          'Fighting it so it goes away fast',
          'Naming it precisely',
        ],
        correctIndex: 1,
        explanation_es:
          'Resistir una emoción le da más combustible. Lo que la acorta es dejarla completar su curva mientras haces algo que sí te importa.',
        explanation_en:
          'Resisting an emotion fuels it. What shortens it is letting it finish its curve while you do something that actually matters to you.',
      },
      {
        type: 'exercise',
        title_es: 'Tu última ola',
        title_en: 'Your last wave',
        instruction_es:
          'Recuerda la última emoción fuerte que tuviste. ¿Cuánto duró de verdad el pico? ¿Qué hiciste mientras bajaba?',
        instruction_en:
          'Recall the last strong emotion you had. How long did the peak actually last? What did you do while it came down?',
        placeholder_es: 'Ej: el pico duró como veinte minutos, salí a caminar...',
        placeholder_en: 'E.g.: the peak lasted about twenty minutes, I went for a walk...',
      },
    ],
  },

  // ═════════════════════════════════════════════════════════════════════════
  {
    id: 'emo_4',
    title_es: 'Disparadores',
    title_en: 'Triggers',
    subtitle_es: 'Lo que enciende la mecha',
    subtitle_en: 'What lights the fuse',
    xpReward: 20,
    order: 3,
    steps: [
      {
        type: 'reading',
        title_es: 'No fue el comentario',
        title_en: 'It was not the comment',
        content_es:
          'Un disparador es algo pequeño que provoca una reacción grande. Casi nunca es el hecho en sí: es lo que ese hecho toca.\n\nSi un comentario sobre tu trabajo te derrumba el día, probablemente no dolió el comentario, sino la idea de "no soy suficiente" que ya estaba ahí.\n\nConocer tus disparadores no los apaga. Te da el segundo que necesitas para elegir.',
        content_en:
          'A trigger is something small that sets off a big reaction. It is rarely the event itself: it is what the event touches.\n\nIf a comment about your work ruins your day, it probably was not the comment that hurt, but the "I am not enough" that was already there.\n\nKnowing your triggers does not switch them off. It gives you the one second you need in order to choose.',
      },
      {
        type: 'reveal',
        question_es: 'Si conoces tus disparadores, ¿dejan de afectarte?',
        question_en: 'If you know your triggers, do they stop affecting you?',
        answer_es:
          'No, y esa es la buena noticia. Seguirás sintiendo el golpe, pero llegará con etiqueta: "esto es mi disparador de rechazo".\n\nCon etiqueta, la reacción deja de ser automática. Ese espacio entre el estímulo y tu respuesta es todo lo que necesitas.',
        answer_en:
          'No, and that is the good news. You will still feel the hit, but it arrives labeled: "this is my rejection trigger".\n\nLabeled, the reaction stops being automatic. That gap between the trigger and your response is all you need.',
      },
      {
        type: 'sort',
        title_es: '¿Hecho o interpretación?',
        title_en: 'Fact or interpretation?',
        instruction_es:
          'Separar lo que pasó de lo que te contaste es el primer paso. Arrastra cada frase a su lugar.',
        instruction_en:
          'Separating what happened from what you told yourself is the first step. Drag each sentence to where it belongs.',
        categories_es: ['Lo que pasó', 'Lo que me conté'],
        categories_en: ['What happened', 'What I told myself'],
        items_es: [
          'No contestó mi mensaje en todo el día',
          'Está claro que ya no le importo',
          'Mi jefe pidió cambios en el informe',
          'Nunca hago nada bien',
        ],
        items_en: [
          'They did not reply all day',
          'Clearly they do not care about me anymore',
          'My boss asked for changes to the report',
          'I never do anything right',
        ],
        itemCategory: [0, 1, 0, 1],
        explanation_es:
          'Los hechos se pueden grabar en video; las interpretaciones no. Cuando algo te tumbe el ánimo, pregúntate qué parte se vería en la grabación.',
        explanation_en:
          'Facts could be caught on video; interpretations could not. When something knocks your mood down, ask which part would show up on the recording.',
      },
      {
        type: 'scenario',
        title_es: 'El grupo se quedó callado',
        title_en: 'The group went quiet',
        situation_es:
          'Cuentas una idea en una reunión y nadie dice nada por unos segundos. Sientes calor en la cara.',
        situation_en:
          'You share an idea in a meeting and nobody says anything for a few seconds. Your face feels hot.',
        options_es: [
          'Me retracto: "bueno, era solo una idea tonta"',
          'Sostengo el silencio y espero',
          'Pregunto: "¿qué opinan?"',
        ],
        options_en: [
          'Walk it back: "well, it was just a silly idea"',
          'Hold the silence and wait',
          'Ask: "what do you think?"',
        ],
        outcomes_es: [
          'Retractarte calma el momento y le enseña a tu cerebro que el silencio era peligroso. La próxima vez el disparador será un poco más fuerte.',
          'El silencio casi siempre es gente pensando, no gente juzgando. Sostenerlo te enseña que puedes tolerar la incomodidad sin que pase nada malo.',
          'Pedir información real rompe el bucle: cambias la interpretación por datos. Es la salida más útil cuando la incomodidad ya está ahí.',
        ],
        outcomes_en: [
          'Walking it back settles the moment and teaches your brain that the silence was dangerous. Next time the trigger will be a little stronger.',
          'Silence is almost always people thinking, not people judging. Holding it teaches you that you can tolerate discomfort and nothing bad happens.',
          'Asking for real information breaks the loop: you swap interpretation for data. It is the most useful exit once the discomfort is there.',
        ],
      },
      {
        type: 'exercise',
        title_es: 'Mapea un disparador',
        title_en: 'Map one trigger',
        instruction_es:
          'Piensa en algo pequeño que te descoloca más de lo razonable. ¿Qué idea sobre ti toca esa situación?',
        instruction_en:
          'Think of something small that throws you off more than it should. What belief about yourself does it touch?',
        placeholder_es:
          'Ej: que me corrijan delante de otros, toca la idea de que no soy capaz...',
        placeholder_en:
          'E.g.: being corrected in front of others touches the idea that I am not capable...',
      },
    ],
  },

  // ═════════════════════════════════════════════════════════════════════════
  {
    id: 'emo_5',
    title_es: 'Responder en vez de reaccionar',
    title_en: 'Responding instead of reacting',
    subtitle_es: 'El segundo que lo cambia todo',
    subtitle_en: 'The second that changes everything',
    xpReward: 25,
    order: 4,
    steps: [
      {
        type: 'reading',
        title_es: 'Reaccionar es automático',
        title_en: 'Reacting is automatic',
        content_es:
          'Reaccionar es lo que hace el cuerpo solo: contestas de más, te callas de golpe, cierras la puerta.\n\nResponder es lo que eliges cuando metes un segundo de aire entre lo que pasó y lo que haces.\n\nNo se trata de ser de piedra. Se trata de que la decisión la tomes tú, no la primera emoción que llegó.',
        content_en:
          'Reacting is what the body does on its own: you snap back, you shut down, you slam the door.\n\nResponding is what you choose when you put one second of air between what happened and what you do.\n\nThis is not about being made of stone. It is about you making the call, not the first emotion that showed up.',
      },
      {
        type: 'sort',
        title_es: 'Reacción o respuesta',
        title_en: 'Reaction or response',
        instruction_es: 'Clasifica cada conducta según venga del piloto automático o de una elección.',
        instruction_en: 'Sort each behavior by whether it comes from autopilot or from a choice.',
        categories_es: ['Reacción', 'Respuesta'],
        categories_en: ['Reaction', 'Response'],
        items_es: [
          'Contesto el mensaje enojado al instante',
          'Digo "déjame pensarlo y te digo mañana"',
          'Salgo del cuarto dando un portazo',
          'Aviso que necesito diez minutos antes de seguir',
        ],
        items_en: [
          'Fire back an angry text immediately',
          'Say "let me think about it, I will tell you tomorrow"',
          'Walk out slamming the door',
          'Say I need ten minutes before continuing',
        ],
        itemCategory: [0, 1, 0, 1],
        explanation_es:
          'Fíjate que ambas respuestas incluyen pausa y aviso. No es aguantarse: es avisar que vas a decidir con la cabeza fría.',
        explanation_en:
          'Notice both responses include a pause and a heads-up. It is not bottling up: it is signaling that you will decide with a cool head.',
      },
      {
        type: 'quiz',
        question_es: '¿Qué distingue una respuesta de una reacción?',
        question_en: 'What separates a response from a reaction?',
        options_es: [
          'Que no sientes nada al responder',
          'Que hay una pausa y una elección de por medio',
          'Que siempre es más amable',
        ],
        options_en: [
          'You feel nothing when responding',
          'There is a pause and a choice in between',
          'It is always nicer',
        ],
        correctIndex: 1,
        explanation_es:
          'Una respuesta puede ser firme, incómoda o cortante. Lo que la define no es el tono, sino que la elegiste tú.',
        explanation_en:
          'A response can be firm, uncomfortable or blunt. What defines it is not the tone, but that you chose it.',
      },
      {
        type: 'slider',
        question_es: 'Cuando algo te molesta, ¿qué tan rápido actúas?',
        question_en: 'When something upsets you, how fast do you act?',
        minLabel_es: 'Me tomo mi tiempo',
        minLabel_en: 'I take my time',
        maxLabel_es: 'Reacciono al instante',
        maxLabel_en: 'I react instantly',
        responses_es: [
          'Ya tienes la pausa instalada. El siguiente nivel es usarla para decir lo que sí quieres decir, no solo para callar.',
          'Depende del día y de quién esté enfrente. Identifica con quién se te acorta la mecha: ahí está el trabajo.',
          'La mecha corta casi siempre viene de sentirse amenazado, no de falta de carácter. Empieza por una sola frase: "déjame pensarlo".',
        ],
        responses_en: [
          'You already have the pause installed. The next level is using it to say what you do want to say, not just to stay quiet.',
          'It depends on the day and who is in front of you. Identify who shortens your fuse: that is where the work is.',
          'A short fuse almost always comes from feeling threatened, not from a lack of character. Start with one sentence: "let me think about it".',
        ],
      },
      {
        type: 'exercise',
        title_es: 'Tu frase de pausa',
        title_en: 'Your pause sentence',
        instruction_es:
          'Escribe una frase corta que puedas decir para ganar tiempo cuando algo te encienda. Que suene a ti.',
        instruction_en:
          'Write a short sentence you can say to buy time when something sets you off. Make it sound like you.',
        placeholder_es: 'Ej: "necesito un momento para pensarlo bien"...',
        placeholder_en: 'E.g.: "I need a moment to think this through"...',
      },
    ],
  },
];

// ═══════════════════════════════════════════════════════════════════════════

async function main() {
  if (DRY_RUN) {
    console.log('MODO SIMULACIÓN — no se escribe nada en Firestore\n');
  }

  const resumen = {};
  let totalPasos = 0;

  for (const lec of LECCIONES) {
    const tipos = lec.steps.map((s) => s.type);
    tipos.forEach((t) => (resumen[t] = (resumen[t] || 0) + 1));
    totalPasos += lec.steps.length;
    console.log(`${lec.id}  "${lec.title_es}"`);
    console.log(`   ${lec.steps.length} pasos: ${tipos.join(' → ')}`);
  }

  console.log('\n=== RESUMEN ===');
  console.log(`lecciones: ${LECCIONES.length} | pasos: ${totalPasos}`);
  console.log('por tipo:', JSON.stringify(resumen));
  console.log('antes: 5 lecciones × 3 pasos = 15 pasos (reading/quiz/exercise)');

  if (DRY_RUN) {
    console.log('\nPara escribir de verdad: node seed_route_emociones.js');
    return;
  }

  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
  const db = admin.firestore();
  const rutaRef = db.collection('wellness_routes').doc(ROUTE_ID);

  const ruta = await rutaRef.get();
  if (!ruta.exists) {
    throw new Error(`La ruta ${ROUTE_ID} no existe en Firestore. Abortado.`);
  }

  console.log('\nEscribiendo...');
  for (const lec of LECCIONES) {
    const lecRef = rutaRef.collection('lessons').doc(lec.id);

    await lecRef.set(
      {
        title_es: lec.title_es,
        title_en: lec.title_en,
        subtitle_es: lec.subtitle_es,
        subtitle_en: lec.subtitle_en,
        xpReward: lec.xpReward,
        order: lec.order,
      },
      { merge: true },
    );

    // Los pasos viejos se borran: cambia la cantidad, mezclarlos duplicaría.
    const viejos = await lecRef.collection('steps').get();
    const batch = db.batch();
    viejos.forEach((d) => batch.delete(d.ref));
    lec.steps.forEach((paso, i) => {
      const { type, ...campos } = paso;
      batch.set(lecRef.collection('steps').doc(`step_${i}`), {
        type,
        order: i,
        ...campos,
      });
    });
    await batch.commit();

    console.log(`  ${lec.id}: ${viejos.size} pasos viejos → ${lec.steps.length} nuevos`);
  }

  console.log('\nListo.');
}

main()
  .then(() => process.exit(0))
  .catch((e) => {
    console.error('ERROR:', e.message);
    process.exit(1);
  });
