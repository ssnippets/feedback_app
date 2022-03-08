import { Op } from 'sequelize';
import model from '../models';

const { Message } = model;

export default {
    async newMessage(req, res) {
        const { message, sender } = req.body;
        const nowDate = new Date();

        try {
            await Message.create({
                message: message,
                sender: sender,
                sent_at: nowDate
            });
            return res.status(201).send({ message: "Message created successfully." });
        } catch (e) {
            console.log(e);
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
                order: [['sent_at', 'DESC']],
                limit: MAX_MESSAGES,
                offset: req.offset || 0
            });
            return res.status(200).send({
                data: messages,
                count: count
            })
        } catch (e) {
            console.log(e);
            return res.status(500).send({
                message: 'Error'
            })

        }


    }
}