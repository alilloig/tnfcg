const NodeEnvironment = require("jest-environment-node");

class CustomEnvironment extends NodeEnvironment {
  async setup() {
    await super.setup();
    this.global.Uint8Array = Uint8Array;
    this.global.ArrayBuffer = ArrayBuffer;
  }
}

module.exports = CustomEnvironment;
