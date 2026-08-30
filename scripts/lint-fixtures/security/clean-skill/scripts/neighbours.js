// Fixture only — never executed.
// ok: sh-envdump
const home = process.env.HOME;
// ok: sh-noverify
const agent = new https.Agent({ rejectUnauthorized: true });
