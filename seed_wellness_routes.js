// seed_wellness_routes.js
// ═══════════════════════════════════════════════════════════════
// Script para subir las rutas de bienestar a Firestore
// Ejecutar con: node seed_wellness_routes.js
// Requiere: npm install firebase-admin
// ═══════════════════════════════════════════════════════════════

const admin = require('firebase-admin');

// Inicializar Firebase Admin
// Opción 1: Con service account (descargar de Firebase Console > Project Settings > Service Accounts)
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

// Opción 2: Si estás en un entorno con credenciales configuradas
//admin.initializeApp({
  //projectId: 'lumen-app-5bcda',
//});

const db = admin.firestore();

const routes = [
  // ═══════════════════════════════════════════
  // RUTA 1: Manejo de Emociones
  // ═══════════════════════════════════════════
  {
    id: 'emociones',
    title_es: 'Manejo de Emociones',
    title_en: 'Emotion Management',
    description_es: 'Aprende a identificar y gestionar lo que sientes',
    description_en: 'Learn to identify and manage your feelings',
    emoji: '🎭',
    color: 0xFF6366F1,
    colorDark: 0xFF4338CA,
    order: 0,
    lessons: [
      {
        id: 'emo_1',
        title_es: '¿Qué son las emociones?',
        title_en: 'What are emotions?',
        subtitle_es: 'Las emociones son tu GPS interno',
        subtitle_en: 'Emotions are your internal GPS',
        xpReward: 15,
        order: 0,
        steps: [
          {
            type: 'reading',
            order: 0,
            title_es: 'Tu radar emocional',
            title_en: 'Your emotional radar',
            content_es: 'Las emociones son señales que tu cuerpo y mente envían para ayudarte a navegar la vida. No son buenas ni malas — son información.\n\nImagina que tus emociones son como el clima: a veces hay sol, a veces lluvia, pero ambos son necesarios.\n\nLa clave no es evitar sentir, sino aprender a escuchar lo que tus emociones te dicen.',
            content_en: 'Emotions are signals that your body and mind send to help you navigate life. They are neither good nor bad — they are information.\n\nImagine your emotions are like the weather: sometimes sunny, sometimes rainy, but both are necessary.\n\nThe key is not to avoid feeling, but to learn to listen to what your emotions tell you.',
          },
          {
            type: 'quiz',
            order: 1,
            title_es: '¿Las emociones negativas son malas?',
            title_en: 'Are negative emotions bad?',
            question_es: '¿Las emociones negativas son malas?',
            question_en: 'Are negative emotions bad?',
            options_es: ['Sí, hay que evitarlas siempre', 'No, todas las emociones son información útil', 'Solo algunas son útiles'],
            options_en: ['Yes, they should always be avoided', 'No, all emotions are useful information', 'Only some are useful'],
            correctIndex: 1,
            explanation_es: '¡Correcto! Todas las emociones cumplen una función. La tristeza nos ayuda a procesar pérdidas, el miedo nos protege, y el enojo nos indica que algo nos importa.',
            explanation_en: 'Correct! All emotions serve a purpose. Sadness helps us process losses, fear protects us, and anger tells us something matters to us.',
          },
          {
            type: 'exercise',
            order: 2,
            title_es: 'Nombra tu emoción',
            title_en: 'Name your emotion',
            instruction_es: 'Cierra los ojos por 10 segundos. ¿Qué emoción sientes ahora mismo? Escríbela junto con dónde la sientes en tu cuerpo.',
            instruction_en: 'Close your eyes for 10 seconds. What emotion do you feel right now? Write it down along with where you feel it in your body.',
            placeholder_es: 'Ej: Siento curiosidad, la siento como energía en el pecho...',
            placeholder_en: 'E.g.: I feel curiosity, I feel it as energy in my chest...',
          },
        ],
      },
      {
        id: 'emo_2',
        title_es: 'La rueda emocional',
        title_en: 'The emotion wheel',
        subtitle_es: 'Amplía tu vocabulario emocional',
        subtitle_en: 'Expand your emotional vocabulary',
        xpReward: 15,
        order: 1,
        steps: [
          {
            type: 'reading',
            order: 0,
            title_es: 'Más allá de "bien" o "mal"',
            title_en: 'Beyond "fine" or "bad"',
            content_es: 'La mayoría de personas solo usan 3-4 palabras para describir cómo se sienten: bien, mal, regular, cansado.\n\nPero existen más de 30 emociones distintas. Cuanto más preciso seas al nombrar lo que sientes, mejor podrás manejarlo.\n\nEsto se llama "granularidad emocional" y está científicamente demostrado que mejora tu bienestar.',
            content_en: 'Most people only use 3-4 words to describe how they feel: fine, bad, okay, tired.\n\nBut there are over 30 distinct emotions. The more precise you are at naming what you feel, the better you can manage it.\n\nThis is called "emotional granularity" and it is scientifically proven to improve your wellbeing.',
          },
          {
            type: 'quiz',
            order: 1,
            title_es: '¿Qué es la granularidad emocional?',
            title_en: 'What is emotional granularity?',
            question_es: '¿Qué es la granularidad emocional?',
            question_en: 'What is emotional granularity?',
            options_es: ['Sentir muchas emociones a la vez', 'La capacidad de nombrar emociones con precisión', 'No sentir nada'],
            options_en: ['Feeling many emotions at once', 'The ability to name emotions precisely', 'Not feeling anything'],
            correctIndex: 1,
            explanation_es: 'La granularidad emocional es poder distinguir entre "estoy frustrado" y "estoy decepcionado". Esta precisión te da más herramientas para responder adecuadamente.',
            explanation_en: 'Emotional granularity is being able to distinguish between "I\'m frustrated" and "I\'m disappointed." This precision gives you more tools to respond appropriately.',
          },
          {
            type: 'exercise',
            order: 2,
            title_es: 'Expande tu vocabulario',
            title_en: 'Expand your vocabulary',
            instruction_es: 'Piensa en tu día de hoy. En vez de "bien" o "mal", intenta usar al menos 3 palabras diferentes para describir cómo te sentiste en distintos momentos.',
            instruction_en: 'Think about your day today. Instead of "fine" or "bad," try to use at least 3 different words to describe how you felt at different moments.',
            placeholder_es: 'Ej: En la mañana me sentí motivado, a mediodía un poco abrumado, y ahora siento tranquilidad...',
            placeholder_en: 'E.g.: In the morning I felt motivated, at noon a bit overwhelmed, and now I feel calm...',
          },
        ],
      },
      {
        id: 'emo_3',
        title_es: 'Emociones en el cuerpo',
        title_en: 'Emotions in the body',
        subtitle_es: 'Tu cuerpo habla, aprende a escucharlo',
        subtitle_en: 'Your body speaks, learn to listen',
        xpReward: 20,
        order: 2,
        steps: [
          {
            type: 'reading',
            order: 0,
            title_es: 'El mapa corporal',
            title_en: 'The body map',
            content_es: 'Cada emoción se manifiesta físicamente. La ansiedad puede sentirse como un nudo en el estómago, la alegría como ligereza en el pecho, y el enojo como tensión en la mandíbula.\n\nReconocer estas señales corporales te ayuda a identificar tus emociones antes de que te abrumen.\n\nEs como tener un sistema de alerta temprana.',
            content_en: 'Every emotion manifests physically. Anxiety can feel like a knot in the stomach, joy like lightness in the chest, and anger like tension in the jaw.\n\nRecognizing these bodily signals helps you identify your emotions before they overwhelm you.\n\nIt\'s like having an early warning system.',
          },
          {
            type: 'quiz',
            order: 1,
            title_es: '¿Dónde suele manifestarse la ansiedad en el cuerpo?',
            title_en: 'Where does anxiety usually manifest in the body?',
            question_es: '¿Dónde suele manifestarse la ansiedad en el cuerpo?',
            question_en: 'Where does anxiety usually manifest in the body?',
            options_es: ['En los pies', 'En el estómago y el pecho', 'Solo en la cabeza'],
            options_en: ['In the feet', 'In the stomach and chest', 'Only in the head'],
            correctIndex: 1,
            explanation_es: 'La ansiedad frecuentemente se siente como un nudo en el estómago, opresión en el pecho, o tensión en los hombros. Cada persona puede experimentarlo diferente.',
            explanation_en: 'Anxiety frequently feels like a knot in the stomach, tightness in the chest, or tension in the shoulders. Each person may experience it differently.',
          },
          {
            type: 'exercise',
            order: 2,
            title_es: 'Escaneo corporal rápido',
            title_en: 'Quick body scan',
            instruction_es: 'Haz un recorrido mental de tu cuerpo de pies a cabeza. ¿Dónde sientes tensión? ¿Dónde hay comodidad? Describe lo que encuentres.',
            instruction_en: 'Do a mental scan of your body from feet to head. Where do you feel tension? Where is there comfort? Describe what you find.',
            placeholder_es: 'Ej: Siento los hombros tensos, las manos relajadas, un poco de presión en la frente...',
            placeholder_en: 'E.g.: I feel my shoulders tense, my hands relaxed, a little pressure on my forehead...',
          },
        ],
      },
      {
        id: 'emo_4',
        title_es: 'Técnica STOP',
        title_en: 'STOP Technique',
        subtitle_es: 'Pausa antes de reaccionar',
        subtitle_en: 'Pause before reacting',
        xpReward: 20,
        order: 3,
        steps: [
          {
            type: 'reading',
            order: 0,
            title_es: 'S-T-O-P',
            title_en: 'S-T-O-P',
            content_es: 'Cuando una emoción fuerte te invade, usa la técnica STOP:\n\nS - Stop (Para): Detén lo que estés haciendo.\nT - Take a breath (Respira): Haz 3 respiraciones profundas.\nO - Observe (Observa): ¿Qué sientes? ¿Qué piensas?\nP - Proceed (Procede): Ahora decide cómo actuar conscientemente.\n\nEste espacio de 30 segundos puede cambiar completamente tu respuesta.',
            content_en: 'When a strong emotion overwhelms you, use the STOP technique:\n\nS - Stop: Pause whatever you\'re doing.\nT - Take a breath: Take 3 deep breaths.\nO - Observe: What do you feel? What are you thinking?\nP - Proceed: Now decide how to act consciously.\n\nThis 30-second pause can completely change your response.',
          },
          {
            type: 'quiz',
            order: 1,
            title_es: '¿Cuál es el primer paso de la técnica STOP?',
            title_en: 'What is the first step of the STOP technique?',
            question_es: '¿Cuál es el primer paso de la técnica STOP?',
            question_en: 'What is the first step of the STOP technique?',
            options_es: ['Respirar profundo', 'Detenerte por completo', 'Observar tus pensamientos'],
            options_en: ['Take a deep breath', 'Stop completely', 'Observe your thoughts'],
            correctIndex: 1,
            explanation_es: 'El primer paso es PARAR. Detener cualquier acción automática es fundamental antes de poder respirar, observar y decidir conscientemente.',
            explanation_en: 'The first step is to STOP. Stopping any automatic action is essential before you can breathe, observe, and decide consciously.',
          },
          {
            type: 'exercise',
            order: 2,
            title_es: 'Practica STOP',
            title_en: 'Practice STOP',
            instruction_es: 'Piensa en una situación reciente donde reaccionaste impulsivamente. ¿Cómo habrías respondido si hubieras usado la técnica STOP? Describe la diferencia.',
            instruction_en: 'Think of a recent situation where you reacted impulsively. How would you have responded if you had used the STOP technique? Describe the difference.',
            placeholder_es: 'Ej: Cuando mi compañero me interrumpió, grité. Con STOP habría respirado y dicho calmadamente que necesitaba terminar de hablar...',
            placeholder_en: 'E.g.: When my coworker interrupted me, I yelled. With STOP I would have breathed and calmly said I needed to finish talking...',
          },
        ],
      },
      {
        id: 'emo_5',
        title_es: 'Regulación emocional',
        title_en: 'Emotional regulation',
        subtitle_es: 'Herramientas para el día a día',
        subtitle_en: 'Daily tools',
        xpReward: 25,
        order: 4,
        steps: [
          {
            type: 'reading',
            order: 0,
            title_es: 'Tu caja de herramientas',
            title_en: 'Your toolbox',
            content_es: 'Regular tus emociones no significa suprimirlas. Significa tener estrategias para manejar su intensidad.\n\nAlgunas herramientas probadas:\n• Respiración 4-7-8 para calmar la ansiedad\n• Movimiento físico para liberar enojo\n• Escribir para procesar tristeza\n• Hablar con alguien para sentirte menos solo\n• Música para cambiar tu estado emocional\n\nLa clave es tener varias opciones y saber cuál usar en cada momento.',
            content_en: 'Regulating your emotions doesn\'t mean suppressing them. It means having strategies to manage their intensity.\n\nSome proven tools:\n• 4-7-8 breathing to calm anxiety\n• Physical movement to release anger\n• Writing to process sadness\n• Talking to someone to feel less alone\n• Music to change your emotional state\n\nThe key is having several options and knowing which to use at each moment.',
          },
          {
            type: 'quiz',
            order: 1,
            title_es: '¿Qué significa regular las emociones?',
            title_en: 'What does regulating emotions mean?',
            question_es: '¿Qué significa regular las emociones?',
            question_en: 'What does regulating emotions mean?',
            options_es: ['No sentir nada', 'Manejar la intensidad sin suprimirlas', 'Solo sentir emociones positivas'],
            options_en: ['Not feeling anything', 'Managing intensity without suppressing them', 'Only feeling positive emotions'],
            correctIndex: 1,
            explanation_es: 'Regular emociones es manejar su intensidad y duración, no eliminarlas. Es como bajar el volumen de la música: sigue sonando, pero a un nivel manejable.',
            explanation_en: 'Regulating emotions is managing their intensity and duration, not eliminating them. It\'s like turning down the volume: the music still plays, but at a manageable level.',
          },
          {
            type: 'exercise',
            order: 2,
            title_es: 'Tu kit personal',
            title_en: 'Your personal kit',
            instruction_es: 'Crea tu kit de regulación emocional. Para cada emoción difícil, escribe una herramienta que te funcione.',
            instruction_en: 'Create your emotional regulation kit. For each difficult emotion, write a tool that works for you.',
            placeholder_es: 'Ej: Ansiedad → respirar. Enojo → caminar. Tristeza → escribir. Estrés → música...',
            placeholder_en: 'E.g.: Anxiety → breathe. Anger → walk. Sadness → write. Stress → music...',
          },
        ],
      },
    ],
  },

  // ═══════════════════════════════════════════
  // RUTA 2: Autoconocimiento
  // ═══════════════════════════════════════════
  {
    id: 'autoconocimiento',
    title_es: 'Autoconocimiento',
    title_en: 'Self-Knowledge',
    description_es: 'Descubre quién eres realmente',
    description_en: 'Discover who you really are',
    emoji: '🔍',
    color: 0xFF10B981,
    colorDark: 0xFF059669,
    order: 1,
    lessons: [
      {
        id: 'auto_1', title_es: 'Tus valores', title_en: 'Your values',
        subtitle_es: '¿Qué es importante para ti?', subtitle_en: 'What is important to you?',
        xpReward: 15, order: 0,
        steps: [
          { type: 'reading', order: 0, title_es: 'La brújula interior', title_en: 'The inner compass',
            content_es: 'Tus valores son los principios que guían tu vida. Cuando actúas alineado con tus valores, sientes satisfacción. Cuando los ignoras, sientes vacío o frustración.\n\nAlgunos valores comunes: honestidad, familia, libertad, creatividad, justicia, aventura, seguridad, crecimiento.\n\nNo hay valores correctos o incorrectos — solo los tuyos.',
            content_en: 'Your values are the principles that guide your life. When you act aligned with your values, you feel satisfaction. When you ignore them, you feel empty or frustrated.\n\nSome common values: honesty, family, freedom, creativity, justice, adventure, security, growth.\n\nThere are no right or wrong values — only yours.' },
          { type: 'quiz', order: 1, title_es: '¿Qué pasa cuando vives alineado con tus valores?', title_en: 'What happens when you live aligned with your values?',
            question_es: '¿Qué pasa cuando vives alineado con tus valores?', question_en: 'What happens when you live aligned with your values?',
            options_es: ['Nada especial', 'Sientes satisfacción y propósito', 'Te vuelves perfecto'],
            options_en: ['Nothing special', 'You feel satisfaction and purpose', 'You become perfect'],
            correctIndex: 1,
            explanation_es: 'Vivir alineado con tus valores genera un sentido de autenticidad y satisfacción profunda.',
            explanation_en: 'Living aligned with your values generates a sense of authenticity and deep satisfaction.' },
          { type: 'exercise', order: 2, title_es: 'Identifica tus 5 valores', title_en: 'Identify your 5 values',
            instruction_es: 'De la siguiente lista, elige los 5 que más resuenan contigo y ordénalos: honestidad, familia, libertad, creatividad, justicia, aventura, seguridad, crecimiento, amor, salud, éxito, generosidad.',
            instruction_en: 'From the following list, choose the 5 that resonate most with you and rank them: honesty, family, freedom, creativity, justice, adventure, security, growth, love, health, success, generosity.',
            placeholder_es: 'Mis 5 valores principales son: 1...', placeholder_en: 'My 5 main values are: 1...' },
        ],
      },
      {
        id: 'auto_2', title_es: 'Fortalezas personales', title_en: 'Personal strengths',
        subtitle_es: 'Lo que te hace único', subtitle_en: 'What makes you unique',
        xpReward: 15, order: 1,
        steps: [
          { type: 'reading', order: 0, title_es: 'Tus superpoderes', title_en: 'Your superpowers',
            content_es: 'Todos tenemos fortalezas naturales — cosas que hacemos bien sin esfuerzo excesivo. Pueden ser habilidades sociales, creatividad, perseverancia, humor, empatía, liderazgo, o pensamiento analítico.\n\nConocer tus fortalezas te permite usarlas estratégicamente y confiar más en ti mismo.',
            content_en: 'We all have natural strengths — things we do well without excessive effort. They can be social skills, creativity, perseverance, humor, empathy, leadership, or analytical thinking.\n\nKnowing your strengths allows you to use them strategically and trust yourself more.' },
          { type: 'quiz', order: 1, title_es: '¿Cómo identificas una fortaleza personal?', title_en: 'How do you identify a personal strength?',
            question_es: '¿Cómo identificas una fortaleza personal?', question_en: 'How do you identify a personal strength?',
            options_es: ['Es algo que te cuesta mucho', 'Es algo que haces bien naturalmente', 'Es algo que otros hacen'],
            options_en: ['It\'s something very difficult for you', 'It\'s something you do well naturally', 'It\'s something others do'],
            correctIndex: 1,
            explanation_es: 'Las fortalezas son habilidades que ejercitas con facilidad y que, al usarlas, te energizan en vez de agotarte.',
            explanation_en: 'Strengths are skills you exercise with ease and that energize you rather than drain you when used.' },
          { type: 'exercise', order: 2, title_es: 'Mapa de fortalezas', title_en: 'Strengths map',
            instruction_es: 'Escribe 3 cosas que haces bien y que disfrutas hacer. Pregunta a alguien cercano qué creen que son tus fortalezas.',
            instruction_en: 'Write 3 things you do well and enjoy doing. Ask someone close what they think your strengths are.',
            placeholder_es: 'Mis fortalezas: 1...', placeholder_en: 'My strengths: 1...' },
        ],
      },
      {
        id: 'auto_3', title_es: 'Patrones de pensamiento', title_en: 'Thought patterns',
        subtitle_es: 'Identifica tus narrativas', subtitle_en: 'Identify your narratives',
        xpReward: 20, order: 2,
        steps: [
          { type: 'reading', order: 0, title_es: 'Las historias que te cuentas', title_en: 'The stories you tell yourself',
            content_es: 'Tu mente genera pensamientos automáticos constantemente. Algunos son útiles, otros son distorsiones que afectan cómo te sientes.\n\nDistorsiones comunes:\n• Todo o nada: "Si no es perfecto, es un fracaso"\n• Catastrofizar: "Seguro va a salir mal"\n• Lectura mental: "Seguro piensa mal de mí"\n\nReconocer estos patrones es el primer paso para cambiarlos.',
            content_en: 'Your mind constantly generates automatic thoughts. Some are useful, others are distortions that affect how you feel.\n\nCommon distortions:\n• All or nothing: "If it\'s not perfect, it\'s a failure"\n• Catastrophizing: "It\'s surely going to go wrong"\n• Mind reading: "They surely think badly of me"\n\nRecognizing these patterns is the first step to changing them.' },
          { type: 'quiz', order: 1, title_es: '"Si no saco 10, soy un fracaso" es un ejemplo de:', title_en: '"If I don\'t get an A, I\'m a failure" is an example of:',
            question_es: '"Si no saco 10, soy un fracaso" es un ejemplo de:', question_en: '"If I don\'t get an A, I\'m a failure" is an example of:',
            options_es: ['Pensamiento realista', 'Pensamiento todo o nada', 'Pensamiento positivo'],
            options_en: ['Realistic thinking', 'All-or-nothing thinking', 'Positive thinking'],
            correctIndex: 1,
            explanation_es: 'El pensamiento "todo o nada" no reconoce matices. Un 8 no es un fracaso, es un buen resultado.',
            explanation_en: 'All-or-nothing thinking doesn\'t recognize nuances. A B+ is not a failure, it\'s a good result.' },
          { type: 'exercise', order: 2, title_es: 'Atrapa un pensamiento', title_en: 'Catch a thought',
            instruction_es: 'Escribe un pensamiento negativo recurrente que tengas. Luego escribe una versión más equilibrada y realista.',
            instruction_en: 'Write a recurring negative thought you have. Then write a more balanced and realistic version.',
            placeholder_es: 'Pensamiento: "Nunca hago nada bien"\nVersión equilibrada: "A veces cometo errores, pero también hago muchas cosas bien"',
            placeholder_en: 'Thought: "I never do anything right"\nBalanced version: "Sometimes I make mistakes, but I also do many things well"' },
        ],
      },
    ],
  },

  // Rutas 3-7 (formato compacto)
  {
    id: 'mindfulness', title_es: 'Mindfulness', title_en: 'Mindfulness',
    description_es: 'Vive el presente con atención plena', description_en: 'Live in the present with full awareness',
    emoji: '🧘', color: 0xFF3B82F6, colorDark: 0xFF1D4ED8, order: 2,
    lessons: [
      { id: 'mind_1', title_es: '¿Qué es mindfulness?', title_en: 'What is mindfulness?', subtitle_es: 'Atención al momento presente', subtitle_en: 'Attention to the present moment', xpReward: 15, order: 0, steps: [
        { type: 'reading', order: 0, title_es: 'Estar aquí y ahora', title_en: 'Being here and now', content_es: 'Mindfulness es prestar atención al momento presente sin juzgar. Suena simple, pero la mente tiende a viajar al pasado (culpa) o al futuro (ansiedad).\n\nPracticar mindfulness no requiere meditar horas. Puede ser tan simple como notar el sabor de tu comida o sentir tus pies en el suelo.', content_en: 'Mindfulness is paying attention to the present moment without judgment. It sounds simple, but the mind tends to travel to the past (guilt) or the future (anxiety).\n\nPracticing mindfulness doesn\'t require hours of meditation. It can be as simple as noticing the taste of your food or feeling your feet on the ground.' },
        { type: 'quiz', order: 1, title_es: '¿Qué es mindfulness?', title_en: 'What is mindfulness?', question_es: '¿Qué es mindfulness?', question_en: 'What is mindfulness?', options_es: ['No pensar en nada', 'Atención al presente sin juzgar', 'Solo meditar sentado'], options_en: ['Not thinking about anything', 'Attention to the present without judging', 'Only meditating while seated'], correctIndex: 1, explanation_es: 'Mindfulness es atención consciente al presente. No se trata de vaciar la mente, sino de observar sin juzgar.', explanation_en: 'Mindfulness is conscious attention to the present. It\'s not about emptying the mind, but observing without judgment.' },
        { type: 'exercise', order: 2, title_es: 'Minuto mindful', title_en: 'Mindful minute', instruction_es: 'Durante 60 segundos, enfócate solo en tu respiración. Cada vez que tu mente se distraiga, gentilmente regresa a la respiración. ¿Cuántas veces se distrajo tu mente?', instruction_en: 'For 60 seconds, focus only on your breathing. Every time your mind wanders, gently return to the breath. How many times did your mind wander?', placeholder_es: 'Mi mente se distrajo unas... veces. Me di cuenta de que...', placeholder_en: 'My mind wandered about... times. I realized that...' },
      ]},
      { id: 'mind_2', title_es: 'Respiración consciente', title_en: 'Conscious breathing', subtitle_es: 'Tu ancla al presente', subtitle_en: 'Your anchor to the present', xpReward: 15, order: 1, steps: [
        { type: 'reading', order: 0, title_es: 'El poder de respirar', title_en: 'The power of breathing', content_es: 'La respiración es la única función del cuerpo que es automática y voluntaria. Esto la convierte en un puente perfecto entre tu mente consciente y tu sistema nervioso.\n\nRespirar lento y profundo activa tu sistema parasimpático (calma), mientras que respirar rápido activa el simpático (alerta).', content_en: 'Breathing is the only body function that is both automatic and voluntary. This makes it a perfect bridge between your conscious mind and nervous system.\n\nSlow, deep breathing activates your parasympathetic system (calm), while fast breathing activates the sympathetic system (alert).' },
        { type: 'quiz', order: 1, title_es: '¿Qué efecto tiene la respiración lenta y profunda?', title_en: 'What effect does slow, deep breathing have?', question_es: '¿Qué efecto tiene la respiración lenta y profunda?', question_en: 'What effect does slow, deep breathing have?', options_es: ['Te da más energía', 'Activa la calma (sistema parasimpático)', 'No tiene efecto'], options_en: ['Gives you more energy', 'Activates calm (parasympathetic system)', 'Has no effect'], correctIndex: 1, explanation_es: 'La respiración lenta envía señales de seguridad a tu cerebro, reduciendo cortisol y activando la relajación.', explanation_en: 'Slow breathing sends safety signals to your brain, reducing cortisol and activating relaxation.' },
        { type: 'exercise', order: 2, title_es: 'Respiración 4-7-8', title_en: '4-7-8 Breathing', instruction_es: 'Prueba la técnica 4-7-8:\n1. Inhala por la nariz contando hasta 4\n2. Sostén la respiración contando hasta 7\n3. Exhala por la boca contando hasta 8\n\nRepite 4 veces. ¿Cómo te sientes después?', instruction_en: 'Try the 4-7-8 technique:\n1. Inhale through nose counting to 4\n2. Hold breath counting to 7\n3. Exhale through mouth counting to 8\n\nRepeat 4 times. How do you feel after?', placeholder_es: 'Después de la respiración me siento...', placeholder_en: 'After the breathing I feel...' },
      ]},
      { id: 'mind_3', title_es: 'Comer con atención', title_en: 'Mindful eating', subtitle_es: 'Mindfulness en lo cotidiano', subtitle_en: 'Mindfulness in daily life', xpReward: 20, order: 2, steps: [
        { type: 'reading', order: 0, title_es: 'Más allá de la meditación', title_en: 'Beyond meditation', content_es: 'El mindfulness no se limita a meditar. Puedes practicarlo en cualquier actividad diaria.\n\nComer con atención significa notar colores, texturas, sabores y aromas de tu comida. Masticar despacio. Disfrutar cada bocado.\n\nEsto no solo mejora tu relación con la comida, sino que entrena tu capacidad de estar presente.', content_en: 'Mindfulness isn\'t limited to meditation. You can practice it in any daily activity.\n\nMindful eating means noticing colors, textures, flavors and aromas of your food. Chewing slowly. Enjoying each bite.\n\nThis not only improves your relationship with food but trains your ability to be present.' },
        { type: 'quiz', order: 1, title_es: '¿Solo se puede practicar mindfulness meditando?', title_en: 'Can mindfulness only be practiced through meditation?', question_es: '¿Solo se puede practicar mindfulness meditando?', question_en: 'Can mindfulness only be practiced through meditation?', options_es: ['Sí, solo sentado en silencio', 'No, se puede practicar en cualquier actividad', 'Solo con un instructor'], options_en: ['Yes, only sitting in silence', 'No, it can be practiced in any activity', 'Only with an instructor'], correctIndex: 1, explanation_es: 'Cualquier actividad puede convertirse en práctica de mindfulness: comer, caminar, ducharte, incluso lavar los platos.', explanation_en: 'Any activity can become mindfulness practice: eating, walking, showering, even washing dishes.' },
        { type: 'exercise', order: 2, title_es: 'Próxima comida mindful', title_en: 'Next mindful meal', instruction_es: 'En tu próxima comida, dedica los primeros 5 bocados a comer con total atención. Sin celular, sin TV. Nota sabores, texturas y temperaturas. Describe la experiencia.', instruction_en: 'At your next meal, dedicate the first 5 bites to eating with full attention. No phone, no TV. Notice flavors, textures and temperatures. Describe the experience.', placeholder_es: 'Noté que...', placeholder_en: 'I noticed that...' },
      ]},
    ],
  },
  {
    id: 'resiliencia', title_es: 'Resiliencia', title_en: 'Resilience',
    description_es: 'Fortalece tu capacidad de superar adversidades', description_en: 'Strengthen your ability to overcome adversity',
    emoji: '💪', color: 0xFFEF4444, colorDark: 0xFFDC2626, order: 3,
    lessons: [
      { id: 'res_1', title_es: '¿Qué es la resiliencia?', title_en: 'What is resilience?', subtitle_es: 'Más que resistir, es crecer', subtitle_en: 'More than enduring, it\'s growing', xpReward: 15, order: 0, steps: [
        { type: 'reading', order: 0, title_es: 'Bambú, no roble', title_en: 'Bamboo, not oak', content_es: 'La resiliencia no es ser fuerte como un roble que no se mueve. Es ser flexible como el bambú: se dobla con el viento pero no se rompe.\n\nLas personas resilientes no evitan el dolor — lo atraviesan y salen transformadas.\n\nLa buena noticia: la resiliencia se puede desarrollar, no es un rasgo fijo.', content_en: 'Resilience isn\'t being strong like an oak that doesn\'t move. It\'s being flexible like bamboo: it bends with the wind but doesn\'t break.\n\nResilient people don\'t avoid pain — they go through it and emerge transformed.\n\nThe good news: resilience can be developed, it\'s not a fixed trait.' },
        { type: 'quiz', order: 1, title_es: '¿Qué significa ser resiliente?', title_en: 'What does it mean to be resilient?', question_es: '¿Qué significa ser resiliente?', question_en: 'What does it mean to be resilient?', options_es: ['No sentir dolor nunca', 'Adaptarse y crecer ante la adversidad', 'Ser siempre positivo'], options_en: ['Never feeling pain', 'Adapting and growing in the face of adversity', 'Always being positive'], correctIndex: 1, explanation_es: 'La resiliencia es la capacidad de adaptarte, recuperarte y crecer después de situaciones difíciles.', explanation_en: 'Resilience is the ability to adapt, recover and grow after difficult situations.' },
        { type: 'exercise', order: 2, title_es: 'Tu historia de resiliencia', title_en: 'Your resilience story', instruction_es: 'Piensa en un momento difícil que superaste. ¿Qué aprendiste? ¿Cómo te hizo más fuerte?', instruction_en: 'Think of a difficult moment you overcame. What did you learn? How did it make you stronger?', placeholder_es: 'Una vez superé...', placeholder_en: 'I once overcame...' },
      ]},
      { id: 'res_2', title_es: 'Mentalidad de crecimiento', title_en: 'Growth mindset', subtitle_es: 'Los errores son maestros', subtitle_en: 'Mistakes are teachers', xpReward: 15, order: 1, steps: [
        { type: 'reading', order: 0, title_es: 'Todavía no', title_en: 'Not yet', content_es: 'Carol Dweck descubrió que hay dos mentalidades:\n\n• Fija: "No soy bueno en esto" (se rinde)\n• De crecimiento: "Todavía no soy bueno en esto" (sigue intentando)\n\nLa diferencia de una sola palabra — "todavía" — cambia todo tu enfoque ante los retos.', content_en: 'Carol Dweck discovered there are two mindsets:\n\n• Fixed: "I\'m not good at this" (gives up)\n• Growth: "I\'m not good at this yet" (keeps trying)\n\nThe difference of a single word — "yet" — changes your entire approach to challenges.' },
        { type: 'quiz', order: 1, title_es: '"No puedo hacer esto" vs "Todavía no puedo hacer esto". ¿Cuál refleja mentalidad de crecimiento?', title_en: '"I can\'t do this" vs "I can\'t do this yet." Which reflects a growth mindset?', question_es: '"No puedo hacer esto" vs "Todavía no puedo hacer esto". ¿Cuál refleja mentalidad de crecimiento?', question_en: '"I can\'t do this" vs "I can\'t do this yet." Which reflects a growth mindset?', options_es: ['La primera', 'La segunda', 'Las dos son iguales'], options_en: ['The first', 'The second', 'Both are the same'], correctIndex: 1, explanation_es: '"Todavía no" implica que puedes aprender y mejorar. Es la base de la mentalidad de crecimiento.', explanation_en: '"Not yet" implies you can learn and improve. It\'s the foundation of a growth mindset.' },
        { type: 'exercise', order: 2, title_es: 'Transforma tus "no puedo"', title_en: 'Transform your "I can\'t"', instruction_es: 'Escribe 3 cosas que crees que "no puedes hacer" y agrégales "todavía".', instruction_en: 'Write 3 things you believe you "can\'t do" and add "yet" to them.', placeholder_es: '1. No puedo... todavía\n2. No sé... todavía\n3. No logro... todavía', placeholder_en: '1. I can\'t... yet\n2. I don\'t know how to... yet\n3. I haven\'t achieved... yet' },
      ]},
    ],
  },
  {
    id: 'autoestima', title_es: 'Autoestima', title_en: 'Self-Esteem',
    description_es: 'Construye una relación sana contigo mismo', description_en: 'Build a healthy relationship with yourself',
    emoji: '⭐', color: 0xFFF59E0B, colorDark: 0xFFD97706, order: 4,
    lessons: [
      { id: 'est_1', title_es: 'Tu diálogo interno', title_en: 'Your inner dialogue', subtitle_es: '¿Cómo te hablas a ti mismo?', subtitle_en: 'How do you talk to yourself?', xpReward: 15, order: 0, steps: [
        { type: 'reading', order: 0, title_es: 'La voz interior', title_en: 'The inner voice', content_es: 'La persona con la que más hablas en tu vida eres tú mismo. Ese diálogo interno influye enormemente en cómo te sientes.\n\nSi tu voz interior es constantemente crítica ("eres un desastre", "no sirves"), tu autoestima se erosiona.\n\nLa autocompasión es tratarte con la misma amabilidad que tratarías a un buen amigo.', content_en: 'The person you talk to most in your life is yourself. That inner dialogue enormously influences how you feel.\n\nIf your inner voice is constantly critical ("you\'re a disaster", "you\'re worthless"), your self-esteem erodes.\n\nSelf-compassion is treating yourself with the same kindness you would show a good friend.' },
        { type: 'quiz', order: 1, title_es: '¿Qué es la autocompasión?', title_en: 'What is self-compassion?', question_es: '¿Qué es la autocompasión?', question_en: 'What is self-compassion?', options_es: ['Sentir lástima por ti mismo', 'Tratarte con la misma amabilidad que a un amigo', 'No tener autocrítica nunca'], options_en: ['Feeling sorry for yourself', 'Treating yourself with the same kindness as a friend', 'Never being self-critical'], correctIndex: 1, explanation_es: 'La autocompasión es reconocer tu sufrimiento sin juzgarte, y tratarte con gentileza y comprensión.', explanation_en: 'Self-compassion is recognizing your suffering without judging yourself, and treating yourself with kindness and understanding.' },
        { type: 'exercise', order: 2, title_es: 'Carta a ti mismo', title_en: 'Letter to yourself', instruction_es: 'Escríbete una carta breve como si le escribieras a tu mejor amigo que está pasando por lo que tú estás pasando ahora.', instruction_en: 'Write yourself a brief letter as if you were writing to your best friend going through what you\'re going through now.', placeholder_es: 'Querido yo: Sé que estás pasando por...', placeholder_en: 'Dear me: I know you\'re going through...' },
      ]},
      { id: 'est_2', title_es: 'Celebra tus logros', title_en: 'Celebrate your achievements', subtitle_es: 'Lo que has construido importa', subtitle_en: 'What you\'ve built matters', xpReward: 15, order: 1, steps: [
        { type: 'reading', order: 0, title_es: 'El sesgo de lo negativo', title_en: 'The negativity bias', content_es: 'El cerebro humano tiene un sesgo natural hacia lo negativo: recuerdas más los fracasos que los éxitos, más las críticas que los elogios.\n\nPara contrarrestar esto, necesitas practicar intencionalmente el reconocimiento de tus logros, por pequeños que sean.\n\nCompletaste esta lección? Eso ya es un logro.', content_en: 'The human brain has a natural negativity bias: you remember failures more than successes, criticism more than praise.\n\nTo counteract this, you need to intentionally practice recognizing your achievements, no matter how small.\n\nDid you complete this lesson? That\'s already an achievement.' },
        { type: 'quiz', order: 1, title_es: '¿Por qué recordamos más lo negativo?', title_en: 'Why do we remember negative things more?', question_es: '¿Por qué recordamos más lo negativo?', question_en: 'Why do we remember negative things more?', options_es: ['Porque somos pesimistas', 'Por un sesgo evolutivo del cerebro', 'Porque lo positivo no importa'], options_en: ['Because we\'re pessimists', 'Due to an evolutionary brain bias', 'Because positive things don\'t matter'], correctIndex: 1, explanation_es: 'El sesgo de negatividad es evolutivo: nuestros ancestros sobrevivían prestando más atención a amenazas. Hoy, necesitamos compensar conscientemente.', explanation_en: 'The negativity bias is evolutionary: our ancestors survived by paying more attention to threats. Today, we need to consciously compensate.' },
        { type: 'exercise', order: 2, title_es: '5 logros recientes', title_en: '5 recent achievements', instruction_es: 'Escribe 5 cosas que hayas logrado recientemente, por pequeñas que sean. Pueden ser desde levantarte temprano hasta completar un proyecto.', instruction_en: 'Write 5 things you\'ve achieved recently, no matter how small. They can range from getting up early to completing a project.', placeholder_es: '1. Logré...\n2. Completé...\n3. Mejoré en...', placeholder_en: '1. I achieved...\n2. I completed...\n3. I improved at...' },
      ]},
    ],
  },
  {
    id: 'relaciones', title_es: 'Relaciones Saludables', title_en: 'Healthy Relationships',
    description_es: 'Conecta mejor con los demás', description_en: 'Connect better with others',
    emoji: '🤝', color: 0xFFEC4899, colorDark: 0xFFDB2777, order: 5,
    lessons: [
      { id: 'rel_1', title_es: 'Comunicación asertiva', title_en: 'Assertive communication', subtitle_es: 'Di lo que sientes sin herir', subtitle_en: 'Say what you feel without hurting', xpReward: 15, order: 0, steps: [
        { type: 'reading', order: 0, title_es: 'El arte de comunicar', title_en: 'The art of communication', content_es: 'La comunicación asertiva es expresar tus necesidades y sentimientos de forma clara y respetuosa, sin ser agresivo ni pasivo.\n\nFórmula asertiva:\n"Cuando [situación], me siento [emoción], y necesito [petición]."\n\nEjemplo: "Cuando llegas tarde sin avisar, me siento preocupado, y necesito que me envíes un mensaje."', content_en: 'Assertive communication is expressing your needs and feelings clearly and respectfully, without being aggressive or passive.\n\nAssertive formula:\n"When [situation], I feel [emotion], and I need [request]."\n\nExample: "When you arrive late without notice, I feel worried, and I need you to send me a message."' },
        { type: 'quiz', order: 1, title_es: '¿Cuál es una respuesta asertiva?', title_en: 'Which is an assertive response?', question_es: '¿Cuál es una respuesta asertiva?', question_en: 'Which is an assertive response?', options_es: ['"Nunca me escuchas, eres imposible"', '"Está bien, no importa" (aunque sí importa)', '"Cuando me interrumpes, me siento frustrado. ¿Podrías dejarme terminar?"'], options_en: ['"You never listen, you\'re impossible"', '"It\'s fine, it doesn\'t matter" (even though it does)', '"When you interrupt me, I feel frustrated. Could you let me finish?"'], correctIndex: 2, explanation_es: 'La tercera opción es asertiva: describe la situación, expresa el sentimiento y hace una petición clara sin atacar.', explanation_en: 'The third option is assertive: it describes the situation, expresses the feeling and makes a clear request without attacking.' },
        { type: 'exercise', order: 2, title_es: 'Practica la fórmula', title_en: 'Practice the formula', instruction_es: 'Piensa en una situación donde no expresaste lo que sentías. Usa la fórmula: "Cuando..., me siento..., necesito..."', instruction_en: 'Think of a situation where you didn\'t express what you felt. Use the formula: "When..., I feel..., I need..."', placeholder_es: 'Cuando... me siento... y necesito...', placeholder_en: 'When... I feel... and I need...' },
      ]},
      { id: 'rel_2', title_es: 'Escucha activa', title_en: 'Active listening', subtitle_es: 'Oír vs. escuchar', subtitle_en: 'Hearing vs. listening', xpReward: 15, order: 1, steps: [
        { type: 'reading', order: 0, title_es: 'Presencia total', title_en: 'Full presence', content_es: 'La mayoría del tiempo cuando alguien habla, estamos pensando en qué vamos a responder, no en lo que está diciendo.\n\nLa escucha activa significa:\n• Mantener contacto visual\n• No interrumpir\n• Reflejar: "Entonces lo que dices es..."\n• Preguntar para entender, no para juzgar', content_en: 'Most of the time when someone talks, we\'re thinking about what we\'re going to reply, not what they\'re saying.\n\nActive listening means:\n• Maintaining eye contact\n• Not interrupting\n• Reflecting: "So what you\'re saying is..."\n• Asking to understand, not to judge' },
        { type: 'quiz', order: 1, title_es: '¿Qué NO es escucha activa?', title_en: 'What is NOT active listening?', question_es: '¿Qué NO es escucha activa?', question_en: 'What is NOT active listening?', options_es: ['Mantener contacto visual', 'Pensar en tu respuesta mientras el otro habla', 'Parafrasear lo que dice el otro'], options_en: ['Maintaining eye contact', 'Thinking about your response while the other person talks', 'Paraphrasing what the other person says'], correctIndex: 1, explanation_es: 'Pensar en tu respuesta mientras el otro habla es oír, no escuchar. La escucha activa requiere tu atención completa.', explanation_en: 'Thinking about your response while someone else talks is hearing, not listening. Active listening requires your full attention.' },
        { type: 'exercise', order: 2, title_es: 'Escucha a alguien', title_en: 'Listen to someone', instruction_es: 'En tu próxima conversación, practica escucha activa por 5 minutos. No interrumpas, no des consejos, solo escucha y haz preguntas. ¿Cómo fue?', instruction_en: 'In your next conversation, practice active listening for 5 minutes. Don\'t interrupt, don\'t give advice, just listen and ask questions. How was it?', placeholder_es: 'Cuando practiqué escucha activa, noté que...', placeholder_en: 'When I practiced active listening, I noticed that...' },
      ]},
    ],
  },
  {
    id: 'amor', title_es: 'Amor y Conexión', title_en: 'Love and Connection',
    description_es: 'El amor en todas sus formas', description_en: 'Love in all its forms',
    emoji: '❤️', color: 0xFFF97316, colorDark: 0xFFEA580C, order: 6,
    lessons: [
      { id: 'amor_1', title_es: 'Los 5 lenguajes del amor', title_en: 'The 5 love languages', subtitle_es: '¿Cómo das y recibes amor?', subtitle_en: 'How do you give and receive love?', xpReward: 15, order: 0, steps: [
        { type: 'reading', order: 0, title_es: 'Habla su idioma', title_en: 'Speak their language', content_es: 'Gary Chapman identificó 5 formas en que las personas expresan y reciben amor:\n\n1. Palabras de afirmación ("Te quiero", "Estoy orgulloso de ti")\n2. Tiempo de calidad (atención plena, sin distracciones)\n3. Actos de servicio (hacer cosas por el otro)\n4. Regalos (detalles significativos)\n5. Contacto físico (abrazos, caricias)\n\nConflictos surgen cuando hablas un lenguaje diferente al de tu pareja o seres queridos.', content_en: 'Gary Chapman identified 5 ways people express and receive love:\n\n1. Words of affirmation ("I love you", "I\'m proud of you")\n2. Quality time (full attention, no distractions)\n3. Acts of service (doing things for the other person)\n4. Gifts (meaningful details)\n5. Physical touch (hugs, caresses)\n\nConflicts arise when you speak a different language than your partner or loved ones.' },
        { type: 'quiz', order: 1, title_es: 'Si tu pareja se siente amada cuando le ayudas con tareas, su lenguaje probablemente es:', title_en: 'If your partner feels loved when you help with chores, their language is probably:', question_es: 'Si tu pareja se siente amada cuando le ayudas con tareas, su lenguaje probablemente es:', question_en: 'If your partner feels loved when you help with chores, their language is probably:', options_es: ['Palabras de afirmación', 'Actos de servicio', 'Regalos'], options_en: ['Words of affirmation', 'Acts of service', 'Gifts'], correctIndex: 1, explanation_es: 'Los actos de servicio muestran amor a través de acciones: cocinar, ayudar, resolver problemas. Para estas personas, las acciones hablan más que las palabras.', explanation_en: 'Acts of service show love through actions: cooking, helping, solving problems. For these people, actions speak louder than words.' },
        { type: 'exercise', order: 2, title_es: 'Tu lenguaje del amor', title_en: 'Your love language', instruction_es: '¿Cuál crees que es tu lenguaje principal del amor? ¿Y el de las personas más cercanas a ti? ¿Hay diferencias?', instruction_en: 'What do you think is your main love language? And that of the people closest to you? Are there differences?', placeholder_es: 'Mi lenguaje principal es... porque me siento más querido cuando...', placeholder_en: 'My main language is... because I feel most loved when...' },
      ]},
      { id: 'amor_2', title_es: 'Amor propio', title_en: 'Self-love', subtitle_es: 'La relación más importante', subtitle_en: 'The most important relationship', xpReward: 20, order: 1, steps: [
        { type: 'reading', order: 0, title_es: 'No es egoísmo', title_en: 'It\'s not selfishness', content_es: 'El amor propio no es narcisismo ni egoísmo. Es reconocer tu valor, cuidar tu bienestar y establecer límites saludables.\n\nNo puedes servir de una taza vacía. Cuidarte a ti mismo te permite estar mejor para los demás.\n\nEl amor propio incluye: descansar sin culpa, decir "no", celebrar tus logros, y tratarte con gentileza.', content_en: 'Self-love is not narcissism or selfishness. It\'s recognizing your worth, caring for your wellbeing and setting healthy boundaries.\n\nYou can\'t pour from an empty cup. Taking care of yourself allows you to be better for others.\n\nSelf-love includes: resting without guilt, saying "no", celebrating your achievements, and treating yourself with kindness.' },
        { type: 'quiz', order: 1, title_es: '¿Qué incluye el amor propio?', title_en: 'What does self-love include?', question_es: '¿Qué incluye el amor propio?', question_en: 'What does self-love include?', options_es: ['Poner siempre a otros primero', 'Establecer límites y cuidar tu bienestar', 'No necesitar a nadie'], options_en: ['Always putting others first', 'Setting boundaries and caring for your wellbeing', 'Not needing anyone'], correctIndex: 1, explanation_es: 'El amor propio es cuidar tu bienestar físico y emocional, establecer límites saludables y reconocer tu valor.', explanation_en: 'Self-love is caring for your physical and emotional wellbeing, setting healthy boundaries and recognizing your worth.' },
        { type: 'exercise', order: 2, title_es: 'Acto de amor propio', title_en: 'Act of self-love', instruction_es: '¿Qué es algo que necesitas pero te niegas? Escribe un acto de amor propio que puedas hacer hoy.', instruction_en: 'What is something you need but deny yourself? Write an act of self-love you can do today.', placeholder_es: 'Hoy me voy a permitir...', placeholder_en: 'Today I\'m going to allow myself...' },
      ]},
    ],
  },
];

async function seedRoutes() {
  console.log('🌱 Starting seed of wellness routes...\n');

  for (const route of routes) {
    const { lessons, ...routeData } = route;
    const routeRef = db.collection('wellness_routes').doc(route.id);

    // Write route document
    await routeRef.set(routeData);
    console.log(`✅ Route: ${route.title_es} (${route.id})`);

    for (const lesson of lessons) {
      const { steps, ...lessonData } = lesson;
      const lessonRef = routeRef.collection('lessons').doc(lesson.id);

      // Write lesson document
      await lessonRef.set(lessonData);
      console.log(`   📖 Lesson: ${lesson.title_es} (${lesson.id})`);

      for (let i = 0; i < steps.length; i++) {
        const step = steps[i];
        const stepRef = lessonRef.collection('steps').doc(`step_${i}`);

        await stepRef.set(step);
        console.log(`      📝 Step ${i}: ${step.type} - ${step.title_es}`);
      }
    }
    console.log('');
  }

  console.log('🎉 Seed complete! All routes, lessons and steps uploaded to Firestore.');
  console.log(`   Total routes: ${routes.length}`);
  console.log(`   Total lessons: ${routes.reduce((sum, r) => sum + r.lessons.length, 0)}`);
  console.log(`   Total steps: ${routes.reduce((sum, r) => sum + r.lessons.reduce((s, l) => s + l.steps.length, 0), 0)}`);
}

seedRoutes().catch(console.error);
