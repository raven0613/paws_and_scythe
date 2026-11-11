extends RefCounted

const POP_DURATION = 0.3
const POP_STRETCH = 0.4
const POP_TILT = 0.4
const POP_SHAKE = Vector2(10, 10)
const POP_CYCLES = 5
const POP_VERTICAL_CYCLES = 3.5
const DECAY_POWER = 2.0
const POP_LAYER = 2
const DISTURB_DISTANCE = 4.0
const DISTURB_INTERVAL = 0.08
const DISTURB_DURATION = 0.5
const DISTURB_CYCLES = 1.75
const DISTURB_TILT = 0.025
# 每側的可見列數；0 保留排列推移。最近上下各一列使用完整強度。
const INSERT_DISTURB_COUNT = 3
const HOVER_DISTURB_COUNT = 3
const DISTURB_FALLOFF = 0.65
const EXIT_SCALE = 1.2
const EXIT_RISE_DURATION = 0.08
const EXIT_SHRINK_DURATION = 0.09
const EXIT_INTERVAL = 0.08
const REFLOW_DURATION = 0.16
const REFLOW_INTERVAL = 0.08
const SETTLE_DURATION = 0.16
const SETTLE_DISTANCE = 1.5
const SETTLE_CYCLES = 1.5

# 插入時的排列推移與 DISTURB 疊加，各自使用自己的時長。
const INSERT_PUSH_DURATION = 0.25

# 平時波動；Hover 凍結共用時間，離開後從同一相位繼續。
const IDLE_AMPLITUDE = 1.5
const IDLE_PERIOD = 2.4
const IDLE_PHASE_STEP = 0.5
const IDLE_RESUME_DURATION = 0.2

# Hover 進入時回彈放大並抖動，停留時保持放大。
const HOVER_SCALE = 1.25
const HOVER_SCALE_DURATION = 0.18
const HOVER_SHAKE_DURATION = 0.25
const HOVER_SHAKE = Vector2(6.0, 4.0)
const HOVER_TILT = 0.25
const HOVER_CYCLES = 2.5
const HOVER_VERTICAL_CYCLES = 4.0
const HOVER_DECAY_POWER = 2.0
const HOVER_RELEASE_DURATION = 0.16
const HOVER_LAYER = 1
const HOVER_GAP = 6.0
