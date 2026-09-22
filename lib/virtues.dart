// Canonical Virtues & The Golden Mean (v2) for Character and Personality.
// Ported from lib/virtues.js for phils-brain-app.

class VirtueSphere {
  final String id;
  final String icon;
  final String titleEn;
  final String titleEs;
  final String descEn;
  final String descEs;

  const VirtueSphere({
    required this.id,
    required this.icon,
    required this.titleEn,
    required this.titleEs,
    required this.descEn,
    required this.descEs,
  });
}

class VirtueDef {
  final String slug;
  final String sphere;
  final String virtueEn;
  final String virtueEs;
  final String deficiencyEn;
  final String deficiencyEs;
  final String excessEn;
  final String excessEs;
  final String poeticEn;
  final String poeticEs;

  const VirtueDef({
    required this.slug,
    required this.sphere,
    required this.virtueEn,
    required this.virtueEs,
    required this.deficiencyEn,
    required this.deficiencyEs,
    required this.excessEn,
    required this.excessEs,
    required this.poeticEn,
    required this.poeticEs,
  });
}

const List<VirtueSphere> kVirtueSpheres = [
  VirtueSphere(
    id: 'courage_and_fortitude',
    icon: '🛡️',
    titleEn: 'Courage & Fortitude',
    titleEs: 'Coraje y Fortaleza',
    descEn: 'Will and resolve in engaging danger, friction, and adversity.',
    descEs: 'Voluntad y resolución frente al peligro, la fricción y la adversidad.',
  ),
  VirtueSphere(
    id: 'self_mastery_and_equanimity',
    icon: '🌊',
    titleEn: 'Self-Mastery & Equanimity',
    titleEs: 'Dominio Propio y Ecuanimidad',
    descEn: 'Inner equilibrium, emotional stability, and measured presence.',
    descEs: 'Equilibrio interior, estabilidad emocional y presencia templada.',
  ),
  VirtueSphere(
    id: 'social_grace_and_warmth',
    icon: '🤝',
    titleEn: 'Social Grace & Relational Warmth',
    titleEs: 'Gracia Social y Calidez Relacional',
    descEn: 'Philia, benevolent hospitality, candor, and enduring loyalty.',
    descEs: 'Philia, hospitalidad benevolente, franqueza y lealtad perdurable.',
  ),
  VirtueSphere(
    id: 'intellect_and_wisdom',
    icon: '🦉',
    titleEn: 'Intellect & Pragmatic Wisdom',
    titleEs: 'Intelecto y Sabiduría Práctica',
    descEn: 'Phronesis, discernment, truth-seeking, and grounded realism.',
    descEs: 'Phronesis, discernimiento, búsqueda de verdad y realismo lúcido.',
  ),
  VirtueSphere(
    id: 'creative_agency_and_vitality',
    icon: '✨',
    titleEn: 'Creative Agency & Vitality',
    titleEs: 'Agencia Creativa y Vitalidad',
    descEn: 'Poiesis, playfulness, purposeful ambition, and resilient optimism.',
    descEs: 'Poiesis, espíritu lúdico, ambición deliberada y optimismo resiliente.',
  ),
  VirtueSphere(
    id: 'justice_and_duty',
    icon: '⚖️',
    titleEn: 'Justice & Civic Duty',
    titleEs: 'Justicia y Deber Cívico',
    descEn: 'Rectitude, honorable responsibility, order, and cultivated excellence.',
    descEs: 'Rectitud, responsabilidad honorable, orden y excelencia cultivada.',
  ),
];

const List<VirtueDef> kVirtues = [
  // --- I. Courage & Fortitude ---
  VirtueDef(
    slug: 'practices/virtue-courage',
    sphere: 'courage_and_fortitude',
    virtueEn: 'Courageous',
    virtueEs: 'Valiente',
    deficiencyEn: 'Cowardly',
    deficiencyEs: 'Cobarde',
    excessEn: 'Reckless / Rash',
    excessEs: 'Temerario / Imprudente',
    poeticEn: 'The steady flame that burns through the shadows of doubt.',
    poeticEs: 'La llama constante que arde a través de las sombras de la duda.',
  ),
  VirtueDef(
    slug: 'practices/virtue-steadfastness',
    sphere: 'courage_and_fortitude',
    virtueEn: 'Steadfast / Resolute',
    virtueEs: 'Firme / Inquebrantable',
    deficiencyEn: 'Flighty / Fickle',
    deficiencyEs: 'Voluble / Inconstante',
    excessEn: 'Intransigent / Obstinate',
    excessEs: 'Obstinado / Inflexible',
    poeticEn: 'The ancient oak that bends in the storm without yielding its soil.',
    poeticEs: 'El antiguo roble que se dobla en la tormenta pero nunca cede su terreno.',
  ),
  VirtueDef(
    slug: 'practices/virtue-persistence',
    sphere: 'courage_and_fortitude',
    virtueEn: 'Persistent / Gritty',
    virtueEs: 'Perseverante / Tenaz',
    deficiencyEn: 'Lackadaisical',
    deficiencyEs: 'Desganado / Apático',
    excessEn: 'Obsessive / Stubborn',
    excessEs: 'Terco / Obsesivo',
    poeticEn: 'Water patiently carving canyons through solid granite.',
    poeticEs: 'El agua que desgasta pacientemente la piedra, sin detenerse, sin romperse.',
  ),
  VirtueDef(
    slug: 'practices/virtue-prudence',
    sphere: 'courage_and_fortitude',
    virtueEn: 'Prudent / Cautious',
    virtueEs: 'Prudente / Cauteloso',
    deficiencyEn: 'Paralyzed / Indecisive',
    deficiencyEs: 'Indeciso / Titubeante',
    excessEn: 'Timid / Hyper-Vigilant',
    excessEs: 'Medroso / Pusilánime',
    poeticEn: 'The careful step that tests the ice before dancing across the frozen lake.',
    poeticEs: 'El paso cuidadoso que prueba el hielo antes de bailar sobre el lago congelado.',
  ),

  // --- II. Self-Mastery & Equanimity ---
  VirtueDef(
    slug: 'practices/virtue-calm',
    sphere: 'self_mastery_and_equanimity',
    virtueEn: 'Calm / Serene',
    virtueEs: 'Tranquilo / Sereno',
    deficiencyEn: 'Panicked / Hysterical',
    deficiencyEs: 'Aterrado / Presa del pánico',
    excessEn: 'Apathetic / Numb',
    excessEs: 'Apático / Insensible',
    poeticEn: 'A quiet harbor sheltered from the raging sea.',
    poeticEs: 'Un puerto tranquilo en una tormenta furiosa.',
  ),
  VirtueDef(
    slug: 'practices/virtue-carefree',
    sphere: 'self_mastery_and_equanimity',
    virtueEn: 'Carefree / Equanimous',
    virtueEs: 'Despreocupado / Relajado',
    deficiencyEn: 'Chronic Worrier',
    deficiencyEs: 'Aprensivo / Ansioso',
    excessEn: 'Frivolous',
    excessEs: 'Frívolo',
    poeticEn: 'A leaf dancing on the wind, untethered but trusting the breeze.',
    poeticEs: 'Una hoja bailando en el viento, libre pero confiando en la brisa.',
  ),
  VirtueDef(
    slug: 'practices/virtue-mellow',
    sphere: 'self_mastery_and_equanimity',
    virtueEn: 'Mellow / Patient',
    virtueEs: 'Paciente / Templado',
    deficiencyEn: 'Quick-Tempered',
    deficiencyEs: 'Iracundo / Colérico',
    excessEn: 'Passive / Doormat',
    excessEs: 'Pasivo / Complaciente',
    poeticEn: 'The smooth surface of a deep lake, undisturbed by skipping stones.',
    poeticEs: 'La superficie lisa de un lago profundo, inalterada por las piedras que saltan.',
  ),
  VirtueDef(
    slug: 'practices/virtue-humility',
    sphere: 'self_mastery_and_equanimity',
    virtueEn: 'Humble / Modest',
    virtueEs: 'Humilde / Modesto',
    deficiencyEn: 'Arrogant / Haughty',
    deficiencyEs: 'Arrogante / Soberbio',
    excessEn: 'Self-Abasing',
    excessEs: 'Sumiso / Autodespreciativo',
    poeticEn: 'The quiet mountain that knows its height without boasting to the clouds.',
    poeticEs: 'La montaña silenciosa que conoce su altura pero no se jacta ante las nubes.',
  ),
  VirtueDef(
    slug: 'practices/virtue-confidence',
    sphere: 'self_mastery_and_equanimity',
    virtueEn: 'Confident / Poised',
    virtueEs: 'Seguro / Resuelto',
    deficiencyEn: 'Insecure / Self-Doubting',
    deficiencyEs: 'Inseguro / Dubitativo',
    excessEn: 'Conceited / Megalomaniac',
    excessEs: 'Presuntuoso / Megalómano',
    poeticEn: 'The deep-rooted tree standing tall, neither straining for the sky nor bowing to the dirt.',
    poeticEs: 'El árbol de raíces profundas que se erige alto, sin forzarse hacia el cielo ni inclinarse ante la tierra.',
  ),

  // --- III. Social Grace & Relational Warmth ---
  VirtueDef(
    slug: 'practices/virtue-friendliness',
    sphere: 'social_grace_and_warmth',
    virtueEn: 'Friendly / Warm',
    virtueEs: 'Amigable / Cálido',
    deficiencyEn: 'Unfriendly / Aloof',
    deficiencyEs: 'Huraño / Antipático',
    excessEn: 'Smothering / Intrusive',
    excessEs: 'Invasivo / Empalagoso',
    poeticEn: 'An open door to a sunlit parlor, welcoming without trapping.',
    poeticEs: 'Una puerta abierta a un salón iluminado por el sol, que acoge sin atrapar.',
  ),
  VirtueDef(
    slug: 'practices/virtue-empathy',
    sphere: 'social_grace_and_warmth',
    virtueEn: 'Empathetic / Compassionate',
    virtueEs: 'Empático / Compasivo',
    deficiencyEn: 'Callous / Detached',
    deficiencyEs: 'Insensible / Cruel',
    excessEn: 'Enmeshed / Manipulative',
    excessEs: 'Codependiente / Manipulador',
    poeticEn: 'The strings of two instruments vibrating in perfect, harmonious resonance.',
    poeticEs: 'Las cuerdas de dos instrumentos vibrando en perfecta y armoniosa resonancia.',
  ),
  VirtueDef(
    slug: 'practices/virtue-generosity',
    sphere: 'social_grace_and_warmth',
    virtueEn: 'Generous / Magnanimous',
    virtueEs: 'Generoso / Magnánimo',
    deficiencyEn: 'Stingy / Miserly',
    deficiencyEs: 'Tacaño / Avaro',
    excessEn: 'Wasteful / Prodigal',
    excessEs: 'Derrochador / Pródigo',
    poeticEn: 'The spring that waters the valley without draining the mountain.',
    poeticEs: 'El manantial que riega el valle sin secar la montaña.',
  ),
  VirtueDef(
    slug: 'practices/virtue-honesty',
    sphere: 'social_grace_and_warmth',
    virtueEn: 'Honest / Sincere',
    virtueEs: 'Honesto / Sincero',
    deficiencyEn: 'Dishonest / Deceitful',
    deficiencyEs: 'Deshonesto / Falso',
    excessEn: 'Tactless / Brutal',
    excessEs: 'Sin tacto / Brutal',
    poeticEn: 'A clear glass that reveals the world without distorting its beauty.',
    poeticEs: 'Un cristal claro que revela el mundo sin distorsionar su belleza.',
  ),
  VirtueDef(
    slug: 'practices/virtue-loyalty',
    sphere: 'social_grace_and_warmth',
    virtueEn: 'Loyal / Faithful',
    virtueEs: 'Leal / Fiel',
    deficiencyEn: 'Disloyal / Treacherous',
    deficiencyEs: 'Desleal / Traidor',
    excessEn: 'Codependent / Fanatical',
    excessEs: 'Fanático / Codependiente',
    poeticEn: 'The anchor that holds the ship steady without dragging it to the ocean floor.',
    poeticEs: 'El ancla que mantiene firme el barco sin arrastrarlo al fondo del océano.',
  ),
  VirtueDef(
    slug: 'practices/virtue-graciousness',
    sphere: 'social_grace_and_warmth',
    virtueEn: 'Gracious / Appreciative',
    virtueEs: 'Gracioso / Elogioso',
    deficiencyEn: 'Insulting / Derogatory',
    deficiencyEs: 'Despectivo / Ofensivo',
    excessEn: 'Sycophantic / Fawning',
    excessEs: 'Zalamero / Adulador',
    poeticEn: "A mirror that reflects one's inner gold without blinding the eyes.",
    poeticEs: 'Un espejo que refleja el oro interior sin cegar los ojos.',
  ),
  VirtueDef(
    slug: 'practices/virtue-charm',
    sphere: 'social_grace_and_warmth',
    virtueEn: 'Charming / Magnetic',
    virtueEs: 'Encantador / Carismático',
    deficiencyEn: 'Irritating / Abrasive',
    deficiencyEs: 'Fastidioso / Pesado',
    excessEn: 'Seductive / Manipulative',
    excessEs: 'Seductor / Manipulador',
    poeticEn: 'The sunlight that warms the face without burning the skin.',
    poeticEs: 'La luz del sol que calienta el rostro sin quemar la piel.',
  ),
  VirtueDef(
    slug: 'practices/virtue-helpfulness',
    sphere: 'social_grace_and_warmth',
    virtueEn: 'Helpful / Service-Minded',
    virtueEs: 'Servicial / Solidario',
    deficiencyEn: 'Obstinate / Unhelpful',
    deficiencyEs: 'Egoísta / Obstinado',
    excessEn: 'Meddlesome / Overbearing',
    excessEs: 'Entrometido / Paternalista',
    poeticEn: 'The extended hand that waits for a grasp rather than pulling by force.',
    poeticEs: 'La mano extendida que espera ser tomada en lugar de tirar por la fuerza.',
  ),

  // --- IV. Intellect & Pragmatic Wisdom ---
  VirtueDef(
    slug: 'practices/virtue-wisdom',
    sphere: 'intellect_and_wisdom',
    virtueEn: 'Wise / Sagacious',
    virtueEs: 'Sabio / Juicioso',
    deficiencyEn: 'Naive / Gullible',
    deficiencyEs: 'Ingenuo / Crédulo',
    excessEn: 'Condescending / Pedantic',
    excessEs: 'Condescendiente / Pedante',
    poeticEn: 'The sage who walks in the valley, knowing the peak but sharing the path.',
    poeticEs: 'El sabio que camina por el valle, conociendo la cima pero compartiendo el camino.',
  ),
  VirtueDef(
    slug: 'practices/virtue-curiosity',
    sphere: 'intellect_and_wisdom',
    virtueEn: 'Curious / Inquisitive',
    virtueEs: 'Curioso / Indagador',
    deficiencyEn: 'Indifferent / Incurious',
    deficiencyEs: 'Apático / Desinteresado',
    excessEn: 'Intrusive / Prying',
    excessEs: 'Metiche / Entrometido',
    poeticEn: 'The open window that invites the breeze without demanding the storm.',
    poeticEs: 'La ventana abierta que invita a la brisa sin exigir la tormenta.',
  ),
  VirtueDef(
    slug: 'practices/virtue-logic',
    sphere: 'intellect_and_wisdom',
    virtueEn: 'Logical / Rational',
    virtueEs: 'Lógico / Razonable',
    deficiencyEn: 'Overly Emotional',
    deficiencyEs: 'Histérico / Melodramático',
    excessEn: 'Cold-Hearted / Hyper-Rational',
    excessEs: 'Gélido / Calculador',
    poeticEn: 'The compass that finds true north amidst the fog of feeling.',
    poeticEs: 'La brújula que encuentra el norte verdadero en medio de la niebla del sentimiento.',
  ),
  VirtueDef(
    slug: 'practices/virtue-realism',
    sphere: 'intellect_and_wisdom',
    virtueEn: 'Realistic / Pragmatic',
    virtueEs: 'Realista / Pragmático',
    deficiencyEn: 'Naive Idealist',
    deficiencyEs: 'Utopista / Iluso',
    excessEn: 'Cynical / Defeatist',
    excessEs: 'Cínico / Derrotista',
    poeticEn: 'The roots that drink from the actual earth to support reaching branches.',
    poeticEs: 'Las raíces que beben de la tierra real para sostener las ramas que se extienden.',
  ),
  VirtueDef(
    slug: 'practices/virtue-discernment',
    sphere: 'intellect_and_wisdom',
    virtueEn: 'Discerning / Perceptive',
    virtueEs: 'Perspicaz / Inteligente',
    deficiencyEn: 'Dull / Thoughtless',
    deficiencyEs: 'Obtuso / Insensato',
    excessEn: 'Know-It-All / Dogmatic',
    excessEs: 'Sabelotodo / Pedante',
    poeticEn: "A lantern that illuminates the path for all, rather than shining in others' eyes.",
    poeticEs: 'Una linterna que ilumina el camino para todos, en lugar de encandilar ojos ajenos.',
  ),

  // --- V. Creative Agency & Vitality ---
  VirtueDef(
    slug: 'practices/virtue-creativity',
    sphere: 'creative_agency_and_vitality',
    virtueEn: 'Creative / Inventive',
    virtueEs: 'Creativo / Inventivo',
    deficiencyEn: 'Unimaginative / Dull',
    deficiencyEs: 'Estéril / Sin imaginación',
    excessEn: 'Scatter-Brained / Chaotic',
    excessEs: 'Disperso / Caótico',
    poeticEn: 'A river that carves new canyons, guided by its own banks.',
    poeticEs: 'Un río que talla nuevos cañones, guiado por sus propias orillas.',
  ),
  VirtueDef(
    slug: 'practices/virtue-drivenness',
    sphere: 'creative_agency_and_vitality',
    virtueEn: 'Driven / Purposeful',
    virtueEs: 'Motivado / Emprendedor',
    deficiencyEn: 'Lazy / Indolent',
    deficiencyEs: 'Flojo / Indolente',
    excessEn: 'Workaholic / Obsessed',
    excessEs: 'Adicto al trabajo / Obsesivo',
    poeticEn: 'The steady heartbeat of ambition that fuels the journey but remembers to rest.',
    poeticEs: 'El latido constante de la ambición que alimenta el viaje pero recuerda descansar.',
  ),
  VirtueDef(
    slug: 'practices/virtue-inspiration',
    sphere: 'creative_agency_and_vitality',
    virtueEn: 'Inspiring / Motivational',
    virtueEs: 'Inspirador / Alentador',
    deficiencyEn: 'Discouraging / Demoralizing',
    deficiencyEs: 'Desalentador / Tóxico',
    excessEn: 'Demagogic / Coercive',
    excessEs: 'Manipulador / Demagogo',
    poeticEn: "The wind beneath a bird's wings, lifting without directing its flight.",
    poeticEs: 'El viento bajo las alas de un pájaro, que eleva sin dirigir su vuelo.',
  ),
  VirtueDef(
    slug: 'practices/virtue-lightheartedness',
    sphere: 'creative_agency_and_vitality',
    virtueEn: 'Light-Hearted / Buoyant',
    virtueEs: 'Alegre / Desenfadado',
    deficiencyEn: 'Depressive / Gloomy',
    deficiencyEs: 'Melancólico / Sombrío',
    excessEn: 'Toxic-Positive',
    excessEs: 'Positivo Tóxico',
    poeticEn: 'A bird that acknowledges gravity but still chooses to sing in the sky.',
    poeticEs: 'Un pájaro que reconoce la gravedad pero aún así elige cantar en el cielo.',
  ),
  VirtueDef(
    slug: 'practices/virtue-goodhumor',
    sphere: 'creative_agency_and_vitality',
    virtueEn: 'Good-Humored / Witty',
    virtueEs: 'Jovial / Buen humor',
    deficiencyEn: 'Grouchy / Irritable',
    deficiencyEs: 'Cascarrabias / Gruñón',
    excessEn: 'Flippant / Derisive',
    excessEs: 'Burlón / Cínico',
    poeticEn: 'The gentle ripple of laughter that keeps the spirit afloat.',
    poeticEs: 'La suave onda de risa que mantiene el espíritu a flote.',
  ),

  // --- VI. Justice & Civic Duty ---
  VirtueDef(
    slug: 'practices/virtue-justice',
    sphere: 'justice_and_duty',
    virtueEn: 'Just / Equitable',
    virtueEs: 'Justo / Equitativo',
    deficiencyEn: 'Unfair / Biased',
    deficiencyEs: 'Injusto / Arbitrario',
    excessEn: 'Draconian / Merciless',
    excessEs: 'Draconiano / Despiadado',
    poeticEn: 'The perfectly balanced scale weighing the feather against the heart.',
    poeticEs: 'La balanza perfectamente equilibrada que pesa la pluma contra el corazón.',
  ),
  VirtueDef(
    slug: 'practices/virtue-integrity',
    sphere: 'justice_and_duty',
    virtueEn: 'Integrity / Rectitude',
    virtueEs: 'Íntegro / Recto',
    deficiencyEn: 'Corrupt / Crooked',
    deficiencyEs: 'Corrupto / Deshonesto',
    excessEn: 'Sanctimonious',
    excessEs: 'Santurrón / Farisaico',
    poeticEn: 'The internal compass that always points to the good, quietly and true.',
    poeticEs: 'La brújula interna que siempre apunta hacia el bien, en silencio y con verdad.',
  ),
  VirtueDef(
    slug: 'practices/virtue-duty',
    sphere: 'justice_and_duty',
    virtueEn: 'Dutiful / Responsible',
    virtueEs: 'Cumplidor / Responsable',
    deficiencyEn: 'Rebellious / Anarchic',
    deficiencyEs: 'Rebelde / Anárquico',
    excessEn: 'Servile / Obsequious',
    excessEs: 'Servil / Rastrero',
    poeticEn: 'The faithful orbit of a planet, honoring its sun without losing its self.',
    poeticEs: 'La órbita fiel de un planeta, honrando a su sol sin perder su esencia.',
  ),
  VirtueDef(
    slug: 'practices/virtue-organization',
    sphere: 'justice_and_duty',
    virtueEn: 'Organized / Methodical',
    virtueEs: 'Organizado / Metódico',
    deficiencyEn: 'Disorganized / Chaotic',
    deficiencyEs: 'Desorganizado / Caótico',
    excessEn: 'Rigid / Bureaucratic',
    excessEs: 'Rígido / Burocrático',
    poeticEn: 'The lattice that supports the vine, giving it shape so it can bloom.',
    poeticEs: 'La celosía que sostiene la enredadera, dándole forma para que pueda florecer.',
  ),
  VirtueDef(
    slug: 'practices/virtue-refinement',
    sphere: 'justice_and_duty',
    virtueEn: 'Cultivated / Refined',
    virtueEs: 'Culto / Refinado',
    deficiencyEn: 'Barbaric / Coarse',
    deficiencyEs: 'Bárbaro / Vulgar',
    excessEn: 'Snobbish / Elitist',
    excessEs: 'Esnob / Elitista',
    poeticEn: 'A polished gem that catches the light without sneering at the raw stone.',
    poeticEs: 'Una gema pulida que atrapa la luz sin burlarse de la piedra en bruto.',
  ),
];

final Map<String, VirtueDef> kVirtuesBySlug = {
  for (final v in kVirtues) v.slug: v,
};

VirtueDef? getVirtueBySlug(String slug) => kVirtuesBySlug[slug];

VirtueSphere? getSphereById(String id) {
  for (final s in kVirtueSpheres) {
    if (s.id == id) return s;
  }
  return null;
}

VirtueDef getFocusVirtueForDate([DateTime? date]) {
  final d = date ?? DateTime.now();
  final startOfYear = DateTime(d.year, 1, 1);
  final diff = d.difference(startOfYear).inDays;
  final weekNum = diff ~/ 7;
  final idx = weekNum.abs() % kVirtues.length;
  return kVirtues[idx];
}
