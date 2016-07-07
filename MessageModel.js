class MessageModel {
  constructor(dictionary) {
    this.userId = dictionary.id
    this.message = dictionary.message
    this.renderType = "message"
  }
}

module.exports = MessageModel
