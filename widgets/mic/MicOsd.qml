import "../sound"
import "../shared"

VolumeStyleOsd {
    vol: MicService.vol
    muted: MicService.muted
    audioTarget: MicService.source?.audio
    mutedTextKey: "mic.muted"
    iconFor: function (v, m) {
        return m || v === 0 ? "󰍭" : "󰍬";
    }
}
