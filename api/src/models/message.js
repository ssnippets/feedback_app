'use strict';
const {
  Model
} = require('sequelize');
module.exports = (sequelize, DataTypes) => {
  class Message extends Model {
    /**
     * Helper method for defining associations.
     * This method is not a part of Sequelize lifecycle.
     * The `models/index` file will call this method automatically.
     */
    static associate(models) {
      // define association here
    }
  }
  Message.init({
    sender: DataTypes.STRING,
    message: DataTypes.STRING,
    sent_at: DataTypes.DATE,
    approved: DataTypes.BOOLEAN,
    approval_code: DataTypes.STRING
  }, {
    sequelize,
    modelName: 'Message',
  });
  return Message;
};