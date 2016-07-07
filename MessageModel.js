class MessageModel {
  constructor(dictionary, tag) {
    this.userId = dictionary.id
    this.message = dictionary.message
    this.renderType = "message"
    this.tag = tag 
  }
}

module.exports = MessageModel
