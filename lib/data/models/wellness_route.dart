import 'package:flutter/material.dart';

/// Una ruta de bienestar (colección de lecciones)
class WellnessRoute {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final Color color;
  final Color colorDark;
  final List<Lesson> lessons;

  const WellnessRoute({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
    required this.colorDark,
    required this.lessons,
  });

  int get totalLessons => lessons.length;

  /// Todas las rutas disponibles
  static List<WellnessRoute> get all => [
        _manejoEmociones,
        _autoconocimiento,
        _mindfulness,
        _resiliencia,
        _autoestima,
        _relaciones,
        _amor,
      ];

  // ═══════════════════════════════════════════
  // RUTA 1: Manejo de Emociones
  // ═══════════════════════════════════════════
  static const _manejoEmociones = WellnessRoute(
    id: 'emociones',
    title: 'Manejo de Emociones',
    description: 'Aprende a identificar y gestionar lo que sientes',
    emoji: '🎭',
    color: Color(0xFF6366F1),
    colorDark: Color(0xFF4338CA),
    lessons: [
      Lesson(
        id: 'emo_1',
        title: '¿Qué son las emociones?',
        subtitle: 'Las emociones son tu GPS interno',
        xpReward: 15,
        steps: [
          LessonStep.reading(
            title: 'Tu radar emocional',
            content: 'Las emociones son señales que tu cuerpo y mente envían para ayudarte a navegar la vida. No son buenas ni malas — son información.\n\nImagina que tus emociones son como el clima: a veces hay sol, a veces lluvia, pero ambos son necesarios.\n\nLa clave no es evitar sentir, sino aprender a escuchar lo que tus emociones te dicen.',
          ),
          LessonStep.quiz(
            question: '¿Las emociones negativas son malas?',
            options: [
              'Sí, hay que evitarlas siempre',
              'No, todas las emociones son información útil',
              'Solo algunas son útiles',
            ],
            correctIndex: 1,
            explanation: '¡Correcto! Todas las emociones cumplen una función. La tristeza nos ayuda a procesar pérdidas, el miedo nos protege, y el enojo nos indica que algo nos importa.',
          ),
          LessonStep.exercise(
            title: 'Nombra tu emoción',
            instruction: 'Cierra los ojos por 10 segundos. ¿Qué emoción sientes ahora mismo? Escríbela junto con dónde la sientes en tu cuerpo.',
            placeholder: 'Ej: Siento curiosidad, la siento como energía en el pecho...',
          ),
        ],
      ),
      Lesson(
        id: 'emo_2',
        title: 'La rueda emocional',
        subtitle: 'Amplía tu vocabulario emocional',
        xpReward: 15,
        steps: [
          LessonStep.reading(
            title: 'Más allá de "bien" o "mal"',
            content: 'La mayoría de personas solo usan 3-4 palabras para describir cómo se sienten: bien, mal, regular, cansado.\n\nPero existen más de 30 emociones distintas. Cuanto más preciso seas al nombrar lo que sientes, mejor podrás manejarlo.\n\nEsto se llama "granularidad emocional" y está científicamente demostrado que mejora tu bienestar.',
          ),
          LessonStep.quiz(
            question: '¿Qué es la granularidad emocional?',
            options: [
              'Sentir muchas emociones a la vez',
              'La capacidad de nombrar emociones con precisión',
              'No sentir nada',
            ],
            correctIndex: 1,
            explanation: 'La granularidad emocional es poder distinguir entre "estoy frustrado" y "estoy decepcionado". Esta precisión te da más herramientas para responder adecuadamente.',
          ),
          LessonStep.exercise(
            title: 'Expande tu vocabulario',
            instruction: 'Piensa en tu día de hoy. En vez de "bien" o "mal", intenta usar al menos 3 palabras diferentes para describir cómo te sentiste en distintos momentos.',
            placeholder: 'Ej: En la mañana me sentí motivado, a mediodía un poco abrumado, y ahora siento tranquilidad...',
          ),
        ],
      ),
      Lesson(
        id: 'emo_3',
        title: 'Emociones en el cuerpo',
        subtitle: 'Tu cuerpo habla, aprende a escucharlo',
        xpReward: 20,
        steps: [
          LessonStep.reading(
            title: 'El mapa corporal',
            content: 'Cada emoción se manifiesta físicamente. La ansiedad puede sentirse como un nudo en el estómago, la alegría como ligereza en el pecho, y el enojo como tensión en la mandíbula.\n\nReconocer estas señales corporales te ayuda a identificar tus emociones antes de que te abrumen.\n\nEs como tener un sistema de alerta temprana.',
          ),
          LessonStep.quiz(
            question: '¿Dónde suele manifestarse la ansiedad en el cuerpo?',
            options: [
              'En los pies',
              'En el estómago y el pecho',
              'Solo en la cabeza',
            ],
            correctIndex: 1,
            explanation: 'La ansiedad frecuentemente se siente como un nudo en el estómago, opresión en el pecho, o tensión en los hombros. Cada persona puede experimentarlo diferente.',
          ),
          LessonStep.exercise(
            title: 'Escaneo corporal rápido',
            instruction: 'Haz un recorrido mental de tu cuerpo de pies a cabeza. ¿Dónde sientes tensión? ¿Dónde hay comodidad? Describe lo que encuentres.',
            placeholder: 'Ej: Siento los hombros tensos, las manos relajadas, un poco de presión en la frente...',
          ),
        ],
      ),
      Lesson(
        id: 'emo_4',
        title: 'Técnica STOP',
        subtitle: 'Pausa antes de reaccionar',
        xpReward: 20,
        steps: [
          LessonStep.reading(
            title: 'S-T-O-P',
            content: 'Cuando una emoción fuerte te invade, usa la técnica STOP:\n\nS - Stop (Para): Detén lo que estés haciendo.\nT - Take a breath (Respira): Haz 3 respiraciones profundas.\nO - Observe (Observa): ¿Qué sientes? ¿Qué piensas?\nP - Proceed (Procede): Ahora decide cómo actuar conscientemente.\n\nEste espacio de 30 segundos puede cambiar completamente tu respuesta.',
          ),
          LessonStep.quiz(
            question: '¿Cuál es el primer paso de la técnica STOP?',
            options: [
              'Respirar profundo',
              'Detenerte por completo',
              'Observar tus pensamientos',
            ],
            correctIndex: 1,
            explanation: 'El primer paso es PARAR. Detener cualquier acción automática es fundamental antes de poder respirar, observar y decidir conscientemente.',
          ),
          LessonStep.exercise(
            title: 'Practica STOP',
            instruction: 'Piensa en una situación reciente donde reaccionaste impulsivamente. ¿Cómo habrías respondido si hubieras usado la técnica STOP? Describe la diferencia.',
            placeholder: 'Ej: Cuando mi compañero me interrumpió, grité. Con STOP habría respirado y dicho calmadamente que necesitaba terminar de hablar...',
          ),
        ],
      ),
      Lesson(
        id: 'emo_5',
        title: 'Regulación emocional',
        subtitle: 'Herramientas para el día a día',
        xpReward: 25,
        steps: [
          LessonStep.reading(
            title: 'Tu caja de herramientas',
            content: 'Regular tus emociones no significa suprimirlas. Significa tener estrategias para manejar su intensidad.\n\nAlgunas herramientas probadas:\n• Respiración 4-7-8 para calmar la ansiedad\n• Movimiento físico para liberar enojo\n• Escribir para procesar tristeza\n• Hablar con alguien para sentirte menos solo\n• Música para cambiar tu estado emocional\n\nLa clave es tener varias opciones y saber cuál usar en cada momento.',
          ),
          LessonStep.quiz(
            question: '¿Qué significa regular las emociones?',
            options: [
              'No sentir nada',
              'Manejar la intensidad sin suprimirlas',
              'Solo sentir emociones positivas',
            ],
            correctIndex: 1,
            explanation: 'Regular emociones es manejar su intensidad y duración, no eliminarlas. Es como bajar el volumen de la música: sigue sonando, pero a un nivel manejable.',
          ),
          LessonStep.exercise(
            title: 'Tu kit personal',
            instruction: 'Crea tu kit de regulación emocional. Para cada emoción difícil, escribe una herramienta que te funcione.',
            placeholder: 'Ej: Ansiedad → respirar. Enojo → caminar. Tristeza → escribir. Estrés → música...',
          ),
        ],
      ),
    ],
  );

  // ═══════════════════════════════════════════
  // RUTA 2: Autoconocimiento
  // ═══════════════════════════════════════════
  static const _autoconocimiento = WellnessRoute(
    id: 'autoconocimiento',
    title: 'Autoconocimiento',
    description: 'Descubre quién eres realmente',
    emoji: '🔍',
    color: Color(0xFF10B981),
    colorDark: Color(0xFF059669),
    lessons: [
      Lesson(id: 'auto_1', title: 'Tus valores', subtitle: '¿Qué es importante para ti?', xpReward: 15, steps: [
        LessonStep.reading(title: 'La brújula interior', content: 'Tus valores son los principios que guían tu vida. Cuando actúas alineado con tus valores, sientes satisfacción. Cuando los ignoras, sientes vacío o frustración.\n\nAlgunos valores comunes: honestidad, familia, libertad, creatividad, justicia, aventura, seguridad, crecimiento.\n\nNo hay valores correctos o incorrectos — solo los tuyos.'),
        LessonStep.quiz(question: '¿Qué pasa cuando vives alineado con tus valores?', options: ['Nada especial', 'Sientes satisfacción y propósito', 'Te vuelves perfecto'], correctIndex: 1, explanation: 'Vivir alineado con tus valores genera un sentido de autenticidad y satisfacción profunda.'),
        LessonStep.exercise(title: 'Identifica tus 5 valores', instruction: 'De la siguiente lista, elige los 5 que más resuenan contigo y ordénalos: honestidad, familia, libertad, creatividad, justicia, aventura, seguridad, crecimiento, amor, salud, éxito, generosidad.', placeholder: 'Mis 5 valores principales son: 1...'),
      ]),
      Lesson(id: 'auto_2', title: 'Fortalezas personales', subtitle: 'Lo que te hace único', xpReward: 15, steps: [
        LessonStep.reading(title: 'Tus superpoderes', content: 'Todos tenemos fortalezas naturales — cosas que hacemos bien sin esfuerzo excesivo. Pueden ser habilidades sociales, creatividad, perseverancia, humor, empatía, liderazgo, o pensamiento analítico.\n\nConocer tus fortalezas te permite usarlas estratégicamente y confiar más en ti mismo.'),
        LessonStep.quiz(question: '¿Cómo identificas una fortaleza personal?', options: ['Es algo que te cuesta mucho', 'Es algo que haces bien naturalmente', 'Es algo que otros hacen'], correctIndex: 1, explanation: 'Las fortalezas son habilidades que ejercitas con facilidad y que, al usarlas, te energizan en vez de agotarte.'),
        LessonStep.exercise(title: 'Mapa de fortalezas', instruction: 'Escribe 3 cosas que haces bien y que disfrutas hacer. Pregunta a alguien cercano qué creen que son tus fortalezas.', placeholder: 'Mis fortalezas: 1...'),
      ]),
      Lesson(id: 'auto_3', title: 'Patrones de pensamiento', subtitle: 'Identifica tus narrativas', xpReward: 20, steps: [
        LessonStep.reading(title: 'Las historias que te cuentas', content: 'Tu mente genera pensamientos automáticos constantemente. Algunos son útiles, otros son distorsiones que afectan cómo te sientes.\n\nDistorsiones comunes:\n• Todo o nada: "Si no es perfecto, es un fracaso"\n• Catastrofizar: "Seguro va a salir mal"\n• Lectura mental: "Seguro piensa mal de mí"\n\nReconocer estos patrones es el primer paso para cambiarlos.'),
        LessonStep.quiz(question: '"Si no saco 10, soy un fracaso" es un ejemplo de:', options: ['Pensamiento realista', 'Pensamiento todo o nada', 'Pensamiento positivo'], correctIndex: 1, explanation: 'El pensamiento "todo o nada" no reconoce matices. Un 8 no es un fracaso, es un buen resultado.'),
        LessonStep.exercise(title: 'Atrapa un pensamiento', instruction: 'Escribe un pensamiento negativo recurrente que tengas. Luego escribe una versión más equilibrada y realista.', placeholder: 'Pensamiento: "Nunca hago nada bien"\nVersión equilibrada: "A veces cometo errores, pero también hago muchas cosas bien"'),
      ]),
    ],
  );

  // ═══════════════════════════════════════════
  // RUTA 3: Mindfulness
  // ═══════════════════════════════════════════
  static const _mindfulness = WellnessRoute(
    id: 'mindfulness',
    title: 'Mindfulness',
    description: 'Vive el presente con atención plena',
    emoji: '🧘',
    color: Color(0xFF3B82F6),
    colorDark: Color(0xFF1D4ED8),
    lessons: [
      Lesson(id: 'mind_1', title: '¿Qué es mindfulness?', subtitle: 'Atención al momento presente', xpReward: 15, steps: [
        LessonStep.reading(title: 'Estar aquí y ahora', content: 'Mindfulness es prestar atención al momento presente sin juzgar. Suena simple, pero la mente tiende a viajar al pasado (culpa) o al futuro (ansiedad).\n\nPracticar mindfulness no requiere meditar horas. Puede ser tan simple como notar el sabor de tu comida o sentir tus pies en el suelo.'),
        LessonStep.quiz(question: '¿Qué es mindfulness?', options: ['No pensar en nada', 'Atención al presente sin juzgar', 'Solo meditar sentado'], correctIndex: 1, explanation: 'Mindfulness es atención consciente al presente. No se trata de vaciar la mente, sino de observar sin juzgar.'),
        LessonStep.exercise(title: 'Minuto mindful', instruction: 'Durante 60 segundos, enfócate solo en tu respiración. Cada vez que tu mente se distraiga, gentilmente regresa a la respiración. ¿Cuántas veces se distrajo tu mente?', placeholder: 'Mi mente se distrajo unas... veces. Me di cuenta de que...'),
      ]),
      Lesson(id: 'mind_2', title: 'Respiración consciente', subtitle: 'Tu ancla al presente', xpReward: 15, steps: [
        LessonStep.reading(title: 'El poder de respirar', content: 'La respiración es la única función del cuerpo que es automática y voluntaria. Esto la convierte en un puente perfecto entre tu mente consciente y tu sistema nervioso.\n\nRespirar lento y profundo activa tu sistema parasimpático (calma), mientras que respirar rápido activa el simpático (alerta).'),
        LessonStep.quiz(question: '¿Qué efecto tiene la respiración lenta y profunda?', options: ['Te da más energía', 'Activa la calma (sistema parasimpático)', 'No tiene efecto'], correctIndex: 1, explanation: 'La respiración lenta envía señales de seguridad a tu cerebro, reduciendo cortisol y activando la relajación.'),
        LessonStep.exercise(title: 'Respiración 4-7-8', instruction: 'Prueba la técnica 4-7-8:\n1. Inhala por la nariz contando hasta 4\n2. Sostén la respiración contando hasta 7\n3. Exhala por la boca contando hasta 8\n\nRepite 4 veces. ¿Cómo te sientes después?', placeholder: 'Después de la respiración me siento...'),
      ]),
      Lesson(id: 'mind_3', title: 'Comer con atención', subtitle: 'Mindfulness en lo cotidiano', xpReward: 20, steps: [
        LessonStep.reading(title: 'Más allá de la meditación', content: 'El mindfulness no se limita a meditar. Puedes practicarlo en cualquier actividad diaria.\n\nComer con atención significa notar colores, texturas, sabores y aromas de tu comida. Masticar despacio. Disfrutar cada bocado.\n\nEsto no solo mejora tu relación con la comida, sino que entrena tu capacidad de estar presente.'),
        LessonStep.quiz(question: '¿Solo se puede practicar mindfulness meditando?', options: ['Sí, solo sentado en silencio', 'No, se puede practicar en cualquier actividad', 'Solo con un instructor'], correctIndex: 1, explanation: 'Cualquier actividad puede convertirse en práctica de mindfulness: comer, caminar, ducharte, incluso lavar los platos.'),
        LessonStep.exercise(title: 'Próxima comida mindful', instruction: 'En tu próxima comida, dedica los primeros 5 bocados a comer con total atención. Sin celular, sin TV. Nota sabores, texturas y temperaturas. Describe la experiencia.', placeholder: 'Noté que...'),
      ]),
    ],
  );

  // ═══════════════════════════════════════════
  // RUTA 4: Resiliencia
  // ═══════════════════════════════════════════
  static const _resiliencia = WellnessRoute(
    id: 'resiliencia',
    title: 'Resiliencia',
    description: 'Fortalece tu capacidad de superar adversidades',
    emoji: '💪',
    color: Color(0xFFEF4444),
    colorDark: Color(0xFFDC2626),
    lessons: [
      Lesson(id: 'res_1', title: '¿Qué es la resiliencia?', subtitle: 'Más que resistir, es crecer', xpReward: 15, steps: [
        LessonStep.reading(title: 'Bambú, no roble', content: 'La resiliencia no es ser fuerte como un roble que no se mueve. Es ser flexible como el bambú: se dobla con el viento pero no se rompe.\n\nLas personas resilientes no evitan el dolor — lo atraviesan y salen transformadas.\n\nLa buena noticia: la resiliencia se puede desarrollar, no es un rasgo fijo.'),
        LessonStep.quiz(question: '¿Qué significa ser resiliente?', options: ['No sentir dolor nunca', 'Adaptarse y crecer ante la adversidad', 'Ser siempre positivo'], correctIndex: 1, explanation: 'La resiliencia es la capacidad de adaptarte, recuperarte y crecer después de situaciones difíciles.'),
        LessonStep.exercise(title: 'Tu historia de resiliencia', instruction: 'Piensa en un momento difícil que superaste. ¿Qué aprendiste? ¿Cómo te hizo más fuerte?', placeholder: 'Una vez superé...'),
      ]),
      Lesson(id: 'res_2', title: 'Mentalidad de crecimiento', subtitle: 'Los errores son maestros', xpReward: 15, steps: [
        LessonStep.reading(title: 'Todavía no', content: 'Carol Dweck descubrió que hay dos mentalidades:\n\n• Fija: "No soy bueno en esto" (se rinde)\n• De crecimiento: "Todavía no soy bueno en esto" (sigue intentando)\n\nLa diferencia de una sola palabra — "todavía" — cambia todo tu enfoque ante los retos.'),
        LessonStep.quiz(question: '"No puedo hacer esto" vs "Todavía no puedo hacer esto". ¿Cuál refleja mentalidad de crecimiento?', options: ['La primera', 'La segunda', 'Las dos son iguales'], correctIndex: 1, explanation: '"Todavía no" implica que puedes aprender y mejorar. Es la base de la mentalidad de crecimiento.'),
        LessonStep.exercise(title: 'Transforma tus "no puedo"', instruction: 'Escribe 3 cosas que crees que "no puedes hacer" y agrégales "todavía".', placeholder: '1. No puedo... todavía\n2. No sé... todavía\n3. No logro... todavía'),
      ]),
    ],
  );

  // ═══════════════════════════════════════════
  // RUTA 5: Autoestima
  // ═══════════════════════════════════════════
  static const _autoestima = WellnessRoute(
    id: 'autoestima',
    title: 'Autoestima',
    description: 'Construye una relación sana contigo mismo',
    emoji: '⭐',
    color: Color(0xFFF59E0B),
    colorDark: Color(0xFFD97706),
    lessons: [
      Lesson(id: 'est_1', title: 'Tu diálogo interno', subtitle: '¿Cómo te hablas a ti mismo?', xpReward: 15, steps: [
        LessonStep.reading(title: 'La voz interior', content: 'La persona con la que más hablas en tu vida eres tú mismo. Ese diálogo interno influye enormemente en cómo te sientes.\n\nSi tu voz interior es constantemente crítica ("eres un desastre", "no sirves"), tu autoestima se erosiona.\n\nLa autocompasión es tratarte con la misma amabilidad que tratarías a un buen amigo.'),
        LessonStep.quiz(question: '¿Qué es la autocompasión?', options: ['Sentir lástima por ti mismo', 'Tratarte con la misma amabilidad que a un amigo', 'No tener autocrítica nunca'], correctIndex: 1, explanation: 'La autocompasión es reconocer tu sufrimiento sin juzgarte, y tratarte con gentileza y comprensión.'),
        LessonStep.exercise(title: 'Carta a ti mismo', instruction: 'Escríbete una carta breve como si le escribieras a tu mejor amigo que está pasando por lo que tú estás pasando ahora.', placeholder: 'Querido yo: Sé que estás pasando por...'),
      ]),
      Lesson(id: 'est_2', title: 'Celebra tus logros', subtitle: 'Lo que has construido importa', xpReward: 15, steps: [
        LessonStep.reading(title: 'El sesgo de lo negativo', content: 'El cerebro humano tiene un sesgo natural hacia lo negativo: recuerdas más los fracasos que los éxitos, más las críticas que los elogios.\n\nPara contrarrestar esto, necesitas practicar intencionalmente el reconocimiento de tus logros, por pequeños que sean.\n\nCompletaste esta lección? Eso ya es un logro.'),
        LessonStep.quiz(question: '¿Por qué recordamos más lo negativo?', options: ['Porque somos pesimistas', 'Por un sesgo evolutivo del cerebro', 'Porque lo positivo no importa'], correctIndex: 1, explanation: 'El sesgo de negatividad es evolutivo: nuestros ancestros sobrevivían prestando más atención a amenazas. Hoy, necesitamos compensar conscientemente.'),
        LessonStep.exercise(title: '5 logros recientes', instruction: 'Escribe 5 cosas que hayas logrado recientemente, por pequeñas que sean. Pueden ser desde levantarte temprano hasta completar un proyecto.', placeholder: '1. Logré...\n2. Completé...\n3. Mejoré en...'),
      ]),
    ],
  );

  // ═══════════════════════════════════════════
  // RUTA 6: Relaciones Saludables
  // ═══════════════════════════════════════════
  static const _relaciones = WellnessRoute(
    id: 'relaciones',
    title: 'Relaciones Saludables',
    description: 'Conecta mejor con los demás',
    emoji: '🤝',
    color: Color(0xFFEC4899),
    colorDark: Color(0xFFDB2777),
    lessons: [
      Lesson(id: 'rel_1', title: 'Comunicación asertiva', subtitle: 'Di lo que sientes sin herir', xpReward: 15, steps: [
        LessonStep.reading(title: 'El arte de comunicar', content: 'La comunicación asertiva es expresar tus necesidades y sentimientos de forma clara y respetuosa, sin ser agresivo ni pasivo.\n\nFórmula asertiva:\n"Cuando [situación], me siento [emoción], y necesito [petición]."\n\nEjemplo: "Cuando llegas tarde sin avisar, me siento preocupado, y necesito que me envíes un mensaje."'),
        LessonStep.quiz(question: '¿Cuál es una respuesta asertiva?', options: ['"Nunca me escuchas, eres imposible"', '"Está bien, no importa" (aunque sí importa)', '"Cuando me interrumpes, me siento frustrado. ¿Podrías dejarme terminar?"'], correctIndex: 2, explanation: 'La tercera opción es asertiva: describe la situación, expresa el sentimiento y hace una petición clara sin atacar.'),
        LessonStep.exercise(title: 'Practica la fórmula', instruction: 'Piensa en una situación donde no expresaste lo que sentías. Usa la fórmula: "Cuando..., me siento..., necesito..."', placeholder: 'Cuando... me siento... y necesito...'),
      ]),
      Lesson(id: 'rel_2', title: 'Escucha activa', subtitle: 'Oír vs. escuchar', xpReward: 15, steps: [
        LessonStep.reading(title: 'Presencia total', content: 'La mayoría del tiempo cuando alguien habla, estamos pensando en qué vamos a responder, no en lo que está diciendo.\n\nLa escucha activa significa:\n• Mantener contacto visual\n• No interrumpir\n• Reflejar: "Entonces lo que dices es..."\n• Preguntar para entender, no para juzgar'),
        LessonStep.quiz(question: '¿Qué NO es escucha activa?', options: ['Mantener contacto visual', 'Pensar en tu respuesta mientras el otro habla', 'Parafrasear lo que dice el otro'], correctIndex: 1, explanation: 'Pensar en tu respuesta mientras el otro habla es oír, no escuchar. La escucha activa requiere tu atención completa.'),
        LessonStep.exercise(title: 'Escucha a alguien', instruction: 'En tu próxima conversación, practica escucha activa por 5 minutos. No interrumpas, no des consejos, solo escucha y haz preguntas. ¿Cómo fue?', placeholder: 'Cuando practiqué escucha activa, noté que...'),
      ]),
    ],
  );

  // ═══════════════════════════════════════════
  // RUTA 7: Amor y Conexión
  // ═══════════════════════════════════════════
  static const _amor = WellnessRoute(
    id: 'amor',
    title: 'Amor y Conexión',
    description: 'El amor en todas sus formas',
    emoji: '❤️',
    color: Color(0xFFF97316),
    colorDark: Color(0xFFEA580C),
    lessons: [
      Lesson(id: 'amor_1', title: 'Los 5 lenguajes del amor', subtitle: '¿Cómo das y recibes amor?', xpReward: 15, steps: [
        LessonStep.reading(title: 'Habla su idioma', content: 'Gary Chapman identificó 5 formas en que las personas expresan y reciben amor:\n\n1. Palabras de afirmación ("Te quiero", "Estoy orgulloso de ti")\n2. Tiempo de calidad (atención plena, sin distracciones)\n3. Actos de servicio (hacer cosas por el otro)\n4. Regalos (detalles significativos)\n5. Contacto físico (abrazos, caricias)\n\nConflictos surgen cuando hablas un lenguaje diferente al de tu pareja o seres queridos.'),
        LessonStep.quiz(question: 'Si tu pareja se siente amada cuando le ayudas con tareas, su lenguaje probablemente es:', options: ['Palabras de afirmación', 'Actos de servicio', 'Regalos'], correctIndex: 1, explanation: 'Los actos de servicio muestran amor a través de acciones: cocinar, ayudar, resolver problemas. Para estas personas, las acciones hablan más que las palabras.'),
        LessonStep.exercise(title: 'Tu lenguaje del amor', instruction: '¿Cuál crees que es tu lenguaje principal del amor? ¿Y el de las personas más cercanas a ti? ¿Hay diferencias?', placeholder: 'Mi lenguaje principal es... porque me siento más querido cuando...'),
      ]),
      Lesson(id: 'amor_2', title: 'Amor propio', subtitle: 'La relación más importante', xpReward: 20, steps: [
        LessonStep.reading(title: 'No es egoísmo', content: 'El amor propio no es narcisismo ni egoísmo. Es reconocer tu valor, cuidar tu bienestar y establecer límites saludables.\n\nNo puedes servir de una taza vacía. Cuidarte a ti mismo te permite estar mejor para los demás.\n\nEl amor propio incluye: descansar sin culpa, decir "no", celebrar tus logros, y tratarte con gentileza.'),
        LessonStep.quiz(question: '¿Qué incluye el amor propio?', options: ['Poner siempre a otros primero', 'Establecer límites y cuidar tu bienestar', 'No necesitar a nadie'], correctIndex: 1, explanation: 'El amor propio es cuidar tu bienestar físico y emocional, establecer límites saludables y reconocer tu valor.'),
        LessonStep.exercise(title: 'Acto de amor propio', instruction: '¿Qué es algo que necesitas pero te niegas? Escribe un acto de amor propio que puedas hacer hoy.', placeholder: 'Hoy me voy a permitir...'),
      ]),
    ],
  );
}

/// Una lección individual dentro de una ruta
class Lesson {
  final String id;
  final String title;
  final String subtitle;
  final int xpReward;
  final List<LessonStep> steps;

  const Lesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.xpReward,
    required this.steps,
  });

  int get totalSteps => steps.length;
}

/// Un paso dentro de una lección (lectura, quiz o ejercicio)
class LessonStep {
  final LessonStepType type;
  final String title;
  final String? content;       // Para reading
  final String? question;      // Para quiz
  final List<String>? options; // Para quiz
  final int? correctIndex;     // Para quiz
  final String? explanation;   // Para quiz
  final String? instruction;   // Para exercise
  final String? placeholder;   // Para exercise

  const LessonStep._({
    required this.type,
    required this.title,
    this.content,
    this.question,
    this.options,
    this.correctIndex,
    this.explanation,
    this.instruction,
    this.placeholder,
  });

  const LessonStep.reading({
    required String title,
    required String content,
  }) : this._(type: LessonStepType.reading, title: title, content: content);

  const LessonStep.quiz({
    required String question,
    required List<String> options,
    required int correctIndex,
    required String explanation,
  }) : this._(
          type: LessonStepType.quiz,
          title: question,
          question: question,
          options: options,
          correctIndex: correctIndex,
          explanation: explanation,
        );

  const LessonStep.exercise({
    required String title,
    required String instruction,
    String? placeholder,
  }) : this._(
          type: LessonStepType.exercise,
          title: title,
          instruction: instruction,
          placeholder: placeholder,
        );
}

enum LessonStepType {
  reading,
  quiz,
  exercise,
}