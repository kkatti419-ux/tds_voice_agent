(function () {
  let processor = null;
  let stream = null;
  let audioContext = null;
  let source = null;

  function floatTo16BitPCM(float32Array) {
    const buffer = new ArrayBuffer(float32Array.length * 2);
    const view = new DataView(buffer);
    let offset = 0;
    for (let i = 0; i < float32Array.length; i++, offset += 2) {
      const s = Math.max(-1, Math.min(1, float32Array[i]));
      view.setInt16(offset, s * 0x7fff, true);
    }
    return new Uint8Array(buffer);
  }

  function rmsToDb(rms) {
    let db = 20 * Math.log10(rms + 1e-8);
    if (!isFinite(db)) db = -120;
    return Math.max(-120, Math.min(0, db));
  }

  window.stopAudioCapture = function () {
    try {
      if (processor) {
        processor.disconnect();
        processor = null;
      }
      if (source) {
        source.disconnect();
        source = null;
      }
      if (stream) {
        stream.getTracks().forEach(function (t) {
          t.stop();
        });
        stream = null;
      }
      if (audioContext) {
        audioContext.close();
        audioContext = null;
      }
    } catch (e) {
      // ignore
    }
  };

  window.startAudioCapture = function (onPcm, onLevel) {
    window.stopAudioCapture();
    let pcmFrames = 0;
    navigator.mediaDevices.getUserMedia({ audio: true }).then(function (s) {
      stream = s;
      console.log('[audio_processor] getUserMedia OK, tracks=', s.getTracks().length);
      audioContext = new AudioContext({ sampleRate: 16000 });
      audioContext.resume().catch(function () {});
      source = audioContext.createMediaStreamSource(stream);
      processor = audioContext.createScriptProcessor(4096, 1, 1);
      processor.onaudioprocess = function (e) {
        pcmFrames++;
        if (pcmFrames <= 3) {
          console.log('[audio_processor] onaudioprocess frame', pcmFrames);
        }
        const input = e.inputBuffer.getChannelData(0);
        let sum = 0;
        for (let i = 0; i < input.length; i++) {
          sum += input[i] * input[i];
        }
        const rms = Math.sqrt(sum / input.length);
        if (onLevel) {
          onLevel(rmsToDb(rms));
        }
        const pcm16 = floatTo16BitPCM(input);
        // Send JSON string; Dart callback signature stays JS-interop-safe.
        onPcm(JSON.stringify(Array.from(pcm16)));
      };
      source.connect(processor);
      const mute = audioContext.createGain();
      mute.gain.value = 0;
      processor.connect(mute);
      mute.connect(audioContext.destination);
    }).catch(function (err) {
      console.error('getUserMedia failed:', err);
    });
  };
})();
