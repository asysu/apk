import { createServer } from 'node:http';
import { readFileSync } from 'node:fs';

const port = Number(process.env.PORT ?? 8787);
const model = process.env.GEMINI_MODEL ?? 'gemini-2.5-flash';
const maxBodyBytes = 32 * 1024;
const allowedReasons = new Set(['incorrect_answer', 'slow_answer']);
const allowedSubjects = new Set(['mathematics', 'english']);

function loadApiKeys() {
  let fileKeys = [];
  try {
    const config = JSON.parse(
      readFileSync(new URL('./private-api-keys.json', import.meta.url), 'utf8'),
    );
    if (
      config === null ||
      typeof config !== 'object' ||
      !Array.isArray(config.keys) ||
      config.keys.length !== 3 ||
      config.keys.some((key) => typeof key !== 'string')
    ) {
      throw new Error('Expected exactly three string entries in "keys".');
    }
    fileKeys = config.keys;
  } catch (error) {
    if (error?.code !== 'ENOENT') {
      throw new Error('Could not read server/private-api-keys.json.', {
        cause: error,
      });
    }
  }

  return fileKeys.filter((key) => key.trim().length > 0);
}

const apiKeys = loadApiKeys();

function readJson(request) {
  return new Promise((resolve, reject) => {
    let body = '';
    let bytes = 0;
    let tooLarge = false;
    request.setEncoding('utf8');
    request.on('data', (chunk) => {
      if (tooLarge) return;
      bytes += Buffer.byteLength(chunk);
      if (bytes > maxBodyBytes) {
        tooLarge = true;
        reject(Object.assign(new Error('Request body is too large.'), { status: 413 }));
        return;
      }
      body += chunk;
    });
    request.on('end', () => {
      if (tooLarge) return;
      try {
        resolve(JSON.parse(body));
      } catch {
        reject(Object.assign(new Error('Request body must be valid JSON.'), { status: 400 }));
      }
    });
    request.on('error', (error) => {
      if (!tooLarge) reject(error);
    });
  });
}

function validateInput(input) {
  if (
    input === null ||
    typeof input !== 'object' ||
    typeof input.topicTitle !== 'string' ||
    typeof input.lesson !== 'string' ||
    typeof input.question !== 'string' ||
    !allowedReasons.has(input.reason)
  ) {
    throw Object.assign(new Error('Required coaching fields are missing.'), { status: 400 });
  }
  return {
    topicTitle: input.topicTitle.slice(0, 180),
    lesson: input.lesson.slice(0, 4000),
    example: typeof input.example === 'string' ? input.example.slice(0, 1000) : '',
    question: input.question.slice(0, 1000),
    selectedAnswer:
      typeof input.selectedAnswer === 'string' ? input.selectedAnswer.slice(0, 500) : '',
    reason: input.reason,
  };
}

async function generateExplanation(input) {
  const situation = input.reason === 'slow_answer'
    ? 'Şagird sualı həddindən artıq uzun müddətdə həll etdi.'
    : `Şagirdin seçdiyi cavab səhvdir: "${input.selectedAnswer || 'cavab verilməyib'}".`;
  const prompt = [
    'Sən 9-cu sinif buraxılış imtahanına hazırlaşan şagird üçün mehriban Azərbaycan dili müəllimisən.',
    `Mövzu: ${input.topicTitle}`,
    `Dərs qeydi: ${input.lesson}`,
    `Nümunə: ${input.example}`,
    `Sual: ${input.question}`,
    situation,
    'Səhvin məntiqini qısa və aydın izah et, sonra düzgün yanaşmanı bir nümunə ilə göstər.',
    'Yalnız Azərbaycan dilində, maksimum 140 söz yaz. Şagirdin adını və ya cavab variantını uydurma.',
  ].join('\n');

  return requestGemini(prompt, { maxOutputTokens: 300, temperature: 0.3 });
}

function validateReviewInput(input) {
  if (
    input === null ||
    typeof input !== 'object' ||
    typeof input.topicTitle !== 'string' ||
    typeof input.lesson !== 'string' ||
    !['mathematics', 'english'].includes(input.subject)
  ) {
    throw Object.assign(new Error('Required review fields are missing.'), { status: 400 });
  }
  return {
    topicTitle: input.topicTitle.slice(0, 180),
    lesson: input.lesson.slice(0, 4000),
    example: typeof input.example === 'string' ? input.example.slice(0, 1000) : '',
    subject: input.subject,
  };
}

async function generateReviewQuestion(input) {
  const prompt = [
    'Create one original grade-9 exam review question for an Azerbaijan student.',
    `Topic: ${input.topicTitle}`,
    `Study notes: ${input.lesson}`,
    `Example: ${input.example}`,
    input.subject === 'english'
      ? 'Write the question and four answer choices in English; write the explanation in Azerbaijani.'
      : 'Write the question, four answer choices, and explanation in Azerbaijani.',
    'Return only a JSON object with string fields "prompt" and "explanation", an array "options" of exactly four strings, and integer "correctIndex" from 0 to 3.',
  ].join('\n');
  const text = await requestGemini(prompt, {
    maxOutputTokens: 400,
    temperature: 0.7,
    responseMimeType: 'application/json',
  });
  let question;
  try {
    question = JSON.parse(text);
  } catch {
    throw Object.assign(new Error('AI returned an invalid review question.'), { status: 503 });
  }
  if (
    question === null ||
    typeof question !== 'object' ||
    typeof question.prompt !== 'string' ||
    typeof question.explanation !== 'string' ||
    !Array.isArray(question.options) ||
    question.options.length !== 4 ||
    question.options.some((option) => typeof option !== 'string') ||
    !Number.isInteger(question.correctIndex) ||
    question.correctIndex < 0 ||
    question.correctIndex > 3
  ) {
    throw Object.assign(new Error('AI returned an invalid review question.'), { status: 503 });
  }
  return question;
}

function validateTutorInput(input, topicField) {
  if (
    input === null ||
    typeof input !== 'object' ||
    !allowedSubjects.has(input.subject) ||
    typeof input[topicField] !== 'string' ||
    input[topicField].trim().length === 0
  ) {
    throw Object.assign(new Error('Subject and question/topic are required.'), { status: 400 });
  }
  return {
    subject: input.subject,
    text: input[topicField].trim().slice(0, topicField === 'question' ? 1200 : 240),
  };
}

async function askTutor(input) {
  const subject = input.subject === 'mathematics' ? 'Riyaziyyat' : 'İngilis dili';
  const prompt = [
    'Sən Azərbaycan 9-cu sinif buraxılış imtahanına hazırlaşdıran mehriban müəllimsən.',
    `Fənn: ${subject}. Şagirdin sualı: ${input.text}`,
    'Cavabı Azərbaycan dilində, sadə və düzgün izah et; İngilis dili qrammatikası nümunələri İngiliscə qala bilər.',
    'Yalnız 9-cu sinif və daha aşağı səviyyəli məktəb proqramı daxilində kömək et.',
    'Şagird imtahanda çıxma ehtimalını soruşarsa, dəqiq proqnoz və zəmanət vermə. Mövzunun proqram baxımından məşqə dəyər olub-olmadığını ehtiyatla izah et və DİM-in rəsmi proqramını yoxlamağı tövsiyə et.',
    'JSON qaytar: {"answer":"qısa izah","lessonTopic":"mövzu adı"}. Sual dərs mövzusu deyilsə lessonTopic boş sətir olsun.',
  ].join('\n');
  const text = await requestGemini(prompt, {
    maxOutputTokens: 500,
    temperature: 0.3,
    responseMimeType: 'application/json',
  });
  const result = parseObject(text);
  if (
    typeof result.answer !== 'string' ||
    typeof result.lessonTopic !== 'string' ||
    result.answer.length > 5000 ||
    result.lessonTopic.length > 240
  ) {
    throw Object.assign(new Error('AI returned an invalid answer.'), { status: 503 });
  }
  return result;
}

async function teachTopic(input) {
  const subject = input.subject === 'mathematics' ? 'Riyaziyyat' : 'İngilis dili';
  const prompt = [
    'Sən Azərbaycan 9-cu sinif buraxılış imtahanına hazırlaşdıran müəllimsən.',
    `Fənn: ${subject}. Mövzu: ${input.text}`,
    'Azərbaycan dilində qısa, aydın dərs hazırla. Səviyyə 9-cu sinif və ya aşağı olmalıdır.',
    'Riyaziyyatda düstur və addım-addım həll; İngilis dilində qayda və düzgün İngilis nümunəsi ver.',
    'İmtahanda mütləq çıxacağına dair iddia etmə. Mövzu proqramdankənardırsa bunu answer/summary daxilində nəzakətlə bildir.',
    'JSON qaytar: {"title":"başlıq","summary":"qısa dərs, əsas qayda və addımlar","example":"həll edilmiş bir nümunə","practiceTip":"şagirdin özü sınayacağı bir qısa məşq və ya yadda saxlama qaydası"}.',
  ].join('\n');
  const text = await requestGemini(prompt, {
    maxOutputTokens: 800,
    temperature: 0.35,
    responseMimeType: 'application/json',
  });
  const result = parseObject(text);
  if (
    ['title', 'summary', 'example', 'practiceTip'].some(
      (field) => typeof result[field] !== 'string' || result[field].length > 5000,
    )
  ) {
    throw Object.assign(new Error('AI returned an invalid lesson.'), { status: 503 });
  }
  return result;
}

function parseObject(text) {
  try {
    const result = JSON.parse(text);
    if (result === null || typeof result !== 'object' || Array.isArray(result)) {
      throw new Error('Expected object.');
    }
    return result;
  } catch {
    throw Object.assign(new Error('AI returned invalid JSON.'), { status: 503 });
  }
}

async function requestGemini(prompt, generationConfig) {
  if (apiKeys.length === 0) {
    throw Object.assign(new Error('AI assistant is not configured.'), { status: 503 });
  }

  let lastError;
  for (const key of apiKeys) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 12000);
    try {
      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(key)}`,
        {
          method: 'POST',
          headers: { 'content-type': 'application/json' },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig,
          }),
          signal: controller.signal,
        },
      );
      if (!response.ok) {
        lastError = new Error(`Gemini returned HTTP ${response.status}.`);
        await response.body?.cancel();
        continue;
      }
      const result = await response.json();
      const text = result?.candidates?.[0]?.content?.parts
        ?.map((part) => part.text)
        .filter((part) => typeof part === 'string')
        .join('')
        .trim();
      if (text) return text;
      lastError = new Error('Gemini returned no explanation text.');
    } catch (error) {
      lastError = error;
    } finally {
      clearTimeout(timeout);
    }
  }

  throw Object.assign(
    new Error('All configured AI providers failed.'),
    { status: 503, cause: lastError },
  );
}

function respond(response, status, payload) {
  response.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'cache-control': 'no-store',
    'access-control-allow-origin': process.env.APP_ORIGIN ?? '*',
    'access-control-allow-methods': 'POST, OPTIONS',
    'access-control-allow-headers': 'content-type',
  });
  response.end(JSON.stringify(payload));
}

const server = createServer(async (request, response) => {
  const url = new URL(request.url ?? '/', `http://${request.headers.host ?? 'localhost'}`);
  if (request.method === 'OPTIONS') {
    respond(response, 204, {});
    return;
  }
  if (
    request.method !== 'POST' ||
    !['/coach', '/review-question', '/ask', '/teach'].includes(url.pathname)
  ) {
    respond(response, 404, { error: 'Not found.' });
    return;
  }

  try {
    const body = await readJson(request);
    if (url.pathname === '/ask') {
      respond(response, 200, await askTutor(validateTutorInput(body, 'question')));
    } else if (url.pathname === '/teach') {
      respond(response, 200, await teachTopic(validateTutorInput(body, 'topic')));
    } else if (url.pathname === '/review-question') {
      const input = validateReviewInput(body);
      respond(response, 200, await generateReviewQuestion(input));
    } else {
      const input = validateInput(body);
      respond(response, 200, { text: await generateExplanation(input) });
    }
  } catch (error) {
    const status = Number.isInteger(error?.status) ? error.status : 500;
    if (status >= 500) {
      console.error(`Coach request failed (${status}).`);
    }
    respond(response, status, {
      error: status === 503
        ? 'AI assistant is temporarily unavailable.'
        : status === 400 || status === 413
            ? error.message
            : 'The coaching request could not be completed.',
    });
  }
});

server.listen(port, '0.0.0.0', () => {
  console.log(`Coach service listening on port ${port}.`);
});
