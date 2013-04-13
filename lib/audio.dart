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
    return js.scoped(() {
      String val = js.context.getString(_inner);
      return "${this.runtimeType}($val)";  
    });    
  }
}

class AudioContext extends Wrapper {
  AudioDestinationNode destination;
  
  AudioContext() : super(js.scoped(() {
      return js.retain(js.context.createAudioContext());
    })) {
    js.scoped(() {
      destination = new AudioDestinationNode(_inner.destination);
    });
  }
  
  num get currentTime {
    return js.scoped(() => _inner.currentTime);
  }
  
  num get sampleRate {
    return js.scoped(() => _inner.sampleRate);
  }
  
  AudioBuffer createBuffer(num numberOfChannels, num length, num sampleRate) {
    return js.scoped(() {
      return new AudioBuffer(_inner.createBuffer(numberOfChannels, length, sampleRate));
    });
  }
  
  AudioBufferSourceNode createBufferSource() {
    return js.scoped(() {
      return new AudioBufferSourceNode(_inner.createBufferSource());
    });
  }

  GainNode createGain() {  
    return js.scoped(() {
      return new GainNode(_inner.createGain());
    });
  }
}

class AudioBuffer extends Wrapper {
  AudioBuffer(js.Proxy inner) : super(inner);
  
  ChannelData getChannelData(num channel) {
    return js.scoped(() => new ChannelData(_inner.getChannelData(channel)));
  }
}

class ChannelData extends Wrapper {
  ChannelData(js.Proxy inner) : super(inner);
  
  num get length {
    return js.scoped(() => _inner.length);
  }
  
  num operator [](int index) {
    return js.scoped(() =>_inner[index]);
  }
  
  operator []=(int index, num value) {
    js.scoped(() { _inner[index] = value; });
  }
}

class AudioParam extends Wrapper {
  AudioParam(js.Proxy inner) : super(inner);

  num get value {
    return js.scoped(() => _inner.value);
  }

  set value(num value) {
    return js.scoped(() { _inner.value = value; });
  }
  
  void setTargetAtTime(num target, num startTime, num timeConstant) {
    js.scoped(() => _inner.setTargetAtTime(target, startTime, timeConstant));    
  }
  
  void linearRampToValueAtTime(num value, num endTime) {
    js.scoped(() => _inner.linearRampToValueAtTime(value, endTime));        
  }
}

class AudioNode extends Wrapper {
  AudioNode(js.Proxy inner) : super(inner);
  void connect(AudioNode destination, [num output = 0]) {
    js.scoped(() {
      _inner.connect(destination._inner, output);
    });  
  }
}

class AudioBufferSourceNode extends AudioNode {

  AudioParam playbackRate;
  AudioParam gain;
  
  AudioBufferSourceNode(js.Proxy inner) : super(inner) {
    js.scoped(() {
      playbackRate = new AudioParam(_inner.playbackRate);
      gain = new AudioParam(_inner.gain);
    });
  }

  AudioBuffer get buffer {
    return js.scoped(() {
      if (_inner.buffer == null) {
        return null;
      }
      return new AudioBuffer(_inner.buffer);
    });
  }
  
  set buffer(AudioBuffer value) {
    js.scoped(() { _inner.buffer = value._inner; });
  }
  
  bool get loop {
    return js.scoped(() => _inner.loop);
  }
  
  set loop(bool value) {
    js.scoped(() { _inner.loop = value; });
  }  
  
  void start(num when /* [num offset, num duration] */) {
    js.scoped(() => _inner.start(when));    
  }
  void stop(num when) {
    js.scoped(() => _inner.stop(when));    
  }
}

class GainNode extends AudioNode {
  AudioParam gain;
  GainNode(js.Proxy inner) : super(inner) {
    js.scoped(() {
      gain = new AudioParam(_inner.gain);
    });    
  }
}

class AudioDestinationNode extends AudioNode {
  AudioDestinationNode(js.Proxy inner) : super(inner);
}

