// Ruta: Manejo de Emociones
// IDs de lecciones permanentes: el progreso de los usuarios se guarda por id.

module.exports = {
  id: 'emociones',
  order: 0,
  title_es: 'Manejo de Emociones',
  title_en: 'Emotion Management',
  description_es: 'Aprende a identificar y gestionar lo que sientes',
  description_en: 'Learn to identify and manage your feelings',
  emoji: '🎭',
  color: 0xff6366f1,
  colorDark: 0xff4338ca,

  lessons: [
    // ═══════════════════════════════════════════════════════════════════════
    {
      id: 'emo_1',
      title_es: '¿Qué son las emociones?',
      title_en: 'What are emotions?',
      subtitle_es: 'Tu GPS interno, no tu enemigo',
      subtitle_en: 'Your internal GPS, not your enemy',
      xpReward: 20,
      steps: [
        {
          type: 'story',
          speaker: '🧭',
          title_es: 'Tráfico a las 8:40',
          title_en: 'Traffic at 8:40',
          lines_es: [
            '* Son las 8:40. Vas tarde y el tráfico no avanza.',
            'Notas algo en el pecho, ¿verdad? Esa presión.',
            '> Sí... estoy desesperado.',
            'Eso es una emoción haciendo su trabajo. Te avisa que algo que te importa está en riesgo: llegar a tiempo.',
            '> ¿Y por qué se siente tan mal?',
            'Porque una alarma que no molesta no sirve. Las emociones no son buenas ni malas: son información.',
            'Aquí vas a aprender a leer esa información en vez de pelearte con ella.',
          ],
          lines_en: [
            '* It is 8:40. You are running late and traffic is not moving.',
            'You notice something in your chest, right? That pressure.',
            '> Yeah... I am losing it.',
            'That is an emotion doing its job. It is telling you something you care about is at risk: being on time.',
            '> So why does it feel so bad?',
            'Because an alarm that does not bother you is useless. Emotions are not good or bad: they are information.',
            'Here you will learn to read that information instead of fighting it.',
          ],
        },
        {
          type: 'mythfact',
          title_es: 'Lo que crees saber de las emociones',
          title_en: 'What you think you know about emotions',
          statements_es: [
            'Las emociones negativas son malas y hay que evitarlas',
            'Puedes sentir dos emociones opuestas al mismo tiempo',
            'Las personas fuertes no lloran',
            'Las emociones influyen en tus decisiones aunque te creas objetivo',
          ],
          statements_en: [
            'Negative emotions are bad and should be avoided',
            'You can feel two opposite emotions at the same time',
            'Strong people do not cry',
            'Emotions shape your decisions even when you think you are objective',
          ],
          truths: [false, true, false, true],
          feedbacks_es: [
            'Mito. Todas cumplen una función: la tristeza ayuda a procesar pérdidas, el miedo te protege y el enojo marca lo que te importa.',
            'Realidad. Ilusión y nervios por un trabajo nuevo, alivio y tristeza al cerrar una etapa. Las emociones mezcladas son normales.',
            'Mito. Sentir no es debilidad. Reconocer lo que sientes pide más valor que esconderlo.',
            'Realidad. Nadie decide sin emociones. Saber qué sientes te ayuda a notar cuándo te están empujando.',
          ],
          feedbacks_en: [
            'Myth. Every emotion has a job: sadness helps you process loss, fear protects you, and anger marks what matters to you.',
            'Fact. Excitement and nerves about a new job, relief and sadness when something ends. Mixed emotions are normal.',
            'Myth. Feeling is not weakness. Acknowledging what you feel takes more courage than hiding it.',
            'Fact. Nobody decides without emotions. Knowing what you feel helps you notice when they are pushing you.',
          ],
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

    // ═══════════════════════════════════════════════════════════════════════
    {
      id: 'emo_2',
      title_es: 'La rueda emocional',
      title_en: 'The emotion wheel',
      subtitle_es: 'Más palabras, más control',
      subtitle_en: 'More words, more control',
      xpReward: 20,
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
            'La frustración mira un obstáculo, la decepción mira una expectativa rota y la ansiedad mira al futuro. Son tres respuestas distintas porque piden tres cosas distintas.',
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
          type: 'pick',
          question_es: '¿Cuáles de estas palabras usaste esta semana para decir cómo te sentías?',
          question_en: 'Which of these words did you use this week to describe how you felt?',
          options_es: ['Bien', 'Mal', 'Estresado', 'Cansado', 'Nostálgico', 'Orgulloso', 'Abrumado', 'Agradecido', 'Inquieto'],
          options_en: ['Fine', 'Bad', 'Stressed', 'Tired', 'Nostalgic', 'Proud', 'Overwhelmed', 'Grateful', 'Restless'],
          explanation_es:
            'Las primeras cuatro son el vocabulario "de supervivencia": sirven, pero dicen poco. Palabras como nostálgico, orgulloso o inquieto apuntan a algo concreto, y lo concreto se puede atender.',
          explanation_en:
            'The first four are "survival" vocabulary: they work, but they say little. Words like nostalgic, proud or restless point at something specific, and specific things can be addressed.',
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
          placeholder_es: 'Ej: en la mañana motivado, al mediodía abrumado, ahora tranquilo...',
          placeholder_en: 'E.g.: motivated in the morning, overwhelmed at noon, calm now...',
        },
      ],
    },

    // ═══════════════════════════════════════════════════════════════════════
    {
      id: 'emo_3',
      title_es: 'La ola emocional',
      title_en: 'The emotional wave',
      subtitle_es: 'Toda emoción sube y baja',
      subtitle_en: 'Every emotion rises and falls',
      xpReward: 20,
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
          type: 'practice',
          title_es: 'Surfea la ola',
          title_en: 'Surf the wave',
          intro_es:
            'Piensa en algo que te haya molestado un poco hace poco (no lo más fuerte que hayas vivido). Deja que la emoción aparezca y acompáñala durante poco más de un minuto, sin intentar arreglarla.',
          intro_en:
            'Think of something that bothered you a little recently (not the hardest thing you have lived through). Let the emotion show up and stay with it for just over a minute, without trying to fix it.',
          prompts_es: [
            'Trae la situación a tu mente',
            '¿Dónde la sientes en el cuerpo?',
            'Inhala lento',
            'Exhala más lento todavía',
            'Ponle un número del 0 al 10',
            'Solo obsérvala. No tienes que hacer nada con ella',
            'Inhala',
            'Exhala y deja espacio',
            'Nota si cambió de forma o de lugar',
            'Inhala',
            'Exhala',
            '¿Qué número le das ahora?',
          ],
          prompts_en: [
            'Bring the situation to mind',
            'Where do you feel it in your body?',
            'Breathe in slowly',
            'Breathe out even more slowly',
            'Give it a number from 0 to 10',
            'Just watch it. You do not have to do anything with it',
            'Breathe in',
            'Breathe out and make room',
            'Notice whether it changed shape or place',
            'Breathe in',
            'Breathe out',
            'What number would you give it now?',
          ],
          durations: [8, 8, 4, 6, 6, 12, 4, 6, 8, 4, 6, 6],
          motions: ['still', 'still', 'in', 'out', 'still', 'still', 'in', 'out', 'still', 'in', 'out', 'still'],
          outro_es:
            'Si bajó aunque sea un punto, acabas de comprobar que la ola baja sola cuando no la alimentas. Si no bajó, también está bien: a veces la ola es más larga, y quedarte ya es la práctica.',
          outro_en:
            'If it dropped even one point, you just saw the wave come down on its own when you do not feed it. If it did not, that is okay too: some waves are longer, and staying is the practice.',
        },
        {
          type: 'quiz',
          question_es: '¿Qué suele alargar una emoción intensa?',
          question_en: 'What usually makes an intense emotion last longer?',
          options_es: ['Dejarla estar mientras baja', 'Pelearte con ella para que se vaya rápido', 'Nombrarla con precisión'],
          options_en: ['Letting it be while it comes down', 'Fighting it so it goes away fast', 'Naming it precisely'],
          correctIndex: 1,
          explanation_es:
            'Resistir una emoción le da más combustible. Lo que la acorta es dejarla completar su curva mientras haces algo que sí te importa.',
          explanation_en:
            'Resisting an emotion fuels it. What shortens it is letting it finish its curve while you do something that actually matters to you.',
        },
        {
          type: 'commit',
          title_es: 'La próxima ola',
          title_en: 'The next wave',
          content_es: 'Elige cómo vas a practicar hoy o mañana, cuando llegue una emoción fuerte.',
          content_en: 'Choose how you will practice today or tomorrow when a strong emotion shows up.',
          options_es: [
            'Esperar diez minutos antes de actuar',
            'Ponerle un número del 0 al 10 y ver cómo cambia',
            'Hacer la práctica "Surfea la ola" otra vez',
          ],
          options_en: [
            'Wait ten minutes before acting',
            'Give it a number from 0 to 10 and watch it change',
            'Do the "Surf the wave" practice again',
          ],
        },
      ],
    },

    // ═══════════════════════════════════════════════════════════════════════
    {
      id: 'emo_4',
      title_es: 'Disparadores',
      title_en: 'Triggers',
      subtitle_es: 'Lo que enciende la mecha',
      subtitle_en: 'What lights the fuse',
      xpReward: 25,
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
          type: 'pick',
          question_es: '¿Cuáles de estas situaciones te descolocan más de lo que quisieras?',
          question_en: 'Which of these situations throw you off more than you would like?',
          options_es: [
            'Que me ignoren o me dejen en visto',
            'Que me corrijan delante de otros',
            'Que cambien los planes a última hora',
            'Sentir que no me escuchan',
            'Que me comparen con alguien',
            'Que alguien llegue tarde',
            'Que critiquen a mi familia',
            'Desorden o ruido cuando necesito concentrarme',
          ],
          options_en: [
            'Being ignored or left on read',
            'Being corrected in front of others',
            'Last-minute changes of plan',
            'Feeling that nobody is listening',
            'Being compared to someone',
            'Someone showing up late',
            'Criticism of my family',
            'Mess or noise when I need to focus',
          ],
          explanation_es:
            'Mira lo que marcaste y busca el tema común: ¿rechazo, control, respeto, justicia? Casi siempre hay uno o dos temas de fondo detrás de muchos disparadores distintos.',
          explanation_en:
            'Look at what you checked and find the common theme: rejection, control, respect, fairness? There are usually one or two themes behind many different triggers.',
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
          instruction_es: 'Separar lo que pasó de lo que te contaste es el primer paso. Arrastra cada frase a su lugar.',
          instruction_en: 'Separating what happened from what you told yourself is the first step. Drag each sentence to where it belongs.',
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
          situation_es: 'Cuentas una idea en una reunión y nadie dice nada por unos segundos. Sientes calor en la cara.',
          situation_en: 'You share an idea in a meeting and nobody says anything for a few seconds. Your face feels hot.',
          options_es: [
            'Me retracto: "bueno, era solo una idea tonta"',
            'Sostengo el silencio y espero',
            'Pregunto: "¿qué opinan?"',
          ],
          options_en: ['Walk it back: "well, it was just a silly idea"', 'Hold the silence and wait', 'Ask: "what do you think?"'],
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
          instruction_es: 'Piensa en algo pequeño que te descoloca más de lo razonable. ¿Qué idea sobre ti toca esa situación?',
          instruction_en: 'Think of something small that throws you off more than it should. What belief about yourself does it touch?',
          placeholder_es: 'Ej: que me corrijan delante de otros toca la idea de que no soy capaz...',
          placeholder_en: 'E.g.: being corrected in front of others touches the idea that I am not capable...',
        },
      ],
    },

    // ═══════════════════════════════════════════════════════════════════════
    {
      id: 'emo_5',
      title_es: 'Responder en vez de reaccionar',
      title_en: 'Responding instead of reacting',
      subtitle_es: 'El segundo que lo cambia todo',
      subtitle_en: 'The second that changes everything',
      xpReward: 25,
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
          type: 'order',
          title_es: 'La técnica STOP',
          title_en: 'The STOP technique',
          instruction_es: 'STOP es una pausa de treinta segundos para cuando una emoción fuerte te invade. Toca los pasos en orden.',
          instruction_en: 'STOP is a thirty-second pause for when a strong emotion floods you. Tap the steps in order.',
          items_es: [
            'S · Para: detén lo que estás haciendo',
            'T · Toma aire: tres respiraciones lentas',
            'O · Observa: qué sientes y qué piensas',
            'P · Procede: elige qué hacer ahora',
          ],
          items_en: [
            'S · Stop: pause whatever you are doing',
            'T · Take a breath: three slow breaths',
            'O · Observe: what you feel and what you think',
            'P · Proceed: choose what to do now',
          ],
          explanation_es: 'El orden importa: sin parar primero, no hay espacio para respirar ni observar. Y "procede" no significa ceder: puede ser decir que no.',
          explanation_en: 'Order matters: without stopping first, there is no room to breathe or observe. And "proceed" does not mean giving in: it can mean saying no.',
        },
        {
          type: 'practice',
          title_es: 'Haz un STOP ahora',
          title_en: 'Do a STOP now',
          intro_es: 'La pausa se entrena en calma para que salga sola en la tormenta. Hagámosla una vez completa, aunque ahora estés tranquilo.',
          intro_en: 'The pause is trained in calm so it shows up on its own in the storm. Let us do one full round, even if you feel calm right now.',
          prompts_es: [
            'Para. Quédate quieto donde estás',
            'Inhala lento',
            'Exhala más lento',
            'Inhala',
            'Exhala',
            'Observa: ¿qué sientes en este momento?',
            '¿Qué estás pensando?',
            'Procede: ¿qué es lo más útil que puedes hacer ahora?',
          ],
          prompts_en: [
            'Stop. Stay still right where you are',
            'Breathe in slowly',
            'Breathe out more slowly',
            'Breathe in',
            'Breathe out',
            'Observe: what are you feeling right now?',
            'What are you thinking?',
            'Proceed: what is the most useful thing you can do now?',
          ],
          durations: [5, 4, 6, 4, 6, 9, 7, 8],
          motions: ['hold', 'in', 'out', 'in', 'out', 'still', 'still', 'still'],
          outro_es: 'Menos de un minuto. Esa es toda la distancia entre reaccionar y responder.',
          outro_en: 'Less than a minute. That is the whole distance between reacting and responding.',
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
          instruction_es: 'Escribe una frase corta que puedas decir para ganar tiempo cuando algo te encienda. Que suene a ti.',
          instruction_en: 'Write a short sentence you can say to buy time when something sets you off. Make it sound like you.',
          placeholder_es: 'Ej: "necesito un momento para pensarlo bien"...',
          placeholder_en: 'E.g.: "I need a moment to think this through"...',
        },
      ],
    },

    // ═══════════════════════════════════════════════════════════════════════
    {
      id: 'emo_6',
      title_es: 'Tu cuerpo habla',
      title_en: 'Your body speaks',
      subtitle_es: 'Señales antes de las palabras',
      subtitle_en: 'Signals before words',
      xpReward: 25,
      steps: [
        {
          type: 'reading',
          title_es: 'El mapa corporal',
          title_en: 'The body map',
          content_es:
            'Cada emoción deja huella en el cuerpo. La ansiedad aprieta el estómago, el enojo calienta la cara y tensa la mandíbula, la tristeza pesa en el pecho y en los brazos.\n\nEn un estudio con cientos de personas de distintos países, los mapas corporales de cada emoción se parecían mucho entre culturas.\n\nMuchas veces el cuerpo se entera antes que la mente. Aprender a leerlo es tener un sistema de alerta temprana.',
          content_en:
            'Every emotion leaves a trace in the body. Anxiety tightens the stomach, anger heats the face and clenches the jaw, sadness weighs on the chest and arms.\n\nIn a study with hundreds of people from different countries, the body maps for each emotion were strikingly similar across cultures.\n\nOften the body finds out before the mind does. Learning to read it gives you an early warning system.',
        },
        {
          type: 'sort',
          title_es: '¿Qué emoción suele ser?',
          title_en: 'Which emotion is it usually?',
          instruction_es: 'Arrastra cada señal del cuerpo a la emoción con la que más suele aparecer.',
          instruction_en: 'Drag each body signal to the emotion it most often shows up with.',
          categories_es: ['Ansiedad', 'Enojo', 'Tristeza'],
          categories_en: ['Anxiety', 'Anger', 'Sadness'],
          items_es: [
            'Mandíbula apretada',
            'Nudo en el estómago',
            'Pesadez en brazos y piernas',
            'Calor en la cara y puños cerrados',
            'Respiración corta y rápida',
            'Nudo en la garganta',
          ],
          items_en: [
            'Clenched jaw',
            'Knot in the stomach',
            'Heaviness in arms and legs',
            'Hot face and clenched fists',
            'Short, fast breathing',
            'Lump in the throat',
          ],
          itemCategory: [1, 0, 2, 1, 0, 2],
          explanation_es:
            'Son patrones frecuentes, no reglas: cada cuerpo tiene su propio idioma. Lo importante es descubrir el tuyo.',
          explanation_en:
            'These are common patterns, not rules: every body has its own language. What matters is learning yours.',
        },
        {
          type: 'practice',
          title_es: 'Escaneo corporal',
          title_en: 'Body scan',
          intro_es:
            'Siéntate o recuéstate cómodo. Vas a recorrer tu cuerpo de abajo hacia arriba, solo notando lo que hay. No tienes que cambiar nada.',
          intro_en:
            'Sit or lie down comfortably. You will move through your body from the bottom up, just noticing what is there. You do not have to change anything.',
          prompts_es: [
            'Suelta los hombros y apoya bien el cuerpo',
            'Lleva la atención a tus pies',
            'Sube a las piernas: ¿hay peso, tensión, nada?',
            'Nota tu abdomen al respirar',
            'Inhala hacia el pecho',
            'Exhala soltando',
            'Revisa hombros y cuello',
            'Revisa mandíbula y frente',
            'Inhala',
            'Exhala y afloja lo que encontraste',
          ],
          prompts_en: [
            'Drop your shoulders and let your body settle',
            'Bring your attention to your feet',
            'Move up to your legs: weight, tension, nothing?',
            'Notice your belly as you breathe',
            'Breathe into your chest',
            'Breathe out and let go',
            'Check your shoulders and neck',
            'Check your jaw and forehead',
            'Breathe in',
            'Breathe out and loosen what you found',
          ],
          durations: [6, 8, 10, 8, 4, 6, 9, 9, 4, 7],
          motions: ['still', 'still', 'still', 'still', 'in', 'out', 'still', 'still', 'in', 'out'],
          outro_es:
            'Si encontraste tensión, no hay que eliminarla. Notarla ya es información: es tu cuerpo avisando algo antes de que tu mente lo ponga en palabras.',
          outro_en:
            'If you found tension, you do not have to get rid of it. Noticing it is already information: your body flagging something before your mind puts it into words.',
        },
        {
          type: 'pick',
          question_es: '¿Dónde sueles sentir el estrés?',
          question_en: 'Where do you usually feel stress?',
          options_es: ['Hombros y cuello', 'Estómago', 'Pecho', 'Mandíbula', 'Cabeza', 'Espalda baja', 'Manos o piernas inquietas', 'En el sueño'],
          options_en: ['Shoulders and neck', 'Stomach', 'Chest', 'Jaw', 'Head', 'Lower back', 'Restless hands or legs', 'In my sleep'],
          explanation_es:
            'Estas son tus señales tempranas. La próxima vez que aparezcan, pregúntate: "¿qué me está preocupando ahora mismo?" A veces la respuesta te sorprende.',
          explanation_en:
            'These are your early signals. Next time they show up, ask yourself: "what is worrying me right now?" Sometimes the answer surprises you.',
        },
        {
          type: 'quiz',
          question_es: '¿Para qué sirve reconocer las señales del cuerpo?',
          question_en: 'What is the point of recognizing body signals?',
          options_es: [
            'Para eliminar las emociones antes de sentirlas',
            'Para detectar una emoción antes de que te desborde',
            'Para no tener que hablar de lo que sientes',
          ],
          options_en: [
            'To get rid of emotions before you feel them',
            'To catch an emotion before it overwhelms you',
            'So you never have to talk about how you feel',
          ],
          correctIndex: 1,
          explanation_es:
            'Una emoción en 3 sobre 10 es fácil de manejar; en 9 sobre 10, casi imposible. El cuerpo te avisa cuando todavía estás en el 3.',
          explanation_en:
            'An emotion at 3 out of 10 is easy to handle; at 9 out of 10, almost impossible. Your body warns you while you are still at 3.',
        },
        {
          type: 'exercise',
          title_es: 'Tu señal temprana',
          title_en: 'Your early signal',
          instruction_es:
            '¿Cuál es la primera señal de tu cuerpo cuando empiezas a enojarte o a preocuparte? ¿Qué podrías hacer justo en ese momento?',
          instruction_en:
            'What is the first signal your body gives when you start getting angry or worried? What could you do right at that moment?',
          placeholder_es: 'Ej: se me tensan los hombros; podría soltarlos y respirar...',
          placeholder_en: 'E.g.: my shoulders tense up; I could drop them and breathe...',
        },
      ],
    },

    // ═══════════════════════════════════════════════════════════════════════
    {
      id: 'emo_7',
      title_es: 'La tristeza tiene sentido',
      title_en: 'Sadness makes sense',
      subtitle_es: 'No hay que arreglarla, hay que acompañarla',
      subtitle_en: 'It needs company, not fixing',
      xpReward: 25,
      steps: [
        {
          type: 'story',
          speaker: '🌧️',
          title_es: 'Ana perdió su trabajo',
          title_en: 'Ana lost her job',
          lines_es: [
            '* Tu amiga Ana te cuenta que la despidieron.',
            '> ¡Ánimo! Todo pasa por algo. Mira el lado positivo.',
            '* Ana sonríe un poco forzada y cambia de tema.',
            'Ese impulso de animar rápido es muy humano. Queremos que el otro deje de sufrir... y dejar de sentirnos incómodos nosotros.',
            'Pero la tristeza no necesita que la arreglen. Necesita espacio.',
            '> ¿Y qué le digo entonces?',
            'Algo como: "Qué difícil. Aquí estoy." A veces acompañar es todo lo que hace falta. Y eso también vale contigo.',
          ],
          lines_en: [
            '* Your friend Ana tells you she was fired.',
            '> Cheer up! Everything happens for a reason. Look on the bright side.',
            '* Ana gives a forced smile and changes the subject.',
            'That urge to cheer someone up fast is very human. We want them to stop hurting... and ourselves to stop feeling uncomfortable.',
            'But sadness does not need fixing. It needs room.',
            '> So what do I say instead?',
            'Something like: "That is really hard. I am here." Sometimes being there is all it takes. And that goes for you, too.',
          ],
        },
        {
          type: 'reveal',
          question_es: '¿Para qué sirve la tristeza?',
          question_en: 'What is sadness for?',
          answer_es:
            'La tristeza aparece cuando perdiste algo que valorabas. Te baja el ritmo para que proceses lo que pasó, y le avisa a los demás que necesitas apoyo.\n\nPor eso pelearte con ella suele alargarla: interrumpes justo el proceso que la resuelve.',
          answer_en:
            'Sadness shows up when you lose something you valued. It slows you down so you can process what happened, and it signals to others that you need support.\n\nThat is why fighting it tends to make it last longer: you interrupt the very process that resolves it.',
        },
        {
          type: 'mythfact',
          title_es: 'Mitos sobre la tristeza',
          title_en: 'Myths about sadness',
          statements_es: [
            'Llorar es señal de debilidad',
            'Distraerte un rato cuando estás triste está bien',
            'Si llevas semanas triste, basta con echarle ganas',
            'Hablar de lo que te duele puede aliviarlo',
          ],
          statements_en: [
            'Crying is a sign of weakness',
            'Distracting yourself for a while when you are sad is fine',
            'If you have been sad for weeks, you just need to try harder',
            'Talking about what hurts can ease it',
          ],
          truths: [false, true, false, true],
          feedbacks_es: [
            'Mito. Llorar es una respuesta humana normal. Mucha gente se siente mejor después, sobre todo cuando alguien la acompaña.',
            'Realidad. Tomarte un respiro es sano. El problema es cuando la distracción se vuelve la única estrategia y nunca le das espacio a lo que sientes.',
            'Mito. Si la tristeza dura semanas, te quita el interés por casi todo o afecta tu sueño y apetito, puede ser depresión. No es falta de ganas: merece ayuda profesional.',
            'Realidad. Ponerlo en palabras con alguien de confianza ayuda a ordenarlo y quita la sensación de estar solo con eso.',
          ],
          feedbacks_en: [
            'Myth. Crying is a normal human response. Many people feel better afterward, especially when someone is with them.',
            'Fact. Taking a break is healthy. The problem is when distraction becomes the only strategy and you never give your feelings room.',
            'Myth. If sadness lasts for weeks, drains your interest in almost everything, or affects your sleep and appetite, it may be depression. That is not a lack of effort: it deserves professional help.',
            'Fact. Putting it into words with someone you trust helps you make sense of it and eases the feeling of being alone with it.',
          ],
        },
        {
          type: 'scenario',
          title_es: 'Un domingo gris',
          title_en: 'A gray Sunday',
          situation_es: 'Es domingo en la tarde. Sin una razón clara, te sientes triste y sin ganas de nada.',
          situation_en: 'It is Sunday afternoon. For no clear reason, you feel sad and unmotivated.',
          options_es: [
            'Me obligo a estar productivo para no pensar',
            'Me permito un rato tranquilo y luego salgo a caminar',
            'Me quedo en la cama viendo redes toda la tarde',
          ],
          options_en: [
            'Force myself to be productive so I do not think',
            'Allow myself some quiet time, then go for a walk',
            'Stay in bed scrolling social media all afternoon',
          ],
          outcomes_es: [
            'Mantenerte ocupado ayuda un rato, pero si es para no sentir, la tristeza suele esperarte en la noche. Funciona mejor si primero reconoces "hoy estoy triste".',
            'Darle espacio a la emoción y luego moverte un poco es de las combinaciones que más ayudan. No borra la tristeza, pero evita que se estanque.',
            'Descansar no tiene nada de malo. Pero horas de redes suelen dejarte peor: comparación, cansancio y la sensación de haber perdido el día.',
          ],
          outcomes_en: [
            'Keeping busy helps for a while, but if it is a way to avoid feeling, the sadness tends to wait for you at night. It works better if you first admit "I am sad today".',
            'Giving the emotion room and then moving a little is one of the most helpful combinations. It does not erase the sadness, but it keeps it from getting stuck.',
            'Resting is fine. But hours of scrolling usually leave you worse: comparison, fatigue, and the feeling of a lost day.',
          ],
        },
        {
          type: 'sort',
          title_es: '¿Te ayuda o te hunde?',
          title_en: 'Does it help or sink you?',
          instruction_es: 'Clasifica cada acción según lo que suele provocar cuando estás triste.',
          instruction_en: 'Sort each action by what it usually does when you are sad.',
          categories_es: ['Me ayuda a atravesarla', 'Me hunde más'],
          categories_en: ['Helps me get through', 'Sinks me deeper'],
          items_es: [
            'Escribir lo que siento',
            'Aislarme de todos por días',
            'Hablar con alguien de confianza',
            'Repetirme que no debería sentirme así',
            'Moverme un poco, aunque sea caminar',
            'Pasar horas en redes para no pensar',
          ],
          items_en: [
            'Writing down what I feel',
            'Isolating from everyone for days',
            'Talking to someone I trust',
            'Telling myself I should not feel this way',
            'Moving a little, even just a walk',
            'Spending hours on social media to avoid thinking',
          ],
          itemCategory: [0, 1, 0, 1, 0, 1],
          explanation_es:
            'Lo que ayuda tiene algo en común: te conecta con lo que sientes, con otros o con tu cuerpo. Lo que hunde te desconecta.',
          explanation_en:
            'What helps has something in common: it connects you with your feelings, with others, or with your body. What sinks you disconnects you.',
        },
        {
          type: 'commit',
          title_es: 'Un gesto de cuidado',
          title_en: 'A small act of care',
          content_es: 'En los días tristes, lo pequeño cuenta mucho. Elige uno para hoy o para el próximo día gris.',
          content_en: 'On sad days, small things count a lot. Choose one for today or for the next gray day.',
          options_es: [
            'Escribirle a alguien que me hace bien',
            'Salir a caminar diez minutos',
            'Escribir tres líneas sobre cómo me siento',
            'Prepararme algo rico con calma',
          ],
          options_en: [
            'Text someone who is good for me',
            'Go for a ten-minute walk',
            'Write three lines about how I feel',
            'Make myself something nice, slowly',
          ],
        },
      ],
    },

    // ═══════════════════════════════════════════════════════════════════════
    {
      id: 'emo_8',
      title_es: 'Enojo sin explotar',
      title_en: 'Anger without exploding',
      subtitle_es: 'Ni tragártelo ni lanzarlo',
      subtitle_en: 'Neither swallow it nor throw it',
      xpReward: 25,
      steps: [
        {
          type: 'reading',
          title_es: 'El enojo no es el problema',
          title_en: 'Anger is not the problem',
          content_es:
            'El enojo avisa que algo te pareció injusto o que alguien cruzó un límite. Esa información es valiosa.\n\nLo que causa problemas es lo que hacemos con él. Hay dos extremos: explotar (gritar, insultar, romper) o tragártelo (callar, sonreír y acumular).\n\nEntre los dos hay un camino: bajar la temperatura primero y después decir lo que te importa con firmeza.',
          content_en:
            'Anger tells you something felt unfair or someone crossed a line. That information is valuable.\n\nWhat causes problems is what we do with it. There are two extremes: exploding (yelling, insulting, breaking things) or swallowing it (staying quiet, smiling, and piling it up).\n\nBetween them there is a path: lower the temperature first, then say what matters to you firmly.',
        },
        {
          type: 'mythfact',
          title_es: 'Mitos sobre el enojo',
          title_en: 'Myths about anger',
          statements_es: [
            'Golpear una almohada o gritar ayuda a sacar el enojo',
            'Tragarte el enojo siempre evita problemas',
            'El enojo puede darte fuerza para poner un límite',
            'Bajar la activación del cuerpo reduce el enojo',
          ],
          statements_en: [
            'Punching a pillow or yelling helps get the anger out',
            'Swallowing your anger always avoids trouble',
            'Anger can give you the strength to set a boundary',
            'Calming your body down reduces anger',
          ],
          truths: [false, false, true, true],
          feedbacks_es: [
            'Mito. Los estudios muestran que "desahogarse" con golpes o gritos tiende a mantener el enojo encendido, no a sacarlo.',
            'Mito. Lo que no se dice suele salir después: en sarcasmo, en distancia o en una explosión por algo pequeño.',
            'Realidad. Bien usado, el enojo te da la energía para decir "esto no está bien" cuando sería más cómodo callar.',
            'Realidad. Respirar lento, relajar los músculos o hacer una pausa tranquila bajan el enojo mejor que las actividades que te aceleran más.',
          ],
          feedbacks_en: [
            'Myth. Research shows that "venting" by hitting or yelling tends to keep anger burning, not release it.',
            'Myth. What goes unsaid usually comes out later: as sarcasm, distance, or an explosion over something small.',
            'Fact. Used well, anger gives you the energy to say "this is not okay" when staying quiet would be easier.',
            'Fact. Slow breathing, relaxing your muscles, or a calm pause reduce anger better than activities that rev you up.',
          ],
        },
        {
          type: 'order',
          title_es: 'Enfriar antes de hablar',
          title_en: 'Cool down before talking',
          instruction_es: 'Pon en orden los pasos para expresar un enojo sin explotar.',
          instruction_en: 'Put the steps for expressing anger without exploding in order.',
          items_es: [
            'Notar las señales: calor, mandíbula tensa, voz más alta',
            'Pedir una pausa: "necesito unos minutos"',
            'Bajar la activación: respirar lento o caminar tranquilo',
            'Preguntarte qué límite o necesidad se cruzó',
            'Volver y decirlo con calma y firmeza',
          ],
          items_en: [
            'Notice the signals: heat, tight jaw, louder voice',
            'Ask for a pause: "I need a few minutes"',
            'Lower the arousal: slow breathing or a calm walk',
            'Ask yourself which boundary or need was crossed',
            'Come back and say it calmly and firmly',
          ],
          explanation_es:
            'La pausa no es huir: es avisar que vas a volver. Si nunca vuelves a hablarlo, se convierte en tragártelo.',
          explanation_en:
            'The pause is not running away: it is letting them know you will come back. If you never come back to it, it turns into swallowing it.',
        },
        {
          type: 'slider',
          question_es: 'Cuando te enojas, ¿qué tan seguido terminas diciendo algo de lo que te arrepientes?',
          question_en: 'When you get angry, how often do you end up saying something you regret?',
          minLabel_es: 'Casi nunca',
          minLabel_en: 'Almost never',
          maxLabel_es: 'Muy seguido',
          maxLabel_en: 'Very often',
          responses_es: [
            'Buen control. Revisa el otro lado: ¿dices lo que te molesta o te lo guardas? Callar mucho también cuesta.',
            'A veces se te escapa. Casi siempre pasa cuando hablas en el pico: la pausa de antes es tu mejor herramienta.',
            'No eres una mala persona: tu alarma se dispara rápido y fuerte. La pausa ("necesito unos minutos") es lo primero que vale la pena practicar.',
          ],
          responses_en: [
            'Good control. Check the other side: do you say what bothers you, or keep it in? Staying quiet too much also has a cost.',
            'Sometimes it slips out. It almost always happens when you speak at the peak: the pause is your best tool.',
            'You are not a bad person: your alarm fires fast and loud. The pause ("I need a few minutes") is the first thing worth practicing.',
          ],
        },
        {
          type: 'scenario',
          title_es: 'Cancelan otra vez',
          title_en: 'Cancelled again',
          situation_es: 'Es la tercera vez este mes que un amigo cancela los planes una hora antes. Estás en camino.',
          situation_en: 'It is the third time this month a friend cancels plans an hour before. You are already on your way.',
          options_es: [
            'Le contesto: "como siempre, ya ni me sorprende"',
            'Le digo "ok, no pasa nada" aunque sí me molesta',
            'Le digo "me molesta que se cancele a última hora; la próxima avísame antes"',
          ],
          options_en: [
            'Reply: "as usual, I am not even surprised anymore"',
            'Say "okay, no worries" even though it does bother me',
            'Say "it bothers me when plans get cancelled last minute; next time let me know sooner"',
          ],
          outcomes_es: [
            'El sarcasmo descarga un poco, pero tu amigo solo escucha un ataque y se defiende. Lo que de verdad te importa no llega.',
            'Evitas el conflicto hoy, pero el enojo se queda. A la cuarta cancelación probablemente explotes por algo menor.',
            'Nombras lo que pasó, cómo te afecta y lo que necesitas, sin atacar. No garantiza que cambie, pero le das la información para hacerlo.',
          ],
          outcomes_en: [
            'Sarcasm releases a bit, but your friend only hears an attack and gets defensive. What you actually care about does not get across.',
            'You avoid conflict today, but the anger stays. By the fourth cancellation you will probably explode over something minor.',
            'You name what happened, how it affects you, and what you need, without attacking. It does not guarantee change, but it gives them the information to change.',
          ],
        },
        {
          type: 'exercise',
          title_es: '¿Qué había debajo?',
          title_en: 'What was underneath?',
          instruction_es:
            'Recuerda tu último enojo fuerte. ¿Qué límite, necesidad o valor sentiste pisado? ¿Cómo podrías decirlo sin atacar?',
          instruction_en:
            'Recall your last strong anger. Which boundary, need or value felt stepped on? How could you say it without attacking?',
          placeholder_es: 'Ej: sentí que no respetaron mi tiempo; podría decir...',
          placeholder_en: 'E.g.: I felt my time was not respected; I could say...',
        },
      ],
    },

    // ═══════════════════════════════════════════════════════════════════════
    {
      id: 'emo_9',
      title_es: 'Miedo y ansiedad',
      title_en: 'Fear and anxiety',
      subtitle_es: 'Una alarma que a veces exagera',
      subtitle_en: 'An alarm that sometimes overreacts',
      xpReward: 30,
      steps: [
        {
          type: 'story',
          speaker: '🔔',
          title_es: 'La alarma de humo',
          title_en: 'The smoke alarm',
          lines_es: [
            'Imagina una alarma de humo que suena cada vez que tuestas pan.',
            '> Sería insoportable.',
            'Pues algo así pasa a veces con tu sistema de alarma. El miedo existe para protegerte de peligros reales.',
            'La ansiedad es esa misma alarma sonando por algo que podría pasar, aunque no esté pasando.',
            '> ¿Y cómo la apago?',
            'No se trata de arrancar la alarma: la necesitas. Se trata de revisar si de verdad hay fuego...',
            '...y de bajarle el volumen con el cuerpo. Eso es lo que vas a practicar hoy.',
          ],
          lines_en: [
            'Imagine a smoke alarm that goes off every time you make toast.',
            '> That would be unbearable.',
            'Well, something like that sometimes happens with your alarm system. Fear exists to protect you from real danger.',
            'Anxiety is that same alarm going off for something that could happen, even though it is not happening.',
            '> So how do I turn it off?',
            'It is not about ripping out the alarm: you need it. It is about checking whether there really is a fire...',
            '...and turning the volume down with your body. That is what you will practice today.',
          ],
        },
        {
          type: 'mythfact',
          title_es: 'Mitos sobre la ansiedad',
          title_en: 'Myths about anxiety',
          statements_es: [
            'Evitar lo que te da ansiedad la reduce a largo plazo',
            'La ansiedad se siente en el cuerpo: corazón acelerado, sudor, mareo',
            'Un poco de nervios puede ayudarte a rendir mejor',
            'Si sientes ansiedad, es porque algo malo va a pasar',
          ],
          statements_en: [
            'Avoiding what makes you anxious reduces anxiety in the long run',
            'Anxiety shows up in the body: racing heart, sweating, dizziness',
            'A few nerves can help you perform better',
            'If you feel anxious, it means something bad is going to happen',
          ],
          truths: [false, true, true, false],
          feedbacks_es: [
            'Mito. Evitar da alivio inmediato, pero le confirma a tu cerebro que era peligroso, y con el tiempo la ansiedad crece. Acercarte poco a poco es lo que la reduce.',
            'Realidad. Es tu sistema de alerta preparándote para actuar: muy incómodo, pero no peligroso en sí. Si tienes síntomas nuevos o muy fuertes, revísalo con un médico.',
            'Realidad. Una activación moderada te ayuda a concentrarte. El problema es cuando es tan alta que te bloquea.',
            'Mito. La ansiedad es una predicción, no una profecía. Sentir que algo va a salir mal no lo vuelve más probable.',
          ],
          feedbacks_en: [
            'Myth. Avoiding brings instant relief, but it confirms to your brain that it was dangerous, and over time anxiety grows. Approaching step by step is what reduces it.',
            'Fact. It is your alert system preparing you to act: very uncomfortable, but not dangerous in itself. If your symptoms are new or very intense, get checked by a doctor.',
            'Fact. Moderate arousal helps you focus. The problem is when it gets so high that it freezes you.',
            'Myth. Anxiety is a prediction, not a prophecy. Feeling that something will go wrong does not make it more likely.',
          ],
        },
        {
          type: 'practice',
          title_es: 'Respiración cuadrada',
          title_en: 'Box breathing',
          intro_es:
            'Cuatro tiempos para inhalar, sostener, exhalar y sostener, como si dibujaras un cuadrado. Si sostener te incomoda, solo haz la pausa más corta.',
          intro_en:
            'Four counts to breathe in, hold, breathe out and hold, as if tracing a square. If holding feels uncomfortable, just make the pause shorter.',
          prompts_es: ['Inhala', 'Sostén', 'Exhala', 'Sostén', 'Inhala', 'Sostén', 'Exhala', 'Sostén', 'Inhala', 'Sostén', 'Exhala', 'Sostén', 'Inhala', 'Sostén', 'Exhala', 'Descansa'],
          prompts_en: ['Breathe in', 'Hold', 'Breathe out', 'Hold', 'Breathe in', 'Hold', 'Breathe out', 'Hold', 'Breathe in', 'Hold', 'Breathe out', 'Hold', 'Breathe in', 'Hold', 'Breathe out', 'Rest'],
          durations: [4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4],
          motions: ['in', 'hold', 'out', 'hold', 'in', 'hold', 'out', 'hold', 'in', 'hold', 'out', 'hold', 'in', 'hold', 'out', 'still'],
          outro_es:
            'Respirar lento y parejo le manda a tu cuerpo la señal de que no hay peligro inmediato. Úsala antes de algo que te pone nervioso, no solo en medio de la tormenta.',
          outro_en:
            'Slow, even breathing signals to your body that there is no immediate danger. Use it before something that makes you nervous, not only in the middle of the storm.',
        },
        {
          type: 'pick',
          question_es: '¿Qué sueles hacer cuando algo te da ansiedad?',
          question_en: 'What do you tend to do when something makes you anxious?',
          options_es: [
            'Lo pospongo',
            'Busco que alguien me asegure que todo saldrá bien',
            'Reviso una y otra vez',
            'Me distraigo con el celular',
            'Pienso en todos los escenarios posibles',
            'Lo enfrento aunque esté nervioso',
          ],
          options_en: [
            'Put it off',
            'Look for someone to reassure me it will be fine',
            'Check again and again',
            'Distract myself with my phone',
            'Think through every possible scenario',
            'Face it even though I am nervous',
          ],
          explanation_es:
            'Posponer, pedir que te tranquilicen, revisar y darle vueltas se llaman "conductas de seguridad": alivian hoy y mantienen la ansiedad mañana. No hace falta dejarlas todas; empieza por notar cuál usas más.',
          explanation_en:
            'Putting off, seeking reassurance, checking and overthinking are called "safety behaviors": they relieve today and keep the anxiety going tomorrow. You do not have to drop them all; start by noticing which one you use most.',
        },
        {
          type: 'reveal',
          question_es: '¿Qué preguntarte cuando la ansiedad dice "va a salir mal"?',
          question_en: 'What should you ask when anxiety says "this will go wrong"?',
          answer_es:
            'Primero: "¿Qué es lo más probable que pase?" No lo peor ni lo mejor: lo más probable.\n\nDespués: "Si pasara lo que temo, ¿qué haría?" Casi siempre descubres que podrías con ello, aunque no te guste.\n\nSi la ansiedad es constante o te impide hacer tu vida, habla con un profesional: la ansiedad responde muy bien al tratamiento.',
          answer_en:
            'First: "What is most likely to happen?" Not the worst or the best: the most likely.\n\nThen: "If what I fear did happen, what would I do?" You almost always find you could handle it, even if you would not like it.\n\nIf anxiety is constant or keeps you from living your life, talk to a professional: anxiety responds very well to treatment.',
        },
        {
          type: 'commit',
          title_es: 'Un paso hacia lo que evitas',
          title_en: 'One step toward what you avoid',
          content_es: 'La ansiedad baja cuando te acercas en pasos pequeños. Elige el tuyo.',
          content_en: 'Anxiety goes down when you approach in small steps. Choose yours.',
          options_es: [
            'Hacer hoy esa llamada o mensaje que vengo posponiendo',
            'Hacer la respiración cuadrada antes de algo que me pone nervioso',
            'Preguntarme "¿qué es lo más probable?" la próxima vez que me preocupe',
          ],
          options_en: [
            'Make that call or send that message I keep putting off, today',
            'Do box breathing before something that makes me nervous',
            'Ask "what is most likely?" the next time I worry',
          ],
        },
      ],
    },

    // ═══════════════════════════════════════════════════════════════════════
    {
      id: 'emo_10',
      title_es: 'Tu caja de herramientas',
      title_en: 'Your toolbox',
      subtitle_es: 'Todo lo que aprendiste, listo para usar',
      subtitle_en: 'Everything you learned, ready to use',
      xpReward: 35,
      steps: [
        {
          type: 'reading',
          title_es: 'Regular no es reprimir',
          title_en: 'Regulating is not suppressing',
          content_es:
            'Regular una emoción no es hacerla desaparecer. Es manejar su intensidad para que puedas elegir qué hacer con ella.\n\nNo existe una herramienta que sirva para todo. La respiración lenta es excelente para la ansiedad, pero la tristeza suele pedir compañía y el enojo, una pausa y un límite claro.\n\nTener varias herramientas, y saber cuál usar, es lo que te da libertad.',
          content_en:
            'Regulating an emotion is not making it disappear. It is managing its intensity so you can choose what to do with it.\n\nNo single tool works for everything. Slow breathing is great for anxiety, but sadness usually needs company, and anger needs a pause and a clear boundary.\n\nHaving several tools, and knowing which one to use, is what gives you freedom.',
        },
        {
          type: 'sort',
          title_es: '¿Qué herramienta para qué emoción?',
          title_en: 'Which tool for which emotion?',
          instruction_es: 'Arrastra cada herramienta a la emoción donde suele funcionar mejor.',
          instruction_en: 'Drag each tool to the emotion it usually works best for.',
          categories_es: ['Ansiedad', 'Enojo', 'Tristeza'],
          categories_en: ['Anxiety', 'Anger', 'Sadness'],
          items_es: [
            'Respiración cuadrada',
            'Pedir una pausa antes de hablar',
            'Buscar a alguien de confianza',
            'Preguntarme qué es lo más probable',
            'Identificar qué límite se cruzó',
            'Darme permiso de sentirla sin prisa',
          ],
          items_en: [
            'Box breathing',
            'Asking for a pause before talking',
            'Reaching out to someone I trust',
            'Asking what is most likely',
            'Identifying which boundary was crossed',
            'Giving myself permission to feel it, unhurried',
          ],
          itemCategory: [0, 1, 2, 0, 1, 2],
          explanation_es: 'Muchas herramientas sirven para varias emociones; esta es la combinación más típica, no la única.',
          explanation_en: 'Many tools work for several emotions; this is the most typical match, not the only one.',
        },
        {
          type: 'quiz',
          question_es: '¿Qué significa regular una emoción?',
          question_en: 'What does regulating an emotion mean?',
          options_es: ['Hacer que desaparezca', 'Manejar su intensidad y elegir qué hacer con ella', 'No mostrársela a nadie'],
          options_en: ['Making it disappear', 'Managing its intensity and choosing what to do with it', 'Never showing it to anyone'],
          correctIndex: 1,
          explanation_es: 'La emoción puede seguir ahí. Lo que cambia es que ya no decide por ti.',
          explanation_en: 'The emotion can still be there. What changes is that it no longer decides for you.',
        },
        {
          type: 'order',
          title_es: 'Del golpe a la decisión',
          title_en: 'From the hit to the decision',
          instruction_es: 'Repasa la ruta completa: ordena lo que haces desde que llega una emoción fuerte.',
          instruction_en: 'Review the whole route: order what you do from the moment a strong emotion arrives.',
          items_es: [
            'Notar la señal en el cuerpo',
            'Nombrar la emoción con precisión',
            'Separar hechos de interpretaciones',
            'Dejar que la ola baje un poco',
            'Elegir una respuesta',
          ],
          items_en: [
            'Notice the signal in your body',
            'Name the emotion precisely',
            'Separate facts from interpretations',
            'Let the wave come down a bit',
            'Choose a response',
          ],
          explanation_es: 'En la vida real no siempre es tan ordenado, y está bien. Cada paso que logres dar ya cambia el resultado.',
          explanation_en: 'Real life is not always this tidy, and that is fine. Every step you manage to take already changes the outcome.',
        },
        {
          type: 'pick',
          question_es: 'Arma tu caja: ¿qué herramientas quieres tener a mano?',
          question_en: 'Build your toolbox: which tools do you want at hand?',
          options_es: ['Respiración lenta', 'Técnica STOP', 'Nombrar la emoción', 'Escribir', 'Caminar', 'Hablar con alguien', 'Música', 'Pedir una pausa'],
          options_en: ['Slow breathing', 'STOP technique', 'Naming the emotion', 'Writing', 'Walking', 'Talking to someone', 'Music', 'Asking for a pause'],
          responses_es: [
            'Pocas y bien elegidas es mejor que muchas que nunca usas. Practícalas en calma para que salgan solas cuando las necesites.',
            'Buena variedad: tienes opciones para distintas emociones y lugares. Practica primero la que menos conoces.',
            'Tienes una caja muy completa. El reto ahora es usarlas: elige una para practicar esta semana.',
          ],
          responses_en: [
            'A few well-chosen tools beat many you never use. Practice them while calm so they come naturally when you need them.',
            'Good variety: you have options for different emotions and places. Practice the least familiar one first.',
            'That is a very complete toolbox. The challenge now is using it: pick one to practice this week.',
          ],
        },
        {
          type: 'exercise',
          title_es: 'Tu plan de emergencia',
          title_en: 'Your emergency plan',
          instruction_es: 'Completa al menos dos veces: "Cuando sienta ___, voy a ___."',
          instruction_en: 'Complete at least twice: "When I feel ___, I will ___."',
          placeholder_es: 'Ej: Cuando sienta ansiedad, voy a hacer respiración cuadrada. Cuando sienta enojo, voy a pedir diez minutos...',
          placeholder_en: 'E.g.: When I feel anxious, I will do box breathing. When I feel angry, I will ask for ten minutes...',
        },
        {
          type: 'commit',
          title_es: 'Esta semana',
          title_en: 'This week',
          content_es: 'Terminaste la ruta. Lo que la vuelve real es usarla fuera de la app.',
          content_en: 'You finished the route. What makes it real is using it outside the app.',
          options_es: [
            'Usar una herramienta nueva de mi caja',
            'Hacer mi check-in de ánimo todos los días',
            'Repetir la lección que más me costó',
          ],
          options_en: [
            'Use a new tool from my toolbox',
            'Do my mood check-in every day',
            'Redo the lesson I found hardest',
          ],
        },
      ],
    },
  ],
};
