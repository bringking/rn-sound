import chai, {expect} from 'chai';
import dirtyChai from 'dirty-chai';
chai.use(dirtyChai);

//import sound
import Sound from '../src/sound';

describe('RNSound', ()=> {

    describe("should expose static methods", ()=> {
        it('called "enable" that has dubious value', ()=> {
            expect(Sound.enable).to.exist();
        });
        it('called "enableInSilenceMode" to allow sound in iOS during silence ', ()=> {
            expect(Sound.enableInSilenceMode).to.exist();
        });
    });
    describe("should expose static constants", ()=> {
        it('called "MAIN_BUNDLE" that specifies the path to the iOS bundle', ()=> {
            expect(Sound.MAIN_BUNDLE).to.exist();
        });
        it('called "DOCUMENT" that specifies the path to the iOS NSDocumentDirectory', ()=> {
            expect(Sound.DOCUMENT).to.exist();
        });
        it('called "LIBRARY" that specifies the path to the iOS NSLibraryDirectory', ()=> {
            expect(Sound.LIBRARY).to.exist();
        });
        it('called "CACHES" that specifies the path to the iOS NSCachesDirectory', ()=> {
            expect(Sound.CACHES).to.exist();
        });
    });

    describe('on creation', ()=> {
        it('should be loaded after creating an instance', ()=> {
            const sound = new Sound("test", "test");
            expect(sound.isLoaded()).to.be.true();
        })
    })


});