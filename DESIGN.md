---
name: Atelier Acoustique
colors:
  surface: '#131314'
  surface-dim: '#131314'
  surface-bright: '#3a393a'
  surface-container-lowest: '#0e0e0f'
  surface-container-low: '#1c1b1c'
  surface-container: '#201f20'
  surface-container-high: '#2a2a2b'
  surface-container-highest: '#353436'
  on-surface: '#e5e2e3'
  on-surface-variant: '#c6c7c0'
  inverse-surface: '#e5e2e3'
  inverse-on-surface: '#313031'
  outline: '#90918b'
  outline-variant: '#454742'
  surface-tint: '#c7c7c2'
  primary: '#ffffff'
  on-primary: '#30312e'
  primary-container: '#e3e3de'
  on-primary-container: '#646561'
  inverse-primary: '#5e5f5b'
  secondary: '#e0c298'
  on-secondary: '#402d0f'
  secondary-container: '#584323'
  on-secondary-container: '#ceb188'
  tertiary: '#ffffff'
  on-tertiary: '#32302d'
  tertiary-container: '#e7e1dd'
  on-tertiary-container: '#676460'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e3e3de'
  primary-fixed-dim: '#c7c7c2'
  on-primary-fixed: '#1b1c19'
  on-primary-fixed-variant: '#464744'
  secondary-fixed: '#fedeb2'
  secondary-fixed-dim: '#e0c298'
  on-secondary-fixed: '#281800'
  on-secondary-fixed-variant: '#584323'
  tertiary-fixed: '#e7e1dd'
  tertiary-fixed-dim: '#cbc6c1'
  on-tertiary-fixed: '#1d1b19'
  on-tertiary-fixed-variant: '#494643'
  background: '#131314'
  on-background: '#e5e2e3'
  surface-variant: '#353436'
typography:
  headline-xl:
    fontFamily: Hanken Grotesk
    fontSize: 56px
    fontWeight: '300'
    lineHeight: 64px
    letterSpacing: -0.03em
  headline-xl-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 36px
    fontWeight: '300'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 40px
    fontWeight: '400'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 28px
    fontWeight: '400'
    lineHeight: 36px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '400'
    lineHeight: 32px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '300'
    lineHeight: 28px
    letterSpacing: -0.005em
  body-md:
    fontFamily: Hanken Grotesk
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0em
  body-sm:
    fontFamily: Hanken Grotesk
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.08em
  label-sm:
    fontFamily: JetBrains Mono
    fontSize: 10px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.12em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 1.5rem
  gutter-sm: 1rem
  margin: 3rem
  margin-sm: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 2rem
  space-xl: 3.5rem
---

## Brand & Style

This design system embodies the tension between industrial precision and editorial silence. Drawing from Braun-era functionalism, Leica mechanical restraint, and Swiss acoustic engineering, the UI functions not as software, but as an engineered instrument of milled metal, museum glass, and negative space. 

The aesthetic is ultra-reductive, quiet, and hyper-deliberate. It is built for discerning audiophiles, acoustic engineers, and design purists who demand cognitive calm, tactile certainty, and timeless elegance. Every pixel must justify its presence; decorative fluff is strictly forbidden. The emotional tone is whisper-quiet authority, uncompromising physical luxury, and surgical clarity.

## Colors

The palette is anchored in an uncompromising deep obsidian environment punctuated by cashmere ivory and microscopic warm accents.

- **Neutral Canvas (`#0A0A0B`)**: Deep warm obsidian black. The foundational plane of the entire system. Never pure flat digital black `#000000`; it carries a minute fraction of warmth to mirror anodized matte black aluminum.
- **Primary Text & High Contrast Elements (`#F5F4EF`)**: Cashmere cream / warm ivory. Delivers high contrast without the clinical glare of synthetic white. Used for essential typographic hierarchy and primary controls.
- **Secondary Accent (`#C5A880`)**: Muted champagne gold. Reserved strictly for active states, focal micro-indicators, precision needles, and primary focal highlights. Must be deployed with extreme restraint—never as large background fills.
- **Tertiary & Muted Neutrals (`#2A2825` to `#161514`)**: Milled charcoal and whisper-soft warm taupe. Used for hairline dividers, inactive tick marks, and recessed surface containers.
- **Sub-surfaces**: Muted dark obsidian (`#121112`) with frosted opacity overlays (`rgba(245, 244, 239, 0.03)`) to separate functional bays without hard chromatic shifts.

## Typography

Typography pairs surgical, architectural sans-serif forms with hyper-precise monospaced engineering metadata.

- **Primary & Headings (Hanken Grotesk)**: Chosen for its sharp geometric terminals, neutral humanist balance, and refined editorial weights. Headlines are set light and deliberate with tight optical tracking to evoke luxury print publications.
- **Data & Telemetry (JetBrains Mono)**: Employed for technical readouts, frequency intervals, decibel levels, status flags, and physical switch indicators. All monospaced labels are set in uppercase with intentional wide tracking (`0.08em` to `0.12em`) to mirror calibrated mechanical dials and high-end chassis laser engraving.

## Layout & Spacing

The layout is grounded in a disciplined 12-column fixed-max system (1440px max viewport) that transitions into a 4-column module on mobile. Generous margins and breathing rooms act as visual dampeners, isolating controls into contemplative zones.

- **Desktop (1024px+)**: 12 columns, 48px outer canvas margins (`margin`), 24px gutters (`gutter`). Generous vertical padding (`space-xl`) between distinct acoustic control clusters.
- **Tablet (768px - 1023px)**: 8 columns, 32px canvas margins, 20px gutters. Secondary telemetry folds into auxiliary drawer panels.
- **Mobile (< 768px)**: 4 columns, 20px canvas margins (`margin-sm`), 16px gutters (`gutter-sm`). Horizontal touch areas are calibrated to a 44px minimum touch target, while retaining hairline structural dividers.

## Elevation & Depth

This design system avoids high-contrast drop shadows and artificial skeuomorphic layering. Depth is communicated strictly through surface refraction, tonal shifts, and microscopic hairline borders:

1. **Base Plane**: Deep warm obsidian (`#0A0A0B`), non-reflective, flat matte.
2. **Interactive Surfaces**: Subtle frosted glassmorphic acrylic. Background surface is tinted to `rgba(22, 21, 20, 0.65)` layered with a 24px Gaussian backdrop blur (`backdrop-filter: blur(24px)`).
3. **Ghost Outlines**: Separation is rendered with a 1px solid border at `rgba(245, 244, 239, 0.08)` on quiet boundaries, shifting to `rgba(197, 168, 128, 0.35)` when an active instrument focus state is achieved.
4. **Ambient Depth**: Where physical detachment is necessary (e.g., floating volume overlays or master menu modals), use an ultra-diffused shadow: `0 32px 64px -16px rgba(0, 0, 0, 0.8)`, tinted slightly by warm obsidian.

## Shapes

The form language echoes precision-machined audio components: sharp, structural, and softly chamfered.

- Base controls, cards, and container modules adopt soft 0.25rem (4px) corner radii, referencing the delicate deburring of CNC-milled aluminum faceplates.
- Circular touch dials, rotational knobs, and focal LED pins use a continuous 50% circle geometry.
- Decorative pills are banned; buttons, badges, and readouts remain strictly rectangular or softly chamfered to preserve architectural discipline.

## Components

### Buttons
- **Primary**: Cashmere cream background (`#F5F4EF`), warm obsidian text (`#0A0A0B`), 4px corner radius. Monospaced or medium-weight sans typography. Zero shadow; purely flush.
- **Ghost / Minimalist**: Transparent background, 1px perimeter line of `rgba(245, 244, 239, 0.15)`, text in `#F5F4EF`. On hover: border transitions smoothly to delicate gold (`#C5A880`) with a subtle interior fill of `rgba(245, 244, 239, 0.04)`.

### Rotary Dials & Faders (Audio-Specific)
- **Rotary Potentiometers**: Matte dark charcoal track with a 1.5px active arc illuminated in muted gold (`#C5A880`). Center hub displays numerical telemetry in `label-sm` monospaced font.
- **Linear Attenuator Faders**: Hairline vertical track (1px) in `rgba(245, 244, 239, 0.12)`. Fader thumb is a crisp 24x8mm milled rectangle in brushed ivory with a micro center-notch indicator.

### Chips & Filters
- Compact, un-pillshaped badges (4px radius). Inactive: dark surface with `rgba(245, 244, 239, 0.06)` fill and subtle border. Active: border turns to delicate gold (`#C5A880`) with ivory text; no vibrant fills.

### Cards & Control Decks
- Framed by 1px ghost borders (`rgba(245, 244, 239, 0.07)`).
- Background uses frosted acrylic translucency (`rgba(16, 15, 14, 0.7)`).
- Interior padding uses strictly `space-lg` (32px) to prevent crowded controls.

### Input Fields
- Flush bottom-line or understated boxed surface with 1px border `rgba(245, 244, 239, 0.12)`.
- Caret and focus state glow: subtle gold (`#C5A880`).
- Text typed in high-legibility cashmere cream; placeholder values in `rgba(245, 244, 239, 0.3)`.

### Checkboxes & Toggle Switches
- **Switches**: Physical-toggle metaphor. Rectangular capsule housing a sliding square indicator. Inactive: muted charcoal. Active: delicate gold indicator with a soft 2px ambient highlight.
- **Toggles**: Square checkboxes (4px radius). Checked state reveals a microscopic 1.5px gold dot rather than a standard checkmark, reinforcing precision instrument calibration.