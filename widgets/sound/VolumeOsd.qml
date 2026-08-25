import "../shared"

VolumeStyleOsd {
    vol: AudioService.vol
    muted: AudioService.muted
    audioTarget: AudioService.sink?.audio
    mutedTextKey: "sound.muted"
    iconFor: function (v, m) {
        return m || v === 0 ? "󰕟" : v < 0.33 ? "󰕿" : v < 0.67 ? "󰖀" : "󰕾";
    }
}
