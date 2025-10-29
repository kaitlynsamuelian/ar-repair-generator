// Configuration for AR Repair Generator

export const PART_TYPES = {
  shim: {
    name: 'Shim',
    emoji: '📏',
    description: 'Rectangular spacer/pad',
    requiredParams: ['length', 'width', 'thickness'],
    optionalParams: ['chamfer']
  },
  washer: {
    name: 'Washer',
    emoji: '⭕',
    description: 'Disc with center hole',
    requiredParams: ['outer_d', 'inner_d', 'thickness'],
    optionalParams: []
  },
  l_bracket: {
    name: 'L-Bracket',
    emoji: '📐',
    description: 'L-shaped support with optional holes',
    requiredParams: ['leg_a', 'leg_b', 'thickness'],
    optionalParams: ['fillet', 'holes']
  },
  u_clamp: {
    name: 'U-Clamp',
    emoji: '🔩',
    description: 'U shape with mounting holes',
    requiredParams: ['width', 'height', 'depth', 'thickness'],
    optionalParams: ['holes']
  },
  face_plate: {
    name: 'Face Plate',
    emoji: '⬜',
    description: 'Flat plate with hole pattern',
    requiredParams: ['length', 'width', 'thickness'],
    optionalParams: ['holes']
  },
  clip: {
    name: 'Clip',
    emoji: '📎',
    description: 'C-shaped spring clip',
    requiredParams: ['outer_d', 'inner_d', 'thickness', 'gap_angle'],
    optionalParams: []
  }
};

// Manufacturing constraints
export const CONSTRAINTS = {
  nozzle_diameter: 0.4, // mm
  min_thickness: 0.8, // 2x nozzle
  min_hole_diameter: 2.0, // mm
  max_dimension: 200, // mm (typical print bed)
  tolerances: {
    press: -0.2,
    slip: 0.1,
    clearance: 0.3
  }
};

// AI System Prompt
export const AI_SYSTEM_PROMPT = `You are a CAD assistant for generating simple 3D-printable repair parts.

Your job:
1. Analyze user's repair need
2. Choose from: shim, washer, l_bracket, u_clamp, face_plate, clip
3. Use AR measurements when available
4. Return ONLY valid JSON matching the schema
5. Suggest tolerances and materials

Available part types:
- shim: rectangular spacer (params: length, width, thickness, chamfer?)
- washer: disc with hole (params: outer_d, inner_d, thickness)
- l_bracket: L-profile (params: leg_a, leg_b, thickness, fillet?, holes?)
- u_clamp: U-shape (params: width, height, depth, thickness, holes?)
- face_plate: flat plate (params: length, width, thickness, holes?)
- clip: C-shaped spring (params: outer_d, inner_d, thickness, gap_angle)

Rules:
- All dimensions in mm
- thickness >= 0.8mm (2x nozzle)
- Hole diameter for screws: screw_d + 0.3mm clearance
- Press fit: -0.2mm; clearance: +0.3mm
- Fillets on brackets: ~4mm
- Suggest PLA (general), PETG (strength), or TPU (flex)

Return format:
{
  "part_type": "...",
  "parameters": { ... },
  "derived_from": ["explanation of how measurements were used"],
  "tolerance": { "fit": "press|slip|clearance", "delta_mm": 0.2 },
  "material": { "suggested": "PLA", "infill": 30, "perimeters": 3 },
  "notes": "short rationale"
}`;

// Few-shot examples for AI
export const AI_EXAMPLES = [
  {
    user: "I need to stop a wobbly table; gap looks ~2 mm.",
    ar_measurements: { gap: 1.8, foot_area: { length: 30, width: 25 } },
    response: {
      part_type: "shim",
      parameters: { length: 30, width: 25, thickness: 2.0, chamfer: 0.5 },
      derived_from: ["thickness <- round_up(gap)", "dimensions from foot area"],
      tolerance: { fit: "press", delta_mm: 0.1 },
      material: { suggested: "PLA", infill: 20, perimeters: 2 },
      notes: "Round up 1.8→2.0 mm to remove wobble; chamfer for easy insertion"
    }
  },
  {
    user: "Bracket to hold a shelf; legs about 40 and 60 mm; two screws on long leg.",
    ar_measurements: { leg_a: 39.6, leg_b: 59.1, hole_d: 4.2, hole_spacing: 20 },
    response: {
      part_type: "l_bracket",
      parameters: {
        leg_a: 40,
        leg_b: 60,
        thickness: 3,
        fillet: 4,
        holes: [
          { diameter: 4.5, offset_a: 10, offset_b: 10 },
          { diameter: 4.5, offset_a: 10, offset_b: 30 }
        ]
      },
      derived_from: ["leg lengths rounded", "hole_d + 0.3mm for M4 clearance"],
      tolerance: { fit: "clearance", delta_mm: 0.3 },
      material: { suggested: "PETG", infill: 40, perimeters: 4 },
      notes: "Clearance for M4 screws; fillets to reduce stress"
    }
  },
  {
    user: "Small washer for a bolt, around 10mm outer, 5mm hole",
    ar_measurements: { hole_diameter: 5.2 },
    response: {
      part_type: "washer",
      parameters: { outer_d: 12, inner_d: 5.5, thickness: 2 },
      derived_from: ["hole_d + 0.3mm clearance", "outer_d = 2.3x inner for strength"],
      tolerance: { fit: "clearance", delta_mm: 0.3 },
      material: { suggested: "PLA", infill: 100, perimeters: 4 },
      notes: "Solid infill for compression strength"
    }
  }
];

// OpenAI API configuration
export const OPENAI_CONFIG = {
  model: 'gpt-4o-mini',
  temperature: 0.3, // Low for consistency
  max_tokens: 1000
};

