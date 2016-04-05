'use strict';

const RNSound = require('react-native').NativeModules.RNSound;
const IsAndroid = typeof RNSound.setLooping !== 'undefined';
let nextKey = 0;

class Sound {
    constructor( filename, basePath, onError = () => false, options = {} ) {
        if ( IsAndroid ) {
            this._filename = filename.toLowerCase().replace(/\.[^.]+$/, '');
        } else {
            this._filename = basePath ? basePath + '/' + filename : filename;
        }
        this._loaded = false;
        this._key = nextKey++;
        this._duration = -1;
        this._numberOfChannels = -1;
        this._volume = 1;
        this._pan = 0;
        this._numberOfLoops = 0;
        RNSound.prepare(this._filename, this._key, options, ( error, props ) => {
            if ( props ) {
                if ( typeof props.duration === 'number' ) {
                    this._duration = props.duration;
                }
                if ( typeof props.numberOfChannels === 'number' ) {
                    this._numberOfChannels = props.numberOfChannels;
                }
            }
            if ( error === null ) {
                this._loaded = true;
            }
            if ( onError ) {
                onError(error);
            }
        });
    }

    isLoaded() {
        return this._loaded;
    }

    play( onEnd = () => false ) {
        if ( this._loaded ) {
            RNSound.play(this._key, ( successfully ) => onEnd(successfully));
        }
        return this;
    }

    pause() {
        if ( this._loaded ) {
            RNSound.pause(this._key);
        }
        return this;
    }

    stop() {
        if ( this._loaded ) {
            RNSound.stop(this._key);
        }
        return this;
    }

    release() {
        if ( this._loaded ) {
            RNSound.release(this._key);
        }
        return this;
    }

    getDuration() {
        return this._duration;
    }

    getNumberOfChannels() {
        return this._numberOfChannels;
    }

    getVolume() {
        return this._volume;
    }

    setVolume( value ) {
        this._volume = value;
        if ( this._loaded ) {
            if ( IsAndroid ) {
                RNSound.setVolume(this._key, value, value);
            } else {
                RNSound.setVolume(this._key, value);
            }
        }
        return this;
    }

    getPan() {
        return this._pan;
    }

    setPan( value ) {
        if ( this._loaded ) {
            RNSound.setPan(this._key, this._pan = value);
        }
        return this;
    }

    getNumberOfLoops() {
        return this._numberOfLoops;

    }

    setNumberOfLoops( value ) {
        this._numberOfLoops = value;
        if ( this._loaded ) {
            if ( IsAndroid ) {
                RNSound.setLooping(this._key, !!value);
            } else {
                RNSound.setNumberOfLoops(this._key, value);
            }
        }
        return this;
    }

    getCurrentTime(callback) {
        if ( this._loaded ) {
            RNSound.getCurrentTime(this._key, callback);
        }
    }

    setCurrentTime( value ) {
        if ( this._loaded ) {
            RNSound.setCurrentTime(this._key, value);
        }
        return this;
    }

    // ios only
    setCategory( value ) {
        RNSound.setCategory(this._key, value);
    }

    // ios only
    setOnRemotePauseHandler( value ) {

        let onRemotePause = () => {
            if ( value ) {
                value();
                // reset
                RNSound.onRemotePause(this._key, onRemotePause);
            }
        };

        // initial set
        RNSound.onRemotePause(this._key, onRemotePause);

        return this;
    }

    // ios only
    setOnRemotePlayHandler( value ) {
        let onRemotePlay = () => {
            if ( value ) {
                value();
                // reset
                RNSound.onRemotePlay(this._key, onRemotePlay);
            }
        };

        // initial set
        RNSound.onRemotePlay(this._key, onRemotePlay);
        return this;
    }


}

Sound.enable = function ( enabled ) {
    RNSound.enable(enabled);
};
Sound.enableInSilenceMode = function ( enabled ) {
    RNSound.enableInSilenceMode(enabled);
};

if ( !IsAndroid ) {
    Sound.enable(true);
}

Sound.MAIN_BUNDLE = RNSound.MainBundlePath;
Sound.DOCUMENT = RNSound.NSDocumentDirectory;
Sound.LIBRARY = RNSound.NSLibraryDirectory;
Sound.CACHES = RNSound.NSCachesDirectory;

module.exports = Sound;
