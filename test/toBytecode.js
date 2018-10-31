const { AbiCoder } = require('ethers/utils/abi-coder');
console.log('AbiCoder', AbiCoder);
const ethersAbiCoder = new AbiCoder(function (type, value) {
  if (type.match(/^u?int/) && !_.isArray(value) && (!_.isObject(value) || value.constructor.name !== 'BN')) {
    return value.toString();
  }
  return value;
});

function mapStructNameAndType(structName) {
  let type = 'tuple';

  if (structName.indexOf('[]') > -1) {
    type = 'tuple[]';
    structName = structName.slice(0, -2);
  }

  return {type, name: structName};
}

function isSimplifiedStructFormat(type) {
  return typeof type === 'object' && typeof type.components === 'undefined' && typeof type.name === 'undefined';
}

function mapStructToCoderFormat(struct) {
  const components = [];
  Object.keys(struct).forEach(function (key) {
    if (typeof struct[key] === 'object') {
      components.push(
        Object.assign(
          mapStructNameAndType(key),
          {
            components: mapStructToCoderFormat(struct[key])
          }
        )
      );

      return;
    }

    components.push({
      name: key,
      type: struct[key]
    });
  });

  return components;
}

function mapTypes(types) {
  let mappedTypes = [];
  types.forEach(function (type) {
    if (isSimplifiedStructFormat(type)) {
      let structName = Object.keys(type)[0];
      mappedTypes.push(
        Object.assign(
          mapStructNameAndType(structName),
          {
            components: mapStructToCoderFormat(type[structName])
          }
        )
      );

      return;
    }

    mappedTypes.push(type);
  });

  return mappedTypes;
}

function encodeParameters(types, params) {
  return ethersAbiCoder.encode(mapTypes(types), params).replace('0x', '');
}

module.exports = encodeParameters;
