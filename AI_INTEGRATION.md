# AI Integration Guide

## How the Light AI Layer Works

The AR Repair Generator uses a "light AI layer" that doesn't try to recognize objects, but instead helps with:

1. **Part type classification** from user descriptions
2. **Parameter generation** from AR measurements
3. **Tolerance and material suggestions**

## Architecture

```
User Input + AR Measurements
        ↓
    AI Assistant (GPT-4o-mini)
        ↓
  Structured JSON Response
        ↓
   Parametric CAD Generator
        ↓
      3D Model (STL)
```

## AI Prompt System

### System Prompt
Located in `src/config.js` as `AI_SYSTEM_PROMPT`

**Purpose:** Instructs the AI to:
- Choose from 6 part archetypes
- Use AR measurements when available
- Return structured JSON only
- Apply manufacturing constraints
- Suggest materials and tolerances

### Few-Shot Examples
Located in `src/config.js` as `AI_EXAMPLES`

**Purpose:** Show the AI how to respond with 3 concrete examples:
1. Table shim from gap measurement
2. L-bracket with screw holes
3. Washer with clearance tolerance

These examples teach the AI to:
- Round measurements appropriately
- Add clearances for screws
- Choose materials based on use case
- Explain reasoning

## User Prompt Template

```javascript
User request: "{free_text}"
AR measurements (mm): {measurements_json}
Constraints: {constraints_json}

Return JSON:
{
  "part_type": "...",
  "parameters": { ... },
  "derived_from": ["..."],
  "tolerance": { ... },
  "material": { ... },
  "notes": "..."
}
```

## Response Schema

### Shim Example
```json
{
  "part_type": "shim",
  "parameters": {
    "length": 30,
    "width": 25,
    "thickness": 2.0,
    "chamfer": 0.5
  },
  "derived_from": [
    "thickness <- round_up(gap measurement)",
    "dimensions from foot area"
  ],
  "tolerance": {
    "fit": "press",
    "delta_mm": 0.1
  },
  "material": {
    "suggested": "PLA",
    "infill": 20,
    "perimeters": 2
  },
  "notes": "Round up 1.8→2.0 mm to remove wobble; chamfer for easy insertion"
}
```

### L-Bracket Example
```json
{
  "part_type": "l_bracket",
  "parameters": {
    "leg_a": 40,
    "leg_b": 60,
    "thickness": 3,
    "fillet": 4,
    "holes": [
      { "diameter": 4.5, "offset_a": 10, "offset_b": 10 },
      { "diameter": 4.5, "offset_a": 10, "offset_b": 30 }
    ]
  },
  "derived_from": [
    "leg lengths rounded to nearest mm",
    "hole_d + 0.3mm for M4 clearance"
  ],
  "tolerance": {
    "fit": "clearance",
    "delta_mm": 0.3
  },
  "material": {
    "suggested": "PETG",
    "infill": 40,
    "perimeters": 4
  },
  "notes": "Clearance for M4 screws; fillets to reduce stress"
}
```

## Fallback System

If AI is unavailable or fails, the system uses rule-based fallbacks:

### Keyword Matching
```javascript
"washer" || "disc" → washer
"bracket" || "l-shape" → l_bracket
"clamp" || "u-shape" → u_clamp
"plate" || "face" → face_plate
"clip" || "spring" → clip
default → shim
```

### Parameter Inference
```javascript
// For shim:
length = measurements[0] || 30
width = measurements[1] || 30
thickness = measurements[2] || (min_thickness * 2)

// For washer:
outer_d = measurements[0] || 12
inner_d = measurements[1] || 5
thickness = measurements[2] || 2

// etc...
```

## Manufacturing Constraints

Defined in `src/config.js` as `CONSTRAINTS`:

```javascript
{
  nozzle_diameter: 0.4,      // mm
  min_thickness: 0.8,        // 2x nozzle
  min_hole_diameter: 2.0,    // mm
  max_dimension: 200,        // mm (print bed size)
  tolerances: {
    press: -0.2,             // mm (tighter)
    slip: 0.1,               // mm (normal)
    clearance: 0.3           // mm (loose)
  }
}
```

## Validation

After AI generates suggestions, `validateParameters()` ensures:
- Thickness ≥ min_thickness (0.8mm)
- Hole diameters ≥ min_hole_diameter (2mm)
- All dimensions ≤ max_dimension (200mm)
- Values clamped to safe ranges

## API Configuration

### Model Selection
```javascript
model: 'gpt-4o-mini'        // Fast, cheap, good enough
temperature: 0.3            // Low for consistency
max_tokens: 1000           // Plenty for JSON response
```

### Cost Estimate
- Input: ~500 tokens per request
- Output: ~200 tokens per request
- Cost: ~$0.0001 per generation
- Very affordable for this use case!

## Integration Points

### In `main.js`
```javascript
// Initialize with API key
this.aiAssistant = new AIAssistant(apiKey);

// Generate part
const spec = await this.aiAssistant.suggestPart(
  userDescription,
  measurements,
  constraints
);

// Use the structured response
const mesh = generatePart(spec.part_type, spec.parameters);
```

### API Key Management
1. Environment variable: `VITE_OPENAI_API_KEY`
2. localStorage: `openai_api_key`
3. Runtime prompt: User enters in UI

## Extending the AI

### Add New Part Type

1. **Define in config.js:**
```javascript
PART_TYPES.hex_nut = {
  name: 'Hex Nut',
  emoji: '🔩',
  requiredParams: ['outer_d', 'inner_d', 'thickness']
}
```

2. **Add example:**
```javascript
AI_EXAMPLES.push({
  user: "Need a hex nut for M6 bolt",
  ar_measurements: { bolt_d: 6.1 },
  response: {
    part_type: "hex_nut",
    parameters: { outer_d: 11, inner_d: 6.3, thickness: 5 },
    // ...
  }
})
```

3. **Update system prompt:**
Add "hex_nut" to the available types list

4. **Create generator:**
```javascript
export function generateHexNut(params) {
  // Three.js geometry
}
```

### Tune Behavior

Edit `AI_SYSTEM_PROMPT` to change:
- **Tolerance philosophy**: More clearance, tighter fits, etc.
- **Material preferences**: Default to PETG, recommend TPU for flex
- **Dimension rounding**: Nearest 0.5mm, nearest 1mm, etc.
- **Safety margins**: Add extra thickness for strength

### Add Smart Features

Ideas for enhancement:
1. **Shape picker**: "Your points look like a 2-hole plate"
2. **Material switcher**: Suggest PETG for thick brackets
3. **Repair recipes**: Step-by-step assembly instructions
4. **Failure prediction**: "This might be too thin for load"

## Testing the AI

### Test Prompts

```javascript
// Simple spacer
"Need a small spacer for wobbly table"
Measurements: { gap: 2.5 }

// Complex bracket
"L-bracket to mount shelf, needs 2 screws"
Measurements: { leg_a: 50, leg_b: 40, hole_d: 4.0 }

// Ambiguous (tests fallback)
"Something to fix my thing"
Measurements: {}
```

### Expected Behavior

✅ Returns valid JSON
✅ Respects constraints
✅ Includes derived_from explanations
✅ Suggests appropriate materials
✅ Falls back gracefully on errors

## Security Notes

⚠️ **API Key Protection**
- Current: Client-side key (dev only)
- Production: Use backend proxy
- Environment vars are exposed in browser
- Consider serverless function (Netlify/Vercel)

## Performance

- Average latency: 1-2 seconds
- Caching: None (each generation is unique)
- Offline: Falls back to rule-based system
- No training required!

## Why This Approach Works

1. **Not trying to solve vision**: No image recognition needed
2. **Structured output**: No parsing headaches
3. **Deterministic fallback**: Always works without AI
4. **Cheap to run**: Pennies per day
5. **Easy to tune**: Just edit prompts
6. **Explainable**: Shows reasoning in `derived_from`

This is the "light AI layer" in action – using LLMs for what they're good at (structured reasoning) without asking them to do magic! 🎯

