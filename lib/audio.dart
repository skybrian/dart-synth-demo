library audio;
import 'package:js/js.dart' as js;

class Wrapper {
  js.Proxy _inner;
  Wrapper(js.Proxy inner) {
    _inner = js.retain(inner);
  }
  
  void release() {
    js.release(_inner);
    _inner = null;
  }
  
  String toString() {
    if (_inner == null) {
      return "${this.runtimeType}(null)";
    }
    // workaround for https://code.google.com/p/dart/issues/detail?id=9879
    String val = js.context.getString(_inner);
    return "${this.runtimeType}($val)";   
  }
}

class AudioContext extends Wrapper {
  AudioDestinationNode destination;
  
  AudioContext() : super(js.context.createAudioContext()) {
    destination = new AudioDestinationNode(_inner.destination);
  }
  
  num get currentTime {
    return _inner.currentTime;
  }
  
  num get sampleRate {
    return _inner.sampleRate;
  }
  
  AudioBuffer createBuffer(num numberOfChannels, num length, num sampleRate) {
    return new AudioBuffer(_inner.createBuffer(numberOfChannels, length, sampleRate));
  }
  
  AudioBufferSourceNode createBufferSource() {
    return new AudioBufferSourceNode(_inner.createBufferSource());
  }

  GainNode createGain() {  
    return new GainNode(_inner.createGain());
  }
}

class AudioBuffer extends Wrapper {
  AudioBuffer(js.Proxy inner) : super(inner);
  
  ChannelData getChannelData(num channel) {
    return new ChannelData(_inner.getChannelData(channel));
  }
}

class ChannelData extends Wrapper {
  ChannelData(js.Proxy inner) : super(inner);
  
  num get length {
    return _inner.length;
  }
  
  num operator [](int index) {
    return _inner[index];
  }
  
  operator []=(int index, num value) {
    _inner[index] = value;;
  }
}

class AudioParam extends Wrapper {
  AudioParam(js.Proxy inner) : super(inner);

  num get value {
    return _inner.value;
  }

  set value(num value) {
    return _inner.value = value;;
  }
  
  void setTargetAtTime(num target, num startTime, num timeConstant) {
    _inner.setTargetAtTime(target, startTime, timeConstant);    
  }
  
  void linearRampToValueAtTime(num value, num endTime) {
    _inner.linearRampToValueAtTime(value, endTime);        
  }
}

class AudioNode extends Wrapper {
  AudioNode(js.Proxy inner) : super(inner);
  void connect(AudioNode destination, [num output = 0]) {
    _inner.connect(destination._inner, output);
  }
}

class AudioBufferSourceNode extends AudioNode {

  AudioParam playbackRate;
  AudioParam gain;
  
  AudioBufferSourceNode(js.Proxy inner) : super(inner) {
    playbackRate = new AudioParam(_inner.playbackRate);
    gain = new AudioParam(_inner.gain);
  }

  AudioBuffer get buffer {
    if (_inner.buffer == null) {
        return null;
    }
    return new AudioBuffer(_inner.buffer);
  }
  
  set buffer(AudioBuffer value) {
    _inner.buffer = value._inner;;
  }
  
  bool get loop {
    return _inner.loop;
  }
  
  set loop(bool value) {
    _inner.loop = value;
  }  
  
  void start(num when /* [num offset, num duration] */) {
    _inner.start(when);    
  }
  void stop(num when) {
    _inner.stop(when);    
  }
}

class GainNode extends AudioNode {
  AudioParam gain;
  GainNode(js.Proxy inner) : super(inner) {
    gain = new AudioParam(_inner.gain);
  }
}

class AudioDestinationNode extends AudioNode {
  AudioDestinationNode(js.Proxy inner) : super(inner);
}

