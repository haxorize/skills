// Fixture only — never executed. The JavaScript alternatives of the rule named in the file name.
// ruleid: sh-noverify
const agent = new https.Agent({ rejectUnauthorized: false });
// ruleid: sh-noverify
process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
