use_bpm 60

# load bass sample
bass = "/Users/joelamb/Documents/SonicPi/chess-sonification/immortal-game/samples/double-bass-c-2.wav"

# note durations based on relative value of pieces
P = 0.125
N = 0.25
B = 0.25
R = 0.5
Q = 1
K = 2

# The Immortal Game, Adolf Anderssen vs Lionel Kierseritzky, June 21, 1851
# ranks a-h transposed to notes, b as b flat, h as b https://en.wikipedia.org/wiki/BACH_motif


moves = [[P,:e4], [P,:e5], [P,:f4], [P,:f4], [B,:c4],
         [Q,:bb4], [K,:f1], [P,:bb5], [B,:bb5], [N,:f6],
         [N,:f3], [Q,:b6], [P,:d3], [N,:b5], [Q,:g5],
         [N,:f5], [P,:c6], [P,:g4], [ N,:f6], [R,:g1],
         [P,:bb5], [P,:b4], [Q,:g6], [P,:b5], [Q,:g5],
         [Q,:f3], [N,:g8], [B,:f4], [Q,:f6], [N,:c3],
         [B,:c5], [N,:d5], [Q,:b2], [B,:d6], [B,:g1],
         [P,:e5], [Q,:a1], [K,:e2], [N,:a6], [N,:g7],
         [K,:d8], [Q,:f6], [N,:f6], [B, :e7]];



define :transpose do |n|
  offset = (n-:c4)/12
  n = n - (12 * offset)
end

  define :melody do | moves, ratio = 0.9 |
    moves.each_with_index do |item, index|
      # restrict melody notes to single octave range...
    p,n = item
    n = transpose(n)
    # ...but if two consecutive notes are repeated, transpose the second
    # note up or down an octave.
    if index > 0
      x = transpose(moves[index-1][1])
      if n == x
        n += [12,0,-12].choose
      end
    end
  play n, sustain: ratio * p, release: (1-ratio) * p, amp: ((2-p)/2)+0.5
  sleep p
end
end

define :chords do | moves ,ratio = 0.9 |
  count = 0
  moves.each do |item|
    p, n = item;
    n = transpose(n)
    # build a V I chord sequence triggered when  total elapsed
    # note duration is a whole number, ie. a whole number of bars.
    if(count % 1 === 0 && count != 0 )
      play chord(n-5, "m7"), release: p, amp: 2
      sleep p/2
      play chord(n-12, "m"), release: 5*p, amp: 1
    end
    count = count + p
    sleep p
  end
end

define :bassline do | moves, ratio = 0.9|
  moves.each_with_index do |item,index|
    p, n = item
    n = transpose(n)
    # create a walking bassline based on a m7 of every fourth
    # note in the sequence, ie. every other move by white.
    r = chord(n-24, :m7).mirror.shuffle
    if index % 4 == 0
      r.each do |n|
        puts n
        # double the bassline synth with an upright bass sample
        sample bass, rpitch: n-36, start: 0.05, finish: 0.2, lpf: 70, amp: 0.5
        play n, amp: 0.5
        sleep 0.25
      end
    end
  end
end

with_fx :reverb do
  in_thread(name: :lead) do
    with_synth :piano do
      melody(moves)
    end
  end

  in_thread(name: :chords) do
    with_synth :piano do
      chords(moves)
    end
  end


  in_thread(name: :bass) do
    wait 0.75
    with_synth :fm do
      with_synth_defaults depth: 0.5, cutoff: 70, sustain: 0.03, release: 0.2, amp: rrand(0.8, 1) do
        bassline(moves)
      end
    end
  end

  in_thread(name: :cymbals) do
    wait 0.75
    (moves.length*2.2).round.times do
      with_swing 0.1, pulse:8 do
        sample :drum_cymbal_soft, sustain: 0.2, release: 0.4, amp: rrand(0.2, 0.4)
        sleep 0.25
      end
    end
  end
end
