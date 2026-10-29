import '../models/study_models.dart';

const contentBank = <StudyTopic>[
  StudyTopic(
    id: 'math-identities',
    subject: StudySubject.mathematics,
    title: 'Müxtəsər vurma düsturları',
    lesson:
        '(a+b)²=a²+2ab+b²; (a−b)²=a²−2ab+b²; a²−b²=(a−b)(a+b). '
        'İşarələrə və orta həddə diqqət et: kvadrat düsturlarında orta hədd 2ab-dir.',
    example: '(x+3)²=x²+6x+9',
    questions: [
      StudyQuestion(
        prompt: '(x−5)² ifadəsini açın.',
        options: ['x²−10x+25', 'x²−25', 'x²+10x+25', 'x²−5x+25'],
        correctIndex: 0,
        explanation: '(a−b)²=a²−2ab+b² düsturunda a=x, b=5 götürülür.',
      ),
      StudyQuestion(
        prompt: 'a²−16 ifadəsini vuruqlara ayırın.',
        options: ['(a−4)(a+4)', '(a−8)(a+2)', '(a−4)²', 'a(a−16)'],
        correctIndex: 0,
        explanation: 'a²−b²=(a−b)(a+b); burada 16=4².',
      ),
      StudyQuestion(
        prompt: '(m+2)² ifadəsinin orta həddi hansıdır?',
        options: ['4m', '2m', 'm²', '4'],
        correctIndex: 0,
        explanation: 'Orta hədd 2ab-dir: 2·m·2=4m.',
      ),
      StudyQuestion(
        prompt: '(y−3)(y+3) hasilini tapın.',
        options: ['y²−9', 'y²+9', 'y²−6y+9', '2y−6'],
        correctIndex: 0,
        explanation: 'Bu, kvadratlar fərqidir: (y−3)(y+3)=y²−3².',
      ),
    ],
  ),
  StudyTopic(
    id: 'math-roots',
    subject: StudySubject.mathematics,
    title: 'Kvadrat köklər',
    lesson:
        '√a yalnız a≥0 olduqda həqiqi ədəddir. √(ab)=√a·√b (a,b≥0). '
        '√(a²)=|a|; ifadəni sadələşdirərkən tam kvadrat vuruqları kök altından çıxar.',
    example: '√72=√(36·2)=6√2',
    questions: [
      StudyQuestion(
        prompt: '√72-ni sadələşdirin.',
        options: ['6√2', '8√2', '3√8', '36√2'],
        correctIndex: 0,
        explanation: '72=36·2 olduğuna görə √72=6√2.',
      ),
      StudyQuestion(
        prompt: '√49+√16 ifadəsinin qiymətini tapın.',
        options: ['11', '9', '65', '7'],
        correctIndex: 0,
        explanation: '√49=7 və √16=4; cəm 11-dir.',
      ),
      StudyQuestion(
        prompt: '√(9·5) ifadəsini sadələşdirin.',
        options: ['3√5', '9√5', '15', '3√9'],
        correctIndex: 0,
        explanation: '√9·√5=3√5.',
      ),
      StudyQuestion(
        prompt: 'x=−4 olduqda √(x²) neçədir?',
        options: ['4', '−4', '16', '2'],
        correctIndex: 0,
        explanation: '√(x²)=|x| olduğundan |−4|=4.',
      ),
    ],
  ),
  StudyTopic(
    id: 'math-equations',
    subject: StudySubject.mathematics,
    title: 'Tənliklər və diskriminant',
    lesson:
        'ax²+bx+c=0 üçün D=b²−4ac. D>0 olduqda iki, D=0 olduqda bir, '
        'D<0 olduqda həqiqi kök yoxdur. Kök düsturu x=(-b±√D)/(2a)-dır.',
    example: 'x²−5x+6=0: D=1, köklər 2 və 3.',
    questions: [
      StudyQuestion(
        prompt: 'x²−5x+6=0 tənliyinin kökləri hansılardır?',
        options: ['2 və 3', '−2 və −3', '1 və 6', '−1 və −6'],
        correctIndex: 0,
        explanation: '(x−2)(x−3)=0 olduğuna görə x=2 və ya x=3.',
      ),
      StudyQuestion(
        prompt: 'x²+4x+4=0 tənliyinin diskriminantı neçədir?',
        options: ['0', '4', '8', '16'],
        correctIndex: 0,
        explanation: 'D=4²−4·1·4=16−16=0.',
      ),
      StudyQuestion(
        prompt: '2x−8=0 tənliyini həll edin.',
        options: ['4', '−4', '8', '2'],
        correctIndex: 0,
        explanation: '2x=8, hər iki tərəfi 2-yə böldükdə x=4.',
      ),
      StudyQuestion(
        prompt: 'x²−9=0 tənliyinin həlləri hansılardır?',
        options: ['−3 və 3', '3', '−9 və 9', '0 və 9'],
        correctIndex: 0,
        explanation: 'x²=9 olduğuna görə x=±3.',
      ),
    ],
  ),
  StudyTopic(
    id: 'math-systems',
    subject: StudySubject.mathematics,
    title: 'Tənliklər sistemi',
    lesson:
        'Sistemi əvəzetmə və ya toplama üsulu ilə həll et. Əvəzetmədə bir '
        'tənlikdən dəyişəni tapıb o birində yerinə qoy; cavabı hər iki tənlikdə yoxla.',
    example: 'x+y=7, x−y=1. Topladıqda 2x=8, deməli x=4, y=3.',
    questions: [
      StudyQuestion(
        prompt: 'x+y=7 və x−y=1 sistemində (x,y) hansıdır?',
        options: ['(4,3)', '(3,4)', '(7,1)', '(1,7)'],
        correctIndex: 0,
        explanation: 'Tənlikləri topladıqda 2x=8, x=4; buradan y=3.',
      ),
      StudyQuestion(
        prompt: 'x+y=10, x=6 olarsa y neçədir?',
        options: ['4', '6', '10', '16'],
        correctIndex: 0,
        explanation: 'y=10−6=4.',
      ),
      StudyQuestion(
        prompt: '2x+y=9, y=3 olarsa x neçədir?',
        options: ['3', '6', '12', '2'],
        correctIndex: 0,
        explanation: '2x+3=9, 2x=6, x=3.',
      ),
      StudyQuestion(
        prompt: 'x−y=2, x=5 olarsa y neçədir?',
        options: ['3', '7', '2', '5'],
        correctIndex: 0,
        explanation: '5−y=2, deməli y=3.',
      ),
    ],
  ),
  StudyTopic(
    id: 'math-geometry',
    subject: StudySubject.mathematics,
    title: 'Həndəsə: bucaqlar və çevrə',
    lesson:
        'Üçbucağın daxili bucaqlarının cəmi 180°-dir. Çevrənin uzunluğu '
        'C=2πr, sahəsi S=πr². Dairədə diametr radiusun iki qatıdır.',
    example: 'r=3 olduqda C=6π, S=9π.',
    questions: [
      StudyQuestion(
        prompt: 'Üçbucağın iki bucağı 50° və 60°-dirsə, üçüncü bucaq neçədir?',
        options: ['70°', '80°', '90°', '110°'],
        correctIndex: 0,
        explanation: 'Üçbucağın bucaqlarının cəmi 180°-dir: 180−50−60=70°.',
      ),
      StudyQuestion(
        prompt: 'Radiusu 5 olan çevrənin diametri neçədir?',
        options: ['10', '5', '25', '2.5'],
        correctIndex: 0,
        explanation: 'Diametr radiusun iki qatıdır: d=2r=10.',
      ),
      StudyQuestion(
        prompt: 'Radiusu 2 olan dairənin sahəsi nədir?',
        options: ['4π', '2π', '8π', 'π'],
        correctIndex: 0,
        explanation: 'S=πr²=π·2²=4π.',
      ),
      StudyQuestion(
        prompt: 'Düz bucağın ölçüsü neçə dərəcədir?',
        options: ['90°', '180°', '45°', '360°'],
        correctIndex: 0,
        explanation: 'Düz bucaq 90°-dir.',
      ),
    ],
  ),
  StudyTopic(
    id: 'math-area',
    subject: StudySubject.mathematics,
    title: 'Üçbucağın sahəsi',
    lesson:
        'Üçbucağın sahəsi S=ah/2 düsturu ilə hesablanır (a əsas, h həmin '
        'əsasa çəkilmiş hündürlükdür). Düzbucaqlı üçbucaqda katetlər əsas və hündürlük ola bilər.',
    example: 'a=8, h=5 olduqda S=8·5/2=20.',
    questions: [
      StudyQuestion(
        prompt: 'Əsası 10 sm, hündürlüyü 6 sm olan üçbucağın sahəsi nədir?',
        options: ['30 sm²', '60 sm²', '16 sm²', '20 sm²'],
        correctIndex: 0,
        explanation: 'S=ah/2=10·6/2=30 sm².',
      ),
      StudyQuestion(
        prompt: 'Üçbucağın sahəsi 24, əsası 8 olarsa hündürlük neçədir?',
        options: ['6', '3', '12', '4'],
        correctIndex: 0,
        explanation: '24=8h/2=4h, buna görə h=6.',
      ),
      StudyQuestion(
        prompt: 'Katetləri 3 və 4 olan düzbucaqlı üçbucağın sahəsi nədir?',
        options: ['6', '12', '7', '24'],
        correctIndex: 0,
        explanation: 'S=3·4/2=6.',
      ),
      StudyQuestion(
        prompt: 'Əsası 12, hündürlüyü 5 olan üçbucağın sahəsi nədir?',
        options: ['30', '60', '17', '24'],
        correctIndex: 0,
        explanation: 'S=12·5/2=30.',
      ),
    ],
  ),
  StudyTopic(
    id: 'english-nouns',
    subject: StudySubject.english,
    title: 'Nouns: cəm, sayılan və yiyəlik',
    lesson:
        'Countable nouns sayılır və cəm forması ola bilər (book/books); uncountable '
        'nouns adətən cəmlənmir (water, advice). Yiyəlik üçün tək isimə ’s, '
        'cəm -s ilə bitirsə apostrof əlavə olunur: the girl’s bag, the students’ room.',
    example: 'There are two boxes. This is my brother’s bike.',
    questions: [
      StudyQuestion(
        prompt: 'Düzgün cəm formanı seçin: one child, two ___.',
        options: ['children', 'childs', 'childes', 'childrens'],
        correctIndex: 0,
        explanation: 'Child sözünün qeyri-müntəzəm cəm forması children-dir.',
      ),
      StudyQuestion(
        prompt: 'Hansı isim adətən sayılmır?',
        options: ['advice', 'chair', 'apple', 'coin'],
        correctIndex: 0,
        explanation: 'Advice sayılmayan isimdir; “a piece of advice” deyilir.',
      ),
      StudyQuestion(
        prompt: '“The bag belonging to Ali” necə yazılır?',
        options: ['Ali’s bag', 'Alis bag', 'Ali bag’s', 'Alies bag'],
        correctIndex: 0,
        explanation: 'Tək şəxs adına yiyəlik ’s artırılır: Ali’s bag.',
      ),
      StudyQuestion(
        prompt: 'There ___ some milk in the glass.',
        options: ['is', 'are', 'be', 'were'],
        correctIndex: 0,
        explanation: 'Milk sayılmayan tək isimdir, ona görə is işlənir.',
      ),
    ],
  ),
  StudyTopic(
    id: 'english-pronouns',
    subject: StudySubject.english,
    title: 'Pronouns: əvəzliklər',
    lesson:
        'Subject pronouns: I, he, she, it, we, they; object forms: me, him, her, '
        'us, them. Possessive forms: my/mine, their/theirs. Reflexive forms '
        'self/selves ilə bitir. Some əsasən təsdiqdə, any sual və inkarda işlənir.',
    example: 'She made it herself. Is there any juice?',
    questions: [
      StudyQuestion(
        prompt: 'I did the homework by ___.',
        options: ['myself', 'me', 'mine', 'my'],
        correctIndex: 0,
        explanation: 'İşi şəxsin özü gördüyünü vurğulamaq üçün myself işlənir.',
      ),
      StudyQuestion(
        prompt: 'This is ___ book. (mənim)',
        options: ['my', 'mine', 'me', 'I'],
        correctIndex: 0,
        explanation: 'İsimdən əvvəl yiyəlik sifəti my işlənir: my book.',
      ),
      StudyQuestion(
        prompt: 'Do you have ___ questions?',
        options: ['any', 'some', 'no one', 'every'],
        correctIndex: 0,
        explanation: 'Ümumi suallarda any işlənir.',
      ),
      StudyQuestion(
        prompt: 'The teacher spoke to ___. (bizə)',
        options: ['us', 'we', 'our', 'ours'],
        correctIndex: 0,
        explanation: 'Preposition-dan sonra object pronoun us gəlir.',
      ),
    ],
  ),
  StudyTopic(
    id: 'english-comparison',
    subject: StudySubject.english,
    title: 'Adjectives & adverbs: müqayisə',
    lesson:
        'Qısa sifətlərdə comparative -er, superlative -est alır: small, smaller, '
        'the smallest. Uzun sifətlərdə more/most işlənir. Zərf hərəkətin necə '
        'baş verdiyini bildirir; carefully kimi -ly ilə bitə bilər.',
    example: 'This road is longer than that one. She speaks carefully.',
    questions: [
      StudyQuestion(
        prompt: 'My bag is ___ than yours. (heavy)',
        options: ['heavier', 'heavyer', 'heaviest', 'more heavy'],
        correctIndex: 0,
        explanation: 'y ilə bitən heavy sözündə y→i olur və -er artırılır.',
      ),
      StudyQuestion(
        prompt: 'This is the ___ film I have seen. (interesting)',
        options: ['most interesting', 'more interesting', 'interestinger', 'interestingest'],
        correctIndex: 0,
        explanation: 'Uzun sifətlərin üstünlük dərəcəsi the most ilə qurulur.',
      ),
      StudyQuestion(
        prompt: 'He runs ___. (quick)',
        options: ['quickly', 'quick', 'quicker', 'quickest'],
        correctIndex: 0,
        explanation: 'Run feilini izah edən zərf quickly-dir.',
      ),
      StudyQuestion(
        prompt: 'A train is usually ___ than a bicycle. (fast)',
        options: ['faster', 'fastest', 'more fast', 'fastly'],
        correctIndex: 0,
        explanation: 'Fast qısa sifətdir; comparative forması faster-dir.',
      ),
    ],
  ),
  StudyTopic(
    id: 'english-tenses',
    subject: StudySubject.english,
    title: 'Tenses: əsas zamanlar',
    lesson:
        'Present Simple: vərdiş/fakt (She works). Past Simple: bitmiş keçmiş '
        '(worked/went). Present Perfect: have/has + V3, təcrübə/nəticə. Past '
        'Continuous: was/were + V-ing. Future Simple: will + V1.',
    example: 'I have finished my work. They were studying at 8 pm.',
    questions: [
      StudyQuestion(
        prompt: 'She ___ to school every day.',
        options: ['goes', 'go', 'is go', 'going'],
        correctIndex: 0,
        explanation: 'Present Simple-də he/she/it ilə feil -s/-es alır.',
      ),
      StudyQuestion(
        prompt: 'We ___ the museum yesterday.',
        options: ['visited', 'visit', 'have visit', 'were visit'],
        correctIndex: 0,
        explanation: 'Yesterday bitmiş keçmiş vaxtı göstərir; Past Simple işlənir.',
      ),
      StudyQuestion(
        prompt: 'I ___ my homework already.',
        options: ['have finished', 'finish', 'was finish', 'will finished'],
        correctIndex: 0,
        explanation: 'Already nəticəni vurğulayır; Present Perfect: have + V3.',
      ),
      StudyQuestion(
        prompt: 'At 9 pm, they ___ TV.',
        options: ['were watching', 'watched', 'watch', 'will watch'],
        correctIndex: 0,
        explanation: 'Keçmişdə müəyyən anda davam edən hərəkət Past Continuous-dur.',
      ),
    ],
  ),
  StudyTopic(
    id: 'english-modals',
    subject: StudySubject.english,
    title: 'Modal verbs',
    lesson:
        'Can bacarıq/icazə, may nəzakətli icazə/ehtimal, must güclü vaciblik, '
        'have to qayda/zərurət, should məsləhət bildirir. Modal feldən sonra '
        'to-suz feil gəlir (have to istisnadır).',
    example: 'You should revise. You must wear a seat belt.',
    questions: [
      StudyQuestion(
        prompt: 'You ___ see a doctor if you feel ill. (məsləhət)',
        options: ['should', 'can', 'may', 'mustn’t'],
        correctIndex: 0,
        explanation: 'Məsləhət vermək üçün should işlənir.',
      ),
      StudyQuestion(
        prompt: 'When I was five, I ___ swim. (bacarıq)',
        options: ['could', 'must', 'should', 'have to'],
        correctIndex: 0,
        explanation: 'Keçmiş bacarıq could ilə ifadə olunur.',
      ),
      StudyQuestion(
        prompt: 'Students ___ wear a uniform at this school. (qayda)',
        options: ['have to', 'might to', 'should to', 'can to'],
        correctIndex: 0,
        explanation: 'Qayda və zərurət üçün have to + feil işlənir.',
      ),
      StudyQuestion(
        prompt: 'You ___ use your phone during the exam. (qadağa)',
        options: ['mustn’t', 'don’t have', 'should', 'may'],
        correctIndex: 0,
        explanation: 'Mustn’t qəti qadağa bildirir.',
      ),
    ],
  ),
  StudyTopic(
    id: 'english-passive',
    subject: StudySubject.english,
    title: 'Passive Voice: məchul növ',
    lesson:
        'Məchul növ: uyğun zamanda be + V3. Present Simple: am/is/are + V3; '
        'Past Simple: was/were + V3; Future: will be + V3. İşi görən vacib '
        'deyilsə, “by ...” hissəsi buraxıla bilər.',
    example: 'They clean the room. → The room is cleaned.',
    questions: [
      StudyQuestion(
        prompt: '“They build houses” cümləsinin Passive forması hansıdır?',
        options: ['Houses are built.', 'Houses built.', 'Houses were build.', 'Houses are build.'],
        correctIndex: 0,
        explanation: 'Present Simple Passive: are + V3 (built).',
      ),
      StudyQuestion(
        prompt: 'The letter ___ yesterday.',
        options: ['was sent', 'is send', 'sent', 'will sent'],
        correctIndex: 0,
        explanation: 'Yesterday üçün Past Simple Passive: was + V3.',
      ),
      StudyQuestion(
        prompt: 'The work ___ tomorrow.',
        options: ['will be finished', 'is finished', 'was finish', 'will finished'],
        correctIndex: 0,
        explanation: 'Future Passive: will be + V3.',
      ),
      StudyQuestion(
        prompt: '“People speak English here.” → English ___ here.',
        options: ['is spoken', 'speaks', 'was speak', 'is speaking'],
        correctIndex: 0,
        explanation: 'Present Simple Passive quruluşu is + spoken-dır.',
      ),
    ],
  ),
  StudyTopic(
    id: 'english-connectors',
    subject: StudySubject.english,
    title: 'Prepositions & conjunctions',
    lesson:
        'At dəqiq saat, on gün/tarix, in ay/il və uzun dövr üçün işlənir. '
        'Because səbəb, so nəticə, but ziddiyyət bildirir. Sözönlərini ifadə '
        'ilə birlikdə öyrən: interested in, good at, depend on.',
    example: 'We stayed home because it was raining.',
    questions: [
      StudyQuestion(
        prompt: 'The lesson starts ___ 9 o’clock.',
        options: ['at', 'in', 'on', 'for'],
        correctIndex: 0,
        explanation: 'Dəqiq saatlarla at işlənir.',
      ),
      StudyQuestion(
        prompt: 'My birthday is ___ Monday.',
        options: ['on', 'at', 'in', 'by'],
        correctIndex: 0,
        explanation: 'Həftənin günləri ilə on işlənir.',
      ),
      StudyQuestion(
        prompt: 'I was tired, ___ I went to bed early.',
        options: ['so', 'because', 'but', 'although'],
        correctIndex: 0,
        explanation: 'İkinci hissə nəticədir; so “buna görə” deməkdir.',
      ),
      StudyQuestion(
        prompt: 'She is interested ___ science.',
        options: ['in', 'at', 'on', 'for'],
        correctIndex: 0,
        explanation: 'Düzgün söz birləşməsi interested in-dir.',
      ),
    ],
  ),
  StudyTopic(
    id: 'english-vocabulary',
    subject: StudySubject.english,
    title: 'Vocabulary: sinonimlər və antonimlər',
    lesson:
        'Yeni sözləri mövzu və nümunə cümlə ilə yadda saxla. Sinonim oxşar '
        'məna, antonim əks məna daşıyır. Buraxılış modelində sözün cümlədəki '
        'mənasına və söz ailəsinə (decide/decision) diqqət et.',
    example: 'begin ≈ start (sinonim); careful ↔ careless (antonim).',
    questions: [
      StudyQuestion(
        prompt: '“Begin” sözünün sinonimi hansıdır?',
        options: ['start', 'finish', 'forget', 'break'],
        correctIndex: 0,
        explanation: 'Begin və start “başlamaq” mənasını verir.',
      ),
      StudyQuestion(
        prompt: '“Ancient” sözünün antonimi hansıdır?',
        options: ['modern', 'old', 'historic', 'early'],
        correctIndex: 0,
        explanation: 'Ancient “qədim”, modern isə “müasir” deməkdir.',
      ),
      StudyQuestion(
        prompt: '“Difficult” sözünə yaxın mənalı sözü seçin.',
        options: ['hard', 'easy', 'short', 'safe'],
        correctIndex: 0,
        explanation: 'Difficult və hard “çətin” deməkdir.',
      ),
      StudyQuestion(
        prompt: '“Polite” sözünün antonimi hansıdır?',
        options: ['rude', 'kind', 'helpful', 'friendly'],
        correctIndex: 0,
        explanation: 'Polite “nəzakətli”, rude isə “kobud” deməkdir.',
      ),
    ],
  ),
  StudyTopic(
    id: 'english-reading',
    subject: StudySubject.english,
    title: 'Reading comprehension',
    lesson:
        'Mətni əvvəlcə ümumi məna üçün oxu, sonra sualdakı açar sözü tap. '
        'Cavabı mətndən sübut et; açıq sualda tam cümlə yaz. Yeni sözün mənasını '
        'ətrafındakı cümlələrdən təxmin et.',
    example:
        'Leyla visits the library every Saturday. She borrows two books and reads them at home.',
    questions: [
      StudyQuestion(
        prompt: 'Answer in one sentence: What does Leyla do every Saturday?',
        options: [],
        correctIndex: 0,
        openEndedKeywords: ['library', 'two', 'books'],
        explanation:
            'Mətnə görə Leyla şənbə günü kitabxanaya gedir və iki kitab götürür.',
      ),
      StudyQuestion(
        prompt: 'Mətnə əsasən, Leyla kitabxanaya nə vaxt gedir?',
        options: ['Every Saturday', 'Every Monday', 'In the evening', 'In summer'],
        correctIndex: 0,
        explanation: 'Mətnin ilk cümləsində “every Saturday” deyilir.',
      ),
      StudyQuestion(
        prompt: 'Leyla kitabxanadan neçə kitab götürür?',
        options: ['Two', 'One', 'Three', 'Four'],
        correctIndex: 0,
        explanation: 'Mətnə görə o, iki kitab götürür.',
      ),
      StudyQuestion(
        prompt: 'Leyla kitabları harada oxuyur?',
        options: ['At home', 'At school', 'On the bus', 'At the library'],
        correctIndex: 0,
        explanation: 'Son hissədə kitabları evdə oxuduğu bildirilir.',
      ),
    ],
  ),
  StudyTopic(
    id: 'english-listening',
    subject: StudySubject.english,
    title: 'Listening simulation',
    lesson:
        'Dinləmə simulyasiyası: aşağıdakı mətni diqqətlə oxu və səsləndirildiyini '
        'təsəvvür edərək sualları cavablandır. Ad, saat, yer və rəqəmlər kimi '
        'detalları qeyd et. Bu rejim hazırda audio səsləndirmir.',
    example:
        '“Hello, I’m Sam. My train leaves at half past eight. I’m meeting my cousin at the station.”',
    questions: [
      StudyQuestion(
        prompt: 'Samın qatarı saat neçədə yola düşür?',
        options: ['8:30', '8:00', '9:30', '7:30'],
        correctIndex: 0,
        explanation: 'Half past eight saat 8:30 deməkdir.',
      ),
      StudyQuestion(
        prompt: 'Sam kiminlə görüşür?',
        options: ['His cousin', 'His teacher', 'His friend', 'His brother'],
        correctIndex: 0,
        explanation: 'Mətndə cousin (əmisi/dayısı/xalası/bibisi uşağı) deyilir.',
      ),
      StudyQuestion(
        prompt: 'Sam harada görüşəcək?',
        options: ['At the station', 'At school', 'At home', 'At the park'],
        correctIndex: 0,
        explanation: 'Mətndə görüş yeri station kimi göstərilib.',
      ),
      StudyQuestion(
        prompt: 'Samın adını seçin.',
        options: ['Sam', 'Tom', 'Ben', 'Max'],
        correctIndex: 0,
        explanation: 'Dinləmə mətninin əvvəlində “I’m Sam” deyir.',
      ),
    ],
  ),
];
