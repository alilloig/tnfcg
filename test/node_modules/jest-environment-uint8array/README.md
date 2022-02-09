# jest-environment-uint8array

Workaround for a known jest issue that makes type comparisons of `Uint8Array` fail: https://github.com/facebook/jest/issues/4422

# Installation

```
yarn add --dev jest-environment-uint8array
```

# Jest config:

On `package.json`:

```json
  "jest": {
    "testEnvironment": "jest-environment-uint8array"
  }
```
