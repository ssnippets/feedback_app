let getPW = async () => {
    try {
        let dev_pw = await import('./dev_pw');
        return dev_pw;
    } catch (e) {
        console.log("No default SMTP Password to pull in.");
        return {};
    }
}

let smtp_host = process.env.SMTP_HOST || "smtp.mailgun.org";
let smtp_port = process.env.SMTP_PORT !== undefined ? Number.parseInt(process.env.SMTP_PORT) : 465;
let smtp_secure = process.env.SMTP_SECURE !== undefined ? Number.parseBoolean(process.env.SMTP_SECURE) : true;
let sender = process.env.SYSTEM_SENDER || '"System User" <system@dochound.us>"';
let hostname = process.env.SYSTEM_HOSTNAME || "http://localhost:3000";
let END_DESTINATION = process.env.END_DESTINATION || "jorge.ud@gmail.com";
let DEST_SUBJECT = process.env.DEST_SUBJECT || "Forwarded Constituent Message";

const getSmtpCreds = async () => {
    try {
        let Creds = await import('./dev_pw');
        let smtp_username = process.env.SMTP_USERNAME || Creds.SMTP_USERNAME;
        let smtp_password = process.env.SMTP_PASSWORD || Creds.SMTP_PASSWORD;
        return {
            smtp_username,
            smtp_password
        };
    } catch (e) {
        console.log("No default SMTP Password to pull in.");
        console.error(e);
        return {};
    }
};

export {
    getSmtpCreds,
    smtp_host,
    smtp_port,
    smtp_secure,
    sender,
    hostname,
    END_DESTINATION,
    DEST_SUBJECT
}