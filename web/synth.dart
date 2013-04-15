import 'dart:html';
import 'dart:math' as math;
import 'package:synth_demo/audio.dart';
import 'package:js/js.dart' as js;

num TAU = math.PI * 2;
num SAMPLES_PER_CYCLE = 4096;

bool mouseOn = false;
AudioContext context;

void main() {
  setStatus("starting");

  // keep track of whether a mouse button is down

  document.body.onMouseDown.listen((MouseEvent e) {
    if (e.button == 0) {
      mouseOn = true;
    }
  });

  document.body.onMouseUp.listen((MouseEvent e) {
    mouseOn = false;
  });

  document.body.onMouseOut.listen((MouseEvent e) {
    if (e.target == document.body) {
      mouseOn = false;
    }
  });

  // create sounds

  context = new AudioContext();
  print("context: ${context}");

  AudioBuffer sineWave = digitize(1, (num phase) {
    return math.sin(phase * TAU);
  });

  AudioBuffer squareWave = digitize(1, (num phase) {
    return phase < 0.5 ? 1.0 : -1.0;
  });

  AudioBuffer sawToothWave = digitize(1, (num phase) {
    return phase * 2 - 1;
  });
  
  // create keyboard

  GainNode volume = context.createGain();
  volume.gain.value = 0.2;
  volume.connect(context.destination, 0);

  InputElement volumeSlider = query("#volume");
  volumeSlider.value = (volume.gain.value * 100).toString();
  volumeSlider.onChange.listen((Event e) {
    volume.gain.value = double.parse(volumeSlider.value) / 100.0;
  });

  Keyboard keyboard = new Keyboard("sounds", "black_keys", "white_keys", volume);

  List<num> organEnvelope = [0.05, 0.0, 1.0, 0.08];
  keyboard.addPatchButton("Sine", organEnvelope, sineWave);
  keyboard.addPatchButton("Square", organEnvelope, squareWave);
  keyboard.addPatchButton("Sawtooth", organEnvelope, sawToothWave);
  keyboard.addPatchButton("Even Harmonics", organEnvelope,
    makeFractionalHarmonicWave(1, [6, 1, 0, 1, 0, 1, 0, 1]));
  keyboard.addPatchButton("Odd Harmonics", organEnvelope,
    makeFractionalHarmonicWave(1, [6, 0, 1, 0, 1, 0, 1, 0, 1]));
  keyboard.addPatchButton("Octave Harmonics", organEnvelope,
    makeFractionalHarmonicWave(1, [6, 1, 0, 1, 0, 0, 0, 1]));
  keyboard.addPatchButton("Fractional Harmonics", organEnvelope,
    makeFractionalHarmonicWave(3, [0, 0, 6, 1, 1, 1, 1]));
  keyboard.addPatchButton("Fractional Harmonics 2", organEnvelope,
    makeFractionalHarmonicWave(3, [0, 0, 6, 0, 2, 0, 2]));

  var malletEnvelope = [0.01, 1.0, 0.0, 1.0];
  keyboard.addPatchButton("Xylophone", malletEnvelope, sineWave);

  var pianoEnvelope = [0.01, 1.0, 0.2, 0.1];
  keyboard.addPatchButton("Electric Piano",
    pianoEnvelope, makeFractionalHarmonicWave(3,
      [0, 0, 8, 7, 6, 7, 6, 5, 6, 5, 4, 5, 4, 3, 4]));


  List blackOctave = [0, 2, "spacer", 5, 7, 9, "spacer"];
  List blackKeys = ["half_spacer"]
    ..addAll(transpose(29, blackOctave))
    ..addAll(transpose(29 + 12, blackOctave));
  keyboard.addBlackKeys(blackKeys);
  List majorOctave = [0, 2, 4, 5, 7, 9, 11];
  List whiteKeys = transpose(28, majorOctave)
      ..addAll(transpose(28 + 12, majorOctave))
      ..add(28 + 24);
  keyboard.addWhiteKeys(whiteKeys);

  setStatus("");
}

List transpose(num delta, List pitches) {
  List<num> result = [];
  for (var p in pitches) {
    if (p is num) {
      result.add(p + delta);
    } else {
      result.add(p);      
    }
  }
  return result;
}

class Keyboard {
  String soundsId, blackKeysId, whiteKeysId;
  AudioNode destination;
  ButtonElement selectedSoundButton = null;
  Patch selectedPatch = null;
  
  Keyboard(this.soundsId, this.blackKeysId, this.whiteKeysId, this.destination);
  
  addPatchButton(String label, List<num> envelope, AudioBuffer waveBuffer) {
    var patch = new Patch(waveBuffer, envelope);
    var onClass = "sound_on";
    var offClass = "sound_off";
  
    var button = new ButtonElement()
      ..name = "button"
      ..classes.add(offClass);
      
    button.text = label;
  
    void setPatch() {
      if (selectedSoundButton != null) {
        selectedSoundButton.classes
          ..remove(onClass)
          ..add(offClass);
      }
      selectedPatch = patch;
      selectedSoundButton = button;
      button.classes
        ..remove(offClass)
        ..add(onClass);
    }
  
    button.onClick.listen((e) {
      setPatch();
    });
  
    document.getElementById(soundsId).append(button);
  
    if (selectedPatch == null) {
      setPatch();
    }
  
    return patch;
  }
  
  addBlackKeys(List pitches) {
    var parent = document.getElementById(blackKeysId);
    for (var pitch in pitches) {
      if (pitch is num) {
        var button = makeKey(pitch, "black_key_on", "black_key_off");
        parent.append(button);
      } else {
        var spacer = new SpanElement();
        spacer.classes.add(pitch.toString());
        spacer.text = " ";
        parent.append(spacer);
      }
    }
  }
  
  addWhiteKeys(List pitches) {
    var parent = document.getElementById(whiteKeysId);
    for (var pitch in pitches) {
      var button = makeKey(pitch, "white_key_on", "white_key_off");
      parent.append(button);
    }
  }
  
  makeKey(num pitch, String onClass, String offClass) {
    var hertz = getHertz(pitch);

    var button = new ButtonElement();
    button.classes.add(offClass);
    
    Function stopFunction = null;
  
    void start() {
      if (stopFunction != null) {
        stopFunction(context.currentTime);
      }
      stopFunction = selectedPatch.playNote(hertz, context.currentTime, destination);
      button.classes..remove(offClass)..add(onClass);
    }
  
    void stop() {
      if (stopFunction != null) {
        stopFunction(context.currentTime);
      }
      stopFunction = null;
      button.classes..remove(onClass)..add(offClass);
    }
  
  
    button.onMouseDown.listen((e) {
      if (e.which == 1) {
        start();
      }
    });
    button.onMouseOver.listen((e) {
      if (mouseOn) {
        start();
      }
    });
    button.onMouseOut.listen((e) => stop());
    button.onMouseUp.listen((e) => stop());
  
    return button;
  }
}

num getHertz(num pitch) {
  return 440.0 * math.pow(2, (pitch - 49) / 12);
}

/* patches */

class Patch {
  AudioBuffer waveBuffer;
  num attackTime, decayTime, sustainLevel, releaseTime;
  AudioBuffer ringBuffer;
  num ringHarmonic, ringVolume;
  
  Patch(this.waveBuffer, List<num> adsr) {
    attackTime = adsr[0];
    decayTime = adsr[1];
    sustainLevel = adsr[2];
    releaseTime = adsr[3];
  }
  
  void setRing(AudioBuffer waveBuffer, num harmonic, num volume) {
    ringBuffer = waveBuffer;
    ringHarmonic = harmonic;
    ringVolume = volume;
  }
  
  Function playNote(num hertz, num startTime, AudioNode destination) {
  
    AudioBufferSourceNode tone = makeTone(waveBuffer, hertz, startTime);
    AudioNode envelope = makeEnvelope(startTime, attackTime, decayTime, sustainLevel);
  
    AudioBufferSourceNode ring = null;
    if (ringBuffer != null) {
      ring = makeTone(ringBuffer, hertz * ringHarmonic, startTime);
      ring.gain.value = this.ringVolume;
      ring.connect(envelope, 0);
    }
    tone.connect(envelope, 0);
    envelope.connect(destination, 0);
    envelope.release();
  
    void stop(stopTime) {
      num doneTime = stopTime + releaseTime;
      tone.gain.setTargetAtTime(0, stopTime, releaseTime);
      tone.stop(doneTime + 2.0);
      tone.release();
      if (ring != null) {
        ring.gain.setTargetAtTime(0, stopTime, releaseTime);
        ring.stop(doneTime + 2.0);
        ring.release();
      }
    }
  
    return stop;
  }
}

AudioBufferSourceNode makeTone(AudioBuffer waveBuffer, num hertz, num startTime) {
  AudioBufferSourceNode node = context.createBufferSource();
  node.buffer = waveBuffer;
  node.loop = true;

  var sampleHertz = context.sampleRate / SAMPLES_PER_CYCLE;
  node.playbackRate.value = hertz / sampleHertz;

  node.start(startTime);
  node.stop(startTime + 10); // just in case

  return node;
}

GainNode makeEnvelope(num startTime, num attackTime, num decayTime, num sustainLevel) {
  GainNode node = context.createGain();
  node.gain.linearRampToValueAtTime(0.0, startTime);
  node.gain.linearRampToValueAtTime(1.0, startTime + attackTime);
  node.gain.setTargetAtTime(sustainLevel, startTime + attackTime, decayTime);

  return node;
}

AudioBuffer makeFractionalHarmonicWave(num denominator, List<num> harmonics) {
  num total = 0.0;
  for (num h in harmonics) {
    total += h;
  }

  num waveFunction(num phase) {
    num result = 0;
    for (num i = 0; i < harmonics.length; i++) {
      num harmonic = (1 + i) / denominator;
      result += harmonics[i]/total * math.sin(phase * TAU * harmonic);
    }
    return result;
  }

  return digitize(denominator, waveFunction);
}

AudioBuffer digitize(num cycles, Function waveFunction) {
  AudioBuffer buffer = context.createBuffer(1, cycles * SAMPLES_PER_CYCLE, context.sampleRate);
  ChannelData data = buffer.getChannelData(0);
  for (num i = 0; i < data.length; i++) {
    num phase = i/SAMPLES_PER_CYCLE;
    phase = phase - phase.floor();
    data[i] = waveFunction(phase);
  }
  return buffer;
}

void setStatus(String msg) {
  query("#status").text = msg;
}
