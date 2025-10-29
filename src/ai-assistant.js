// AI Assistant for part suggestion and parameter generation
import { AI_SYSTEM_PROMPT, AI_EXAMPLES, OPENAI_CONFIG, CONSTRAINTS } from './config.js';

export class AIAssistant {
  constructor(apiKey) {
    this.apiKey = apiKey;
    this.baseURL = 'https://api.openai.com/v1/chat/completions';
  }

  /**
   * Generate shape recipe from user description
   * @param {string} userDescription - What the user needs
   * @param {Object} measurements - AR measurements
   * @returns {Promise<Object>} - Shape recipe
   */
  async generateShapeRecipe(userDescription, measurements = {}) {
    try {
      const recipePrompt = this.buildRecipePrompt(userDescription, measurements);

      const response = await fetch(this.baseURL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.apiKey}`
        },
        body: JSON.stringify({
          model: OPENAI_CONFIG.model,
          temperature: 0.3,
          max_tokens: 1500,
          messages: [
            { role: 'system', content: this.getRecipeSystemPrompt() },
            { role: 'user', content: recipePrompt }
          ],
          response_format: { type: "json_object" }
        })
      });

      if (!response.ok) {
        throw new Error(`OpenAI API error: ${response.status}`);
      }

      const data = await response.json();
      const recipe = JSON.parse(data.choices[0].message.content);

      return this.validateRecipe(recipe);

    } catch (error) {
      console.error('AI recipe generation failed:', error);
      return this.fallbackRecipe(userDescription, measurements);
    }
  }

  /**
   * Get AI suggestion for part generation
   * @param {string} userDescription - What the user needs
   * @param {Object} measurements - AR measurements
   * @param {Object} constraints - Manufacturing constraints
   * @returns {Promise<Object>} - Structured part specification
   */
  async suggestPart(userDescription, measurements = {}, constraints = CONSTRAINTS) {
    try {
      // Build user prompt
      const userPrompt = this.buildUserPrompt(userDescription, measurements, constraints);

      // Call OpenAI API
      const response = await fetch(this.baseURL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.apiKey}`
        },
        body: JSON.stringify({
          model: OPENAI_CONFIG.model,
          temperature: OPENAI_CONFIG.temperature,
          max_tokens: OPENAI_CONFIG.max_tokens,
          messages: [
            { role: 'system', content: AI_SYSTEM_PROMPT },
            ...this.buildFewShotExamples(),
            { role: 'user', content: userPrompt }
          ],
          response_format: { type: "json_object" }
        })
      });

      if (!response.ok) {
        throw new Error(`OpenAI API error: ${response.status} ${response.statusText}`);
      }

      const data = await response.json();
      const suggestion = JSON.parse(data.choices[0].message.content);

      // Validate and sanitize
      return this.validateSuggestion(suggestion, constraints);

    } catch (error) {
      console.error('AI suggestion failed:', error);
      
      // Fallback to rule-based suggestion
      return this.fallbackSuggestion(userDescription, measurements, constraints);
    }
  }

  /**
   * Build user prompt with measurements and constraints
   */
  buildUserPrompt(userDescription, measurements, constraints) {
    return `User request: "${userDescription}"

AR measurements (mm): ${JSON.stringify(measurements, null, 2)}

Constraints: ${JSON.stringify({
  nozzle_diameter: constraints.nozzle_diameter,
  min_thickness: constraints.min_thickness,
  min_hole_diameter: constraints.min_hole_diameter
}, null, 2)}

Return JSON with part specification.`;
  }

  /**
   * Build few-shot examples for context
   */
  buildFewShotExamples() {
    return AI_EXAMPLES.flatMap(example => [
      { 
        role: 'user', 
        content: `User request: "${example.user}"\n\nAR measurements (mm): ${JSON.stringify(example.ar_measurements)}`
      },
      { 
        role: 'assistant', 
        content: JSON.stringify(example.response)
      }
    ]);
  }

  /**
   * Validate AI suggestion against constraints
   */
  validateSuggestion(suggestion, constraints) {
    const validated = { ...suggestion };

    // Ensure required fields exist
    if (!validated.part_type || !validated.parameters) {
      throw new Error('Invalid suggestion format');
    }

    // Clamp parameters to constraints
    const params = validated.parameters;

    if (params.thickness) {
      params.thickness = Math.max(params.thickness, constraints.min_thickness);
    }

    if (params.holes) {
      params.holes = params.holes.map(hole => ({
        ...hole,
        diameter: Math.max(hole.diameter, constraints.min_hole_diameter)
      }));
    }

    // Ensure all dimensions are within max bounds
    Object.keys(params).forEach(key => {
      if (typeof params[key] === 'number' && params[key] > constraints.max_dimension) {
        params[key] = constraints.max_dimension;
      }
    });

    return validated;
  }

  /**
   * Fallback rule-based suggestion when AI fails
   */
  fallbackSuggestion(userDescription, measurements, constraints) {
    const lowerDesc = userDescription.toLowerCase();

    // Keyword matching
    let partType = 'shim'; // default
    
    if (lowerDesc.includes('washer') || lowerDesc.includes('disc')) {
      partType = 'washer';
    } else if (lowerDesc.includes('bracket') || lowerDesc.includes('l-shape')) {
      partType = 'l_bracket';
    } else if (lowerDesc.includes('clamp') || lowerDesc.includes('u-shape')) {
      partType = 'u_clamp';
    } else if (lowerDesc.includes('plate') || lowerDesc.includes('face')) {
      partType = 'face_plate';
    } else if (lowerDesc.includes('clip') || lowerDesc.includes('spring')) {
      partType = 'clip';
    }

    // Generate basic parameters from measurements
    const params = this.generateBasicParameters(partType, measurements, constraints);

    return {
      part_type: partType,
      parameters: params,
      derived_from: ['Fallback rule-based suggestion'],
      tolerance: { fit: 'slip', delta_mm: 0.2 },
      material: { suggested: 'PLA', infill: 30, perimeters: 3 },
      notes: 'Generated using keyword matching (AI unavailable)'
    };
  }

  /**
   * Generate basic parameters from measurements
   */
  generateBasicParameters(partType, measurements, constraints) {
    const params = {};
    const measArray = Object.values(measurements);

    switch (partType) {
      case 'shim':
        params.length = measArray[0] || 30;
        params.width = measArray[1] || 30;
        params.thickness = measArray[2] || constraints.min_thickness * 2;
        params.chamfer = 0.5;
        break;

      case 'washer':
        params.outer_d = measArray[0] || 12;
        params.inner_d = measArray[1] || 5;
        params.thickness = measArray[2] || 2;
        break;

      case 'l_bracket':
        params.leg_a = measArray[0] || 40;
        params.leg_b = measArray[1] || 40;
        params.thickness = measArray[2] || 3;
        params.fillet = 4;
        params.holes = [];
        break;

      case 'u_clamp':
        params.width = measArray[0] || 20;
        params.height = measArray[1] || 30;
        params.depth = measArray[2] || 10;
        params.thickness = 3;
        params.holes = [];
        break;

      case 'face_plate':
        params.length = measArray[0] || 50;
        params.width = measArray[1] || 50;
        params.thickness = measArray[2] || 3;
        params.holes = [];
        break;

      case 'clip':
        params.outer_d = measArray[0] || 15;
        params.inner_d = measArray[1] || 12;
        params.thickness = 2;
        params.gap_angle = 60;
        break;
    }

    return params;
  }

  /**
   * Check if API key is available
   */
  isConfigured() {
    return !!this.apiKey && this.apiKey !== 'your_openai_api_key_here';
  }

  /**
   * Get system prompt for recipe generation
   */
  getRecipeSystemPrompt() {
    return `You are a 3D CAD assistant that generates shape recipes.

Available primitives: cylinder, box, sphere, cone, torus
Operations: add (combine shapes), subtract (cut away), intersect (keep overlap)

Generate a JSON recipe with these exact fields:
{
  "description": "brief description",
  "steps": [
    {
      "id": 1,
      "operation": "add|subtract|intersect",
      "shape": "cylinder|box|sphere|cone|torus",
      "params": {
        // For cylinder: diameter, height
        // For box: length, width, height
        // For sphere: diameter
        // For cone: top_d, bottom_d, height
        // For torus: diameter, tube_diameter
      },
      "position": [x, y, z],
      "note": "what this step does"
    }
  ]
}

Rules:
- All dimensions in millimeters
- First step must be "add"
- Use measurements when provided
- Add 0.3mm clearance for fits
- Keep it simple (3-6 steps)
- Position is relative to origin [0,0,0]`;
  }

  /**
   * Build recipe generation prompt
   */
  buildRecipePrompt(userDescription, measurements) {
    return `User wants: "${userDescription}"

Measurements available: ${JSON.stringify(measurements, null, 2)}

Generate a shape recipe to build this object.`;
  }

  /**
   * Validate recipe structure
   */
  validateRecipe(recipe) {
    if (!recipe.steps || !Array.isArray(recipe.steps)) {
      throw new Error('Invalid recipe: missing steps array');
    }

    // Ensure first operation is "add"
    if (recipe.steps.length > 0 && recipe.steps[0].operation !== 'add') {
      recipe.steps[0].operation = 'add';
    }

    // Ensure all steps have required fields
    recipe.steps = recipe.steps.map((step, index) => ({
      id: step.id || index + 1,
      operation: step.operation || 'add',
      shape: step.shape,
      params: step.params,
      position: step.position || [0, 0, 0],
      note: step.note || ''
    }));

    return recipe;
  }

  /**
   * Fallback recipe if AI fails
   */
  fallbackRecipe(userDescription, measurements) {
    const lowerDesc = userDescription.toLowerCase();
    const measArray = Object.values(measurements);

    // Simple cylinder (default)
    let recipe = {
      description: "Simple cylinder shape",
      steps: [
        {
          id: 1,
          operation: "add",
          shape: "cylinder",
          params: {
            diameter: measArray[0] || 30,
            height: measArray[1] || 15
          },
          position: [0, 0, 0],
          note: "Main body"
        }
      ]
    };

    // Check for lid/cap keywords
    if (lowerDesc.includes('lid') || lowerDesc.includes('cap')) {
      recipe = {
        description: "Simple lid",
        steps: [
          {
            id: 1,
            operation: "add",
            shape: "cylinder",
            params: {
              diameter: (measArray[0] || 28) + 2,
              height: 15
            },
            position: [0, 0, 0],
            note: "Outer body"
          },
          {
            id: 2,
            operation: "subtract",
            shape: "cylinder",
            params: {
              diameter: (measArray[0] || 28) - 0.3,
              height: 12
            },
            position: [0, 1.5, 0],
            note: "Inner cavity"
          }
        ]
      };
    }

    return recipe;
  }
}

