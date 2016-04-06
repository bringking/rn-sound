// https://blog.formidable.com/unit-testing-react-native-with-mocha-and-enzyme-51518f13ba73#.wqlvkxofx

const React = require('react');
const RN = React;

// MOCK RNSound Bridge Interface
RN.NativeModules = {
    RNSound: {
        enable() {
            return true;
        },
        MainBundlePath: true,
        NSDocumentDirectory: true,
        NSLibraryDirectory: true,
        NSCachesDirectory: true,
        prepare( fileName, key, options, cb ) {
            cb(null, { duration: 1000, numberOfChannels: 2 });
        }
    }
};

module.exports = RN;