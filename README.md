# Dart Synth Demo #

A simple music synthesizer written in Dart and using Web Audio. Demonstrates how to call
Web Audio using the Dart JavaScript Interop library, instead of using Dart's built-in
Web Audio library. (I had to do this due to a [bug][1].)

== Caveats ==

* Runs in Chrome only because it relies on Web Audio.

* It's a direct translation of another [demo][2] that I wrote in JavaScript, so as a Dart
app, the style may seem a bit odd.

[1]: https://code.google.com/p/dart/issues/detail?id=9739
[2]: https://github.com/skybrian/midiplayer
