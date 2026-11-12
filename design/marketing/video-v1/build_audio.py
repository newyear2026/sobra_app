"""Original 20-second soft mallet score; no third-party recordings or samples."""
from pathlib import Path
import wave
import numpy as np

OUT = Path(__file__).resolve().parent
SR = 48000
SECONDS = 20
BEAT = .625  # 96 BPM, eight 4/4 bars
audio = np.zeros((SR * SECONDS, 2), dtype=np.float64)

def note(midi, start, duration=1.4, volume=.1, pan=0):
    t = np.arange(int(duration * SR)) / SR
    hz = 440 * 2 ** ((midi - 69) / 12)
    # Rounded mallet attack and a soft, quickly decaying upper harmonic.
    tone = (np.sin(2*np.pi*hz*t) * np.exp(-3.2*t)
            + .24*np.sin(2*np.pi*2*hz*t)*np.exp(-7*t)
            + .055*np.sin(2*np.pi*3*hz*t)*np.exp(-10*t))
    tone *= np.minimum(t / .008, 1) * np.minimum((duration-t)/.06, 1)
    stereo = np.column_stack([tone*np.sqrt((1-pan)/2), tone*np.sqrt((1+pan)/2)]) * volume
    a = int(start*SR)
    b = min(a+len(stereo), len(audio))
    if a < b: audio[a:b] += stereo[:b-a]

# A short, newly composed D-major pentatonic phrase.
melodies = [
    [74, 78, 81, 78], [76, 74, 71, 74],
    [79, 78, 74, 76], [73, 76, 81, 76],
    [74, 78, 81, 83], [81, 78, 76, 74],
    [71, 74, 78, 76], [78, 76, 74, None],
]
chords = [(50,57,66), (47,54,62), (43,50,59), (45,52,61)] * 2
for bar, (melody, chord) in enumerate(zip(melodies, chords)):
    for beat, pitch in enumerate(melody):
        if pitch is not None:
            note(pitch, (bar*4+beat)*BEAT, volume=.12 if beat == 0 else .09, pan=(-.15 if beat%2 else .15))
    for beat in (0, 2):
        for j, pitch in enumerate(chord):
            note(pitch, (bar*4+beat)*BEAT+j*.022, duration=2.1, volume=.035, pan=(j-1)*.3)

# Light stereo ambience, rendered from the same synthesized notes.
dry = audio.copy()
for seconds, gain in ((.115,.11),(.235,.085),(.37,.04)):
    shift = int(seconds*SR)
    audio[shift:] += dry[:-shift, ::-1] * gain
audio *= np.minimum(np.arange(len(audio)) / (SR*.16), 1)[:,None]
audio *= np.minimum(np.arange(len(audio))[::-1] / (SR*1.0), 1)[:,None]
audio *= .62 / max(np.abs(audio).max(), .001)
with wave.open(str(OUT/'sobrita-original-music.wav'), 'wb') as f:
    f.setnchannels(2)
    f.setsampwidth(2)
    f.setframerate(SR)
    f.writeframes((audio * 32767).astype('<i2').tobytes())
print(OUT/'sobrita-original-music.wav')
