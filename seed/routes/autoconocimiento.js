// Ruta: Autoconocimiento
// IDs de lecciones permanentes: el progreso de los usuarios se guarda por id.

module.exports = {
  id: 'autoconocimiento',
  order: 1,
  title_es: 'Autoconocimiento',
  title_en: 'Self-Knowledge',
  description_es: 'Descubre quién eres realmente',
  description_en: 'Discover who you really are',
  emoji: '🔍',
  color: 0xff10b981,
  colorDark: 0xff059669,

  lessons: [
    // ═══════════════════════════════════════════════════════════════════════
    {
      id: 'auto_1',
      title_es: 'Tus valores',
      title_en: 'Your values',
      subtitle_es: 'La brújula que ya llevas dentro',
      subtitle_en: 'The compass you already carry',
      xpReward: 20,
      steps: [
        {
          type: 'story',
          speaker: '🧭',
          title_es: 'Dos ofertas de trabajo',
          title_en: 'Two job offers',
          lines_es: [
            '* Te ofrecen dos trabajos al mismo tiempo.',
            'Uno paga un 30% más, pero viajarías mucho y casi no verías a tu familia.',
            'El otro paga menos, pero tiene horario flexible y aprenderías cosas nuevas.',
            '> Uf... depende.',
            'Exacto: depende de tus valores. No hay respuesta correcta, hay respuesta tuya.',
            'Los valores son como una brújula: no te dicen a dónde llegar, te dicen hacia dónde caminar.',
            'Cuando vives de espaldas a ellos, algo se siente vacío aunque todo "vaya bien".',
          ],
          lines_en: [
            '* You get two job offers at the same time.',
            'One pays 30% more, but you would travel a lot and barely see your family.',
            'The other pays less, but has flexible hours and you would learn new things.',
            '> Ugh... it depends.',
            'Exactly: it depends on your values. There is no right answer, only your answer.',
            'Values are like a compass: they do not tell you where to arrive, they tell you which way to walk.',
            'When you live with your back to them, something feels empty even when everything is "going well".',
          ],
        },
        {
          type: 'sort',
          title_es: '¿Valor o meta?',
          title_en: 'Value or goal?',
          instruction_es: 'Se parecen, pero no son lo mismo. Arrastra cada frase a su lugar.',
          instruction_en: 'They look alike, but they are not the same. Drag each phrase where it belongs.',
          categories_es: ['Valor (una dirección)', 'Meta (un destino)'],
          categories_en: ['Value (a direction)', 'Goal (a destination)'],
          items_es: ['Ser honesto', 'Comprar una casa', 'Aprender siempre', 'Correr un maratón', 'Cuidar a mi familia', 'Conseguir un ascenso'],
          items_en: ['Being honest', 'Buying a house', 'Always learning', 'Running a marathon', 'Caring for my family', 'Getting a promotion'],
          itemCategory: [0, 1, 0, 1, 0, 1],
          explanation_es:
            'Una meta se cumple y se tacha. Un valor nunca se termina: siempre puedes seguir viviéndolo. Las metas tienen más sentido cuando van en la dirección de tus valores.',
          explanation_en:
            'A goal gets done and crossed off. A value is never finished: you can always keep living it. Goals make the most sense when they point in the direction of your values.',
        },
        {
          type: 'pick',
          question_es: '¿Cuáles de estos valores te importan de verdad?',
          question_en: 'Which of these values truly matter to you?',
          options_es: ['Honestidad', 'Familia', 'Libertad', 'Creatividad', 'Justicia', 'Aventura', 'Seguridad', 'Crecimiento', 'Amistad', 'Salud', 'Generosidad', 'Espiritualidad'],
          options_en: ['Honesty', 'Family', 'Freedom', 'Creativity', 'Fairness', 'Adventure', 'Security', 'Growth', 'Friendship', 'Health', 'Generosity', 'Spirituality'],
          responses_es: [
            'Pocos y claros: eso hace mucho más fácil tomar decisiones difíciles.',
            'Tienes varios valores importantes. Cuando choquen entre sí (aventura contra seguridad, por ejemplo), la forma en que eliges dice mucho de ti.',
            'Marcaste muchos, y es normal: todos suenan bien. Intenta quedarte con tres, los que defenderías aunque te costara algo.',
          ],
          responses_en: [
            'Few and clear: that makes hard decisions much easier.',
            'You have several important values. When they clash (adventure versus security, for example), how you choose says a lot about you.',
            'You checked many, which is normal: they all sound good. Try narrowing to three, the ones you would stand up for even if it cost you something.',
          ],
        },
        {
          type: 'slider',
          question_es: '¿Qué tan lejos está tu semana real de lo que marcaste como importante?',
          question_en: 'How far is your actual week from what you marked as important?',
          minLabel_es: 'Muy cerca',
          minLabel_en: 'Very close',
          maxLabel_es: 'Muy lejos',
          maxLabel_en: 'Very far',
          responses_es: [
            'Tu día a día refleja lo que te importa. Esa coherencia es una fuente enorme de bienestar: cuídala cuando la vida se complique.',
            'Hay partes alineadas y partes que no. Es lo más común. Fíjate en cuál valor tiene la brecha más grande.',
            'Hay una distancia grande, y notarla ya es un paso. No hace falta cambiar tu vida entera: un solo acto pequeño alineado cambia cómo se siente la semana.',
          ],
          responses_en: [
            'Your daily life reflects what matters to you. That coherence is a huge source of wellbeing: protect it when life gets complicated.',
            'Some parts line up and some do not. That is the most common case. Notice which value has the biggest gap.',
            'There is a big distance, and noticing it is already a step. You do not need to change your whole life: one small aligned act changes how the week feels.',
          ],
        },
        {
          type: 'reveal',
          question_es: 'Si valoras la salud pero no haces ejercicio, ¿es mentira que la valoras?',
          question_en: 'If you value health but do not exercise, is it a lie that you value it?',
          answer_es:
            'No. Los valores no son una calificación, son una dirección. Todos vivimos brechas entre lo que valoramos y lo que hacemos.\n\nNotar la brecha no es para culparte: es la información exacta de dónde un pequeño cambio tendría más sentido.',
          answer_en:
            'No. Values are not a grade, they are a direction. Everyone lives with gaps between what they value and what they do.\n\nNoticing the gap is not for blaming yourself: it is exact information about where a small change would mean the most.',
        },
        {
          type: 'commit',
          title_es: 'Un acto alineado',
          title_en: 'One aligned act',
          content_es: 'Los valores se notan en lo que haces, no en lo que dices. Elige un acto pequeño para hoy.',
          content_en: 'Values show in what you do, not in what you say. Choose one small act for today.',
          options_es: [
            'Hacer algo pequeño por mi valor número uno',
            'Contarle a alguien por qué algo me importa tanto',
            'Revisar mi agenda de mañana y ver si refleja lo que valoro',
          ],
          options_en: [
            'Do something small for my number one value',
            'Tell someone why something matters so much to me',
            'Check tomorrow’s schedule and see whether it reflects what I value',
          ],
        },
      ],
    },

    // ═══════════════════════════════════════════════════════════════════════
    {
      id: 'auto_2',
      title_es: 'Fortalezas personales',
      title_en: 'Personal strengths',
      subtitle_es: 'Lo que te da energía al hacerlo',
      subtitle_en: 'What energizes you when you do it',
      xpReward: 20,
      steps: [
        {
          type: 'reading',
          title_es: 'Tus superpoderes',
          title_en: 'Your superpowers',
          content_es:
            'Una fortaleza no es solo algo que haces bien: es algo que haces bien y que te da energía al hacerlo.\n\nLos psicólogos que estudian las fortalezas de carácter describen 24, como la curiosidad, la amabilidad, el humor, la perseverancia o la gratitud.\n\nUsar tus fortalezas principales de formas nuevas se asocia con más bienestar. Y conocerlas te ayuda a confiar en ti cuando las cosas se ponen difíciles.',
          content_en:
            'A strength is not just something you do well: it is something you do well that energizes you while you do it.\n\nPsychologists who study character strengths describe 24, such as curiosity, kindness, humor, perseverance and gratitude.\n\nUsing your top strengths in new ways is linked to greater wellbeing. And knowing them helps you trust yourself when things get hard.',
        },
        {
          type: 'quiz',
          question_es: '¿Cómo reconoces una fortaleza personal?',
          question_en: 'How do you recognize a personal strength?',
          options_es: ['Es algo que te cuesta muchísimo', 'Es algo que haces bien y te da energía', 'Es algo que otros admiran aunque no lo disfrutes'],
          options_en: ['It is something very hard for you', 'It is something you do well that energizes you', 'It is something others admire even if you do not enjoy it'],
          correctIndex: 1,
          explanation_es:
            'Puedes ser bueno en algo que te agota: eso es una habilidad aprendida. Las fortalezas te llenan en vez de vaciarte.',
          explanation_en:
            'You can be good at something that drains you: that is a learned skill. Strengths fill you up instead of emptying you.',
        },
        {
          type: 'pick',
          question_es: '¿Cuáles de estas fortalezas reconoces en ti?',
          question_en: 'Which of these strengths do you recognize in yourself?',
          options_es: ['Curiosidad', 'Amabilidad', 'Humor', 'Perseverancia', 'Creatividad', 'Honestidad', 'Valentía', 'Gratitud', 'Liderazgo', 'Prudencia', 'Trabajo en equipo', 'Capacidad de perdonar'],
          options_en: ['Curiosity', 'Kindness', 'Humor', 'Perseverance', 'Creativity', 'Honesty', 'Bravery', 'Gratitude', 'Leadership', 'Prudence', 'Teamwork', 'Forgiveness'],
          explanation_es:
            'Si te costó marcar, no es que no tengas fortalezas: nos enseñan a ver defectos con más facilidad que virtudes. Pregúntale a alguien cercano; suele ver lo que tú no.',
          explanation_en:
            'If it was hard to check any, it is not that you lack strengths: we are taught to spot flaws more easily than virtues. Ask someone close to you; they often see what you do not.',
        },
        {
          type: 'reveal',
          question_es: '¿Una fortaleza puede volverse un problema?',
          question_en: 'Can a strength become a problem?',
          answer_es:
            'Sí, cuando se usa de más. La perseverancia en exceso es terquedad; la amabilidad sin límites, complacencia; la prudencia extrema, parálisis.\n\nLa pregunta no es solo "¿qué fortalezas tengo?", sino "¿cuánto de cada una necesita esta situación?"',
          answer_en:
            'Yes, when it is overused. Too much perseverance becomes stubbornness; kindness without limits, people-pleasing; extreme prudence, paralysis.\n\nThe question is not only "what strengths do I have?" but "how much of each does this situation need?"',
        },
        {
          type: 'scenario',
          title_es: 'El proyecto atorado',
          title_en: 'The stuck project',
          situation_es:
            'Tu equipo lleva dos semanas sin avanzar en un proyecto. Hay tensión, nadie sabe bien qué sigue y un compañero se ve desanimado.',
          situation_en:
            'Your team has made no progress on a project for two weeks. There is tension, nobody is sure what comes next, and one teammate looks discouraged.',
          options_es: [
            'Propongo una idea totalmente distinta para destrabarlo',
            'Organizo quién hace qué y para cuándo',
            'Me acerco al compañero desanimado para ver cómo está',
          ],
          options_en: [
            'Propose a completely different idea to get unstuck',
            'Organize who does what and by when',
            'Check in with the discouraged teammate',
          ],
          outcomes_es: [
            'Usas creatividad. Es justo lo que hace falta cuando el problema es de enfoque. Si el problema es de organización, conviene combinarla con alguien que aterrice la idea.',
            'Usas liderazgo. Da claridad y baja la tensión rápido. Cuida que no se sienta como imponer: pregunta antes de repartir.',
            'Usas amabilidad. Un equipo con alguien que se siente visto trabaja mejor. No destraba el proyecto por sí sola, pero sostiene a quien lo va a destrabar.',
          ],
          outcomes_en: [
            'You use creativity. It is exactly what helps when the problem is the approach. If the problem is organization, pair it with someone who can ground the idea.',
            'You use leadership. It brings clarity and lowers tension fast. Make sure it does not feel imposed: ask before assigning.',
            'You use kindness. A team where someone feels seen works better. It does not unblock the project on its own, but it supports the person who will.',
          ],
        },
        {
          type: 'exercise',
          title_es: 'Mapa de fortalezas',
          title_en: 'Strengths map',
          instruction_es: 'Escribe tus tres fortalezas principales y, para cada una, una forma nueva de usarla esta semana.',
          instruction_en: 'Write your top three strengths and, for each one, a new way to use it this week.',
          placeholder_es: 'Ej: Curiosidad → preguntarle a un compañero sobre su trabajo...',
          placeholder_en: 'E.g.: Curiosity → ask a coworker about their work...',
        },
      ],
    },

    // ═══════════════════════════════════════════════════════════════════════
    {
      id: 'auto_3',
      title_es: 'Patrones de pensamiento',
      title_en: 'Thought patterns',
      subtitle_es: 'No creas todo lo que piensas',
      subtitle_en: 'Do not believe everything you think',
      xpReward: 25,
      steps: [
        {
          type: 'reading',
          title_es: 'Las historias que te cuentas',
          title_en: 'The stories you tell yourself',
          content_es:
            'Tu mente produce pensamientos automáticos todo el día. Muchos son útiles; otros son atajos que distorsionan la realidad y cambian cómo te sientes.\n\nTres muy comunes:\n• Todo o nada: "si no es perfecto, es un fracaso"\n• Catastrofizar: "esto va a terminar en desastre"\n• Leer mentes: "seguro piensa mal de mí"\n\nNo desaparecen por saberlo, pero reconocerlos les quita poder.',
          content_en:
            'Your mind produces automatic thoughts all day. Many are useful; others are shortcuts that distort reality and change how you feel.\n\nThree very common ones:\n• All or nothing: "if it is not perfect, it is a failure"\n• Catastrophizing: "this is going to end in disaster"\n• Mind reading: "they surely think badly of me"\n\nThey do not vanish because you know about them, but recognizing them takes away their power.',
        },
        {
          type: 'sort',
          title_es: 'Atrapa la distorsión',
          title_en: 'Catch the distortion',
          instruction_es: 'Arrastra cada pensamiento a la distorsión que representa.',
          instruction_en: 'Drag each thought to the distortion it shows.',
          categories_es: ['Todo o nada', 'Catastrofizar', 'Leer mentes'],
          categories_en: ['All or nothing', 'Catastrophizing', 'Mind reading'],
          items_es: [
            'Si no me sale perfecto, no sirvo',
            'Me equivoqué en un correo: me van a despedir',
            'No me saludó, seguro está molesto conmigo',
            'O me va increíble o es un desastre',
            'Si fallo esta entrevista, nunca voy a conseguir trabajo',
            'Se nota que todos piensan que soy aburrido',
          ],
          items_en: [
            'If it does not come out perfect, I am useless',
            'I made a mistake in an email: I am going to get fired',
            'They did not say hi, they must be upset with me',
            'Either it goes amazingly or it is a disaster',
            'If I blow this interview, I will never get a job',
            'It is obvious everyone thinks I am boring',
          ],
          itemCategory: [0, 1, 2, 0, 1, 2],
          explanation_es:
            'Pista: todo o nada no ve grises, catastrofizar salta al peor final y leer mentes da por hecho lo que otro piensa sin preguntarlo.',
          explanation_en:
            'Hint: all or nothing sees no gray, catastrophizing jumps to the worst ending, and mind reading assumes what someone thinks without asking.',
        },
        {
          type: 'quiz',
          question_es: '"Si no saco 10, soy un fracaso" es un ejemplo de:',
          question_en: '"If I do not get a perfect score, I am a failure" is an example of:',
          options_es: ['Pensamiento realista', 'Pensamiento todo o nada', 'Pensamiento positivo'],
          options_en: ['Realistic thinking', 'All-or-nothing thinking', 'Positive thinking'],
          correctIndex: 1,
          explanation_es: 'El pensamiento todo o nada no reconoce matices. Un 8 no es un fracaso: es un buen resultado.',
          explanation_en: 'All-or-nothing thinking does not see nuance. A B+ is not a failure: it is a good result.',
        },
        {
          type: 'mythfact',
          title_es: 'Pensamientos y verdad',
          title_en: 'Thoughts and truth',
          statements_es: [
            'Si lo pienso, debe ser verdad',
            'Todos tenemos pensamientos automáticos negativos',
            'La solución es pensar siempre en positivo',
            'Cambiar cómo interpretas algo puede cambiar cómo te sientes',
          ],
          statements_en: [
            'If I think it, it must be true',
            'Everyone has negative automatic thoughts',
            'The solution is to always think positive',
            'Changing how you interpret something can change how you feel',
          ],
          truths: [false, true, false, true],
          feedbacks_es: [
            'Mito. Los pensamientos son hipótesis, no hechos. Tu mente produce muchísimos al día, y buena parte es ruido.',
            'Realidad. No es señal de que algo esté mal contigo. La diferencia está en si te los crees sin revisarlos.',
            'Mito. Forzar lo positivo suena falso y no dura. Lo útil es un pensamiento equilibrado: realista, con lo bueno y lo malo.',
            'Realidad. Es la base de la terapia cognitivo-conductual, uno de los tratamientos psicológicos con más evidencia.',
          ],
          feedbacks_en: [
            'Myth. Thoughts are hypotheses, not facts. Your mind produces a huge number every day, and much of it is noise.',
            'Fact. It is not a sign that something is wrong with you. The difference is whether you believe them without checking.',
            'Myth. Forced positivity sounds fake and does not last. What helps is balanced thinking: realistic, with the good and the bad.',
            'Fact. This is the basis of cognitive behavioral therapy, one of the most evidence-backed psychological treatments.',
          ],
        },
        {
          type: 'scenario',
          title_es: '"Buen trabajo, pero..."',
          title_en: '"Good job, but..."',
          situation_es: 'Tu jefa revisa tu informe y te dice: "Buen trabajo. Solo revisa la sección tres".',
          situation_en: 'Your boss reviews your report and says: "Good job. Just take another look at section three."',
          options_es: [
            'Solo escucho "revisa la sección tres": lo hice mal',
            'En general le gustó, y hay un detalle que mejorar',
            'Seguro lo dice por compromiso; no le gustó nada',
          ],
          options_en: [
            'All I hear is "section three": I did it wrong',
            'Overall she liked it, and there is one detail to improve',
            'She is just being polite; she did not like any of it',
          ],
          outcomes_es: [
            'Esto se llama filtro mental: te quedas solo con lo negativo e ignoras el resto. Te vas a sentir mal por algo que en realidad fue una buena noticia.',
            'Pensamiento equilibrado: tomas lo bueno y lo que hay que corregir. Te permite mejorar sin derrumbarte.',
            'Lectura de mente: das por hecho una intención que nadie expresó. Si de verdad dudas, lo más útil es preguntar.',
          ],
          outcomes_en: [
            'This is called mental filtering: you keep only the negative and ignore the rest. You will feel bad about something that was actually good news.',
            'Balanced thinking: you take in the good and what needs fixing. It lets you improve without falling apart.',
            'Mind reading: you assume an intention nobody expressed. If you truly doubt it, the most useful move is to ask.',
          ],
        },
        {
          type: 'exercise',
          title_es: 'Atrapa un pensamiento',
          title_en: 'Catch a thought',
          instruction_es: 'Escribe un pensamiento negativo que se te repite. Luego escribe una versión más equilibrada y realista.',
          instruction_en: 'Write down a negative thought that keeps coming back. Then write a more balanced, realistic version.',
          placeholder_es: 'Pensamiento: "Nunca hago nada bien"\nEquilibrado: "A veces me equivoco, y también hago muchas cosas bien"',
          placeholder_en: 'Thought: "I never do anything right"\nBalanced: "Sometimes I make mistakes, and I also do many things well"',
        },
      ],
    },

    // ═══════════════════════════════════════════════════════════════════════
    {
      id: 'auto_4',
      title_es: 'Lo que necesitas',
      title_en: 'What you need',
      subtitle_es: 'La necesidad detrás de la emoción',
      subtitle_en: 'The need behind the emotion',
      xpReward: 25,
      steps: [
        {
          type: 'story',
          title_es: 'Un mal día cualquiera',
          title_en: 'Just a bad day',
          lines_es: [
            '* Llegas a casa agotado. Alguien te pregunta algo sencillo y le contestas de mala manera.',
            '> No sé qué me pasa, ando irritable.',
            'La irritación casi siempre es una emoción mensajera. ¿Qué te faltó hoy?',
            '> Pues... no comí bien, no paré en todo el día y nadie me preguntó cómo estaba.',
            'Ahí está: descanso, alimento, que te tomen en cuenta.',
            'Detrás de muchas emociones difíciles hay una necesidad sin atender.',
            'Cuando atiendes la necesidad, la emoción ya no tiene que gritar.',
          ],
          lines_en: [
            '* You get home exhausted. Someone asks you something simple and you snap at them.',
            '> I do not know what is wrong with me, I am so irritable.',
            'Irritation is almost always a messenger emotion. What did you go without today?',
            '> Well... I did not eat properly, I did not stop all day, and nobody asked how I was.',
            'There it is: rest, food, being noticed.',
            'Behind many difficult emotions there is an unmet need.',
            'When you meet the need, the emotion no longer has to shout.',
          ],
        },
        {
          type: 'sort',
          title_es: '¿Qué necesidad hay detrás?',
          title_en: 'What need is behind it?',
          instruction_es: 'Arrastra cada situación a la necesidad que probablemente no está cubierta.',
          instruction_en: 'Drag each situation to the need that is probably not being met.',
          categories_es: ['Descanso', 'Conexión', 'Reconocimiento'],
          categories_en: ['Rest', 'Connection', 'Recognition'],
          items_es: [
            'Estoy irritable después de dormir cinco horas',
            'Me siento solo aunque estoy rodeado de gente',
            'Me molesta que nadie note mi esfuerzo',
            'Todo me abruma al final de la semana',
            'Extraño hablar de verdad con alguien',
            'Me frustra que nunca tomen en cuenta mis ideas',
          ],
          items_en: [
            'I am irritable after five hours of sleep',
            'I feel lonely even though I am surrounded by people',
            'It bothers me that nobody notices my effort',
            'Everything overwhelms me by the end of the week',
            'I miss having a real conversation with someone',
            'It frustrates me that my ideas are never considered',
          ],
          itemCategory: [0, 1, 2, 0, 1, 2],
          explanation_es:
            'La misma emoción, como la irritación, puede venir de necesidades muy distintas. Por eso conviene preguntar "¿qué me falta?" y no solo "¿qué siento?".',
          explanation_en:
            'The same emotion, like irritation, can come from very different needs. That is why it helps to ask "what am I missing?" and not just "what am I feeling?".',
        },
        {
          type: 'reveal',
          question_es: '¿Por qué nos cuesta tanto reconocer lo que necesitamos?',
          question_en: 'Why is it so hard to recognize what we need?',
          answer_es:
            'Mucha gente aprendió que necesitar es ser débil o una carga: "no molestes", "no seas exigente".\n\nPero las necesidades no desaparecen por ignorarlas; se vuelven irritación, cansancio o resentimiento. Nombrarlas es el primer paso para cuidarlas, tú mismo o pidiendo ayuda.',
          answer_en:
            'Many people learned that having needs means being weak or a burden: "do not bother anyone", "do not be demanding".\n\nBut needs do not disappear when ignored; they turn into irritation, fatigue or resentment. Naming them is the first step to caring for them, on your own or by asking for help.',
        },
        {
          type: 'pick',
          question_es: '¿Qué necesidades has dejado de lado últimamente?',
          question_en: 'Which needs have you been neglecting lately?',
          options_es: ['Dormir bien', 'Comer con calma', 'Moverme', 'Tiempo a solas', 'Tiempo con amigos', 'Sentirme escuchado', 'Divertirme', 'Aprender algo', 'Orden y calma', 'Afecto'],
          options_en: ['Sleeping well', 'Eating calmly', 'Moving my body', 'Time alone', 'Time with friends', 'Feeling heard', 'Having fun', 'Learning something', 'Order and calm', 'Affection'],
          responses_es: [
            'Tienes tus necesidades bastante cubiertas, o te cuesta notar cuáles faltan. Vuelve a revisar en un día pesado.',
            'Varias necesidades están esperando. No tienes que atenderlas todas: elige la que más cambiaría tu semana.',
            'Estás cargando mucho con poco combustible. No es falta de fuerza: es señal de que necesitas priorizarte, y quizá pedir apoyo.',
          ],
          responses_en: [
            'Your needs are fairly well covered, or it is hard for you to notice what is missing. Check again on a heavy day.',
            'Several needs are waiting. You do not have to meet them all: pick the one that would change your week the most.',
            'You are carrying a lot on very little fuel. That is not a lack of strength: it is a sign you need to prioritize yourself, and maybe ask for support.',
          ],
        },
        {
          type: 'quiz',
          question_es: 'Llevas días irritable con todos. ¿Qué es lo más útil preguntarte?',
          question_en: 'You have been irritable with everyone for days. What is the most useful question to ask?',
          options_es: ['¿Por qué la gente está tan insoportable?', '¿Qué necesito que no he tenido?', '¿Cómo dejo de sentir esto?'],
          options_en: ['Why is everyone so unbearable?', 'What do I need that I have not been getting?', 'How do I stop feeling this?'],
          correctIndex: 1,
          explanation_es:
            'Cuando la irritación es con todos, casi nunca el problema son todos. Suele ser una necesidad propia que lleva tiempo sin atenderse.',
          explanation_en:
            'When you are irritated with everyone, the problem is rarely everyone. It is usually a need of yours that has gone unmet for a while.',
        },
        {
          type: 'exercise',
          title_es: 'Emoción, necesidad, acción',
          title_en: 'Emotion, need, action',
          instruction_es: 'Elige una emoción difícil de esta semana. ¿Qué necesidad había detrás? ¿Qué acción pequeña la atendería?',
          instruction_en: 'Pick a difficult emotion from this week. What need was behind it? What small action would meet it?',
          placeholder_es: 'Ej: frustración → necesitaba que me escucharan → pedirle a mi amiga un rato para hablar...',
          placeholder_en: 'E.g.: frustration → I needed to be heard → ask my friend for some time to talk...',
        },
      ],
    },

    // ═══════════════════════════════════════════════════════════════════════
    {
      id: 'auto_5',
      title_es: 'Tu batería',
      title_en: 'Your battery',
      subtitle_es: 'Qué te carga y qué te drena',
      subtitle_en: 'What charges you and what drains you',
      xpReward: 25,
      steps: [
        {
          type: 'reading',
          title_es: 'No solo es dormir',
          title_en: 'It is not just sleep',
          content_es:
            'Tu energía no depende solo de cuánto duermes. Actividades, personas y lugares también cargan o drenan tu batería.\n\nY es muy personal: una fiesta puede recargar a alguien y dejar agotado a otro. Un domingo en silencio puede ser descanso o aburrimiento.\n\nConocer tu propia lista te ayuda a planear mejor la semana y a notar cuándo estás funcionando con la batería en rojo.',
          content_en:
            'Your energy does not depend only on how much you sleep. Activities, people and places also charge or drain your battery.\n\nAnd it is very personal: a party can recharge one person and exhaust another. A quiet Sunday can be rest or boredom.\n\nKnowing your own list helps you plan your week better and notice when you are running on a red battery.',
        },
        {
          type: 'pick',
          question_es: '¿Qué te recarga de verdad?',
          question_en: 'What truly recharges you?',
          options_es: ['Estar en la naturaleza', 'Una buena conversación', 'Tiempo a solas', 'Hacer ejercicio', 'Crear algo', 'Ordenar mi espacio', 'Escuchar música', 'Ayudar a alguien', 'Una siesta', 'Aprender algo nuevo'],
          options_en: ['Being in nature', 'A good conversation', 'Time alone', 'Exercising', 'Making something', 'Tidying my space', 'Listening to music', 'Helping someone', 'A nap', 'Learning something new'],
          explanation_es:
            'Esta es tu lista de recarga. Tenla presente para los días de batería baja: justo cuando estás agotado es cuando más cuesta recordar qué te ayuda.',
          explanation_en:
            'This is your recharge list. Keep it in mind for low-battery days: right when you are exhausted is when it is hardest to remember what helps.',
        },
        {
          type: 'mythfact',
          title_es: 'Mitos sobre la energía',
          title_en: 'Myths about energy',
          statements_es: [
            'Descansar es perder el tiempo',
            'Ver redes sociales siempre es descanso',
            'Algunas personas te dejan con más energía y otras con menos',
            'Decir que no puede ser una forma de cuidar tu energía',
          ],
          statements_en: [
            'Resting is a waste of time',
            'Scrolling social media is always restful',
            'Some people leave you with more energy and others with less',
            'Saying no can be a way to protect your energy',
          ],
          truths: [false, false, true, true],
          feedbacks_es: [
            'Mito. El descanso es parte del rendimiento, no su enemigo. Sin recarga, la concentración y el ánimo caen.',
            'Mito. Muchas veces se siente como descanso, pero deja la mente más cansada, sobre todo cuando hay comparación.',
            'Realidad. Fíjate cómo te sientes después de ver a cada persona. No es para juzgarla, es para saber cuánto tiempo y cuándo.',
            'Realidad. Cada sí a algo que te drena es un no a algo que te carga. Un no a tiempo es cuidado, no egoísmo.',
          ],
          feedbacks_en: [
            'Myth. Rest is part of performance, not its enemy. Without recharging, focus and mood drop.',
            'Myth. It often feels like rest but leaves your mind more tired, especially when comparison is involved.',
            'Fact. Notice how you feel after seeing each person. It is not about judging them, it is about knowing how much time and when.',
            'Fact. Every yes to something that drains you is a no to something that charges you. A timely no is self-care, not selfishness.',
          ],
        },
        {
          type: 'slider',
          question_es: '¿Qué tan agotado te has sentido esta semana?',
          question_en: 'How drained have you felt this week?',
          minLabel_es: 'Con energía',
          minLabel_en: 'Energized',
          maxLabel_es: 'Agotado',
          maxLabel_en: 'Drained',
          responses_es: [
            'Tu batería está bien. Buen momento para notar qué estás haciendo distinto y protegerlo.',
            'Batería a media carga. Todavía hay margen: una sola actividad de tu lista de recarga puede cambiar el final de la semana.',
            'Batería en rojo. No es momento de exigirte más, es momento de recargar. Si el agotamiento dura semanas, vale la pena hablarlo con un profesional.',
          ],
          responses_en: [
            'Your battery is in good shape. A good moment to notice what you are doing differently and protect it.',
            'Half-charged battery. There is still room: a single activity from your recharge list can change how the week ends.',
            'Battery in the red. This is not the time to push harder, it is the time to recharge. If the exhaustion lasts for weeks, it is worth talking to a professional.',
          ],
        },
        {
          type: 'scenario',
          title_es: 'Un sábado libre',
          title_en: 'A free Saturday',
          situation_es: 'Tuviste una semana muy pesada. Te invitan a una fiesta el sábado, y también tienes muchas ganas de quedarte en casa.',
          situation_en: 'You had a very heavy week. You get invited to a party on Saturday, and you also really want to stay home.',
          options_es: [
            'Voy aunque no tenga ganas, para no quedar mal',
            'Me quedo en casa sin culpa',
            'Voy un rato corto y me regreso temprano',
          ],
          options_en: [
            'Go even though I do not feel like it, so I do not look bad',
            'Stay home without guilt',
            'Go for a short while and leave early',
          ],
          outcomes_es: [
            'A veces ir por compromiso está bien. Pero si es un patrón, estás gastando energía que no tienes para cuidar la imagen, y eso se acumula.',
            'Si lo que necesitas es recargar en calma, quedarte es cuidarte. La clave es que sea una elección, no una huida de algo que en el fondo quieres.',
            'Un punto medio muy útil: mantienes la conexión sin vaciar la batería. Avisar desde antes que te irás temprano quita presión.',
          ],
          outcomes_en: [
            'Sometimes going out of obligation is fine. But if it is a pattern, you are spending energy you do not have to protect an image, and that adds up.',
            'If what you need is to recharge quietly, staying home is self-care. The key is that it is a choice, not an escape from something you actually want.',
            'A very useful middle ground: you keep the connection without emptying your battery. Saying in advance that you will leave early takes the pressure off.',
          ],
        },
        {
          type: 'commit',
          title_es: 'Protege tu batería',
          title_en: 'Protect your battery',
          content_es: 'Elige una forma de cuidar tu energía en las próximas 24 horas.',
          content_en: 'Choose one way to take care of your energy in the next 24 hours.',
          options_es: [
            'Hacer hoy una actividad de mi lista de recarga',
            'Decir que no a algo que me drena',
            'Poner un límite de tiempo a las redes hoy',
          ],
          options_en: [
            'Do one activity from my recharge list today',
            'Say no to something that drains me',
            'Set a time limit on social media today',
          ],
        },
      ],
    },

    // ═══════════════════════════════════════════════════════════════════════
    {
      id: 'auto_6',
      title_es: 'Tus reglas invisibles',
      title_en: 'Your invisible rules',
      subtitle_es: 'Creencias que aprendiste sin darte cuenta',
      subtitle_en: 'Beliefs you picked up without noticing',
      xpReward: 25,
      steps: [
        {
          type: 'story',
          title_es: '"Ya, no es para tanto"',
          title_en: '"Come on, it is not a big deal"',
          lines_es: [
            '* De niño, cada vez que llorabas, alguien te decía: "ya, no es para tanto".',
            '* Años después, cuando algo te duele, te lo guardas y sigues como si nada.',
            '> Pues sí, así soy yo.',
            'Tal vez. O tal vez es una regla que aprendiste: "mostrar lo que siento molesta a los demás".',
            'Todos cargamos reglas invisibles. Muchas nos protegieron en su momento.',
            'La pregunta de adulto es otra: ¿esta regla me sigue sirviendo hoy?',
          ],
          lines_en: [
            '* As a kid, every time you cried, someone told you: "come on, it is not a big deal".',
            '* Years later, when something hurts, you keep it to yourself and carry on as if nothing happened.',
            '> Well, yeah, that is just who I am.',
            'Maybe. Or maybe it is a rule you learned: "showing my feelings bothers other people".',
            'We all carry invisible rules. Many of them protected us at the time.',
            'The adult question is different: does this rule still serve me today?',
          ],
        },
        {
          type: 'pick',
          question_es: '¿Cuáles de estas reglas te suenan?',
          question_en: 'Which of these rules sound familiar?',
          options_es: [
            'Tengo que poder solo',
            'Si descanso, soy flojo',
            'No debo molestar a nadie',
            'Tengo que caerle bien a todos',
            'Equivocarme es inaceptable',
            'Mis necesidades van al final',
            'Si no lo hago yo, nadie lo hará bien',
          ],
          options_en: [
            'I have to handle it alone',
            'If I rest, I am lazy',
            'I must not bother anyone',
            'Everyone has to like me',
            'Making mistakes is unacceptable',
            'My needs come last',
            'If I do not do it, nobody will do it right',
          ],
          explanation_es:
            'Son creencias muy comunes, y casi siempre tuvieron sentido en algún momento de tu historia. Hoy, algunas te limitan más de lo que te protegen.',
          explanation_en:
            'These are very common beliefs, and they almost always made sense at some point in your story. Today, some of them limit you more than they protect you.',
        },
        {
          type: 'reveal',
          question_es: '¿Cómo reconoces una regla rígida?',
          question_en: 'How do you recognize a rigid rule?',
          answer_es:
            'Suele venir con palabras absolutas: "tengo que", "debo", "nunca", "siempre".\n\nY trae castigo: si la rompes, sientes culpa o ansiedad desproporcionada. Una regla flexible suena distinto: "prefiero", "me gustaría", "a veces".',
          answer_en:
            'It usually comes with absolute words: "I have to", "I must", "never", "always".\n\nAnd it carries a punishment: if you break it, you feel disproportionate guilt or anxiety. A flexible rule sounds different: "I prefer", "I would like", "sometimes".',
        },
        {
          type: 'sort',
          title_es: 'Rígida o flexible',
          title_en: 'Rigid or flexible',
          instruction_es: 'Arrastra cada frase según sea una regla rígida o su versión flexible.',
          instruction_en: 'Drag each sentence depending on whether it is a rigid rule or its flexible version.',
          categories_es: ['Regla rígida', 'Versión flexible'],
          categories_en: ['Rigid rule', 'Flexible version'],
          items_es: [
            'Tengo que hacerlo todo perfecto',
            'Me gusta hacer las cosas bien, y a veces basta con suficiente',
            'Nunca debo pedir ayuda',
            'Puedo resolver mucho solo y también puedo pedir apoyo',
            'Debo complacer a todos',
            'Me importa cómo se sienten los demás, y lo mío también cuenta',
          ],
          items_en: [
            'I have to do everything perfectly',
            'I like doing things well, and sometimes good enough is enough',
            'I must never ask for help',
            'I can solve a lot on my own and I can also ask for support',
            'I must please everyone',
            'I care how others feel, and my feelings count too',
          ],
          itemCategory: [0, 1, 0, 1, 0, 1],
          explanation_es:
            'La versión flexible no tira el valor a la basura: conserva lo bueno (hacer las cosas bien, ser independiente, ser considerado) y le quita la amenaza.',
          explanation_en:
            'The flexible version does not throw the value away: it keeps the good part (doing things well, being independent, being considerate) and removes the threat.',
        },
        {
          type: 'slider',
          question_es: '¿Qué tanto te hablas con "tengo que" y "debería"?',
          question_en: 'How much do you talk to yourself with "I have to" and "I should"?',
          minLabel_es: 'Casi nada',
          minLabel_en: 'Hardly at all',
          maxLabel_es: 'Todo el tiempo',
          maxLabel_en: 'All the time',
          responses_es: [
            'Te tratas con bastante flexibilidad. Eso te da margen para equivocarte y aprender sin castigarte.',
            'Hay áreas donde te exiges de más. Fíjate en cuáles: trabajo, familia, cuerpo... ahí suele vivir una regla rígida.',
            'Vives bajo mucha presión interna, y cansa. Probar a cambiar un solo "tengo que" por "quiero" o "elijo" durante un día puede sorprenderte.',
          ],
          responses_en: [
            'You treat yourself with quite a lot of flexibility. That gives you room to make mistakes and learn without punishing yourself.',
            'There are areas where you demand too much of yourself. Notice which: work, family, body... that is usually where a rigid rule lives.',
            'You live under a lot of inner pressure, and it is exhausting. Try swapping a single "I have to" for "I want to" or "I choose to" for one day; it may surprise you.',
          ],
        },
        {
          type: 'exercise',
          title_es: 'Reescribe una regla',
          title_en: 'Rewrite a rule',
          instruction_es:
            'Elige una regla que te suene. Escríbela como está hoy y después escribe una versión flexible, como se la dirías a un buen amigo.',
          instruction_en:
            'Choose a rule that sounds familiar. Write it as it is today, then write a flexible version, the way you would say it to a good friend.',
          placeholder_es: 'Hoy: "Tengo que poder solo"\nFlexible: "Puedo con mucho, y pedir ayuda también es inteligente"',
          placeholder_en: 'Today: "I have to handle it alone"\nFlexible: "I can handle a lot, and asking for help is smart too"',
        },
      ],
    },

    // ═══════════════════════════════════════════════════════════════════════
    {
      id: 'auto_7',
      title_es: 'El piloto automático',
      title_en: 'Autopilot',
      subtitle_es: 'Cómo funcionan tus hábitos',
      subtitle_en: 'How your habits work',
      xpReward: 30,
      steps: [
        {
          type: 'reading',
          title_es: 'Buena parte de tu día',
          title_en: 'A big part of your day',
          content_es:
            'Hay estudios que calculan que cerca de la mitad de lo que hacemos en un día lo hacemos por hábito, casi sin pensarlo.\n\nUn hábito tiene una estructura sencilla: una señal que lo dispara, una rutina que haces en automático y una recompensa que tu cerebro quiere repetir.\n\nConocer tus hábitos es conocerte: dicen más de tu vida que tus intenciones.',
          content_en:
            'Some studies estimate that close to half of what we do in a day is done out of habit, almost without thinking.\n\nA habit has a simple structure: a cue that triggers it, a routine you do on autopilot, and a reward your brain wants to repeat.\n\nKnowing your habits is knowing yourself: they say more about your life than your intentions do.',
        },
        {
          type: 'order',
          title_es: 'El ciclo de un hábito',
          title_en: 'The habit loop',
          instruction_es: 'Ordena cómo se forma y se refuerza un hábito.',
          instruction_en: 'Put in order how a habit forms and gets reinforced.',
          items_es: [
            'Señal: algo lo dispara (aburrimiento, llegar a casa)',
            'Rutina: lo que haces en automático',
            'Recompensa: el alivio o el placer que obtienes',
            'Repetición: tu cerebro refuerza el camino',
          ],
          items_en: [
            'Cue: something triggers it (boredom, getting home)',
            'Routine: what you do on autopilot',
            'Reward: the relief or pleasure you get',
            'Repetition: your brain strengthens the path',
          ],
          explanation_es: 'Para cambiar un hábito casi nunca funciona atacar la rutina a fuerza de voluntad. Funciona mejor cambiar la señal o encontrar otra rutina que dé una recompensa parecida.',
          explanation_en: 'To change a habit, attacking the routine with willpower rarely works. It works better to change the cue or find another routine that gives a similar reward.',
        },
        {
          type: 'mythfact',
          title_es: 'Mitos sobre los hábitos',
          title_en: 'Myths about habits',
          statements_es: [
            'Un hábito nuevo se forma en 21 días',
            'Si te saltas un día, arruinas el hábito',
            'Cambiar tu entorno ayuda más que la pura fuerza de voluntad',
            'Los hábitos pequeños pueden generar cambios grandes',
          ],
          statements_en: [
            'A new habit takes 21 days to form',
            'Skipping one day ruins the habit',
            'Changing your environment helps more than sheer willpower',
            'Small habits can lead to big changes',
          ],
          truths: [false, false, true, true],
          feedbacks_es: [
            'Mito. En un estudio conocido, tomó en promedio unos dos meses, con enorme variación entre personas: desde menos de tres semanas hasta más de ocho meses.',
            'Mito. En ese mismo estudio, fallar un día no afectó de forma importante la formación del hábito. Lo que importa es retomar.',
            'Realidad. Dejar el celular en otro cuarto funciona mejor que prometerte no tomarlo. El entorno trabaja por ti las 24 horas.',
            'Realidad. Un hábito diminuto es fácil de repetir, y lo que se repite crece. Empezar pequeño no es conformarse, es ser estratégico.',
          ],
          feedbacks_en: [
            'Myth. In a well-known study it took about two months on average, with huge variation between people: from under three weeks to over eight months.',
            'Myth. In that same study, missing a single day did not meaningfully affect habit formation. What matters is getting back on track.',
            'Fact. Leaving your phone in another room works better than promising yourself not to pick it up. Your environment works for you around the clock.',
            'Fact. A tiny habit is easy to repeat, and what gets repeated grows. Starting small is not settling, it is being strategic.',
          ],
        },
        {
          type: 'pick',
          question_es: '¿Qué hábitos automáticos reconoces en ti?',
          question_en: 'Which autopilot habits do you recognize in yourself?',
          options_es: [
            'Revisar el celular al despertar',
            'Comer frente a una pantalla sin darme cuenta',
            'Posponer lo difícil',
            'Quejarme en cuanto algo sale mal',
            'Desvelarme más de lo que quiero',
            'Morderme las uñas o moverme cuando estoy nervioso',
            'Ir al refrigerador cuando me aburro',
          ],
          options_en: [
            'Checking my phone as soon as I wake up',
            'Eating in front of a screen without noticing',
            'Putting off hard things',
            'Complaining as soon as something goes wrong',
            'Staying up later than I want to',
            'Biting my nails or fidgeting when nervous',
            'Heading to the fridge when bored',
          ],
          explanation_es:
            'Ninguno te hace mala persona: son caminos que tu cerebro aprendió para ahorrar energía. Identificar la señal que los dispara es el primer paso para cambiarlos.',
          explanation_en:
            'None of them makes you a bad person: they are paths your brain learned to save energy. Spotting the cue that triggers them is the first step to changing them.',
        },
        {
          type: 'scenario',
          title_es: 'Cinco minutos que duran tres horas',
          title_en: 'Five minutes that last three hours',
          situation_es: 'Cada noche te acuestas, tomas el celular "cinco minutos" y terminas dormido a la una de la mañana.',
          situation_en: 'Every night you get into bed, pick up your phone "for five minutes", and end up falling asleep at one in the morning.',
          options_es: [
            'Me prometo tener más fuerza de voluntad',
            'Dejo el celular cargando fuera del cuarto',
            'Pongo una alarma a las once que me recuerde dormir',
          ],
          options_en: [
            'Promise myself to have more willpower',
            'Leave the phone charging outside the bedroom',
            'Set an 11 p.m. alarm reminding me to sleep',
          ],
          outcomes_es: [
            'La fuerza de voluntad es más débil justo en la noche, cuando estás cansado. Probablemente funcione dos días y luego vuelva el patrón.',
            'Cambias la señal: sin celular a mano, la rutina no arranca. Es de las estrategias más efectivas, aunque los primeros días se siente raro.',
            'Es un buen recordatorio, pero compite contra una recompensa muy fuerte. Funciona mejor combinado con dejar el celular lejos.',
          ],
          outcomes_en: [
            'Willpower is weakest exactly at night, when you are tired. It will probably work for two days before the pattern returns.',
            'You change the cue: with no phone in reach, the routine does not start. It is one of the most effective strategies, even if the first few days feel strange.',
            'It is a good reminder, but it competes with a very strong reward. It works better combined with keeping the phone out of reach.',
          ],
        },
        {
          type: 'commit',
          title_es: 'Un hábito diminuto',
          title_en: 'A tiny habit',
          content_es: 'Los cambios que duran empiezan ridículamente pequeños y se pegan a algo que ya haces. Elige uno.',
          content_en: 'Changes that last start ridiculously small and attach to something you already do. Choose one.',
          options_es: [
            'Después de lavarme los dientes, hacer tres respiraciones lentas',
            'Al despertar, esperar cinco minutos antes de ver el celular',
            'Al llegar a casa, anotar una cosa buena del día',
          ],
          options_en: [
            'After brushing my teeth, take three slow breaths',
            'When I wake up, wait five minutes before checking my phone',
            'When I get home, write down one good thing from the day',
          ],
        },
      ],
    },

    // ═══════════════════════════════════════════════════════════════════════
    {
      id: 'auto_8',
      title_es: 'Introvertido, extrovertido o en medio',
      title_en: 'Introvert, extrovert, or in between',
      subtitle_es: 'Cómo recargas en lo social',
      subtitle_en: 'How you recharge socially',
      xpReward: 30,
      steps: [
        {
          type: 'reveal',
          question_es: '¿Qué distingue a una persona introvertida de una extrovertida?',
          question_en: 'What sets an introverted person apart from an extroverted one?',
          answer_es:
            'No es ser tímido o sociable. Tiene más que ver con cuánta estimulación disfrutas: a mucha gente introvertida la vida social intensa le gasta batería y recarga en calma; a mucha gente extrovertida le pasa al revés.\n\nY es un espectro: la mayoría de las personas está en algún punto intermedio.',
          answer_en:
            'It is not about being shy or outgoing. It has more to do with how much stimulation you enjoy: many introverted people find intense social life draining and recharge in quiet; many extroverted people are the opposite.\n\nAnd it is a spectrum: most people fall somewhere in between.',
        },
        {
          type: 'mythfact',
          title_es: 'Mitos de la personalidad',
          title_en: 'Personality myths',
          statements_es: [
            'Las personas introvertidas son tímidas',
            'La mayoría de la gente está en un punto intermedio',
            'Una persona introvertida no puede ser buena líder',
            'Puedes actuar más extrovertido o introvertido según la situación',
          ],
          statements_en: [
            'Introverted people are shy',
            'Most people fall somewhere in the middle',
            'An introverted person cannot be a good leader',
            'You can act more extroverted or introverted depending on the situation',
          ],
          truths: [false, true, false, true],
          feedbacks_es: [
            'Mito. La timidez es miedo al juicio de los demás; la introversión es una preferencia por menos estimulación. Puedes ser introvertido y nada tímido, o extrovertido y tímido.',
            'Realidad. Los extremos puros son poco comunes. Por eso es normal que te identifiques con cosas de ambos lados.',
            'Mito. Hay muchos líderes introvertidos. Suelen destacar en escuchar y en darle espacio a las ideas de otros.',
            'Realidad. Tu tendencia es bastante estable, pero tu conducta se adapta a lo que te importa en cada momento.',
          ],
          feedbacks_en: [
            'Myth. Shyness is fear of other people’s judgment; introversion is a preference for less stimulation. You can be introverted and not shy at all, or extroverted and shy.',
            'Fact. Pure extremes are uncommon. That is why it is normal to relate to things on both sides.',
            'Myth. There are plenty of introverted leaders. They often stand out at listening and making room for other people’s ideas.',
            'Fact. Your tendency is fairly stable, but your behavior adapts to what matters to you in each moment.',
          ],
        },
        {
          type: 'sort',
          title_es: 'Tendencias típicas',
          title_en: 'Typical tendencies',
          instruction_es: 'Arrastra cada preferencia al lado del espectro donde suele aparecer más.',
          instruction_en: 'Drag each preference to the side of the spectrum where it tends to show up more.',
          categories_es: ['Más introvertido', 'Más extrovertido'],
          categories_en: ['More introverted', 'More extroverted'],
          items_es: [
            'Una tarde leyendo en calma',
            'Una fiesta con mucha gente',
            'Una conversación profunda uno a uno',
            'Pensar en voz alta con otros',
            'Procesar una idea antes de decirla',
            'Conocer gente nueva en un evento',
          ],
          items_en: [
            'A quiet afternoon reading',
            'A party with lots of people',
            'A deep one-on-one conversation',
            'Thinking out loud with others',
            'Processing an idea before saying it',
            'Meeting new people at an event',
          ],
          itemCategory: [0, 1, 0, 1, 0, 1],
          explanation_es: 'Son tendencias, no cajas. Seguro te identificaste con cosas de ambas columnas, y eso es lo más común.',
          explanation_en: 'These are tendencies, not boxes. You probably related to things in both columns, and that is the most common case.',
        },
        {
          type: 'scenario',
          title_es: 'Viernes en la noche',
          title_en: 'Friday night',
          situation_es: 'Terminaste una semana llena de reuniones y conversaciones. Tus amigos organizan una salida grande.',
          situation_en: 'You just finished a week full of meetings and conversations. Your friends are planning a big night out.',
          options_es: [
            'Voy: estar con gente me recarga',
            'Me quedo en casa: necesito silencio',
            'Propongo algo más tranquilo con uno o dos amigos',
          ],
          options_en: [
            'I go: being around people recharges me',
            'I stay home: I need quiet',
            'I suggest something calmer with one or two friends',
          ],
          outcomes_es: [
            'Si de verdad te recarga, es una gran elección. Solo revisa que no sea por miedo a perderte algo cuando tu cuerpo pide descanso.',
            'Si lo que te recarga es la calma, es una gran elección. Solo revisa que no se vuelva la opción de siempre por evitar la incomodidad social.',
            'Un punto medio que funciona para mucha gente: conexión real con menos estimulación. No hay respuesta correcta; la correcta es la que te deja mejor.',
          ],
          outcomes_en: [
            'If it truly recharges you, that is a great choice. Just check that it is not fear of missing out when your body is asking for rest.',
            'If calm is what recharges you, that is a great choice. Just check it does not become the default for avoiding social discomfort.',
            'A middle ground that works for many people: real connection with less stimulation. There is no right answer; the right one is the one that leaves you better off.',
          ],
        },
        {
          type: 'pick',
          question_es: '¿En qué ambiente piensas mejor?',
          question_en: 'In what environment do you think best?',
          options_es: ['Silencio total', 'Música de fondo', 'Una cafetería con ruido', 'Hablándolo con alguien', 'Caminando', 'Escribiendo'],
          options_en: ['Total silence', 'Background music', 'A noisy café', 'Talking it through with someone', 'Walking', 'Writing'],
          explanation_es:
            'No hay un ambiente ideal para todos. Saber cuál es el tuyo te ayuda a organizar tu trabajo, tu estudio y tu descanso a tu favor.',
          explanation_en:
            'There is no ideal environment for everyone. Knowing yours helps you set up your work, study and rest in your favor.',
        },
        {
          type: 'exercise',
          title_es: 'Tu manual de uso',
          title_en: 'Your user manual',
          instruction_es:
            'Escribe tres frases que ayudarían a alguien a entender cómo recargas energía y qué necesitas en lo social.',
          instruction_en:
            'Write three sentences that would help someone understand how you recharge and what you need socially.',
          placeholder_es: 'Ej: 1. Después de un día con mucha gente necesito una hora a solas. 2. ...',
          placeholder_en: 'E.g.: 1. After a day with lots of people I need an hour alone. 2. ...',
        },
      ],
    },

    // ═══════════════════════════════════════════════════════════════════════
    {
      id: 'auto_9',
      title_es: 'Tus puntos ciegos',
      title_en: 'Your blind spots',
      subtitle_es: 'Lo que otros ven y tú no',
      subtitle_en: 'What others see and you do not',
      xpReward: 30,
      steps: [
        {
          type: 'reading',
          title_es: 'La ventana de Johari',
          title_en: 'The Johari window',
          content_es:
            'Imagina una ventana con cuatro cristales:\n\n• Abierto: lo que tú y los demás saben de ti.\n• Ciego: lo que otros ven de ti y tú no.\n• Oculto: lo que tú sabes y no muestras.\n• Desconocido: lo que nadie ha descubierto todavía.\n\nConocerte mejor es agrandar el cristal abierto: pedir opiniones para reducir tus puntos ciegos y, cuando es seguro, compartir un poco más de lo oculto.',
          content_en:
            'Imagine a window with four panes:\n\n• Open: what you and others know about you.\n• Blind: what others see in you and you do not.\n• Hidden: what you know and do not show.\n• Unknown: what nobody has discovered yet.\n\nKnowing yourself better means enlarging the open pane: asking for feedback to shrink your blind spots and, when it feels safe, sharing a bit more of what is hidden.',
        },
        {
          type: 'sort',
          title_es: '¿Qué cristal es?',
          title_en: 'Which pane is it?',
          instruction_es: 'Arrastra cada situación al cristal de la ventana que le corresponde.',
          instruction_en: 'Drag each situation to the pane of the window it belongs to.',
          categories_es: ['Abierto', 'Ciego', 'Oculto'],
          categories_en: ['Open', 'Blind', 'Hidden'],
          items_es: [
            'Todos saben que soy puntual, y yo también',
            'Mis amigos notan que interrumpo mucho; yo no lo veo',
            'Nadie sabe que me da pánico hablar en público',
            'Mi familia ve que me estreso los domingos; yo no me había dado cuenta',
            'Saben que me encanta cocinar, y yo lo sé',
            'Nunca he contado que a veces me siento solo',
          ],
          items_en: [
            'Everyone knows I am punctual, and so do I',
            'My friends notice I interrupt a lot; I do not see it',
            'Nobody knows public speaking terrifies me',
            'My family sees I get stressed on Sundays; I had not noticed',
            'They know I love cooking, and I know it too',
            'I have never told anyone I sometimes feel lonely',
          ],
          itemCategory: [0, 1, 2, 1, 0, 2],
          explanation_es:
            'Lo oculto no tiene nada de malo: no todo se comparte con todos. Pero lo ciego solo se descubre con ayuda de otros.',
          explanation_en:
            'There is nothing wrong with the hidden pane: not everything is for everyone. But the blind pane can only be uncovered with other people’s help.',
        },
        {
          type: 'reveal',
          question_es: '¿Por qué no podemos ver nuestros propios puntos ciegos?',
          question_en: 'Why can we not see our own blind spots?',
          answer_es:
            'Porque nos juzgamos desde adentro: conocemos nuestras intenciones. Los demás solo ven nuestras acciones.\n\nPor eso alguien puede sentirse "directo" y otros percibirlo como "duro". Ninguno miente: miran desde lugares distintos.',
          answer_en:
            'Because we judge ourselves from the inside: we know our intentions. Others only see our actions.\n\nThat is why someone can feel "direct" while others experience them as "harsh". Nobody is lying: they are looking from different places.',
        },
        {
          type: 'scenario',
          title_es: 'Una crítica inesperada',
          title_en: 'Unexpected feedback',
          situation_es: 'Un compañero te dice en confianza: "A veces, en las juntas, no dejas hablar a los demás".',
          situation_en: 'A coworker tells you privately: "Sometimes in meetings you do not let others speak."',
          options_es: [
            'Le explico por qué eso no es cierto',
            'Le agradezco y le pido un ejemplo concreto',
            'Asiento, no digo nada y me quedo molesto todo el día',
          ],
          options_en: [
            'Explain to them why that is not true',
            'Thank them and ask for a concrete example',
            'Nod, say nothing, and stay upset all day',
          ],
          outcomes_es: [
            'Defenderse es un reflejo muy natural, pero cierra la puerta: la próxima vez esa persona probablemente no te dirá nada, y el punto ciego seguirá ahí.',
            'Pedir un ejemplo convierte algo que duele en información útil. No tienes que estar de acuerdo: primero entiende, después decides.',
            'Guardarte la molestia te deja con la crítica y sin la información para usarla. Puedes volver a hablarlo cuando estés más tranquilo.',
          ],
          outcomes_en: [
            'Defending yourself is a very natural reflex, but it closes the door: next time that person probably will not tell you anything, and the blind spot stays.',
            'Asking for an example turns something painful into useful information. You do not have to agree: understand first, decide later.',
            'Holding in the upset leaves you with the criticism and none of the information to use it. You can bring it up again once you feel calmer.',
          ],
        },
        {
          type: 'order',
          title_es: 'Pedir retroalimentación que sirva',
          title_en: 'Asking for useful feedback',
          instruction_es: 'Ordena los pasos para pedir una opinión sincera sin que termine en discusión.',
          instruction_en: 'Order the steps for asking for honest feedback without it turning into an argument.',
          items_es: [
            'Elegir a alguien que te conozca y te aprecie',
            'Hacer una pregunta concreta, no "¿cómo soy?"',
            'Escuchar sin defenderte',
            'Agradecer, aunque no estés de acuerdo',
            'Decidir después, con calma, qué te sirve',
          ],
          items_en: [
            'Choose someone who knows you and cares about you',
            'Ask a specific question, not "what am I like?"',
            'Listen without defending yourself',
            'Say thank you, even if you disagree',
            'Decide later, calmly, what is useful to you',
          ],
          explanation_es: 'Una pregunta concreta como "¿qué hago en las juntas que te cuesta?" da respuestas mucho más útiles que "¿qué opinas de mí?".',
          explanation_en: 'A specific question like "what do I do in meetings that is hard for you?" gets far more useful answers than "what do you think of me?".',
        },
        {
          type: 'commit',
          title_es: 'Enciende una luz',
          title_en: 'Turn on a light',
          content_es: 'Elige un paso pequeño para ampliar tu ventana esta semana.',
          content_en: 'Choose one small step to widen your window this week.',
          options_es: [
            'Preguntarle a alguien de confianza cuál cree que es mi mayor fortaleza',
            'Preguntarle a alguien de confianza qué podría mejorar en cómo me comunico',
            'Contarle a alguien cercano algo de mí que casi nadie sabe',
          ],
          options_en: [
            'Ask someone I trust what they think my greatest strength is',
            'Ask someone I trust what I could improve in how I communicate',
            'Tell someone close something about me that almost nobody knows',
          ],
        },
      ],
    },

    // ═══════════════════════════════════════════════════════════════════════
    {
      id: 'auto_10',
      title_es: 'Quién quieres ser',
      title_en: 'Who you want to be',
      subtitle_es: 'Ser más tú, a propósito',
      subtitle_en: 'Being more yourself, on purpose',
      xpReward: 35,
      steps: [
        {
          type: 'story',
          title_es: 'Tú, dentro de cinco años',
          title_en: 'You, five years from now',
          lines_es: [
            'Imagina que te encuentras contigo mismo dentro de cinco años.',
            '> ¿Y qué me diría?',
            'Depende de lo que hagas con lo que ya sabes de ti: tus valores, tus fortalezas, lo que te carga, tus reglas invisibles.',
            'Sentirte conectado con tu yo del futuro ayuda a tomar mejores decisiones hoy.',
            '> Pero no quiero convertirme en otra persona.',
            'No se trata de eso. Se trata de ser más tú, a propósito.',
          ],
          lines_en: [
            'Imagine running into yourself five years from now.',
            '> And what would they tell me?',
            'That depends on what you do with what you already know about yourself: your values, your strengths, what recharges you, your invisible rules.',
            'Feeling connected to your future self helps you make better decisions today.',
            '> But I do not want to become someone else.',
            'That is not the point. The point is to be more yourself, on purpose.',
          ],
        },
        {
          type: 'mythfact',
          title_es: 'Repaso de la ruta',
          title_en: 'Route review',
          statements_es: [
            'Los valores y las metas son lo mismo',
            'Detrás de muchas emociones difíciles hay una necesidad sin atender',
            'Un pensamiento automático siempre dice la verdad',
            'Conocerte también implica escuchar cómo te ven los demás',
          ],
          statements_en: [
            'Values and goals are the same thing',
            'Behind many difficult emotions there is an unmet need',
            'An automatic thought always tells the truth',
            'Knowing yourself also means listening to how others see you',
          ],
          truths: [false, true, false, true],
          feedbacks_es: [
            'Mito. Una meta se cumple y se tacha; un valor es una dirección que nunca se termina.',
            'Realidad. Preguntar "¿qué me falta?" suele ser más útil que preguntar "¿qué me pasa?".',
            'Mito. Los pensamientos son hipótesis. Puedes revisarlos antes de creértelos.',
            'Realidad. Tus puntos ciegos solo se descubren con ayuda de otros.',
          ],
          feedbacks_en: [
            'Myth. A goal gets done and crossed off; a value is a direction that is never finished.',
            'Fact. Asking "what am I missing?" is often more useful than asking "what is wrong with me?".',
            'Myth. Thoughts are hypotheses. You can check them before believing them.',
            'Fact. Your blind spots can only be uncovered with other people’s help.',
          ],
        },
        {
          type: 'practice',
          title_es: 'Un día en tu futuro',
          title_en: 'A day in your future',
          intro_es:
            'Vas a imaginar un día normal dentro de cinco años, uno en el que vives de acuerdo con lo que te importa. No tiene que ser perfecto ni nítido: deja que aparezca lo que aparezca.',
          intro_en:
            'You will imagine an ordinary day five years from now, one where you live in line with what matters to you. It does not have to be perfect or vivid: let whatever comes up come up.',
          prompts_es: [
            'Cierra los ojos si te sientes cómodo',
            'Inhala',
            'Exhala despacio',
            'Es un día normal dentro de cinco años',
            '¿Dónde despiertas? ¿Cómo te sientes?',
            '¿Con quién pasas tu tiempo?',
            '¿Qué haces que refleja tus valores?',
            '¿Qué fortaleza estás usando?',
            'Inhala',
            'Exhala y abre los ojos',
          ],
          prompts_en: [
            'Close your eyes if you feel comfortable',
            'Breathe in',
            'Breathe out slowly',
            'It is an ordinary day five years from now',
            'Where do you wake up? How do you feel?',
            'Who do you spend your time with?',
            'What are you doing that reflects your values?',
            'Which strength are you using?',
            'Breathe in',
            'Breathe out and open your eyes',
          ],
          durations: [6, 4, 6, 8, 12, 12, 12, 10, 4, 6],
          motions: ['still', 'in', 'out', 'still', 'still', 'still', 'still', 'still', 'in', 'out'],
          outro_es:
            'No importa que no haya sido nítido. Lo que apareció con más fuerza suele señalar lo que más te importa.',
          outro_en:
            'It does not matter if it was not vivid. Whatever showed up most strongly usually points to what matters most to you.',
        },
        {
          type: 'pick',
          question_es: '¿Qué quieres cultivar en ti este año?',
          question_en: 'What do you want to grow in yourself this year?',
          options_es: ['Paciencia', 'Valentía', 'Constancia', 'Ternura conmigo', 'Creatividad', 'Confianza', 'Calma', 'Alegría', 'Límites sanos'],
          options_en: ['Patience', 'Courage', 'Consistency', 'Kindness toward myself', 'Creativity', 'Confidence', 'Calm', 'Joy', 'Healthy boundaries'],
          responses_es: [
            'Enfocado: una o dos cualidades trabajadas de verdad cambian más que diez a medias.',
            'Una buena lista. Muchas se alimentan entre sí: la calma ayuda a la paciencia, la confianza ayuda a los límites.',
            'Quieres crecer en muchas direcciones, y eso habla bien de ti. Para empezar, elige la que haría más fáciles a las demás.',
          ],
          responses_en: [
            'Focused: one or two qualities worked on for real change more than ten done halfway.',
            'A good list. Many of them feed each other: calm helps patience, confidence helps boundaries.',
            'You want to grow in many directions, which speaks well of you. To start, pick the one that would make the others easier.',
          ],
        },
        {
          type: 'exercise',
          title_es: 'Carta a tu yo del futuro',
          title_en: 'Letter to your future self',
          instruction_es:
            'Escríbele a tu yo de dentro de un año. ¿Qué esperas que haya cuidado? ¿Qué le pides que no olvide? Puedes guardarla en tu diario para releerla.',
          instruction_en:
            'Write to yourself one year from now. What do you hope they took care of? What do you ask them not to forget? You can save it to your diary to reread later.',
          placeholder_es: 'Querido yo del futuro: espero que...',
          placeholder_en: 'Dear future me: I hope that...',
        },
        {
          type: 'commit',
          title_es: 'El primer paso',
          title_en: 'The first step',
          content_es: 'Terminaste la ruta de autoconocimiento. Conocerte no se acaba nunca, pero hoy sabes mucho más que ayer.',
          content_en: 'You finished the self-knowledge route. Getting to know yourself never ends, but today you know much more than yesterday.',
          options_es: [
            'Releer mi carta dentro de un mes',
            'Vivir un valor a propósito cada día de esta semana',
            'Empezar otra ruta para seguir conociéndome',
          ],
          options_en: [
            'Reread my letter in a month',
            'Live one value on purpose every day this week',
            'Start another route to keep learning about myself',
          ],
        },
      ],
    },
  ],
};
