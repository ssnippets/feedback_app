const Message = require('../models/').Message;

import { randomBytes } from 'crypto';
import * as email from './Email';
import * as Config from '../../platformconfig';

let generate_random = () => {
    const buf = randomBytes(16);
    return Date.now().toString() + buf.toString('hex');
}
export default {
    async newMessage(req, res) {
        const { message, sender } = req.body;
        const nowDate = new Date();

        let approval_code = generate_random();

        console.log("Approval Code: " + approval_code);
        try {
            await Message.create({
                message: message,
                sender: sender,
                sent_at: nowDate,
                approved: false,
                approval_code: approval_code,
            });

            let email_contents = email.generateValidationEmail(approval_code);
            await email.sendEmail(sender, email_contents.subject, email_contents.body);

            return res.status(201).send({ message: "Message created successfully." });
        } catch (e) {
            console.error(e);
            return res.status(500)
                .send(
                    { message: 'Could not perform operation at this time try again later.' });
        }
    },

    async getMessages(req, res) {
        const MAX_MESSAGES = 100;
        try {
            const count = await Message.count();
            const messages = await Message.findAll({
                where: {approved: true},
                order: [['sent_at', 'DESC']],
                limit: MAX_MESSAGES,
                offset: req.offset || 0
            });
            return res.status(200).send({
                data: messages,
                count: count
            })
        } catch (e) {
            console.error(e);
            return res.status(500).send({
                message: 'Error'
            });

        }


    },
    
    async validateCode(req, res){
        let code = req.params.code;
        try{
            const message = await Message.findOne({where: {approval_code : code}});
            if (message == null){
                return res.status(404).send("The code you specified was not found.");
            } else{
                message.set({
                    approved : true,
                    approval_code: null
                }, {omitNull: false});
                message.save();
            }
            // code is validated, send out the email comment to the destination:
            email.sendEmail(Config.END_DESTINATION, Config.DEST_SUBJECT, email.generateDestinationEmail(message.message, message.sender));
            return res.status(200).send('Your message has been validated and will be submitted. Thank you.')
        } catch(e) {
            console.error(e);
            return res.status(500).send({
                message: 'Error'
            });
        }
    }
}