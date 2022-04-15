const nodemailer = require("nodemailer");
import * as Config from '../../platformconfig';

/// end todo

let generateDestinationEmail = function(message, sender){
    let body = `This message has been forwarded for a constituent with the following email address: <em>${sender}</em>.<br/>
---- Begin Message ----<br/>
<br/>
${message}<br/>
<br/>
----  End Message  ----<br/>
<br/>- Team`;
    return body;
}
let generateValidationEmail = function(code) {
    let subject = "Email Validation Required";
    let body = 
` Thank you for submitting your comment, in order to submit, please click on the following link to confirm your email:
<a href="${Config.hostname}/validate/${code}">${Config.hostname}/validate/${code}</a>.
`;
return {subject: subject, body: body};
}

let sendEmail = async function(dest, subject, message){
    const smtpCreds = await Config.getSmtpCreds();
    let transporter = nodemailer.createTransport({
        host: Config.smtp_host,
        port: Config.smtp_port,
        secure: Config.smtp_secure, // true for 465, false for other ports
        auth: {
          user: smtpCreds.smtp_username, // generated ethereal user
          pass: smtpCreds.smtp_password, // generated ethereal password
        },
      });
      let info = await transporter.sendMail({
        from: Config.sender, // sender address
        to: dest, // list of receivers
        subject: subject, // Subject line
        // text: "Hello world?", // plain text body
        html: message, // html body
      });
      console.log("Message sent: %s", info.messageId);
}

export {generateValidationEmail, sendEmail, generateDestinationEmail}