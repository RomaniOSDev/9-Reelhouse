#!/usr/bin/env python3
import json
import os

closers = [
    "Name the choice out loud the next time a scene uses it.",
    "Look for the opposite choice in the following scene and compare the feeling.",
    "Sketch a tiny frame in the margin and mark where the choice sits.",
    "Replay ten seconds and point at the exact moment the choice lands.",
    "Ask what would change if the opposite choice replaced this one.",
    "Keep a one-line note so you can find the pattern again tomorrow.",
]

def words(text):
    return len(text.split())

def card(lesson_id, index, title, core, sketch, closer_i):
    body = core.strip()
    if words(body) < 26:
        body = body.rstrip(".") + ". " + closers[closer_i % len(closers)]
    if words(body) < 26:
        body += " Write the idea in your own words before you move on."
    return {"id": f"{lesson_id}-c{index}", "title": title, "body": body, "sketch": sketch}

def lesson(lid, track, title, minutes, term, sketches, cores, quiz):
    cards = []
    for i, (ctitle, core) in enumerate(cores):
        sketch = sketches[i] if i < len(sketches) else None
        cards.append(card(lid, i + 1, ctitle, core, sketch, track * 6 + i))
    questions = []
    for i, (prompt, options, answer, why) in enumerate(quiz):
        questions.append({"id": f"{lid}-q{i+1}", "prompt": prompt, "options": options, "answer": answer, "why": why})
    return {
        "id": lid, "track": track, "title": title, "minutes": minutes, "termId": term,
        "cards": cards, "quiz": questions,
    }

L = []

def add(lid, track, title, minutes, term, sketches, cores, quiz):
    L.append(lesson(lid, track, title, minutes, term, sketches, cores, quiz))

add("see-1", 0, "How Close the Camera Sits", 6, "shot-size", ["scale", "depth"], [
    ("The distance choice", "A shot size is how much of a person and a place you allow inside the frame. An extreme wide shot makes a figure tiny so the world feels larger than the character."),
    ("Wide context", "A wide shot still shows the full room or street, and the person is readable from head to toe. Use it when the location is part of the pressure on the character."),
    ("Full body", "A full shot fits the whole body with a modest margin above the head and below the feet. You can read posture, costume, and the first step of a walk."),
    ("Medium range", "A medium frame usually runs from the head toward the waist or knees. Hands enter the story, and the face is close enough to catch a decision."),
    ("Close and closer", "A close-up fills the frame with a face. An extreme close-up keeps only eyes or a mouth, so a blink can become the whole event."),
    ("Pick with a reason", "Choose the size that matches the information the audience needs in that second. If the room matters, stay wide. If a lie matters, come in close."),
], [
    ("Which framing makes the place feel larger than the person?", ["Close-up", "Extreme wide", "Medium close-up", "Insert of a hand"], 1, "An extreme wide shot shrinks the figure inside a large world."),
    ("A full shot is mainly useful because it shows", ["Only the eyes", "The whole body and posture", "A title card", "The microphone"], 1, "Head-to-toe framing lets posture and costume read clearly."),
    ("When should you move closer?", ["When a small change in the face is the point", "When you want more parking lot", "When the horizon is boring", "When the slate is closed"], 0, "Closer frames trade location for expression and detail."),
])

add("see-2", 0, "The Angle Changes Power", 6, "camera-angle", ["angle", "scale"], [
    ("Eye level", "An eye-level camera meets the person as a peer. It feels neutral, which is useful when you want the audience to judge the moment without being pushed."),
    ("Low angle", "A low angle looks up. The horizon drops, the figure grows, and the person can feel stronger, taller, or more threatening even if the dialogue stays quiet."),
    ("High angle", "A high angle looks down. The horizon rises and the person can feel smaller, watched, or stuck, especially if the floor fills the lower frame."),
    ("Dutch tilt", "A Dutch angle rolls the horizon off level. The place feels uneasy. Use it sparingly, because a tilt with no story reason just looks like a mistake."),
    ("Over the shoulder", "An over-the-shoulder angle puts a nearer shoulder in the foreground and the other person beyond it. The audience sits inside the conversation."),
    ("Match the power", "Ask who holds the moment before you pick the height. Heroes, bullies, and frightened people should not all be photographed from the same polite height."),
], [
    ("A low angle tends to make a person feel", ["Shorter and ignored", "Taller or more forceful", "Out of focus", "Silent"], 1, "Looking up enlarges the figure and drops the horizon."),
    ("A Dutch angle is a tilt of the", ["Horizon", "Microphone", "Credit roll", "Clapper hinge"], 0, "The horizon leaves level, which makes the frame feel unstable."),
    ("Over-the-shoulder framing places the audience", ["Outside the building", "Inside one person's view of another", "Above the roof", "Behind the projector"], 1, "The foreground shoulder puts us in the conversation."),
])

add("see-3", 0, "Thirds, Not a Cage", 6, "rule-of-thirds", ["thirds", "scale"], [
    ("The grid", "Imagine the frame split into thirds, both across and down. The four crossings are calm places to rest an eye, a face, or a horizon."),
    ("Lead room", "If a person looks or walks to the right, leave open space on that side. The empty area is lead room, and it lets the look have somewhere to go."),
    ("Headroom", "Headroom is the space above the hair. Too much and the person sinks. Too little and the frame feels cramped. Match it to how close you are."),
    ("Horizon line", "A horizon on the lower third gives the sky the story. A horizon on the upper third gives the ground the story. The center is calm and formal."),
    ("Break it on purpose", "Center a face when the moment is symmetrical, formal, or trapped. Breaking the thirds works when you can say why, not when you forgot the grid."),
    ("Move, then settle", "During a pan the subject can cross the center. When the camera settles, give the look room again so the frame feels finished rather than caught mid-step."),
], [
    ("Lead room belongs", ["Behind the direction of the look", "In front of the direction of the look", "Only above the head", "Only on the floor"], 1, "Open space in front of a look gives the gaze somewhere to travel."),
    ("A low horizon emphasizes the", ["Sky", "Shoes only", "Credits", "Boom pole"], 0, "Putting the horizon low hands most of the frame to the sky."),
    ("Centering a subject is useful when the moment is", ["Accidental", "Formal or symmetrical", "Always wrong", "Out of focus"], 1, "A centered face can feel deliberate, trapped, or ceremonial."),
])

add("see-4", 0, "Layers Make Space", 5, "depth-layers", ["depth", "scale"], [
    ("Three distances", "A frame with a foreground, a subject, and a background feels deeper than a flat wall. Even a doorframe or a shoulder can be the near layer."),
    ("Foreground as a frame", "A dark doorway, a plant, or a shoulder at the edge tells the eye where to enter. It also hides a little, which makes the reveal feel earned."),
    ("Separation", "If the subject and the wall share the same brightness, they melt together. A rim of light or a shift in focus pulls the person off the background."),
    ("Planes of action", "Let an extra cross the foreground while the main action stays in the middle. The passing shape adds life without stealing the sentence being spoken."),
    ("Depth with lenses", "A longer lens stacks layers so a street looks compressed. A wider lens stretches the gap between a hand in front and a door behind."),
    ("Do not clutter", "Depth is not a pile of objects. One clear near shape, one subject, and one readable background are enough for the eye to travel."),
], [
    ("A simple deep frame usually has", ["Only a flat wall", "Foreground, subject, and background", "Three titles", "No person"], 1, "Three distances give the eye a path into the shot."),
    ("A longer lens tends to make distances look", ["More compressed", "Much wider", "Invisible", "Brighter"], 0, "Telephoto stacking squeezes the space between layers."),
    ("Foreground shapes help when they", ["Cover the whole subject", "Guide the eye and add a near layer", "Replace the story", "Hide the horizon always"], 1, "A partial near shape frames the subject instead of burying it."),
])

add("see-5", 0, "What a Lens Does", 6, "focal-length", ["lens", "depth"], [
    ("Focal length", "Focal length describes how wide or narrow the lens sees. A short lens takes in more of the room. A long lens reaches a smaller slice from farther away."),
    ("Wide feeling", "Wide lenses exaggerate distance. A hand toward the lens looks large, and a hallway seems to stretch. That stretch can feel energetic or unsettling."),
    ("Long feeling", "Long lenses flatten faces gently and pile the background close behind the subject. Crowds, traffic, and hills feel nearer than a walk would suggest."),
    ("Portrait range", "A moderate telephoto is a common portrait choice because the face stays natural and the background softens. You are not stuck with it, but it is a kind default."),
    ("Focus falloff", "Wider lenses keep more of the set sharp. Longer lenses, opened up, throw the background into blur so a face can separate from a busy street."),
    ("Choose the distance too", "The same framing from a different distance is a different picture. Walk closer with a wide lens or step back with a long lens and watch the room change."),
], [
    ("A short focal length sees", ["A narrower slice", "More of the room", "Only titles", "No depth"], 1, "Wide lenses include more of the surroundings."),
    ("Long lenses often make the background feel", ["Farther and emptier", "Closer and more stacked", "Black and white", "Silent"], 1, "Telephoto compression piles distant layers behind the subject."),
    ("To change the feel without changing the crop, you can", ["Only add music", "Change lens and camera distance together", "Erase the horizon", "Close the slate"], 1, "Matching the crop from a new distance changes perspective."),
])

add("see-6", 0, "Moving the Camera", 6, "camera-move", ["move", "scale"], [
    ("Motivation", "Move the camera when the story moves: a look, a walk, a reveal, or a change in attention. A drift with no reason feels like the tripod was bored."),
    ("Pan and tilt", "A pan turns left or right. A tilt tips up or down. Lead the subject a little so they do not bump the edge the moment they start walking."),
    ("Dolly and track", "A dolly rolls the whole camera nearer, farther, or alongside. Unlike a zoom, the perspective changes because the camera actually travels."),
    ("Zoom", "A zoom changes focal length without moving the camera. The world stretches or stacks, but you do not travel through the room. Use it when the decision is optical."),
    ("Handheld", "Handheld movement adds breath and urgency. Keep the horizon mostly level unless the scene is truly chaotic, and give the operator a path so the shake stays intentional."),
    ("Start and stop", "Ease into a move and ease out. A hard start looks like a mistake. Hold a beat at the end so the audience can read the new frame before the cut."),
], [
    ("A dolly differs from a zoom because the camera", ["Changes color", "Physically travels", "Only tilts the horizon", "Records sound"], 1, "Travel changes perspective. A zoom only changes focal length."),
    ("A pan is a turn", ["Left or right", "Only upward", "Of the slate", "Of the credits"], 0, "Pan is the horizontal swivel."),
    ("A move feels finished when you", ["Cut during the fastest shake", "Hold a readable frame at the end", "Hide the subject", "Roll the horizon always"], 1, "A short hold lets the new composition land."),
])

add("light-1", 1, "Key, Fill, and Back", 6, "three-point", ["trio", "soft"], [
    ("Key light", "The key is the main light that explains the shape of a face. Place it off to one side so a cheek, a nose, and an eye socket get different brightness."),
    ("Fill light", "Fill opens the shadow side just enough to keep detail. If fill equals the key, the face goes flat. If fill is absent, the mood gets stark."),
    ("Back light", "A back light, or rim, traces hair and shoulder so the person separates from a dark wall. It is often the difference between a portrait and a silhouette by accident."),
    ("Ratios", "Think of the relationship, not a shopping list of lamps. A strong key and weak fill feels dramatic. A closer match feels open, calm, or documentary."),
    ("One source first", "Start with the key alone and look. Add fill only if the shadow hides a story you still need. Add a rim if the person disappears into the set."),
    ("Eye light", "A small reflection in the eyes keeps a face alive. It can be the key itself. If the eyes go dead, nudge a soft source until a tiny catchlight appears."),
], [
    ("The key light is", ["The main light shaping the face", "Always behind the camera only", "The end credit", "A sound cue"], 0, "The key is the primary modeling light."),
    ("Fill is used to", ["Erase the subject", "Open shadows without flattening them completely", "Replace the lens", "Tilt the horizon"], 1, "Fill controls how much shadow detail remains."),
    ("A rim light helps the subject", ["Separate from the background", "Become darker than the wall", "Lose both eyes", "Hide the nose"], 0, "The edge light traces hair and shoulder against the set."),
])

add("light-2", 1, "Hard Edge or Soft Wrap", 6, "hard-soft", ["soft", "contrast"], [
    ("Hard light", "A small, distant source throws a hard shadow with a crisp edge. Noon sun and a bare bulb are hard. The shadow becomes a graphic shape in the frame."),
    ("Soft light", "A large source relative to the face wraps around cheeks and softens the shadow line. Overcast sky, a big window, or a diffused lamp all behave this way."),
    ("Distance and size", "Moving a soft source closer makes it relatively larger and even softer. Backing it away makes it harder. Size is about the source compared with the subject."),
    ("Shadow story", "Hard light can feel harsh, comic, or dangerous. Soft light can feel intimate, overcast, or kind. Neither is morally better. Match the edge to the scene."),
    ("Mixed edges", "A hard key and a soft fill is a classic mix. The bright side has shape, and the shadow side still holds a gentle detail instead of a black hole."),
    ("Watch the nose", "On a face, the nose shadow tells you the edge quality immediately. If that shadow is a sharp stripe, you are in hard light even if the room looks pretty."),
], [
    ("Hard light is associated with a shadow that is", ["Crisp at the edge", "Always invisible", "Only green", "Behind the lens"], 0, "A small source makes a defined shadow edge."),
    ("A source becomes softer when it is", ["Relatively larger and closer", "A tiny distant point", "Turned off", "Painted red only"], 0, "A larger apparent source wraps the face."),
    ("The nose shadow is a quick test of", ["Edge quality", "Focal length", "Dialogue spelling", "Festival week"], 0, "A sharp nose shadow means the key is hard."),
])

add("light-3", 1, "Warm and Cool", 6, "color-temp", ["temp", "mood"], [
    ("Color temperature", "Warm light leans amber, like a household lamp or sunset. Cool light leans blue, like shade, moonlight in movies, or a north window at noon."),
    ("Contrast of color", "A warm face against a cool window feels richer than a frame where every surface shares one color. The difference guides the eye without a louder performance."),
    ("Motivation", "If the story lamp is tungsten, let the key be warm. If the night outside is the source, let the edge go cool. The audience believes light that has a visible cause."),
    ("Skin", "Faces usually want a color you would still call skin. You can warm them, but a strong green or heavy blue on skin needs a reason or it feels like a mistake."),
    ("Time of day", "Late sun is warm and low. Open shade is cooler. Mixing them in one room, with sun on the table and shade on the wall, sells the hour."),
    ("Grade later, plan now", "You can push color in the finish, but the separation has to be photographed. If everything is the same gray, no grade will invent a window that was never there."),
], [
    ("Household lamps are usually described as", ["Warm", "Pure green", "Invisible", "Silent"], 0, "Tungsten and many practical lamps read amber."),
    ("A warm face against a cool window creates", ["Color separation", "A flat single color", "No direction", "A louder microphone"], 0, "Opposite colors separate subject and setting."),
    ("Skin color usually needs", ["A reason if it leaves a believable range", "Always pure blue", "No light", "A Dutch tilt"], 0, "Odd skin color should be motivated, not accidental."),
])

add("light-4", 1, "Contrast Tells the Hour", 6, "contrast-ratio", ["contrast", "soft"], [
    ("Contrast", "Contrast is the gap between the bright side and the shadow side. A small gap feels open and even. A large gap feels dramatic, late, or secretive."),
    ("High contrast", "Deep shadows and bright edges can suggest night, danger, or a harsh sun. Protect one detail you still need, such as the eyes, so the face does not vanish."),
    ("Low contrast", "When shadows stay readable, the scene can feel like daytime interior, a gentle memory, or a calm conversation. The set remains visible behind the person."),
    ("Ratio in practice", "You do not need a meter to begin. Squint. If the shadow cheek disappears, contrast is high. If both cheeks look similar, contrast is low."),
    ("Background too", "A bright window behind a dark face is also contrast. Expose with a choice: keep the face and let the window bloom, or keep the view and let the face fall."),
    ("Change it in the scene", "Contrast can shift when a character steps from a hallway into a lamp. That change is a story beat, not a continuity error, if you planned the geography."),
], [
    ("High contrast means the bright-to-shadow gap is", ["Large", "Almost zero", "Only about sound", "A credit list"], 0, "A big gap between highlight and shadow is high contrast."),
    ("Squinting helps you judge whether", ["The shadow side disappears", "The script is finished", "The slate is numbered", "The lens is clean only"], 0, "If the shadow cheek vanishes when you squint, contrast is strong."),
    ("A bright window behind a person forces a choice about", ["What you expose for", "Which font to use", "The festival tier", "The diary rating"], 0, "You choose face detail or the view outside."),
])

add("light-5", 1, "Light With a Reason", 6, "motivated-light", ["motiv", "trio"], [
    ("Motivated light", "Motivated light pretends to come from a source the audience can believe: a window, a lamp, a sign, a fireplace, or the open sky."),
    ("The practical", "A practical is a lamp that appears in the frame. It may be too weak to light the face alone, so a hidden source can imitate it from the same direction."),
    ("Direction first", "Before you add brightness, point the light from the story source. A pretty face lit from the wrong side of a visible window feels false even if the exposure is nice."),
    ("Cheating", "You may cheat the source a little toward camera so eyes stay alive. Keep the cheat on the same side as the window or lamp so the logic holds."),
    ("Offscreen sources", "A streetlamp just out of frame can still motivate a rim. Show a hint of it, or a glow on the wall, so the audience knows the light has a home."),
    ("When style breaks logic", "A musical number or a dream can use light that no room would make. Signal that freedom with the rest of the style so it feels chosen."),
], [
    ("Motivated light appears to come from", ["A source the story can believe", "The credit roller", "A random color with no cause", "The diary list"], 0, "Windows, lamps, and sky give light a cause."),
    ("A practical is", ["A lamp seen in the frame", "A type of cut", "A logline", "A rank"], 0, "Practicals are visible fixtures in the set."),
    ("A small cheat toward camera is fair if you", ["Keep it on the source's side", "Light from the opposite wall", "Turn the source off", "Hide both eyes"], 0, "The direction should still agree with the visible source."),
])

add("light-6", 1, "Mood Is a Choice", 6, "lighting-mood", ["mood", "contrast"], [
    ("Mood inventory", "Light can feel safe, lonely, festive, sick, holy, or cheap. Pick one word before you place a lamp, then refuse choices that fight that word."),
    ("Direction and mood", "Light from below can feel eerie because sunlight rarely does that. Light from a high side window can feel like late afternoon even without a clock."),
    ("Color and mood", "Amber pools feel domestic. Cyan edges feel nocturnal or clinical. A single saturated color in a otherwise quiet frame becomes the mood all by itself."),
    ("Contrast and mood", "Open shadows feel honest or daytime. Crushed shadows feel secret, night, or menace. The same dialogue changes temperature when the gap between cheeks changes."),
    ("Movement of light", "A passing headlight, a flickering sign, or a door opening can change mood inside the shot. Let the change happen for a story reason, then settle."),
    ("Consistency", "Once a scene promises a mood, keep it through the coverage. A sudden flat wide shot in a moody close-up scene breaks the spell harder than a small continuity slip."),
], [
    ("A useful first step for mood is to", ["Pick a word and light toward it", "Add every color", "Remove the subject", "Ignore the window"], 0, "One clear mood word steers direction, color, and contrast."),
    ("Light from below often feels odd because", ["Natural sun rarely comes from there", "Lenses forbid it", "Dialogue stops", "The slate breaks"], 0, "Underlighting fights everyday experience, so it feels uncanny."),
    ("Coverage should", ["Keep the scene's mood", "Randomize contrast every setup", "Always go flat", "Hide the key"], 0, "The wide shot and the close-up should belong to the same world."),
])

add("edit-1", 2, "The Cut Is a Thought", 6, "cut", ["cuts", "match"], [
    ("A cut is a join", "A cut replaces one shot with another at a chosen frame. The audience reads the join as a thought: meanwhile, therefore, later, or closer."),
    ("Why cut", "Cut to answer a question the previous shot raised, or to ask a new one. If the new shot adds nothing, the cut feels like a blink for its own sake."),
    ("Shot, reverse, shot", "A simple conversation pattern shows one person, then the other, then back. The rhythm can speed up as the argument tightens."),
    ("Cut on action", "If a hand reaches and the next shot continues the reach, the eye follows the motion and forgives the join. Action is a bridge."),
    ("Hold for the reaction", "Sometimes the better cut stays on the listener. The line is in the sound, and the story is in the face that receives it."),
    ("Do not rescue", "Editing can shape a performance, but it cannot invent an angle you never filmed. Coverage is a promise you make on set for the bench later."),
], [
    ("A cut is best when the new shot", ["Adds a new piece of story information", "Repeats the same frame for no reason", "Hides the only performance", "Removes the sound"], 0, "Each join should change what the audience knows or feels."),
    ("Cutting on action helps because", ["Motion bridges the join", "The slate must clap", "Color disappears", "The lens zooms itself"], 0, "Continuing movement carries the eye across the cut."),
    ("A reaction shot is useful when", ["The listener's face is the story", "You need a title", "The room is empty", "You forgot the line"], 0, "The response can matter more than the speaker's mouth."),
])

add("edit-2", 2, "Continuity Keeps Trust", 6, "continuity", ["match", "cuts"], [
    ("Screen direction", "If a person walks left to right, the next shot should keep that direction unless you show a turn. A sudden flip feels like they changed their mind without a scene."),
    ("Eyelines", "When two people talk, their looks should meet. If both look off to the same side, they seem to be staring past each other into different rooms."),
    ("The line", "Imagine a line through the two people. Keep the camera on one side of it and the left-right relationship stays stable. Cross it only with a moving shot that explains the cross."),
    ("Props and hands", "A glass in the right hand should not jump to the left hand after a cut. Small prop jumps are loud because the audience was watching the gesture."),
    ("Matching action", "Start the next shot a little before the move finishes so you can choose a frame where the hands agree. Overlap is a gift from set to the edit."),
    ("When to break", "A dream, a panic, or a comic double take can break continuity on purpose. The break should feel like style, not like a missed note in an otherwise careful scene."),
], [
    ("Screen direction should stay consistent unless you", ["Show a turn or a motivated crossing", "Change the font", "Cut the sound", "Close the diary"], 0, "An unexplained flip reads as a mistake."),
    ("Eyelines in a conversation should", ["Meet across the cut", "Both aim at the same empty side", "Point at the floor always", "Ignore each other by accident"], 0, "Opposite looks sell that the people see one another."),
    ("The imaginary line helps you keep", ["Left and right relationships", "The musical key", "The reel count", "The rating stars"], 0, "Staying on one side of the line preserves geography."),
])

add("edit-3", 2, "Rhythm You Can Feel", 6, "editing-rhythm", ["rhythm", "pace"], [
    ("Shot length", "Rhythm is the pattern of how long shots last. A string of short shots feels urgent. A long hold feels like waiting, dread, or calm."),
    ("Accent", "Not every cut should be the same length. A sudden short shot after three long ones is an accent, like a drummer leaving a gap and then striking."),
    ("Dialogue rhythm", "People rarely talk in equal bars. Let some lines finish in the shot and some land on the listener. The unevenness feels like speech, not a metronome."),
    ("Breathing room", "After a revelation, a short hold lets the audience feel it. Cutting away instantly can look like you were afraid of the performance."),
    ("Music and cuts", "You may cut with the music or against it. With the beat feels planned and sometimes comic. Against the beat can feel tense or free."),
    ("Watch it mute", "Play the scene without sound. If the picture still has a pulse, the rhythm is really there. If it dies, the music was doing all the work."),
], [
    ("A run of very short shots tends to feel", ["Urgent", "Sleepy by default", "Like a still photo", "Unrelated to pace"], 0, "Frequent cuts raise the sense of speed."),
    ("An accent in editing is", ["A shot length that breaks the pattern", "A lamp color", "A rank name", "A diary mood"], 0, "Changing the established duration makes a beat land."),
    ("Watching a cut mute helps you test", ["Whether the picture has its own pulse", "The microphone brand", "The focal length label", "The export file"], 0, "If rhythm depends only on music, the picture is thin."),
])

add("edit-4", 2, "Montage Compresses Time", 6, "montage", ["montage", "cuts"], [
    ("What a montage is", "A montage is a chain of shots that collapses time. Training, travel, a season of work, or a relationship changing can pass in a minute of fragments."),
    ("Progress", "Each fragment should show a change: a higher stack of papers, a longer run, a colder coat. If every shot repeats the same information, time does not feel like it moved."),
    ("The unifying idea", "Hold the sequence together with one idea, one piece of music, or one repeated gesture. The audience should know what is being compressed."),
    ("Enter and exit", "Start the montage with a clear before, and land on a clear after. The last shot is the result the sequence was building."),
    ("Not a junk drawer", "Montage is not a place to hide shots you like but do not understand. If a shot does not change the state of the story, leave it out."),
    ("Sound across it", "A continuous voice, song, or room tone can glue different days together. A hard silence between fragments makes them feel like separate scenes instead of one passage."),
], [
    ("A montage mainly", ["Compresses time", "Removes all sound", "Replaces the lens", "Locks the vault"], 0, "Fragments stand in for a longer stretch of story time."),
    ("Each fragment should", ["Show a change", "Repeat the identical fact", "Hide the subject", "Reset the streak"], 0, "Progress keeps the sequence moving."),
    ("The end of a montage should land on", ["The result of the passage", "An unrelated title", "The same first frame", "A blank logline"], 0, "The last image is the after that the chain earned."),
])

add("edit-5", 2, "Transitions With a Job", 6, "transition", ["wipe", "cuts"], [
    ("The straight cut", "Most joins should be straight cuts. They are invisible when the idea is clear. Fancy transitions are seasoning, not the meal."),
    ("Dissolve", "A dissolve blends two images and often means time passing, memory, or a soft comparison. A dissolve in the middle of continuous action usually feels sleepy."),
    ("Fade", "A fade to black can end a chapter or a day. A fade in can begin one. If you fade every scene, the film feels like it keeps falling asleep."),
    ("Wipe and iris", "A wipe or an iris is graphic and often playful or old-fashioned. It announces itself. Use it when the story likes that announcement."),
    ("Match as transition", "A match cut joins two shots by a similar shape or motion. It compares ideas: a spinning plate becomes a planet, an eye becomes a tunnel."),
    ("Sound lead", "Sometimes the next scene's sound arrives before the picture. That J-cut or L-cut is a transition too, and it can be smoother than any visual blend."),
], [
    ("The default join should usually be a", ["Straight cut", "Spinning wipe", "Fade every line", "Iris on every face"], 0, "Straight cuts carry most storytelling."),
    ("A dissolve often suggests", ["Time passing or memory", "A broken tripod", "A harder shadow", "A new rank"], 0, "The blend reads as a softer passage of time or thought."),
    ("A match cut joins shots through", ["Similar shape or motion", "Identical file names", "The same diary rating", "A louder key light"], 0, "Visual rhyme links two ideas."),
])

add("edit-6", 2, "Pacing the Scene", 6, "pacing", ["pace", "rhythm"], [
    ("Pace versus rhythm", "Rhythm is the local pattern of cuts. Pace is how fast the scene's information arrives. A scene can have lively rhythm and still take its time with the plot."),
    ("Enter late", "Start the scene as close to the change as you can. Walking in, sitting down, and greeting can often be trimmed if the audience can infer them."),
    ("Leave early", "Once the decision lands, you rarely need the goodbye. The next scene can answer the question. Lingering is a choice, not a duty."),
    ("Rise", "Let the scene tighten. Shorter lines, closer frames, and quicker reactions can build toward the turn. Then give the turn itself enough room to be seen."),
    ("Air pockets", "A pause before a confession lets the audience lean in. Fill every gap and the confession arrives with no weight."),
    ("Scene against scene", "A fast scene after a slow one feels faster. Pace is relative. Build the film as a sequence of breaths, not as one speed from the first frame to the last."),
], [
    ("Entering a scene late means you", ["Begin near the change", "Show every footstep always", "Start on the credits", "Remove the decision"], 0, "Skip the approach when the audience can infer it."),
    ("A pause before an important line", ["Gives the moment weight", "Always ruins rhythm", "Is a lighting error", "Ends the festival"], 0, "Air lets the audience anticipate."),
    ("Pace is felt relative to", ["The scenes around it", "Only the lens chart", "The export name", "A single cut in isolation always"], 0, "Contrast with neighboring scenes changes the feeling of speed."),
])

add("sound-1", 3, "Inside the Story or Outside", 6, "diegetic-sound", ["diegetic", "talk"], [
    ("Diegetic", "Diegetic sound belongs to the world of the story. Footsteps, a radio in the kitchen, and dialogue the characters can hear are all inside that world."),
    ("Non-diegetic", "A musical score the characters do not hear, or a narrator they cannot answer, sits outside the story world. The audience receives it as commentary."),
    ("The border", "A song can start on a radio, which is diegetic, and then swell into a score, which is not. The handoff is a style choice if the moment of change is clear."),
    ("Who hears it", "Ask who in the scene can hear the sound. If only the audience hears the low drone, it is a mood tool, not a truck outside."),
    ("Point of hearing", "You can shift toward one character's ears: muffle the room, raise a tinnitus ring, duck the party. The mix becomes subjective without a visual effect."),
    ("Do not explain twice", "If the picture already shows the door slam, the sound should confirm it, not fight it. If you want surprise, let the sound arrive a fraction early or late on purpose."),
], [
    ("Diegetic sound is heard", ["Inside the story world", "Only by the editor", "Never by anyone", "Only in the credits"], 0, "Characters could, in principle, hear diegetic sound."),
    ("A traditional score is usually", ["Non-diegetic", "A practical lamp", "A prop continuity note", "A shot size"], 0, "Characters typically do not hear the score."),
    ("Subjective hearing means the mix", ["Follows one character's ears", "Removes all levels", "Always uses silence", "Ignores the picture"], 0, "Muffling or ringing can put us inside a head."),
])

add("sound-2", 3, "Footsteps and Cloth", 6, "foley", ["foley", "mix"], [
    ("What foley is", "Foley is performed sound for movement: steps, cloth, a cup set down, a key turned. It is recorded to picture so the gesture has a body."),
    ("Why production sound is not enough", "Dialogue microphones are aimed at mouths, not shoes. The steps may be thin or full of other noise. Foley restores the gesture cleanly."),
    ("Surface", "Wood, gravel, carpet, and wet stone should not share one generic thud. The surface tells the audience where the person is even in a tight close-up."),
    ("Cloth", "A jacket shift when arms fold sells the costume. Too much cloth rustle fights the words. The art is choosing the gestures that matter."),
    ("Sync", "A step that lands a few frames late feels like a ghost. Line the impact up with the picture, then adjust level so it sits under the voice."),
    ("Taste", "Not every tiny move needs a sound. Add the ones that carry story: the nervous glass, the careful step, the angry door. Leave the rest quiet."),
], [
    ("Foley is mainly", ["Performed movement sound matched to picture", "The musical theme", "A type of wide shot", "A diary mood"], 0, "Artists perform steps and object handling to the image."),
    ("Shoe surfaces matter because they tell us", ["Where the person is walking", "The focal length", "The rank", "The logline genre"], 0, "Gravel and carpet describe the place."),
    ("A late footstep feels wrong because", ["Sync with the picture is off", "Warm light is illegal", "The thirds grid moved", "The festival ended"], 0, "The impact should meet the visible step."),
])

add("sound-3", 3, "When Silence Hits", 6, "silence", ["silence", "mix"], [
    ("Silence is a sound", "A sudden drop in ambience is as loud as a bang. The audience leans in because the room they trusted just disappeared."),
    ("Room tone", "True digital zero can feel like a technical hole. A very low room tone under a quiet scene keeps the space alive without crowding the words."),
    ("Before the hit", "Pull sound down just before a revelation or a scare. The contrast makes the next noise, or the continued quiet, feel larger."),
    ("Subjective silence", "After a blast, a ringing hush can put us in a character's ears. Bring the world back slowly as they recover."),
    ("Do not fear the pause", "A line that sits in quiet has edges. Filling every gap with music tells the audience what to feel and removes their work."),
    ("Endings", "Ending a scene on a held quiet can be stronger than a musical button. Let the last look finish before the next ambience arrives."),
], [
    ("A sudden silence works because of", ["Contrast with the sound before it", "A brighter key light only", "More close-ups automatically", "A longer lens"], 0, "The drop is felt against what came before."),
    ("A little room tone under quiet scenes", ["Keeps the space from feeling like a dead hole", "Is always a mistake", "Replaces dialogue", "Changes shot size"], 0, "Low ambience maintains the room."),
    ("Subjective silence can follow", ["A loud blast in the character's ears", "A correct quiz only", "A poster unlock", "A wide establishing shot always"], 0, "Ringing hush places us inside the impact."),
])

add("sound-4", 3, "Dialogue You Can Follow", 6, "dialogue-edit", ["talk", "mix"], [
    ("Clarity first", "If the audience cannot parse the words, the performance does not exist for them. Clarity is the first job, style comes after the sentence is understood."),
    ("Breath and pace", "Keep the breaths that show thought. Remove the ones that are only noise between clean words. The edit of air is part of the performance."),
    ("Overlaps", "People interrupt. A little overlap feels alive. Too much and both lines die. Choose whose words must win and duck the other gently."),
    ("Alternate takes", "You can build one reading from several takes if the room and the eyeline agree. A sudden change in distance or accent will show the seam."),
    ("ADR with care", "Replacing a line later can save a noisy take. Match the energy and the distance. A booth voice in a shouty street scene sounds like a different room because it is."),
    ("Offscreen lines", "A line from someone just outside the frame can carry a scene, but the picture still needs a place for us to look, usually the listener."),
], [
    ("The first job of dialogue editing is", ["Clarity of the words", "Maximum rustle", "Removing every breath always", "Adding a wipe"], 0, "If the line cannot be understood, nothing else matters."),
    ("Overlapping speech should be", ["Controlled so the important words survive", "Always total", "Forbidden", "Only musical"], 0, "A little overlap feels human. Too much hides both lines."),
    ("ADR fails when the new line", ["Sounds like a different room and energy", "Matches distance and effort", "Fits the mouth", "Keeps the accent"], 0, "Booth recordings must agree with the photographed space."),
])

add("sound-5", 3, "Where Music Enters", 6, "music-cue", ["score", "silence"], [
    ("Cue the change", "Music is powerful when it marks a change: a decision, a memory, a turn into danger. If it plays under everything, it marks nothing."),
    ("Enter quietly", "Bring a cue in under a breath or a look, not always on the cut. An entrance that is felt a second later can seem like the character's realization."),
    ("Leave room for words", "Score and dialogue occupy the same attention. Thin the music, or choose a register that does not sit on the voice, when the line carries the plot."),
    ("Source versus score", "A song from a car radio can be diegetic and still emotional. Know whether the character chose it. That choice is character, not just soundtrack."),
    ("Against the picture", "Cheerful music over a cruel image, used honestly, can be chilling or comic. The contrast is the point. Do not do it by accident."),
    ("Outro", "End the cue when the idea ends. A tail that drags into the next scene glues two ideas you may have wanted separate. Silence can be the cut."),
], [
    ("Music communicates most clearly when it", ["Marks a change", "Plays at one level for the entire film with no shape", "Replaces all footsteps", "Covers every line"], 0, "A cue should have a reason to begin."),
    ("Under dialogue, music often needs to", ["Sit out of the way of the voice", "Be louder than the words", "Stop the picture", "Change the lens"], 0, "The line has to remain understandable."),
    ("A song the character chose on a radio is", ["Part of their character", "Always non-diegetic", "A lighting ratio", "A shot list"], 0, "Source music can express taste and mood from inside the story."),
])

add("sound-6", 3, "The Mix Is a Picture", 6, "sound-mix", ["mix", "diegetic"], [
    ("Hierarchy", "The mix decides what the audience hears first. Usually the voice leads, then story effects, then ambience and music. The order can change when the story asks."),
    ("Depth", "Closer sounds are drier and more present. Farther sounds have more space around them. A shout from down the hall should not feel like a whisper in the ear."),
    ("Perspective cuts", "When you cut from a wide shot to a close-up, the voice can come slightly nearer. A huge jump in tone between angles feels like two different recordings."),
    ("Panning", "A little pan can follow a car or a person crossing. Hard left-right pans on ordinary dialogue become tiring and fight the center image."),
    ("Dynamic range", "Whispers and shouts need a path between them. If everything is equally loud, nothing can rise. Leave headroom so a slam can actually slam."),
    ("Check small speakers", "Play the mix on a laptop or a phone speaker as well as good headphones. If the words vanish, the mix only worked in the room where you made it."),
], [
    ("In a typical dialogue scene the first priority is", ["The voice", "The loudest footstep", "The deepest rumble", "The end crawl"], 0, "Words usually lead the hierarchy."),
    ("Farther sounds should feel", ["More spacious and less present", "Drier than a close whisper", "Always centered and huge", "Like a studio booth"], 0, "Distance adds space and reduces intimacy."),
    ("Checking on a small speaker reveals whether", ["Speech still survives", "The lens was wide", "The thirds were kept", "The rank changed"], 0, "A mix that only works on big speakers will fail many viewers."),
])

add("page-1", 4, "Shape of a Story", 6, "story-structure", ["beats", "desire"], [
    ("A shape, not a cage", "Structure is the order of pressure. Someone wants something, an obstacle answers, and the situation changes. The labels you use matter less than the change."),
    ("Beginning", "The opening shows the world and the want, or the lack of one. By the time the first turn arrives, we should know who we are following and why today is not ordinary."),
    ("Middle", "The middle tests the want. Plans fail, alliances shift, and the person learns the real size of the problem. If nothing is harder at the halfway point, the story is idling."),
    ("End", "The end forces a choice that costs something. A victory with no cost, or a loss with no meaning, both feel like the film stopped rather than concluded."),
    ("Scenes are mini stories", "Each scene can have a small want and a small result. The result should make the next scene necessary. String those results and you have a plot."),
    ("Outline in sentences", "Write the film as a chain of therefore and but, not and then. Therefore means consequence. But means reversal. And then is just a list."),
], [
    ("A useful story change requires", ["A want and an obstacle", "Only a location", "A favorite lens", "A silent credit"], 0, "Pressure comes from desire meeting resistance."),
    ("The middle should generally make the problem", ["Larger or clearer", "Disappear without a choice", "Unrelated", "Only prettier"], 0, "Tests escalate or reveal the real conflict."),
    ("Therefore and but are stronger than and then because they show", ["Consequence and reversal", "Camera serial numbers", "Mood chips", "Poster captions"], 0, "Causal links beat a loose list of events."),
])

add("page-2", 4, "What the Person Wants", 6, "character-desire", ["desire", "goal"], [
    ("Want versus need", "The want is what the person thinks will fix life. The need is what would actually change them. Stories get interesting when those two are not the same."),
    ("Visible want", "A want you can photograph is stronger than a mood. Get the key, leave the town, win the apology, keep the secret. The audience can track a concrete aim."),
    ("Opposition", "Someone or something should want the opposite, or want the same thing exclusively. Without opposition, the want is a walk, not a story."),
    ("Stakes", "Ask what happens if they fail today, not only at the end of the movie. Immediate stakes keep a scene from becoming a chat about a future problem."),
    ("Change the want", "People can want a new thing after they learn. The change should come from an event, not from the writer getting bored of the old goal."),
    ("Ensemble", "If several people want things, give each want a collision with the others. Parallel hobbies that never meet are two films sharing a poster."),
], [
    ("A photographable want is useful because the audience can", ["Track whether it is closer or farther", "Ignore the person", "Skip the middle", "Replace dialogue with music always"], 0, "Concrete aims show progress and failure."),
    ("Opposition turns a wish into", ["A story", "A lens chart", "A room tone", "A rank perk"], 0, "Resistance creates drama."),
    ("Scene stakes should be", ["Immediate enough to matter now", "Only about the final minute", "Hidden from everyone", "A list of equipment"], 0, "Today's risk keeps the scene alive."),
])

add("page-3", 4, "A Scene Needs a Goal", 6, "scene-goal", ["goal", "beats"], [
    ("One job", "Before you write a scene, say what must be different at the end. If you cannot, the scene may be a corridor between real scenes."),
    ("Enter with a tactic", "The person should try something: persuade, sneak, confess, stall, accuse. The tactic can fail. Watching a tactic is more alive than watching a topic."),
    ("Turn", "Somewhere the balance shifts. New information, a refusal, a kiss, a threat. After the turn, the next action cannot be the same as the first one."),
    ("Subtext welcome", "The goal can hide under small talk. Two people discussing coffee can really be negotiating a breakup, if the tactics and the turn are there."),
    ("Cut the throat clearing", "Greetings, repeated plans, and reminders of facts the audience knows are often the first lines to lose. Start at the tactic."),
    ("Exit on the new problem", "End when the goal is won, lost, or changed. The last line or look should make us need the following scene."),
], [
    ("A scene without a change at the end is often", ["A corridor, not a scene", "The best climax", "A perfect montage", "A required fade"], 0, "Scenes exist to alter the situation."),
    ("A tactic is", ["What the person tries in order to get the goal", "The color of the key light", "The export format", "The shot size list"], 0, "We watch an attempt, not only a subject."),
    ("Ending on a new problem helps because", ["The next scene becomes necessary", "The film can stop", "Continuity no longer matters", "Music must be loud"], 0, "A fresh imbalance pulls us forward."),
])

add("page-4", 4, "The Line Under the Line", 6, "subtext", ["subtext", "lines"], [
    ("Subtext", "Subtext is the meaning under the spoken words. People say they are fine while asking to be followed. The audience hears both layers when the picture helps."),
    ("Do not write the theme out loud", "If a character explains the moral in a speech, the scene may be doing the audience's work. Let behavior carry the idea and keep the speech for pressure."),
    ("Objects", "A character who keeps folding a letter is talking about the letter even if the dialogue is about dinner. The prop is a second sentence."),
    ("Contradiction", "The richest lines disagree with the face or the action. A smile while locking a door says more than a paragraph about trust."),
    ("Status", "Who sits, who stands, who pours the drink: status is subtext you can block. The words can pretend to be equal while the bodies are not."),
    ("Trust the audience", "You do not need to cut to a flashback every time a line has a hidden meaning. If the situation is clear, the audience will do the math."),
], [
    ("Subtext is", ["Meaning under the spoken words", "A second microphone", "A type of wipe", "The festival goal"], 0, "The spoken line and the real intent can differ."),
    ("A prop can act as subtext when", ["The handling says what the dialogue avoids", "It is out of focus by mistake", "It matches the slate color", "It is never seen"], 0, "Behavior with an object can be the real line."),
    ("Status can be shown by", ["Who sits, stands, or controls the room", "Only the logline", "The export file", "A random pan"], 0, "Blocking reveals power even when the words sound polite."),
])

add("page-5", 4, "Talk That Sounds Alive", 6, "dialogue", ["lines", "talk"], [
    ("People do not write essays", "Spoken lines are shorter, more repetitive, and more evasive than prose. Read the scene aloud. Anywhere you run out of breath, the line is still written, not spoken."),
    ("Distinct mouths", "A formal person and a blunt person should not share the same sentence shape. Vocabulary, rhythm, and what they refuse to say are character."),
    ("On the nose", "On-the-nose dialogue says the emotion and the plot directly. Sometimes a crisis needs that clarity. Most of the time, aim beside the target and let behavior finish the thought."),
    ("Questions", "A scene of mutual interviewing can feel like a form. Mix questions with attempts, jokes, and refusals so the talk has tactics."),
    ("Silence in the script", "Write the pause. A beat where someone does not answer is dialogue. Do not fill it just because the page looks empty."),
    ("Last line", "The last line of a scene should turn the screw or release it. A trailing pleasantry often means you have not found the end yet."),
], [
    ("A practical test for spoken dialogue is to", ["Read it aloud", "Count the lamps", "Match the focal length", "Hide the verbs"], 0, "Breath and rhythm reveal written lines."),
    ("On-the-nose dialogue", ["States emotion and plot too directly", "Is always required", "Is a lighting term", "Is a type of foley"], 0, "It says the subtext out loud."),
    ("A written pause is", ["Dialogue", "A mistake by definition", "A wipe", "A rank perk"], 0, "Not answering is still a dramatic action."),
])

add("page-6", 4, "One Sentence Story", 7, "logline", ["logline", "desire"], [
    ("The job of a logline", "A logline is one or two sentences that hold a protagonist, a goal, an obstacle, and the stakes. It is a compass, not a trailer full of twists."),
    ("Protagonist", "Name the kind of person, not a list of traits. A cautious archivist is more useful than someone who is nice, smart, and brave."),
    ("Goal and obstacle", "The goal should be active. The obstacle should be strong enough that success is uncertain. If the obstacle is only bad luck for one minute, the story is thin."),
    ("Stakes", "Stakes say what is lost if the goal fails. Keep them concrete: the building, the alibi, the last chance to speak. Vague sadness is harder to film."),
    ("No ending spoiler", "The logline should open the question, not answer it. If your sentence includes the final choice, you wrote a summary of the last act."),
    ("Length", "Aim for roughly twenty-five to forty words. If it is longer, you are probably telling scenes. If it is shorter, you may be missing the obstacle or the cost."),
], [
    ("A logline should include", ["Protagonist, goal, obstacle, and stakes", "The entire ending", "Only the setting", "A list of lenses"], 0, "Those four parts aim the story."),
    ("The ending should usually stay", ["Out of the logline", "In the first five words", "As a spoiler on purpose", "Replaced by a mood chip"], 0, "The sentence should open a question."),
    ("A useful length is about", ["25 to 40 words", "Two hundred words", "Three words", "A full scene"], 0, "Enough for the four parts, not a treatment."),
])

add("dir-1", 5, "Where Bodies Stand", 6, "blocking", ["block", "cover"], [
    ("Blocking", "Blocking is the planned path of bodies in the space. It decides who is near, who is trapped, and when a crossing changes the power."),
    ("Geography first", "Know the doors, the table, and the window before you invent poses. People move because the room offers choices, not because the page says they cross."),
    ("Triangles", "Three people in a triangle keep everyone visible and give you a strong and a weak position. A straight line of faces is harder to cover and flatter to watch."),
    ("Approach and retreat", "Stepping closer is pressure. Stepping back is refusal or fear. Let the distance change when the tactic changes, not on a random line."),
    ("Business", "Give hands a job: pouring, folding, fixing a latch. Business reveals nerves and also gives the editor matches. Empty hands often look like waiting for the next line."),
    ("Marks with mercy", "Marks help the camera, but actors need a reason to land on them. Tie the stop to a look, a touch, or an object so the movement feels caused."),
], [
    ("Blocking is the plan for", ["How people move through the space", "Only the musical score", "The export settings", "The diary filter"], 0, "Paths and positions are the blocking."),
    ("A triangle of three people helps", ["Visibility and power differences", "Hide all faces", "Remove eyelines", "Flatten the room"], 0, "The shape keeps faces readable and status clear."),
    ("Crossing closer usually reads as", ["Pressure", "A lens change", "A fade out", "Lower contrast only"], 0, "Distance is emotional as well as physical."),
])

add("dir-2", 5, "Covering a Scene", 6, "coverage", ["cover", "cuts"], [
    ("What coverage is", "Coverage is the set of angles that will let the scene be cut. A master, singles, and a detail are a common kit. Shoot what the story needs, not every side of the room."),
    ("The master", "The master shows the geography and the full action. Even if you think you will live in close-ups, the master saves you when the close-ups do not cut."),
    ("Singles", "A single is one person. Matching lens and eyeline across singles keeps the conversation in one world. Wild changes in size make the edit hiccup."),
    ("Inserts", "Shoot the hand, the key, the phone, while the light still matches. Inserts are cheap on set and expensive to fake later."),
    ("Safety and risk", "Get a safe version that tells the story, then a braver version. If the day collapses, the safe version still makes a scene."),
    ("Shot list as a servant", "The list is a plan, not a vow. If a performance offers a better angle, change the list and protect the angles you still need for geography."),
], [
    ("A master is useful because it", ["Shows geography and full action", "Replaces all close-ups always", "Records only music", "Is a type of foley"], 0, "The wide view protects the cut."),
    ("An insert should be filmed", ["While the light still matches", "Next month in a new room", "Without looking at the prop", "Only as a painting"], 0, "Matching light keeps the detail in the same world."),
    ("A safe take plus a braver take means", ["You can still cut the scene if the risk fails", "You skip the master", "You erase dialogue", "You avoid marks"], 0, "Safety protects the story. The risk explores it."),
])

add("dir-3", 5, "Rehearsal Finds the Scene", 6, "rehearsal", ["rehearse", "block"], [
    ("Why rehearse", "Rehearsal is where the scene stops being words and becomes behavior. You learn which lines are false and which crosses are only traffic."),
    ("Table then floor", "Talk the intentions first, then stand up. Intentions without movement stay abstract. Movement without intentions becomes marching."),
    ("Ask questions", "Ask what the person wants in the next ten seconds, not how to feel a general emotion. Specific wants produce specific actions."),
    ("Trim in the room", "If a line dies in the air, cut it in rehearsal while everyone can agree. Protecting a dead line until the edit wastes the day."),
    ("Camera in the loop", "Once blocking works, walk the camera path. A beautiful cross that cannot be seen is not yet a shot. Adjust the path or the lens together."),
    ("Leave a little unknown", "Over-rehearsing can polish the life out of a take. Stop when the shape is clear and one or two discoveries are still possible on camera."),
], [
    ("Rehearsal turns the page into", ["Behavior in space", "A finished mix", "A color grade", "A poster"], 0, "You test movement and intention before rolling."),
    ("A useful question is about", ["The want in the next moment", "A vague lifelong mood only", "The file format", "The festival tier"], 0, "Immediate wants create playable actions."),
    ("Stop rehearsing when", ["The shape is clear but a little life remains", "Every accident is forbidden", "The words are memorized and the bodies are frozen", "The slate is painted"], 0, "Leave room for a discovery on the take."),
])

add("dir-4", 5, "Tone Is a Promise", 6, "tone", ["tone", "mood"], [
    ("Tone", "Tone is the attitude of the telling: comic, grave, tender, bleak, playful. It is a promise about how the audience should hold the events."),
    ("Agreement", "Performance, lens, light, and cutting all vote. If the acting is broad and the cutting is funeral-slow, the votes disagree and the scene feels confused."),
    ("Set the range early", "The opening scenes teach the audience how big the jokes and the dangers are. A sudden different size later can work as a turn, but not as an accident."),
    ("Contrast inside the promise", "A grim story can have a kind joke if the joke belongs to a character. The joke should not wink at the audience and cancel the stakes."),
    ("Talk in plain words", "On set, replace tone adjectives with actions. Instead of be more intense, ask for a quieter voice and a step closer. People can play actions."),
    ("Protect the turn", "If the tone shifts, mark the moment: a look, a silence, a change of light. An unmarked shift feels like a different movie wandered in."),
], [
    ("Tone is", ["The attitude of how the story is told", "The brand of the tripod", "A shot size", "A file extension"], 0, "It is the stance the film takes toward events."),
    ("Departments should", ["Agree on the size of the feeling", "Each invent a new tone", "Ignore performance", "Avoid rehearsal"], 0, "Picture and performance vote together."),
    ("Direction is clearer when you ask for", ["A physical action", "A vague intensity", "A different genre every line", "Silence from the whole crew forever"], 0, "Playable verbs beat abstract moods."),
])

add("dir-5", 5, "The Shot List", 6, "shot-list", ["list", "cover"], [
    ("A list is a map", "A shot list is the order of setups you intend to shoot, with the size and the purpose of each. It is how the day stays tied to the scene."),
    ("Purpose column", "Next to each shot, write why it exists: geography, reaction, insert, reveal. If you cannot write the why, you may not need the setup."),
    ("Order for light and energy", "Group setups that share a lighting state. Also consider performance energy. Sometimes you shoot the calm coverage before the shouting, so voices survive."),
    ("Time truth", "Estimate honestly. A company move across the room is not free. A list that needs fourteen hours in a ten-hour day is a wish, not a plan."),
    ("Must, should, could", "Mark the shots the scene dies without, the shots that make it good, and the shots that are gifts. When time slips, the gifts go first."),
    ("Rewrite at lunch", "If the morning changed the scene, rewrite the afternoon list. Clinging to a dead plan produces coverage for a film you are no longer making."),
], [
    ("Each shot on the list should have", ["A purpose", "Only a pretty adjective", "No relation to the scene", "A secret ending"], 0, "Purpose keeps the day tied to the cut."),
    ("When time runs short, drop", ["The gift shots first", "The geography the scene needs", "All sound", "The master always"], 0, "Must-have shots protect the story."),
    ("Grouping setups by light", ["Saves time and keeps the look consistent", "Is forbidden", "Removes blocking", "Ends rehearsal"], 0, "Fewer relights mean more takes."),
])

add("dir-6", 5, "Talking on Set", 6, "set-communication", ["comms", "rehearse"], [
    ("One voice", "People need to know who can say action and who can stop the take. Multiple overlapping bosses create polite chaos and missed notes."),
    ("Short notes", "Give one or two notes between takes, aimed at a person, tied to a moment. A speech about the whole film makes the next take worse, not better."),
    ("Heads of department", "Talk to the camera, light, and sound leads before you change the plan. A surprise move wastes their work and the trust you need at the next surprise."),
    ("Quiet near the frame", "The energy beside the lens leaks into the performance. If the set is chatty, the scene gets chatty. Call for quiet as a tool, not a scolding."),
    ("Credit the crew", "When a suggestion saves the shot, say so. People protect a director who shares the win, and they hide problems from one who only blames."),
    ("Decide", "Gather the useful facts, then choose. Endless maybe is expensive. A clear choice, even a reversible one, lets the company move."),
], [
    ("Notes between takes work best when they are", ["Few and tied to a moment", "A speech about the whole career", "Shouted by everyone", "Saved for the credits"], 0, "Specific, short notes can be played on the next take."),
    ("Changing the plan without telling department leads", ["Wastes work and trust", "Always speeds the day", "Improves focus", "Is required by continuity"], 0, "Surprises in craft departments cost time."),
    ("A clear decision helps because", ["The company can move", "Nobody needs a shot list", "Tone no longer matters", "Sound can be skipped"], 0, "Action beats endless hesitation."),
])

tracks = [
    {"id": 0, "title": "Seeing the Frame", "blurb": "Sizes, angles, thirds, depth, lenses, and how the camera travels."},
    {"id": 1, "title": "Painting with Light", "blurb": "Key and fill, hard and soft edges, color, contrast, cause, and mood."},
    {"id": 2, "title": "The Invisible Art", "blurb": "Cuts, continuity, rhythm, montage, transitions, and the pace of a scene."},
    {"id": 3, "title": "Sound and Score", "blurb": "Story sound, foley, silence, dialogue, music cues, and the mix."},
    {"id": 4, "title": "Story on the Page", "blurb": "Shape, desire, scene goals, subtext, spoken lines, and loglines."},
    {"id": 5, "title": "Directing Actors and Scenes", "blurb": "Blocking, coverage, rehearsal, tone, lists, and clear talk on set."},
]

terms = [
    ("shot-size", "Shot Size", "Shot size is how much of the person and the place the frame includes. It runs from an extreme wide view, where a figure is small in a large world, to an extreme close-up of eyes or mouth. The size decides what information the audience can use.", "If the place is the pressure, stay wider. If a lie or a blink is the pressure, come closer.", "Pass the lesson on distance and framing."),
    ("camera-angle", "Camera Angle", "Camera angle is the height and tilt from which we see the subject. Eye level feels even. A low angle looks up and can enlarge power. A high angle looks down and can shrink it.", "Pick the height after you decide who holds the moment.", "Pass the lesson on angle and power."),
    ("rule-of-thirds", "Rule of Thirds", "The rule of thirds divides the frame into a grid and parks important shapes near the crossings. Lead room is the open space in front of a look or a walk. Headroom is the air above the hair.", "Settle on the grid when the move ends, and break it when symmetry is the point.", "Pass the lesson on thirds and lead room."),
    ("depth-layers", "Depth Layers", "Depth layers are the foreground, the subject, and the background working together. A near shape such as a shoulder or doorway gives the eye a way in. Separation in light or focus keeps the person from melting into the wall.", "One clear shape at each distance is enough. Clutter is not the same as depth.", "Pass the lesson on layers and space."),
    ("focal-length", "Focal Length", "Focal length describes how wide or narrow a lens sees. Short lenses take in more room and stretch distance. Long lenses isolate a slice and stack the background closer to the subject.", "The same crop from a different distance is a different picture. Change lens and position together.", "Pass the lesson on lenses."),
    ("camera-move", "Camera Move", "A camera move travels or turns to follow attention. A pan swivels, a tilt tips, a dolly actually rolls, and a zoom only changes the lens. The move should begin for a story reason and end on a frame you could hold.", "Ease in and ease out. A hard start looks like an accident.", "Pass the lesson on moving the camera."),
    ("three-point", "Three-Point Light", "Three-point light is a working trio: key for shape, fill for shadow detail, and back light for a rim that separates the body from the set. The relationship between them matters more than the number of lamps.", "Start with the key alone. Add fill or rim only when the picture asks.", "Pass the lesson on key, fill, and back."),
    ("hard-soft", "Hard and Soft Light", "Hard light comes from a small source and throws a crisp shadow. Soft light comes from a large source relative to the face and wraps the features. Moving a soft source closer makes it softer still.", "Read the nose shadow. A sharp stripe means the key is hard.", "Pass the lesson on hard and soft edges."),
    ("color-temp", "Color Temperature", "Color temperature is the warm or cool cast of a source. Lamps and sunset lean amber. Shade and many night windows lean blue. A warm face against a cool background separates without shouting.", "Let the visible source motivate the color, and keep skin in a range you still believe.", "Pass the lesson on warm and cool light."),
    ("contrast-ratio", "Contrast Ratio", "Contrast is the gap between bright and shadow. A small gap feels open. A large gap feels dramatic or secret. You can judge a face by squinting: if the shadow cheek vanishes, the gap is high.", "Decide whether the eyes must survive the darkness before you crush the shadow.", "Pass the lesson on contrast."),
    ("motivated-light", "Motivated Light", "Motivated light pretends to come from a cause in the story, such as a window, a lamp, or the sky. A practical is a lamp the camera can see. A hidden source may imitate it from the same side.", "You can cheat a little toward the lens, but stay on the source's side of the face.", "Pass the lesson on cause and practicals."),
    ("lighting-mood", "Lighting Mood", "Lighting mood is the emotional word the light is aiming at: safe, lonely, harsh, tender, clinical. Direction, color, and contrast all vote. Coverage should keep that vote from setup to setup.", "Replace vague mood talk with a direction, a color, and a contrast you can set.", "Pass the lesson on mood."),
    ("cut", "Cut", "A cut joins two shots at a chosen frame and reads as a thought: closer, later, meanwhile, or therefore. The best cuts answer a question or follow an action. A cut that adds nothing feels like a blink.", "Cut on motion when you can, and stay on a reaction when the listener holds the story.", "Pass the lesson on cuts."),
    ("continuity", "Continuity", "Continuity keeps trust in space and time. Screen direction, eyelines, and props should agree across a cut unless you show a turn. The imaginary line between people helps their left and right stay stable.", "Break continuity only when the style announces the break, as in a dream or a panic.", "Pass the lesson on continuity."),
    ("editing-rhythm", "Editing Rhythm", "Editing rhythm is the pattern of shot lengths. Short shots hurry. Long holds wait. An accent is a length that breaks the pattern so a beat can land. Music can ride that pattern or push against it.", "Watch the scene without sound. If the pulse disappears, the picture was not carrying it.", "Pass the lesson on rhythm."),
    ("montage", "Montage", "A montage compresses a stretch of time into a chain of fragments. Each fragment should show change, and the sequence should land on a clear after. One song, voice, or repeated gesture can glue the days together.", "Do not hide leftover shots in a montage. If a shot does not change the state, cut it.", "Pass the lesson on montage."),
    ("transition", "Transition", "A transition is how one shot or scene hands off to the next. Straight cuts do most of the work. Dissolves and fades suggest time or chapters. A match cut compares two shapes. Sound can lead the picture across the join.", "Use a fancy transition only when you want it to be noticed.", "Pass the lesson on transitions."),
    ("pacing", "Pacing", "Pacing is how quickly story information arrives. Enter scenes late, leave when the decision has landed, and let a pause give weight. Pace is relative: a fast scene feels faster after a slow one.", "Build the film as a series of breaths, not one speed from start to finish.", "Pass the lesson on pacing."),
    ("diegetic-sound", "Diegetic Sound", "Diegetic sound belongs to the story world, such as footsteps or a radio the characters could hear. Non-diegetic sound, such as a traditional score, is for the audience alone. A song can cross that border if the handoff is clear.", "Ask who in the scene can hear it. That answer sorts the layer.", "Pass the lesson on story sound and score."),
    ("foley", "Foley", "Foley is movement sound performed to picture: steps, cloth, and object handling. Dialogue microphones often miss those details. The surface under a shoe tells us where we are, and sync must meet the visible impact.", "Add the gestures that carry story and leave the rest quiet.", "Pass the lesson on foley."),
    ("silence", "Silence", "Silence in a mix is a deliberate drop, usually against sound that came before. A little room tone keeps a quiet scene from feeling like a dead technical hole. Subjective silence, such as ringing after a blast, puts us in a character's ears.", "Pull level down before a revelation if you want the next moment to feel larger.", "Pass the lesson on silence."),
    ("dialogue-edit", "Dialogue Edit", "Dialogue editing makes words understandable and keeps the breaths that show thought. Small overlaps feel alive. Replacement lines must match the energy and the room or they will sound like a different place.", "Clarity comes first. Style that hides the sentence has not finished the job.", "Pass the lesson on dialogue editing."),
    ("music-cue", "Music Cue", "A music cue marks a change: a decision, a memory, a turn. It should enter with a reason, leave room for words, and end when the idea ends. A song a character chooses is also character, not only decoration.", "If the cue plays under everything, it stops meaning anything.", "Pass the lesson on music cues."),
    ("sound-mix", "Sound Mix", "The mix sets hierarchy, distance, and loudness. Voices usually lead, close sounds feel dry, and far sounds have more space. Leave room so a loud hit can rise. Then check the words on a small speaker.", "A huge jump in voice tone between a wide shot and a close-up feels like two rooms.", "Pass the lesson on the mix."),
    ("story-structure", "Story Structure", "Story structure is the order of pressure: a want, an obstacle, and a change. Openings show the want, middles test it, and endings force a choice that costs something. Therefore and but are stronger links than and then.", "Each scene can be a small story whose result makes the next scene necessary.", "Pass the lesson on story shape."),
    ("character-desire", "Character Desire", "Desire is what a person is trying to get. A want you can photograph is easier to track than a mood. Opposition and immediate stakes turn the want into drama. The deeper need may not match the want.", "If several people want things, let those wants collide.", "Pass the lesson on desire."),
    ("scene-goal", "Scene Goal", "A scene goal is the change that must happen before the scene ends. The person tries a tactic, the balance turns, and the exit leaves a new problem. Talk can hide the goal, but the goal still has to be there.", "If nothing is different at the end, you may have written a corridor.", "Pass the lesson on scene goals."),
    ("subtext", "Subtext", "Subtext is the meaning under the words. Props, contradictions, and status in the blocking can say what the dialogue avoids. Trust the audience to do the math when the situation is clear.", "A speech that explains the moral often replaces behavior the scene could have shown.", "Pass the lesson on subtext."),
    ("dialogue", "Dialogue", "Dialogue is speech shaped like talk: short, evasive, and full of different rhythms. Read it aloud. On-the-nose lines say the feeling directly. A pause can be a line. The last line should turn or release the scene.", "Give each person a different sentence shape so their mouths are not interchangeable.", "Pass the lesson on dialogue."),
    ("logline", "Logline", "A logline is one or two sentences with a protagonist, a goal, an obstacle, and the stakes. It should open the question rather than spoil the ending. A useful length is about twenty-five to forty words.", "If the sentence is a list of scenes, it is no longer a compass.", "Pass the lesson on loglines."),
    ("blocking", "Blocking", "Blocking is the path of bodies in a space: who approaches, who retreats, and where people stop. Triangles keep faces visible. Distance changes when tactics change. Hands need a job so the movement looks caused.", "Tie a mark to a look or an object so the actor is not marching to tape.", "Pass the lesson on blocking."),
    ("coverage", "Coverage", "Coverage is the set of angles that lets a scene be cut: often a master, singles, and inserts. The master protects geography. Inserts should match the light. A safe version plus a braver version keeps the day alive.", "Write why each shot exists. If you cannot, you may not need the setup.", "Pass the lesson on coverage."),
    ("rehearsal", "Rehearsal", "Rehearsal turns the page into behavior. Talk about the immediate want, then walk the space, then check that the camera can see the path. Cut dead lines in the room. Stop before the life is polished away.", "Ask what the person wants in the next ten seconds, not how to feel in general.", "Pass the lesson on rehearsal."),
    ("tone", "Tone", "Tone is the attitude of the telling. Performance, light, lens, and cutting should agree on how big the feelings are. Shifts in tone need a marked moment or they feel like a different film wandered in.", "On set, replace tone adjectives with actions a person can play.", "Pass the lesson on tone."),
    ("shot-list", "Shot List", "A shot list orders the setups and states the purpose of each. Group work that shares a lighting state. Mark what the scene must have and what is only a gift. Rewrite the list when the scene changes.", "A list that needs more hours than the day has is a wish.", "Pass the lesson on shot lists."),
    ("set-communication", "Set Communication", "Set communication is how decisions and quiet move through the company. One person calls the take. Notes stay short. Department leads hear plan changes. A clear choice lets everyone move.", "Praise a save out loud. People protect a set where credit is shared.", "Pass the lesson on talking on set."),
    ("rack-focus", "Rack Focus", "A rack focus shifts sharpness from one plane to another during the shot, handing attention from a near face to a far door or the reverse. The shift itself is the cut, done inside one image.", "Motivate the shift with a look or a sound so it feels noticed by someone.", "Unlocks when a streak reaches 3 days."),
    ("jump-cut", "Jump Cut", "A jump cut joins two similar angles and drops a piece of time, so the person seems to blink forward. It can feel comic, anxious, or modern. In a classical scene it reads as a mistake unless the style wants the jump.", "Use it when time itself is the feeling, not when you are hiding a flub.", "Unlocks when a streak reaches 7 days."),
    ("match-cut", "Match Cut", "A match cut joins two shots through a similar shape, motion, or idea, such as a round window becoming a round plate. The audience feels the comparison before they can explain it.", "The match should say something, not only look clever.", "Unlocks when a streak reaches 14 days."),
    ("chiaroscuro", "Chiaroscuro", "Chiaroscuro is a strong pattern of light and dark, with deep shadow and a bright edge of form. Faces become sculpted. The mood often feels period, secret, or severe.", "Keep one readable feature, usually the eyes, so the portrait does not turn into a pure silhouette.", "Unlocks when a streak reaches 30 days."),
    ("dolly-zoom", "Dolly Zoom", "A dolly zoom moves the camera nearer while zooming out, or farther while zooming in, so the subject stays a similar size and the background breathes. The world warps while the person holds still. It often marks a realization or a dread.", "Use it rarely. A trick this visible needs a mental shift to justify it.", "Unlocks when a streak reaches 60 days."),
    ("cold-open", "Cold Open", "A cold open starts the story before titles or ordinary setup, often in the middle of a problem. It promises tone and stakes quickly, then lets the film widen.", "Do not explain the cold open with a later speech. Let the images keep their lead.", "Unlocks when a streak reaches 100 days."),
    ("macguffin", "MacGuffin", "A MacGuffin is an object or goal everyone chases whose exact nature matters less than the chase. The case, the letter, or the prototype pushes people into conflict. The drama lives in what they will do to get it.", "Give the object clear stakes even if its inner workings stay vague.", "Unlocks at the Clapper Loader rank."),
    ("dutch-angle", "Dutch Angle", "A Dutch angle rolls the camera so the horizon tilts. Verticals lean. The frame feels unstable, intoxicated, or menacing. A slight tilt reads as an error. A clear tilt reads as style.", "Return to level when the unease should pass, or the whole film will feel accidentally crooked.", "Unlocks at the Editor rank."),
    ("eyeline", "Eyeline", "An eyeline is the direction a person looks, and where that look lands in the next shot. Matched eyelines convince us two people see each other. A missed eyeline makes them look past one another.", "If you cut to what they see, the angle of the look should agree with the angle of the object.", "Unlocks at the Director rank."),
    ("practical", "Practical Light", "A practical is a visible lamp, screen, or window light that belongs to the set. It may need help from a hidden source that copies its direction and color. The audience believes the glow they can see.", "Dim the practical bulb so it looks real on camera instead of a white blob.", "Unlocks after three perfect spotting rounds."),
    ("l-cut", "L-Cut", "An L-cut lets the sound of one shot continue under the picture of the next, or brings the next sound in early. Conversation feels smoother because words are not trapped inside a single face.", "Use it so we watch the listener while the speaker finishes.", "Unlocks after a framing score of 95 or more."),
    ("insert-shot", "Insert Shot", "An insert is a close detail of an object that the wider shots cannot read: a key, a name on paper, a ticking hand. It answers a question. Shoot it in matching light so it belongs to the scene.", "Hold the insert long enough to read, then get out.", "Unlocks after 10 diary entries."),
]

# fix any short definitions by checking later

briefs = []
brief_rows = [
    ("b1", "Rule of Thirds", "Left third, looking right", "Place the subject on the left third with open space to the right.", 0.33, 0.48, -1, True, 0.48, 0.67),
    ("b2", "Rule of Thirds", "Right third, looking left", "Place the subject on the right third with open space to the left.", 0.67, 0.48, -1, False, 0.48, 0.67),
    ("b3", "Rule of Thirds", "Upper left crossing", "Rest the subject near the upper left crossing of the grid.", 0.33, 0.33, -1, True, 0.33, 0.67),
    ("b4", "Rule of Thirds", "Lower right crossing", "Rest the subject near the lower right crossing.", 0.67, 0.67, -1, False, 0.67, 0.67),
    ("b5", "Rule of Thirds", "Left third, low horizon", "Put the subject on the left third and the horizon on the lower third.", 0.33, 0.42, 0.66, True, 0.42, 0.67),
    ("b6", "Rule of Thirds", "Right third, high horizon", "Put the subject on the right third and the horizon on the upper third.", 0.67, 0.55, 0.34, False, 0.55, 0.67),
    ("b7", "Headroom and Lead", "Generous headroom", "Leave a generous band of space above the subject.", 0.5, 0.62, -1, True, 0.62, 0.5),
    ("b8", "Headroom and Lead", "Tight headroom", "Keep the subject high, with only a little air above the head.", 0.5, 0.28, -1, True, 0.28, 0.5),
    ("b9", "Headroom and Lead", "Lead room to the right", "Face the subject right and give the look room to travel.", 0.36, 0.46, -1, True, 0.46, 0.64),
    ("b10", "Headroom and Lead", "Lead room to the left", "Face the subject left and keep the open space in front of the look.", 0.64, 0.46, -1, False, 0.46, 0.64),
    ("b11", "Headroom and Lead", "Low subject, tall sky", "Set the subject low so the upper frame feels open.", 0.48, 0.7, 0.62, True, 0.7, 0.52),
    ("b12", "Headroom and Lead", "High subject", "Lift the subject and keep headroom short.", 0.52, 0.3, -1, False, 0.3, 0.52),
    ("b13", "Horizon and Depth", "Horizon on the lower third", "Drag the horizon down so the sky owns the frame.", 0.5, 0.58, 0.67, True, 0.58, 0.5),
    ("b14", "Horizon and Depth", "Horizon on the upper third", "Lift the horizon so the ground owns the frame.", 0.5, 0.62, 0.33, True, 0.62, 0.5),
    ("b15", "Horizon and Depth", "Centered horizon", "Place the horizon near the middle for a formal, balanced view.", 0.5, 0.5, 0.5, True, 0.5, 0.5),
    ("b16", "Horizon and Depth", "Near subject, low horizon", "Bring the subject forward in the lower half and drop the horizon.", 0.42, 0.68, 0.72, True, 0.68, 0.58),
    ("b17", "Horizon and Depth", "Small subject, deep sky", "Keep the subject modest and low, with space above.", 0.62, 0.72, 0.7, False, 0.72, 0.62),
    ("b18", "Horizon and Depth", "Horizon near the eyes", "Set the horizon close to the subject's eye line.", 0.4, 0.46, 0.46, True, 0.46, 0.6),
    ("b19", "Symmetry and Balance", "Centered portrait", "Center the subject for a symmetrical portrait.", 0.5, 0.42, -1, True, 0.42, 0.5),
    ("b20", "Symmetry and Balance", "Center and level horizon", "Center the subject and park the horizon in the middle.", 0.5, 0.48, 0.5, True, 0.48, 0.5),
    ("b21", "Symmetry and Balance", "Equal side space", "Keep the subject in the middle with similar space on both sides.", 0.5, 0.5, -1, True, 0.5, 0.5),
    ("b22", "Symmetry and Balance", "Low center", "Center the subject in the lower half of the frame.", 0.5, 0.68, 0.4, True, 0.68, 0.5),
    ("b23", "Symmetry and Balance", "High center", "Center the subject in the upper half.", 0.5, 0.32, -1, False, 0.32, 0.5),
    ("b24", "Symmetry and Balance", "Formal stance", "Center the subject and keep the horizon quiet behind them.", 0.5, 0.44, 0.55, True, 0.44, 0.5),
]
for row in brief_rows:
    briefs.append({
        "id": row[0], "category": row[1], "title": row[2], "detail": row[3],
        "subjectX": row[4], "subjectY": row[5], "horizon": row[6],
        "faceRight": row[7], "headroom": row[8], "lead": row[9],
    })

badges = [
    ("first-slate", "First full slate", "Finish all four Takes in a single day."),
    ("light-3", "Three-day light", "Reach a best streak of 3 days."),
    ("light-7", "Week of light", "Reach a best streak of 7 days."),
    ("light-14", "Two-week light", "Reach a best streak of 14 days."),
    ("light-30", "Month of light", "Reach a best streak of 30 days."),
    ("light-60", "Long burn", "Reach a best streak of 60 days."),
    ("light-100", "Hundred-day light", "Reach a best streak of 100 days."),
    ("full-5", "Five full slates", "Complete five full slates."),
    ("perfect-3", "Three perfect rounds", "Finish three Shot Spotter rounds with every frame correct."),
    ("composer-95", "Eye of the lens", "Score 95 or higher on any framing brief."),
    ("diary-10", "Ten watch notes", "Save 10 diary entries."),
    ("lines-25", "Twenty-five loglines", "Save 25 ideas in the script pad."),
    ("track-1", "Track complete", "Pass every lesson in one track."),
    ("track-all", "All tracks", "Pass every lesson in all six tracks."),
    ("night-owl", "Night owl", "Complete a Take after 22:00."),
    ("early-bird", "Early bird", "Complete a Take before 08:00."),
    ("weekend", "Weekend slate", "Finish a full slate on Saturday or Sunday."),
    ("lesson-1", "First checkpoint", "Pass one lesson."),
    ("lesson-10", "Ten lessons", "Pass 10 lessons."),
    ("lesson-all", "Every lesson", "Pass all 36 lessons."),
    ("diary-1", "First log", "Save one diary entry."),
    ("watch-10", "Shelf of ten", "Keep 10 titles on the watch shelf."),
    ("terms-10", "Ten terms opened", "Open 10 glossary terms."),
    ("vault-12", "Twelve frames", "Unlock 12 frame cards."),
    ("vault-all", "Full vault", "Unlock all 48 frame cards."),
    ("rank-editor", "Editor rank", "Reach 1600 Reels."),
    ("rank-auteur", "Auteur rank", "Reach 4000 Reels."),
    ("spotter-50", "Fifty rounds", "Finish 50 Shot Spotter rounds."),
    ("pad-5", "Five ideas", "Save 5 loglines."),
    ("pass-earned", "Rest pass earned", "Earn a rest day pass from a streak."),
]

posters = [
    ("poster-0", "First Beam", "Pass any lesson."),
    ("poster-1", "Loader Stripe", "Reach Clapper Loader."),
    ("poster-2", "Reader Panels", "Reach Script Reader."),
    ("poster-3", "Seven Day Glow", "Hold a 7 day streak."),
    ("poster-4", "Selected Frame", "Reach the festival Selected tier."),
    ("poster-5", "Nominee Frame", "Reach the festival Nominee tier."),
    ("poster-6", "Winner Frame", "Reach the festival Winner tier."),
    ("poster-7", "Edit Bay", "Reach Editor."),
    ("poster-8", "Fortnight", "Hold a 14 day streak."),
    ("poster-9", "Director Wash", "Reach Director."),
    ("poster-10", "Month Mark", "Hold a 30 day streak."),
    ("poster-11", "Last Aisle", "Reach Auteur."),
]

reminders = [
    "Your slate is ready. Two Takes keep the light bright.",
    "A short lesson is waiting in today's slate.",
    "Name one shot you noticed, then log it.",
    "The framing drill takes one round.",
    "Write a logline before the day ends.",
    "The projector light prefers a finished Take.",
    "Open the frame of the day and read the term.",
    "Five frames. One round. The eye gets sharper.",
    "A diary line about what you noticed is enough.",
    "The festival counts every Take you finish.",
    "Return for the next card in your track.",
    "Keep the beam steady with today's slate.",
    "A single saved idea still moves the pad forward.",
    "Look at the week strip and decide the next Take.",
]

genres = ["Mystery", "Romance", "Western", "Science tale", "Family drama", "Heist", "Coming of age", "Ghost story", "Sports drama", "Political thriller", "Road story", "Workplace comedy"]
protagonists = [
    "a cautious archivist", "a night-shift nurse", "a retired mapmaker", "a junior stagehand",
    "a stubborn ferry pilot", "a gifted forger", "a quiet astronomer", "a small-town mayor",
    "a traveling violinist", "an apprentice chef", "a disgraced coach", "a lighthouse keeper",
    "a student journalist", "a park ranger", "a wedding planner", "a subway driver",
    "a puzzle designer", "a choir director", "a storm chaser", "a bookbinder",
    "a wildlife vet", "a clock restorer", "a radio host", "a mountain guide",
]
obstacles = [
    "a sealed archive", "a rival who knows the secret", "a storm that traps the town", "a missing sibling",
    "a deadline before dawn", "a false accusation", "a broken bridge", "a family oath",
    "a blackout", "a stolen notebook", "a fading memory", "a locked theater",
    "a censored broadcast", "a collapsing mine", "a forged letter", "a silent witness",
    "a quarantine", "a championship rule", "a haunted stage", "a drought",
    "a strike", "a lost map", "a courtroom clock", "a vanishing train",
]
twists = [
    "the helper is the one who hid the proof", "the goal protects the wrong person", "the town already knows",
    "the object is empty", "the deadline was a decoy", "the rival is a relative", "the storm is man-made",
    "the memory belongs to someone else", "the stage ghost is a living stagehand", "the map leads inward",
    "the broadcast was never live", "the coach is banned from the field", "the letter names the writer",
    "the witness can speak and chooses not to", "the quarantine is a cover", "the championship is fixed by a friend",
    "the drought hides a diverted river", "the strike leader wants the company saved", "the train never left the yard",
    "the notebook is written in the future", "the locked theater opens from inside", "the oath was never sworn",
    "the bridge was closed on purpose", "the forger is forging their own past",
]
stakes = [
    "or the building is condemned", "or a sibling stays missing", "or the town loses its ferry",
    "or an innocent person is sentenced", "or the last recording is erased", "or the company shuts the stage",
    "or the secret becomes public", "or the team is disbanded", "or the lighthouse goes dark",
    "or the wedding exposes a lie", "or the mine claims another crew", "or the choir loses its hall",
    "or the map is sold", "or the broadcast is silenced", "or the drought becomes permanent",
    "or the train line closes", "or the archive is burned", "or the ranger loses the park",
    "or the journalist is discredited", "or the family never speaks again",
]
moods = ["Thrilled", "Moved", "Inspired", "Tense", "Amused", "Haunted", "Calm", "Curious", "Restless", "Nostalgic", "Challenged", "Bored"]

book = {
    "tracks": tracks,
    "lessons": L,
    "terms": [{"id": a, "title": b, "definition": c, "tip": d, "unlock": e} for a, b, c, d, e in terms],
    "badges": [{"id": a, "title": b, "detail": c} for a, b, c in badges],
    "briefs": briefs,
    "genres": genres,
    "protagonists": protagonists,
    "obstacles": obstacles,
    "twists": twists,
    "stakes": stakes,
    "reminders": reminders,
    "moods": moods,
    "posters": [{"id": a, "name": b, "unlock": c} for a, b, c in posters],
}

problems = []
if len(L) != 36:
    problems.append(f"lessons {len(L)}")
for item in L:
    if not (6 <= len(item["cards"]) <= 8):
        problems.append(f"cards {item['id']}")
    for c in item["cards"]:
        if words(c["body"]) < 25:
            problems.append(f"short {c['id']} {words(c['body'])}")
    if len(item["quiz"]) != 3:
        problems.append(f"quiz {item['id']}")
    for q in item["quiz"]:
        if len(q["options"]) != 4:
            problems.append(f"options {q['id']}")
if len(terms) != 48:
    problems.append("terms")
if len(badges) != 30:
    problems.append("badges")
if len(briefs) != 24:
    problems.append("briefs")
for name, seq, need in [
    ("genres", genres, 12), ("protagonists", protagonists, 24), ("obstacles", obstacles, 24),
    ("twists", twists, 24), ("stakes", stakes, 20), ("reminders", reminders, 14), ("moods", moods, 12),
]:
    if len(seq) != need:
        problems.append(name)
if problems:
    raise SystemExit("CONTENT " + ", ".join(problems))

out = os.path.join(os.path.dirname(__file__), "..", "REELHOUSE", "Code", "Content", "vyreth_book.json")
os.makedirs(os.path.dirname(out), exist_ok=True)
with open(out, "w", encoding="utf-8") as handle:
    json.dump(book, handle, ensure_ascii=False, indent=2)
    handle.write("\n")
print("wrote", out, "lessons", len(L), "terms", len(terms))
