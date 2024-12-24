user_pref("media.hardware-video-decoding.force-enabled", true);
// Thought this is NVIDIA specific?
user_pref("media.ffmpeg.vaapi.enabled", true);
// None of our devices support this
user_pref("media.av1.enabled", false);

// TODO: Change to Video only
// Disable autoplay for audio and video
user_pref("media.autoplay.default", 5);